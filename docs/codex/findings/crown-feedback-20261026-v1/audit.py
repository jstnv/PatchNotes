"""Source-fenced closeout. No gameplay, save, Git or external service writes."""
from pathlib import Path
import hashlib, importlib.util, json, subprocess
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[3]
spec=importlib.util.spec_from_file_location('variant',ROOT/'tools/simulator_variant.py')
variant=importlib.util.module_from_spec(spec);spec.loader.exec_module(variant)
def load(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
V=ROOT/'docs/codex/threads/contracts/simulators/crown-feedback-20261026-v1'
H=ROOT/'docs/codex/threads/contracts/handoffs/crown-feedback-20261026-v1'
meta,base,current,integrity=variant.load_variant(V)
canonical=variant.sim.source_hashes(ROOT/'patch-notes')
assert base==canonical,'Canonical source changed during private work'
assert current==load(H/'candidate-manifest.json'),'Sealed candidate drift'
for name,digest in load(H/'handoff-integrity.json').items():assert sha(H/name)==digest,name
positive=['model-final','flow-guard-final','pack-guard-final','ui-v4','ui-native','ui-streak-final','pack-ui','pack-streak-final','cold-final','pack-cold-final','final-search','final-relationships','final-contracts','final-world']
receipts={}
for label in positive:
    p=OUT/(label+'-run.json');r=load(p)
    assert r['exit']==0 and not r['errors'],label
    if label.startswith('final-'):
        assert r['candidate_source_unchanged'] and r['source_manifest']==current,label
    receipts[label]={'receipt_sha256':sha(p),'exit':r['exit'],'seconds':r['seconds'],'tail':r['tail']}
failures={}
for label in ['feedback-red','ui-red-v1','ui-v2','ui-v3','contracts','pack-cold','pack-cold-diagnostic']:
    p=OUT/(label+'-run.json');r=load(p)
    assert r['exit']!=0,label
    failures[label]={'receipt_sha256':sha(p),'exit':r['exit'],'errors':r['errors']}
case='fresh-action-4417-three-briefs-three-releases'
earlier=OUT/'campaign-run-v1';final=OUT/'campaign-run-final'
runtime=lambda manifest:{k:v for k,v in manifest.items() if not k.startswith('scripts/debug/')}
assert runtime(load(earlier/'workspace-source-manifest.json'))==runtime(load(final/'workspace-source-manifest.json'))
assert load(final/'workspace-source-manifest.json')==current
old=load(earlier/'cases'/case/'result.json');now=load(final/'cases'/case/'result.json')
assert old['ok'] and now['ok'] and old['outcome']==now['outcome'] and old['final_state']==now['final_state'] and old['final_rng']==now['final_rng']
replayed=load(OUT/'campaign-replay-v1/replay-report.json')
assert replayed['ok'] and replayed['final_state']==now['final_state'] and len(replayed['steps'])==227 and replayed['telemetry_samples']==228 and replayed['telemetry_verified']
finance=now['outcome']['finance']
assert now['accepted_commands']==227 and now['final_release_count']==3 and now['final_run_cycle']==128
assert finance['total_overdue_cents']==0 and finance['unpaid_rent_cents']==0 and not finance['financially_blocked']
editor=load(OUT/'flow-guard-final-artifacts/flow-results.json')
compiled=load(OUT/'pack-guard-final-artifacts/flow-results.json')
assert editor['failures']==compiled['failures']==0 and editor['checks']==compiled['checks']==125
assert editor['briefs']==compiled['briefs'] and editor['history']==compiled['history']
export=load(OUT/'export-run.json')
assert export['exit']==0 and sha(OUT/'exports/crown-feedback-private.pck')==export['pack_sha256']
captures={str(p.relative_to(OUT)):sha(p) for folder in ['ui-streak-final-artifacts','pack-streak-final-artifacts'] for p in sorted((OUT/folder/'ui-captures').glob('*.png'))}
assert len(captures)==24,len(captures)
docs=['docs/codex/TODO.md','docs/codex/CURRENT_STATE.md','docs/codex/design/publishers-contracts.md','docs/codex/logs/2026-10-26-crown-feedback-v1.md','docs/codex/logs/2026-10-26-crown-feedback-plan-v1.md']
result={'date':'2026-10-26','branch':subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
 'canonical_unchanged':True,'canonical_identity':variant.identity(canonical),'candidate_identity':variant.identity(current),'sealed_source_changes':len(load(H/'handoff.json')['changes']),
 'candidate_source_manifest':current,'documentation_sha256':{p:sha(ROOT/p) for p in docs},'passing_receipts':receipts,'retained_failed_receipts':failures,'capture_sha256':captures,
 'campaign':{k:now[k] for k in ['source_identity','accepted_commands','final_release_count','final_run_cycle','final_state','final_rng']},'campaign_outcome':now['outcome'],
 'replay_steps':len(replayed['steps']),'telemetry_samples':replayed['telemetry_samples'],'compiled_pack_sha256':export['pack_sha256'],
 'editor_runtime_identity':editor['source'],'compiled_runtime_identity':compiled['source'],
 'normal_crown_catalog_activated':False,'canonical_migration_approved':False,'populated_rival_crown_campaign_verified':False,'human_device_acceptance':False,'player_exe_zip_rebuilt':False,'committed':False,'pushed':False}
(OUT/'audit.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print('PASS: canonical preserved; sealed31-change candidate intact;14 passing receipts;24 native captures; exact227-command/228-sample replay; private compiled equivalence')
