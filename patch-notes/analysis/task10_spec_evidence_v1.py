"""Specification evidence only. Does not implement or exercise a game save loader."""
from pathlib import Path
import json,hashlib,re,subprocess
import tutorial_task17_verify_v1 as v
ROOT=v.ROOT; OUT=ROOT/'design-logs/task10-v1'; OUT.mkdir(exist_ok=True); (OUT/'.gdignore').touch(); v.OUT=OUT
for label,args in [('head',['rev-parse','HEAD']),('branch',['branch','--show-current']),('status',['status','--short']),('diff',['diff'])]: (OUT/f'initial-{label}.txt').write_bytes(v.git(*args))
manifest={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for folder in ['scripts','scenes','data'] for p in (ROOT/folder).rglob('*') if p.is_file()}
(OUT/'source-before.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
persist={
'_cash_cents':'run.cash_cents', '_cash_initialized':'run.cash_initialized', '_completed_run_cycles':'run.completed_cycles', '_available_redraws':'run.redraws',
'_owned_features':'run.owned_features[]', '_familiarity':'run.familiarity[{feature_id,credits}]', '_credited_projects':'run.credited_projects[{project_id,feature_ids}] (stable IDs, not object keys)',
'_released_games':'releases[].sales', '_release_metadata':'releases[].metadata', '_primitive_contract':'contracts.ironclad (null or completed snapshot)',
'_ironclad_completion_committed':'contracts.ironclad_completion_committed', '_sidestreet_entitlements':'contracts.sidestreet[] (ordered)', '_sidestreet_results':'contracts.sidestreet[].result',
'_unlocked_publishers':'publishers.unlocked_ids', '_pending_publisher_notifications':'publishers.pending_notifications', '_seen_tutorial_topics':'guidance.seen_topics',
'_studio_name':'run.studio_name', '_first_studio_economy':'run.first_studio_economy', '_starter_selection_confirmed':'run.starter_selection_confirmed', '_starter_purchase_spent_cents':'run.starter_purchase_spent_cents',
'_first_tutorial_project_id':'guidance.first_project_id', '_first_game_tutorial':'guidance.first_game (null or exact stage/stat/flags snapshot)'}
derived={'_feature_definitions','_feature_offers'}
transient={'_feature_purchase_in_progress','_productive_cycle_in_progress','_committing_cycle_cash','_publishing_cycle','_pending_contract_completion'}
fields=re.findall(r'^var (\w+)',(ROOT/'scripts/run_state.gd').read_text(encoding='utf-8'),re.M)
assert set(fields)==set(persist)|derived|transient
mapping={f:persist.get(f,'REBUILD from compatible catalog' if f in derived else 'MUST be false/null at snapshot; restore false/null') for f in fields}
(OUT/'field-map.json').write_text(json.dumps(mapping,indent=2),encoding='utf-8')
# Format fixture only. RNG values are deliberately synthetic valid signed64 strings.
streams=['snapshot','review','design_deal','design_finalize','alpha_deal','alpha_finalize','beta_deal','beta_insight','contract_deal']
payload={'checkpoint_kind':'studio','run_id':'fixture-run','sequence':'1','source_build':'spec-fixture-only','content_revision':'fixture-content',
'run':{'studio_name':'Fixture Studio','cash_initialized':True,'cash_cents':'550000','completed_cycles':'0','redraws':'4','first_studio_economy':True,'starter_selection_confirmed':False,'starter_purchase_spent_cents':'0','owned_features':['text','4_color_palette','8_bit_sound','keyboard_and_mouse','controller','controls'],'familiarity':[],'credited_projects':[]},
'releases':[],'contracts':{'ironclad':None,'ironclad_completion_committed':False,'sidestreet':[]},'publishers':{'unlocked_ids':[],'pending_notifications':[]},'guidance':{'seen_topics':[],'first_project_id':'','first_game':None},'rng':{'algorithm':'godot-4.7.1-rng-v1','next_project_serial':'1','streams':{x:{'seed':'1','state':'1'} for x in streams}}}
def envelope(p,version='1'):
 text=json.dumps(p,ensure_ascii=False,separators=(',',':'))
 return {'format':'patch-notes-studio-checkpoint','schema_version':version,'payload_utf8':text,'payload_sha256':hashlib.sha256(text.encode('utf-8')).hexdigest()}
fixtures=OUT/'fixtures'; fixtures.mkdir(exist_ok=True)
for name,doc in [('initial-format',envelope(payload)),('incompatible-v2',envelope(payload,'2'))]: (fixtures/f'{name}.json').write_text(json.dumps(doc,indent=2),encoding='utf-8')
bad=envelope(payload); bad['payload_sha256']='0'*64; (fixtures/'checksum-mismatch.json').write_text(json.dumps(bad),encoding='utf-8')
(fixtures/'truncated.json').write_text('{"format":',encoding='utf-8')
large=json.loads(json.dumps(payload)); large['run']['cash_cents']='9223372036854775807'; (fixtures/'int64-max-format.json').write_text(json.dumps(envelope(large),indent=2),encoding='utf-8')
overflow=json.loads(json.dumps(payload)); overflow['run']['cash_cents']='9223372036854775808'; (fixtures/'overflow-invalid.json').write_text(json.dumps(envelope(overflow),indent=2),encoding='utf-8')
assert json.loads(envelope(large)['payload_utf8'])['run']['cash_cents']=='9223372036854775807'
results=[v.run('import',ROOT,['--editor','--import'])]
for name in ['main_menu_history','feature_store','sidestreet_scope_and_year','sales_earning_and_settlement']:
 results.append(v.run('verify_'+name,ROOT,['--script','res://scripts/debug/verify_'+name+'.gd']))
(OUT/'verification.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
assert all(r['exit']==0 and not r['errors'] for r in results)
assert all(hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h for p,h in manifest.items())
p=subprocess.run(['git','diff','--check'],cwd=ROOT,capture_output=True); (OUT/'diff-check.log').write_bytes(p.stdout+p.stderr); assert p.returncode==0
print('PASS specification field coverage, six format fixtures, source guard, import and four baseline suites. Save/restart acceptance tests are specified, NOT implemented or passed.')
