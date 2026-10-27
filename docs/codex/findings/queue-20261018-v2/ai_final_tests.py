from pathlib import Path
import subprocess,sys,json
out=Path('docs/codex/findings/queue-20261018-v2').resolve();results=[]
for label,script,args in [('ai-compare-final','verify_rival_synergy',[]),('ai-world-final','verify_rival_trial_activation',[]),('ai-migration-final','verify_world_restore_file',[str(out/'profile-ai-world-before/APPDATA/Godot/app_userdata/Patch Notes/saves/studio/checkpoint.21.json'),str(out/'ai-migration-final-restored.json')]),('roster-closeout','verify_studio_roster_versions',[])]:
 r=subprocess.run([sys.executable,str(out/'run.py'),label,'res://scripts/debug/'+script+'.gd',*args],capture_output=True,text=True)
 results.append({'label':label,'exit':r.returncode,'output':r.stdout,'stderr':r.stderr});(out/'ai-final-tests.json').write_text(json.dumps(results,indent=2));print(label,r.returncode,flush=True)
