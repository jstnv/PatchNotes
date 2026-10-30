from pathlib import Path
import re, shutil, sys, hashlib, json
OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
targets = {
 'scripts/sales/released_game_sales.gd': ['is_valid','_recalculate','can_campaign','next_cycle'],
 'scripts/fanbase/studio_fanbase.gd': ['plan'],
 'scripts/finance/studio_finance_ledger.gd': ['_is_valid','_validate_journal','_apply','report'],
 'scripts/simulation/campaign_session.gd': ['observation','execute'],
 'scripts/market/rival_trial.gd': ['_feature_maximal_choice','_legal_visible_feature_hand'],
 'scripts/run_state.gd': ['get_feature_research_quote','get_feature_store_offer','get_primitive_reserve_offer','get_financial_block_reason','get_feature_spending_advice','complete_productive_action'],
 'scripts/ui/feature_store.gd': ['_refresh'],
}
if sys.argv[1] == 'restore':
 for name in targets:
  path = ROOT/'patch-notes'/name
  path.write_bytes((OUT/('before-'+name.replace('/','__'))).read_bytes())
 raise SystemExit
for name, funcs in targets.items():
 path = ROOT/'patch-notes'/name
 backup = OUT/('before-'+name.replace('/','__'))
 if backup.exists(): assert backup.read_bytes() == path.read_bytes(), name
 else: backup.write_bytes(path.read_bytes())
 source = path.read_text(encoding='utf-8')
 for func in funcs:
  pattern = r'^(static )?func '+func+r'\((.*?)\) -> ([^:\n]+):'
  match = re.search(pattern,source,re.M|re.S)
  assert match, (name,func)
  signature = match.group(0)
  args = [re.match(r'\s*(\w+)',arg).group(1) for arg in match.group(2).split(',')] if match.group(2).strip() else []
  call = '_profile_original_'+func+'('+','.join(args)+')'
  wrapper = signature+'\n\tvar _clock := Time.get_ticks_usec()\n'
  wrapper += '\t'+('var _answer = ' if match.group(3)!='void' else '')+call+'\n'
  wrapper += '\tload("res://../docs/codex/findings/research-fix-20261027-v1/profile.gd").add("'+name+':'+func+'",Time.get_ticks_usec()-_clock)\n'
  if match.group(3)!='void': wrapper+='\treturn _answer\n'
  source = source[:match.start()]+wrapper+'\n'+signature.replace('func '+func+'(', 'func _profile_original_'+func+'(')+source[match.end():]
 path.write_text(source,encoding='utf-8',newline='\n')
shutil.copyfile(OUT.parent/'research-latency-20261027-v1/run.py',OUT/'run.py')
probe = (OUT.parent/'research-latency-20261027-v1/research_latency.gd').read_text(encoding='utf-8')
probe = probe.replace('sample_start()\n\tvar start', 'load("res://../docs/codex/findings/research-fix-20261027-v1/profile.gd").start()\n\tsample_start()\n\tvar start')
probe = probe.replace('await process_frame\n\tawait process_frame\n\tvar row', 'var profile: Dictionary=load("res://../docs/codex/findings/research-fix-20261027-v1/profile.gd").finish()\n\tawait process_frame\n\tawait process_frame\n\tvar row')
probe = probe.replace('"split_profile":split_profile,','"profile":profile,"split_profile":split_profile,')
(OUT/'research_latency.gd').write_text(probe,encoding='utf-8')
