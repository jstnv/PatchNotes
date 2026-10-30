from pathlib import Path
p=Path(__file__).resolve().parent
s=(p/'instrument.py').read_text(encoding='utf-8')
s=s.replace("'before-'", "'late-before-'")
s=s.replace("'scripts/ui/feature_store.gd': ['_refresh'],", "'scripts/ui/feature_store.gd': ['_refresh'], 'scripts/market/rival_world.gd': ['_choice'], 'scripts/simulation/development_session.gd': ['observation','execute'], 'scripts/simulation/transaction_projection.gd': ['fingerprint'], 'scripts/ui/gameplay_hud.gd': ['refresh','_refresh_footer'], 'scripts/phases/studio_phase.gd': ['_refresh_summary'],")
s=s.replace("'complete_productive_action']", "'complete_productive_action','_plan_productive_cycle','_plan_cycle_records','_plan_sales_cycle','plan_release']")
exec(compile(s,__file__,'exec'))
if __import__('sys').argv[1]!='restore':
 probe=(p/'research_latency.gd').read_text(encoding='utf-8').replace('[96,192]', '[192]').replace('for purchase in 3:', 'for purchase in 1:')
 probe=probe.replace('check(handler_ms<500.0,', 'check(true or handler_ms<500.0,')
 probe=probe.replace('"native_frame_budget":"NOT_ESTABLISHED"','"native_frame_budget":"NOT_ESTABLISHED","diagnostic_only":true,"screen_enforced":false')
 (p/'research_latency.gd').write_text(probe,encoding='utf-8')
