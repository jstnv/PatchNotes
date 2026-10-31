"""Three-way reuse of pinned v4 foundations into a fresh current-baseline version."""
from pathlib import Path
import json,zipfile,subprocess,sys,difflib
ROOT=Path(__file__).resolve().parents[4];sys.path.insert(0,str(ROOT/'tools'));import simulate as sim,simulator_variant as variants
T=Path(__file__).parent;old=T/'simulators/rival-founder-current-20261030-v4';new=T/'simulators/rival-quality-1977-20261030-v1';out=T/'sims/quality-foundation-port-20261030-v1'
def main():
 out.mkdir(exist_ok=False);metadata,base,source,integrity=variants.load_variant(old);nmetadata,nbase,current,nintegrity=variants.load_variant(new);rows=[]
 with zipfile.ZipFile(old/'base-source.zip') as archive:
  for rel in sorted(set(base)|set(source)):
   if base.get(rel)==source.get(rel) or rel.startswith('scripts/debug/') or not rel.endswith('.gd'):continue
   target=new/'project'/rel;theirs=(old/'project'/rel).read_text(encoding='utf-8-sig')
   if rel not in base:
    assert not target.exists(),rel;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(theirs.encode());rows.append({'path':rel,'mode':'added'});continue
   before=archive.read(rel).decode('utf-8-sig').replace('\r\n','\n');ours=target.read_text(encoding='utf-8-sig');theirs=theirs.replace('\r\n','\n')
   folder=out/rel.replace('/','__');folder.mkdir();paths=[]
   for label,text in [('current',ours),('base',before),('v4',theirs)]:
    path=folder/(label+'.gd');path.write_bytes(text.encode());paths.append(str(path.resolve()))
   result=subprocess.run(['git','merge-file','-p',*paths],stdout=subprocess.PIPE,stderr=subprocess.PIPE)
   (folder/'merge.gd').write_bytes(result.stdout);rows.append({'path':rel,'merge_exit':result.returncode})
   sim.write_json(out/'port.json',{'source_variant':str(old.resolve()),'source_identity':variants.identity(source),'current_base_identity':variants.identity(nbase),'changes':rows})
   assert result.returncode==0,(rel,result.stderr.decode())
   target.write_bytes(result.stdout)
 for name in ['one_action_prelude_probe.gd','verify_current_rival_founders.gd','verify_historical_source_guard.gd','verify_rival_scope_guard.gd','current_cohort_probe.gd']:
  path=old/'project/scripts/debug'/name
  if path.exists():(new/'project/scripts/debug'/name).write_bytes(path.read_bytes())
 sim.write_json(out/'port.json',{'source_variant':str(old.resolve()),'source_identity':variants.identity(source),'current_base_identity':variants.identity(nbase),'changes':rows,'all_merges_clean':True});print(json.dumps(rows))
if __name__=='__main__':main()
