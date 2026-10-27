from pathlib import Path
import json,subprocess,sys
out=Path('docs/codex/findings/queue-20261018-v2').resolve()
jobs=[('ai-cold-pre-policy','verify_world_restore_file',[str(out/'profile-ai-world-before/APPDATA/Godot/app_userdata/Patch Notes/saves/studio/checkpoint.21.json'),str(out/'ai-cold-pre-policy-restored.json')]),('ai-cold-pre-roster','verify_world_restore_file',[str(out/'prior-v2.json'),str(out/'ai-cold-pre-roster-restored.json')])]
for name in ['design_extraction','alpha_extraction','beta_extraction','rival_gameplay_activation','studio_checkpoint','genre_checkpoint','studio_folder_menu','studio_roster_versions','legacy_world']:
    if Path('patch-notes/scripts/debug/verify_'+name+'.gd').exists():jobs.append(('final-'+name,'verify_'+name,[]))
for stage,folder,case in [('first','ai-compare-v1.json.first','adventure-4417-trial'),('second','ai-compare-v1.json.second','puzzle-4417-trial-second')]:
    path=out/folder/case
    jobs.append(('ai-replay-'+stage,'campaign_replay_cli',['--case='+str(path/'case.variant.json'),'--tape='+str(path/'replay.tape.json'),'--output='+str(out/('ai-replay-'+stage+'.json'))]))
jobs.append(('campaign-after-ai','campaign_experiment_cli',['--config='+str(out/'campaign-config.json'),'--output-dir='+str(out/'campaign-after-ai-cases'),'--output='+str(out/'campaign-after-ai-report.json')]))
results=[]
for label,script,args in jobs:
    result=subprocess.run([sys.executable,str(out/'run.py'),label,'res://scripts/debug/'+script+'.gd',*args],capture_output=True,text=True)
    results.append({'label':label,'exit':result.returncode,'output':result.stdout,'stderr':result.stderr})
    (out/'final-tests.json').write_text(json.dumps(results,indent=2));print(label,result.returncode,flush=True)
