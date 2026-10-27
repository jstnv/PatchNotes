from pathlib import Path
import subprocess,sys,json,time
out=Path('docs/codex/findings/queue-20261018-v2').resolve()
jobs=[('cold-prior','verify_world_restore_file',[str(out/'prior-v2.json'),str(out/'cold-prior-restored.json')]),('cold-v2','verify_world_restore_file',[str(out/'roster-v2.json'),str(out/'cold-v2-restored.json')])]
for name in ['studio_specialties','studio_folder_menu','studio_checkpoint','genre_checkpoint','feature_store','feature_research','primitive_branches','store_cone_parents','gameplay_tree','legacy_world','rival_gameplay_activation','cult_following','contract_challenge_publishers','research_integration','resourceful','founder_victory','run_factory']:
    path=Path('patch-notes/scripts/debug/verify_'+name+'.gd')
    if path.exists(): jobs.append((name,'verify_'+name,[]))
results=[]
for label,script,args in jobs:
    print('START '+label,flush=True)
    p=subprocess.run([sys.executable,str(out/'run.py'),label,'res://scripts/debug/'+script+'.gd',*args],capture_output=True,text=True)
    results.append({'label':label,'exit':p.returncode,'output':p.stdout,'stderr':p.stderr})
    (out/'batch-results.json').write_text(json.dumps(results,indent=2))
    print('DONE '+label+' '+str(p.returncode),flush=True)
print('BATCH '+str(len(results))+' failed '+str(sum(x['exit']!=0 for x in results)),flush=True)
