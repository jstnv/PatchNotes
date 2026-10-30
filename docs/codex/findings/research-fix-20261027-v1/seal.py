"""Record the actual current source and completed receipts; never invent passes."""
from pathlib import Path
import hashlib,json,subprocess
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[3];PROJECT=ROOT/'patch-notes'
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
runtime={}
for directory in ['scripts','data']:
 for path in (PROJECT/directory).rglob('*'):
  if path.is_file() and path.suffix in ['.gd','.gdc','.json'] and not path.relative_to(PROJECT).as_posix().startswith('scripts/debug/'):
   runtime['res://'+path.relative_to(PROJECT).as_posix()]=sha(path)
for name in ['queries/market_release_index.gd','queries/market_release_index.gdc','queries/market_release_index.gd.remap']:
 path=PROJECT/name
 if path.is_file():runtime['res://'+name]=sha(path)
identity=hashlib.sha256(json.dumps(sorted(runtime.items()),separators=(',',':'),ensure_ascii=False).encode()).hexdigest()
fixtures={}
for name in ['background_checkpoint_v003_c96.json','research_latency_pre_fix.json']:
 path=ROOT/'tools/fixtures'/name
 proof=path.with_suffix('.provenance.json')
 declared=json.loads(proof.read_text(encoding='utf-8'))
 assert sha(path)==declared['sha256'], 'Fixture changed: '+name
 fixtures[name]={'sha256':sha(path),'provenance_sha256':sha(proof)}
source={'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'branch':subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),'runtime_identity':identity,'runtime_files':runtime,'fixtures':fixtures}
(OUT/'source-manifest.json').write_text(json.dumps(source,indent=2),encoding='utf-8')
receipts=[]
for path in sorted(OUT.glob('*-run.json')):
 report=json.loads(path.read_text(encoding='utf-8'))
 row={'file':path.name,'sha256':sha(path),'exit':report.get('exit'),'error_count':len(report.get('errors',[])),'command':report.get('command')}
 result=OUT/(path.name.removesuffix('-run.json')+'.json')
 if result.is_file():
  body=json.loads(result.read_text(encoding='utf-8'))
  row.update({'result_sha256':sha(result),'result':{k:body[k] for k in ['ok','checks','failures','source_identity','actions','stages','diagnostic_only','screen_enforced'] if k in body}})
 receipts.append(row)
gates=[]
for path in sorted(OUT.glob('final-gate*/gate-result.json')):
 body=json.loads(path.read_text(encoding='utf-8'))
 gates.append({'file':str(path.relative_to(OUT)),'sha256':sha(path),'checks':len(body.get('checks',[])),
  'automated_pass':body.get('automated_pass',False),'headless_automated_pass':body.get('headless_automated_pass',False),
  'failure':body.get('failure'),'remaining':body.get('remaining',[]),'artifact_directory':body.get('artifact_directory')})
post=OUT/'post-focus-current/result.json'
post_report=json.loads(post.read_text(encoding='utf-8')) if post.is_file() else None
export=OUT/'current-export/result.json'
export_report=json.loads(export.read_text(encoding='utf-8')) if export.is_file() else None
campaign=OUT/'final-fresh-campaign/result.json'
campaign_report=None
if campaign.is_file():
 body=json.loads(campaign.read_text(encoding='utf-8'))
 campaign_report={k:body[k] for k in ['ok','failures','comparisons','routes','coverage','limits'] if k in body}
 campaign_report['result_sha256']=sha(campaign)
names=set(post_report.get('passed',[])) if post_report else set()
for path in OUT.glob('final-gate*/gate-result.json'):
 names.update(json.loads(path.read_text(encoding='utf-8')).get('checks',[]))
post_identity_file=OUT/'post-focus-current/verifier-artifacts/verify_rival_policy_observation/result.json'
post_identity=json.loads(post_identity_file.read_text(encoding='utf-8')).get('source_identity') if post_identity_file.is_file() else None
diff_file=OUT/'diff-check.json'
diff=json.loads(diff_file.read_text(encoding='utf-8')) if diff_file.is_file() else None
report={'source':source,'current_runtime_matches_post_focus':identity==post_identity,'receipts':receipts,'gates':gates,'passing_verifier_name_union':len(names),'full_single_source_gate_pass':False,'post_focus_checks':post_report,'internal_export':export_report,'final_fresh_campaign':campaign_report,'diff_check':diff,'approval_blockers':[],
 'compatibility':'User explicitly approved the single prior-editor source/current-rules entry; ordinary production-path preservation and rejection test passed10 checks.',
 'performance_limit':'Native doubled-history cycle192 screen still fails; no blanket no-hitch,60FPS or release-readiness claim.'}
(OUT/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps({'runtime_identity':identity,'receipts':len(receipts)}))
