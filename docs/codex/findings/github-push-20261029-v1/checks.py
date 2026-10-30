"""Fresh bounded source checks for the explicitly authorized Git push."""
from pathlib import Path
import json,subprocess,sys
out=Path(__file__).resolve().parent;root=out.parents[3];rows=[]
for label,script,args in [
 ('debug','verify_debug_sandbox',[]),
 ('courses','verify_employee_course_transactions',['--prior='+str(root/'docs/codex/findings/employee-courses-20261029-v1/old-employees.json')]),
 ('bounds','verify_manager_priority_bounds',[]),
 ('beta-dictionary','verify_employee_beta_dictionary',[]),
 ('audio','verify_audio_branch',[]),
 ('gameplay','verify_gameplay_restoration',[]),
 ('codec','verify_checkpoint_codec',[]),
 ('seeded','verify_campaign_seeded_parity',[]),
]:
    label='push-'+label
    result=subprocess.run([sys.executable,str(out/'run.py'),label,'res://scripts/debug/'+script+'.gd',*args],cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
    receipt=out/(label+'-run.json')
    rows.append({'label':label,'exit':result.returncode,'receipt':receipt.name})
    (out/'push-checks.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
    print(label,'PASS' if result.returncode==0 else 'FAIL',flush=True)
    if result.returncode:print(result.stdout[-4000:]);sys.exit(result.returncode)
