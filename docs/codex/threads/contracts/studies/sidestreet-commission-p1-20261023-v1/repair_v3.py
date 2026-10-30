from pathlib import Path
H=Path(__file__).resolve().parent;T=H.parents[1]
P=T/'simulators/sidestreet-commission-p1-v3/project'
p=P/'scripts/contracts/publisher_commission_trial.gd'
s=p.read_text()
old='''\tfor action: Dictionary in d.studio_finance.actions:
\t\tif str(action.source_id).ends_with(":commission") and (action.kind != &"publisher_receipt" or not receipt_sources.has(action.source_id)): return false'''
new='''\tvar primitive: Variant = d.get("primitive_contract")
\tif primitive is Dictionary and primitive.get("paid",false): receipt_sources[primitive.offer_id] = true
\tfor field: String in ["sidestreet_entitlements","publisher_offers"]:
\t\tfor offer: Dictionary in d.get(field,{}).values():
\t\t\tvar state: Variant = offer.get("state")
\t\t\tif state is Dictionary and state.get("paid",false): receipt_sources[state.offer_id] = true
\tfor action: Dictionary in d.studio_finance.actions:
\t\tif action.kind == &"publisher_receipt" and not receipt_sources.has(action.source_id): return false
\t\tif str(action.source_id).ends_with(":commission") and action.kind != &"publisher_receipt": return false'''
assert old in s;s=s.replace(old,new)
p.write_text(s)
print('v3 validates every publisher receipt against a completed trusted source')
