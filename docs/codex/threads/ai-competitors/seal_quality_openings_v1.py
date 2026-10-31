"""Publish only verified, unchanged-material certificates into a private project."""
import argparse,json,hashlib,copy
from pathlib import Path
BASE=Path(__file__).resolve().parent
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def material(c):
 d=copy.deepcopy(c['fixture']);d['world'].pop('source_identity',None);return d
def main():
 p=argparse.ArgumentParser();p.add_argument('--variant',required=True);p.add_argument('--run-suffix');p.add_argument('--output',type=Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=False)
 project=BASE/'simulators'/a.variant/'project';records=[];revision=a.variant.rsplit('-',1)[-1]
 for seed in ['5607','5613']:
  folder=BASE/f'sims/quality-shared-{seed}-20261030-{a.run_suffix or revision}';report=json.loads((folder/'cohort.json').read_text(encoding='utf-8'));result=json.loads((folder/'result.json').read_text());candidate=folder/'cohort.json.opening.json';cert=json.loads(candidate.read_text(encoding='utf-8'));target=project/f'certified/rival-opening-{seed}-v1.json';old=json.loads(target.read_text(encoding='utf-8'))
  assert result['exit']==0 and result['source_unchanged'] and not result.get('engine_errors') and not report['issues']
  manifest=json.loads((folder/'snapshot-manifest.json').read_text())
  assert all(f'certified/rival-opening-{s}-v1.json' in manifest for s in ['5607','5613']),'Missing raw certificate manifest coverage'
  assert len(report['rows'])==8 and all(r['cycle']==72 and r['scope']>=35 and r['cash']>0 and r['phase']!='studio' for r in report['rows'])
  assert all(all(r['metadata']['review']['scope']>=r['metadata']['review']['required_scope'] and r['metadata']['review']['remaining_bugs']==0 for r in studio['releases']) for studio in report['rows'])
  assert cert['source_identity']==cert['generation_source_identity']==report['source']==cert['fixture']['world']['source_identity']
  assert material(old)==material(cert),'Material drift requires a new source-bound generation pass'
  before=a.output/f'before-{seed}.json';before.write_bytes(target.read_bytes());target.write_bytes(candidate.read_bytes())
  tapes={f.name:sha(f) for f in sorted(folder.glob('*.tape.json'))}
  records.append({'seed':seed,'source':report['source'],'report_sha256':sha(folder/'cohort.json'),'before_sha256':sha(before),'certificate_sha256':sha(target),'same_material':True,'prefix_tapes':tapes,'actions':len(report['actions']),'waits':sum(x['type']=='rival_wait' for x in report['actions'])})
 (a.output/'seal.json').write_text(json.dumps({'variant':a.variant,'records':records,'no_gameplay_material_changed':True},indent=2),encoding='utf-8');print(json.dumps(records))
if __name__=='__main__':main()
