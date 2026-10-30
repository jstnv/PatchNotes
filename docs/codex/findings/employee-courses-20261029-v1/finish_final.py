"""Fresh labels after the final generic-Beta-dictionary regression repair."""
from pathlib import Path
import json,subprocess,sys
out=Path(__file__).resolve().parent;root=out.parents[3];checks=[];equivalence=[]
def run(label,probe,*args,comparison=False):
    result=subprocess.run([sys.executable,str(out/'run.py'),label,'res://scripts/debug/'+probe,*args],cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
    receipt=out/(label+'-run.json');item=json.loads(receipt.read_text()) if receipt.exists() else {}
    row={'label':label,'script':probe,'exit':result.returncode,'runtime_identity':item.get('runtime_identity'),'receipt':receipt.name}
    target=equivalence if comparison else checks;target.append(row)
    (out/('verified-equivalence-index.json' if comparison else 'verified-index.json')).write_text(json.dumps(target,indent=2))
    print(label,'PASS' if result.returncode==0 else 'FAIL',item.get('elapsed_seconds'),flush=True)
    if result.returncode:print(result.stdout[-4500:],flush=True);sys.exit(result.returncode)
run('verified-restore','verify_employee_course_restore.gd',str(out/'tail-tier4.json.final.json'))
run('verified-tail-equivalence','verify_employee_course_source_equivalence.gd',str(out/'tail-tier4.json'))
run('verified-tail-replay','verify_employee_course_fixed_campaign.gd','--replay='+str(out/'verified-tail-equivalence.json'))
run('verified-fold','verify_employee_fold_indices.gd',str(out/'campaign-full2.json.final.json'))
run('verified-beta-dictionary','verify_employee_beta_dictionary.gd')
for label,name,args in [
 ('rules','verify_employee_career_rules.gd',[]),
 ('transactions','verify_employee_course_transactions.gd',['--prior='+str(out/'old-employees.json')]),
 ('alignment','verify_production_alignment.gd',[]),
 ('bounds','verify_manager_priority_bounds.gd',[]),
 ('journal','verify_employee_journal_integrity.gd',[]),
 ('qa','verify_qa_employees.gd',[]),
 ('hands','verify_employee_hands.gd',[]),
 ('seeded','verify_campaign_seeded_parity.gd',[]),
 ('employee-native','verify_employee_course_ui.gd',['--native']),
 ('debug','verify_debug_sandbox.gd',[]),
 ('debug-native','verify_developer_tools_ui.gd',['--native']),
 ('world','verify_world_restore_file.gd',[str(root/'docs/codex/findings/studio-beams-20261029-v1/texture-cold.json'),str(out/'verified-restored-world.json')]),
 ('economy','study_employee_course_economy.gd',[]),
 ('malformed','verify_career_predecessor_malformed.gd',[]),
]:run('verified-'+label,name,*args)
for name in ['final-tier1','final-tier2','final-tier3','indexed-tier4']:
    run('verified-equivalence-'+name,'verify_employee_course_source_equivalence.gd',str(out/(name+'.json')),comparison=True)
print('VERIFIED_FINAL_COMPLETE',flush=True)
