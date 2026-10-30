from pathlib import Path
H=Path(__file__).resolve().parent;T=H.parents[1]
P=T/'simulators/sidestreet-commission-p1-v2/project'
p=P/'scripts/contracts/publisher_commission_trial.gd'
s=p.read_text()
old='\tif d.commission_deals.is_empty(): return true'
new='''\tvar receipt_sources := {}
\tfor id: StringName in d.commission_deals: receipt_sources[d.commission_deals[id].terms.quote_id] = true
\tfor action: Dictionary in d.studio_finance.actions:
\t\tif str(action.source_id).ends_with(":commission") and (action.kind != &"publisher_receipt" or not receipt_sources.has(action.source_id)): return false
\tif d.commission_deals.is_empty(): return true'''
assert old in s;s=s.replace(old,new)
old='\tvar prior: Dictionary = d.release_metadata[t.source_release_id]'
new='''\tvar latest: StringName = &""
\tfor released_id: StringName in d.release_metadata:
\t\tif d.release_metadata[released_id].release_cycle <= t.accept_cycle: latest = released_id
\tif latest != t.source_release_id: return {}
\tvar prior: Dictionary = d.release_metadata[t.source_release_id]'''
assert old in s;s=s.replace(old,new)
p.write_text(s)
p=P/'scripts/simulation/begin_project.gd'
s=p.read_text()
s=s.replace('\tvar before := run.random_streams.snapshot()','\tvar frozen_commission := commission_quote.duplicate(true)\n\tvar before := run.random_streams.snapshot()',1)
s=s.replace('not commission_quote.is_empty() and not run.can_bind_commission_quote(commission_quote,next)','not frozen_commission.is_empty() and not run.can_bind_commission_quote(frozen_commission,next)',1)
s=s.replace('\tvar bind := Callable()','\tif not frozen_commission.is_empty() and not run.can_bind_commission_quote(frozen_commission,next):\n\t\trun.random_streams.restore(before)\n\t\treturn {"ok":false,"error":"Prepared commission changed"}\n\tvar bind := Callable()',1)
s=s.replace('if not commission_quote.is_empty(): bind = func() -> bool: return run._bind_commission(commission_quote)','if not frozen_commission.is_empty(): bind = func() -> bool: return run._bind_commission(frozen_commission)',1)
p.write_text(s)
print('v2 orphan receipt, latest-offer provenance and callback quote freezing repaired')
