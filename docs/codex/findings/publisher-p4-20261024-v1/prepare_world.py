"""Derive a test-only supported-rival exercise from the accepted P2/P3 harness."""
from pathlib import Path
import hashlib,json
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
def main():
    source=ROOT/'docs/codex/findings/sidestreet-p2-p3-20261023-v1/world.gd'
    raw=source.read_bytes();s=raw.decode('utf8')
    old='\t\tif view.publisher_relationships[&"sidestreet"].reputation_bp>=2000:\n'
    new='\t\tif view.publisher_relationships[&"sidestreet"].investment_bp>=1500:\n\t\t\tif view.support_quote.is_empty(): return {"type":&"quote_support","payload":payload}\n\t\t\tpayload.support_quote=view.support_quote.duplicate(true)\n\t\t\treturn {"type":&"begin_development","payload":payload}\n'+old
    assert s.count(old)==1;s=s.replace(old,new)
    anchor='\t\tvar payload := {"name":"World pilot "+str(view.releases.size()+1),"genre":"sports","theme":"fantasy"}'
    research='\t\tif view.publisher_relationships[&"sidestreet"].reputation_bp>=2000:\n\t\t\tfor feature in ["maps","sprites","general_combat"]:\n\t\t\t\tif StringName(feature) in view.owned_features: continue\n\t\t\t\tfor quote: Dictionary in view.research_quotes:\n\t\t\t\t\tif quote.feature_id != StringName(feature): continue\n\t\t\t\t\tif quote.get("can_admit",false): return {"type":&"admit_research","payload":{"quote":quote}}\n\t\t\t\t\tif quote.get("can_research",false): return {"type":&"research","payload":{"quote":quote}}\n\t\t\t\treturn {}\n'
    assert s.count(anchor)==1;s=s.replace(anchor,research+anchor)
    s=s.replace('if view.commission_deals.has(view.project_id):desired=commission_hands','if view.commission_deals.has(view.project_id):desired={"design":5,"alpha":7,"beta":6}[current.phase]\n\tif view.support_history.deals.has(view.project_id):desired=commission_hands')
    s=s.replace('has_pending_commission()','has_unlaunched_support()')
    s=s.replace('native.run.commission_deals[id].terms.required_scope=1','native.run.support_deals[id].required_scope=1')
    s=s.replace('range(20)','range(40)')
    s=s.replace('within20 cycles','within40 cycles').replace('at most20','at most40')
    s=s.replace('active commission','active support').replace('commission completion','support completion').replace('completed commissioned','completed supported')
    # Match the already declared legal 3/5/4 -> 2/2/2 -> research+5/7/6 prefix.
    # The first two attempts retained the old world's weaker token heuristic.
    start=s.index('func actor_choice(');end=s.index('func execute()',start)
    original_choice=s[start:end].replace('func actor_choice(','func original_contract_choice(',1)
    chooser='''var _prefix_policy: RefCounted
var _full_policy: RefCounted
func actor_choice(view: Dictionary, scoring: RefCounted, commission_hands: int=10) -> Dictionary:
	if view.phase!=&"studio":return original_contract_choice(view,scoring,commission_hands)
	if view.publisher_relationships[&"sidestreet"].investment_bp<1500:
		if view.releases.size()>=3 and view.publisher_relationships[&"sidestreet"].reputation_bp>=2000:return _full_policy.choose(view)
		if view.phase==&"studio":
			for offer: Dictionary in view.studio_actions.contract_offers:
				if offer.kind==&"ironclad":return {"type":&"accept_contract","payload":{"kind":&"ironclad"}}
			if view.publisher_relationships[&"sidestreet"].reputation_bp<2000:
				for offer: Dictionary in view.studio_actions.contract_offers:
					if offer.kind==&"sidestreet_brief":return {"type":&"accept_contract","payload":{"kind":offer.kind,"offer_id":offer.offer_id}}
		return _prefix_policy.first.call(view) if view.releases.is_empty() else _prefix_policy.later.call(view)
	var development:=Finite.factory({"genre":"sports","theme":"fantasy","name_prefix":"World supported","selection":"features_first","hands":{"design":commission_hands,"alpha":commission_hands,"beta":commission_hands}})
	var chosen: Dictionary=development.call(view)
	if chosen.type==&"begin_development":
		if view.support_quote.is_empty():return {"type":&"quote_support","payload":chosen.payload}
		chosen.payload.support_quote=view.support_quote.duplicate(true)
	return chosen

'''
    s=s[:start]+chooser+original_choice+s[end:]
    old='\t\tvar raw: Variant = policy.call(session.observation())'
    new='\t\tvar observed: Dictionary = session.observation()\n\t\tobserved.test_bank_quote = session.run.get_bank_quote(200000,36)\n\t\tobserved.test_has_loan = not session.run.get_studio_finance_snapshot().bank_loans.is_empty()\n\t\tvar raw: Variant = policy.call(observed)'
    assert s.count(old)==1;s=s.replace(old,new)
    anchor='\tif view.phase!=&"studio":return original_contract_choice(view,scoring,commission_hands)'
    new=anchor+'\n\tif view.publisher_relationships[&"sidestreet"].reputation_bp>=2000 and view.publisher_relationships[&"sidestreet"].investment_bp<1500 and not view.test_has_loan and view.test_bank_quote.get("accepted",false):\n\t\treturn {"type":&"bank_borrow","payload":{"quote":view.test_bank_quote}}'
    assert s.count(anchor)==1;s=s.replace(anchor,new)
    anchor='\tfull.play=Finite.factory(full.cfg.development)'
    assert s.count(anchor)==1;s=s.replace(anchor,anchor+'\n\t_prefix_policy=prefix\n\t_full_policy=full')
    target=HERE/'world.gd';target.write_text(s,encoding='utf8',newline='')
    (HERE/'world-harness-provenance.json').write_text(json.dumps({'reference':str(source.relative_to(ROOT)),'reference_sha256':hashlib.sha256(raw).hexdigest(),'derived_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'scope':'Explicit test policy chooses support after real full commission; no canonical rival policy activation.'},indent=2)+'\n',encoding='utf8')
    print('Derived explicit supported-rival harness; canonical policy unchanged')
if __name__=='__main__':main()
