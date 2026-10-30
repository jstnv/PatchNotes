"""Sequential current-source checks; prior failures/indices remain untouched."""
from pathlib import Path
import json, subprocess, sys, time
out=Path(__file__).resolve().parent
root=out.parents[3]
checks=[]
def run(label,probe,*args):
    result=subprocess.run([sys.executable,str(out/'run.py'),label,'res://scripts/debug/'+probe,*args],cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
    receipt=out/(label+'-run.json')
    item=json.loads(receipt.read_text()) if receipt.exists() else {'exit':result.returncode,'tail':result.stdout[-2000:]}
    checks.append({'label':label,'script':probe,'exit':result.returncode,'runtime_identity':item.get('runtime_identity'),'receipt':receipt.name})
    (out/'indexed-verification-index.json').write_text(json.dumps(checks,indent=2))
    print(label,'PASS' if result.returncode==0 else 'FAIL',item.get('elapsed_seconds'),flush=True)
    if result.returncode: print(result.stdout[-4500:],flush=True);sys.exit(result.returncode)
deadline=time.monotonic()+650
while not (out/'tail-tier4-run.json').exists():
    if time.monotonic()>deadline:raise SystemExit('Tier4 not complete')
    time.sleep(1)
assert json.loads((out/'tail-tier4-run.json').read_text())['exit']==0
run('indexed-replay4','verify_employee_course_fixed_campaign.gd','--replay='+str(out/'tail-tier4.json'))
run('indexed-restore','verify_employee_course_restore.gd',str(out/'tail-tier4.json.final.json'))
for label,name,args in [
 ('indexed-rules','verify_employee_career_rules.gd',[]),
 ('indexed-transactions','verify_employee_course_transactions.gd',['--prior='+str(out/'old-employees.json')]),
 ('indexed-alignment','verify_production_alignment.gd',[]),
 ('indexed-bounds','verify_manager_priority_bounds.gd',[]),
 ('indexed-journal','verify_employee_journal_integrity.gd',[]),
 ('indexed-qa','verify_qa_employees.gd',[]),
 ('indexed-hands','verify_employee_hands.gd',[]),
 ('indexed-seeded','verify_campaign_seeded_parity.gd',[]),
 ('indexed-employee-native','verify_employee_course_ui.gd',['--native']),
 ('indexed-debug','verify_debug_sandbox.gd',[]),
 ('indexed-debug-native','verify_developer_tools_ui.gd',['--native']),
 ('indexed-world','verify_world_restore_file.gd',[str(root/'docs/codex/findings/studio-beams-20261029-v1/texture-cold.json'),str(out/'indexed-restored-world.json')]),
 ('indexed-economy','study_employee_course_economy.gd',[]),
 ('indexed-malformed','verify_career_predecessor_malformed.gd',[]),
]:run(label,name,*args)
print('INDEXED_FOCUSED_VERIFICATION_COMPLETE',flush=True)
