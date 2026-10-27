from run_checks import *

out=BASE/'maintained-gate-jobs-v1'
before=sim.read_json(out/'source.json');after=sim.source_hashes(out/'project')
assert all(after.get(k)==v for k,v in before.items())
added=sorted(set(after)-set(before))
assert all(k.endswith('.gd.uid') and re.fullmatch(r'uid://[a-z0-9]+\s*',(out/'project'/k).read_text()) for k in added)
names=['verify_alpha_pack_ui','verify_alpha_shop_pack','verify_alpha_shop_pack_cold','verify_legacy_world','verify_founder_victory_cold','verify_market_release_index','verify_market_release_index_cold','verify_queue_source_migration']
for name in ['import',*names]:
 record=sim.read_json(out/(name+'.command.json'))
 assert record['exit']==0 and not record['errors']
sim.write_json(out/'summary.json',{'passed':names,'all_original_source_bytes_unchanged':True,'import_generated_uids':{k:after[k] for k in added},'runner_final_assertion':'Initial strict equality rejected six newly generated Godot UID sidecars after all eight jobs passed. This independent audit verifies every original hash and restricts additions to valid .gd.uid files; no verifier failure was waived.','scope':'Eight affected maintained gate jobs, not the entire release gate.'})
print('Eight native jobs PASS; all original source bytes unchanged; '+str(len(added))+' generated UID sidecars validated.')
