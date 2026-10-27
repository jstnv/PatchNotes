from pathlib import Path
import hashlib,importlib.util,json,subprocess
out=Path(__file__).resolve().parent
root=out.parents[3]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
spec=importlib.util.spec_from_file_location('queue_sim',root/'tools/simulate.py')
sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
before=json.loads((out/'campaign-run/workspace-source-manifest.json').read_text())
now=sim.source_hashes(root/'patch-notes')
delta=sorted(p for p in before.keys()|now.keys() if before.get(p)!=now.get(p))
assert delta==['scripts/debug/verify_market_browser.gd'],delta

labels=['research','world','background-v2','market-v2','market-native','employees-headless','employees-native']
checks={}
for label in labels:
    p=out/(label+'-run.json');r=json.loads(p.read_text())
    assert r['exit']==0 and not r['errors'],(label,r)
    checks[label]={'sha256':sha(p),'command':r['command'],'exit':r['exit']}
campaign=json.loads((out/'campaign-run/cases/action-4417-three-releases/result.json').read_text())
replay=json.loads((out/'campaign-replay/replay-report.json').read_text())
assert campaign['ok'] and campaign['commands']==209 and campaign['final_run_cycle']==119 and campaign['final_release_count']==3
assert replay['ok'] and len(replay['steps'])==209 and replay['telemetry_verified'] and replay['telemetry_samples']==210
assert campaign['outcome']['finance']['total_overdue_cents']==0
assert not campaign['outcome']['finance']['financially_blocked']
captures={str(p.relative_to(out)):sha(p) for folder in ['market-native','employees-native'] for p in sorted((out/folder).glob('*.png'))}
assert len(captures)==8

sources=['patch-notes/scripts/cards/feature_research.gd','patch-notes/scripts/run_state.gd',
'patch-notes/scripts/contracts/contract_definitions.gd','patch-notes/scripts/contracts/contract_challenges.gd',
'patch-notes/scripts/contracts/contract_state.gd','patch-notes/scripts/contracts/contract_search.gd',
'patch-notes/scripts/contracts/publisher_relationship_rules.gd','patch-notes/scripts/simulation/studio_actions.gd',
'patch-notes/scripts/employees/employee_roster.gd','patch-notes/scripts/market/rival_trial.gd',
'patch-notes/scripts/finance/studio_finance_ledger.gd','patch-notes/scripts/debug/verify_market_browser.gd',
'docs/codex/threads/contracts/COMPACT-PACKAGE-HANDOFF-2026-10-26-v3.md',
'docs/codex/threads/contracts/CROWN-PAID-WORK-TERMS-2026-10-26-v1.md',
'docs/codex/threads/employees-challenges/2026-10-26-research-accounting-design-task-v1.md',
'docs/codex/threads/employees-challenges/2026-10-26-research-accounting-proposal-v1.md',
'docs/codex/TODO.md','docs/codex/CURRENT_STATE.md','docs/codex/logs/2026-10-26-queue-review-v1.md']
diff=subprocess.run(['git','-c','core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol',
                     'diff','--check','--',*sources],cwd=root,capture_output=True,text=True)
assert diff.returncode==0,diff.stdout+diff.stderr
result={'date':'2026-10-26','branch':subprocess.check_output(['git','branch','--show-current'],cwd=root,text=True).strip(),
        'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),
        'initial_manifest_sha256':sha(out/'campaign-run/workspace-source-manifest.json'),
        'project_delta':delta,'production_unchanged':True,'source_sha256':{p:sha(root/p) for p in sources},
        'review_sha256':sha(out/'REVIEW.md'),'checks':checks,'captures':captures,
        'campaign_result_sha256':sha(out/'campaign-run/cases/action-4417-three-releases/result.json'),
        'replay_report_sha256':sha(out/'campaign-replay/replay-report.json'),'diff_check':diff.returncode}
(out/'audit.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({'checks':len(checks),'captures':len(captures),'campaign_commands':209,'replay_samples':210,'project_delta':delta,'diff_check':diff.returncode}))
