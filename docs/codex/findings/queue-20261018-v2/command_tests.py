from pathlib import Path
import subprocess,sys,json
out=Path('docs/codex/findings/queue-20261018-v2').resolve();results=[]
for name in ['design_command','alpha_command','beta_command','production_extraction','beta_qa_specialization','beta_balanced_operations']:
 r=subprocess.run([sys.executable,str(out/'run.py'),'final-'+name,'res://scripts/debug/verify_'+name+'.gd'],capture_output=True,text=True)
 results.append({'label':name,'exit':r.returncode,'output':r.stdout,'stderr':r.stderr});(out/'command-tests.json').write_text(json.dumps(results,indent=2));print(name,r.returncode,flush=True)
