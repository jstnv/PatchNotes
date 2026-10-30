from pathlib import Path
p=Path(__file__).resolve().parents[4]/'patch-notes/scripts/run_state.gd'
s=p.read_text(encoding='utf-8')
a=s.index('\t# The provider and all entry guards')
b=s.index('\nfunc _plan_cycle_records',a)
s=s[:a]+'\treturn _plan_cycle_records(direct_cash_delta_cents,campaign_release_id,finance_kind,source_id,market)\n\n'+s[b:]
a=s.index('\tvar next_records: Dictionary = {}',s.index('func _plan_cycle_records'))
b=s.index('\tif payable > MAX_SIGNED_INT - cash_after_action:',a)
sales=s[a:b]
header='''\t# Cache only sales/Fan calculations, not a financial decision. Every guard,
\t# provider read, cash overflow check and full finance plan still runs. The
\t# key contains all typed inputs read by _plan_sales_cycle. Support's wider
\t# assessment path deliberately computes afresh.
\tvar cache := preload("res://scripts/simulation/productive_cycle_plan_cache.gd")
\tvar key:=PackedByteArray()
\tvar sales: Dictionary={}
\tif _support_deals.is_empty():
\t\tkey=var_to_bytes([campaign_release_id,_completed_run_cycles,_cash_initialized,
\t\t\t_market_provider.is_valid(),market,_bank_run_id,_released_games,_release_metadata,
\t\t\t_commission_deals,_support_rights,_support_assessments,_fanbase])
\t\tsales=cache.read(key)
\tif sales.is_empty():
\t\tsales=_plan_sales_cycle(campaign_release_id,market)
\t\tif not key.is_empty():cache.remember(key,sales)
\tif sales.is_empty():return {}
\tvar next_records: Dictionary=sales.records
\tvar payable: int=sales.payable
\tvar earned: int=sales.earned
\tvar fan_plan: Dictionary=sales.fans
\tvar support_rights: Dictionary=sales.support_rights
\tvar support_assessments: Dictionary=sales.support_assessments
'''
s=s[:a]+header+s[b:]
a=s.index('\n\n## The direct-effects callback',a)
new='\n\nfunc _plan_sales_cycle(campaign_release_id: StringName,market: Dictionary) -> Dictionary:\n'+sales+'\treturn {"records":next_records,"payable":payable,"earned":earned,"fans":fan_plan,"support_rights":support_rights,"support_assessments":support_assessments}\n'
s=s[:a]+new+s[a:]
p.write_text(s,encoding='utf-8',newline='\n')
