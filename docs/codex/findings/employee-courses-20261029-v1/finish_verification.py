from pathlib import Path
import json,subprocess,sys,time
out=Path(__file__).resolve().parent
root=out.parents[3]
runner=out/'run.py'
script='res://scripts/debug/verify_employee_course_fixed_campaign.gd'
checks=[]
def run(label,probe,*args):
 result=subprocess.run([sys.executable,str(runner),label,probe,*args],cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
 receipt=out/(label+'-run.json')
 item=json.loads(receipt.read_text()) if receipt.exists() else {'exit':result.returncode,'tail':result.stdout[-2000:]}
 checks.append({'label':label,'script':probe,'exit':result.returncode,'runtime_identity':item.get('runtime_identity'),'receipt':receipt.name})
 (out/'final-verification-index.json').write_text(json.dumps(checks,indent=2))
 print(label,'PASS' if result.returncode==0 else 'FAIL',item.get('elapsed_seconds'),flush=True)
 if result.returncode: print(result.stdout[-4500:],flush=True);sys.exit(result.returncode)
wait_until=time.monotonic()+650
while not (out/'final-tier3-run.json').exists():
 if time.monotonic()>wait_until:raise SystemExit('Tier3 not complete')
 time.sleep(1)
prior=json.loads((out/'final-tier3-run.json').read_text());assert prior['exit']==0 and prior['runtime_source_unchanged']
run('replay-tier3',script,'--replay='+str(out/'final-tier3.json'))
run('final-tier4',script,'--tiers=4','--resume='+str(out/'final-tier3.json.final.json'))
run('replay-tier4',script,'--replay='+str(out/'final-tier4.json'))
run('final-trained-restore','res://scripts/debug/verify_employee_course_restore.gd',str(out/'final-tier4.json.final.json'))
for label,name,args in [
 ('final-rules','verify_employee_career_rules.gd',[]),
 ('final-transactions','verify_employee_course_transactions.gd',['--prior='+str(out/'old-employees.json')]),
 ('final-alignment','verify_production_alignment.gd',[]),
 ('final-bounds','verify_manager_priority_bounds.gd',[]),
 ('final-journal-integrity','verify_employee_journal_integrity.gd',[]),
 ('final-qa-retained','verify_qa_employees.gd',[]),
 ('final-employee-hands','verify_employee_hands.gd',[]),
 ('final-seeded-parity','verify_campaign_seeded_parity.gd',[]),
 ('final-employee-native','verify_employee_course_ui.gd',['--native']),
 ('final-debug-backend','verify_debug_sandbox.gd',[]),
 ('final-debug-native','verify_developer_tools_ui.gd',['--native']),
 ('final-world-restore','verify_world_restore_file.gd',[str(root/'docs/codex/findings/studio-beams-20261029-v1/texture-cold.json'),str(out/'final-restored-world.json')]),
 ('final-economy','study_employee_course_economy.gd',[]),
 ('final-journal-profile','profile_employee_career_journal.gd',[]),
 ]:run(label,'res://scripts/debug/'+name,*args)
print('FINAL_FOCUSED_VERIFICATION_COMPLETE',flush=True)
