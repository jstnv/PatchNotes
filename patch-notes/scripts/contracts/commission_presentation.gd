## Read-only rendering of the committed result. Does not re-grade or pay it.
extends RefCounted

static func result_text(run: RunState, id: StringName) -> String:
	if run._support_deals.has(id): return _support_text(run,id)
	var deals := run.get_commission_deals()
	if not deals.has(id) or deals[id].result == null: return ""
	var deal: Dictionary = deals[id]
	var result: Dictionary = deal.result
	var rep := 0
	var inv := 0
	for event: Dictionary in run._publisher_relationships.events:
		if event.kind == RunState.Commission.KIND and event.source_id == id:
			rep = event.credited_reputation_bp
			inv = event.credited_investment_bp
	return "SideStreet commission — publisher-owned title\nScope %d / %d (%.2f%%) · Review %.1f / 6.0 (%.2f%% delivery)\nFee: %s × %.2f%% = %s (lower delivery fraction, rounded down to cents)\nStanding requested: +%.2f Reputation / +%.2f Investment; credited: +%.2f / +%.2f (independent caps 100).\nStudio sales income: $0. Raw units, title sales and Fans remain; post-launch campaigns unavailable. Promotion was consumed normally. Fee is a separate publisher receipt and may service arrears." % [result.delivered_scope,deal.terms.required_scope,result.scope_bp/100.0,result.review_tenths/10.0,result.review_bp/100.0,CashFormatter.format_exact_cents(deal.terms.fee_cents),result.delivery_bp/100.0,CashFormatter.format_exact_cents(result.fee_paid_cents),result.relationship_award_bp/100.0,result.relationship_award_bp/100.0,rep/100.0,inv/100.0]

static func _support_text(run: RunState, id: StringName) -> String:
	var t: Dictionary = run._support_deals[id]
	var rights: Dictionary = run._support_rights.get(id,RunState.Support.empty_rights())
	var text := "SideStreet support — Studio-owned title\nFunding %s once at Begin (nonoperating); launch marketing +%d Awareness.\nRecoup %s / %s from 20%% of this title's cumulative raw net through earning cycle 24; no debt or other-title claim.\nStudio entitlement %s · paid %s · age %d earning cycles.\n" % [CashFormatter.format_exact_cents(t.funding_cents),t.marketing_points,CashFormatter.format_exact_cents(rights.publisher_recoup_cents),CashFormatter.format_exact_cents(t.budget_cents),CashFormatter.format_exact_cents(rights.studio_earned_cents),CashFormatter.format_exact_cents(rights.studio_settled_cents),rights.earning_cycles]
	if run._support_assessments.has(id):
		var a: Dictionary = run._support_assessments[id]
		var credit := 0
		for event: Dictionary in run._publisher_relationships.events:
			if event.kind == RunState.Support.KIND and event.source_id == id: credit = event.credited_investment_bp
		text += "Assessment at earning cycle 6: Review %.1f / 7.0; actual units %d / 1,000 — %s. Requested +%d Investment; credited +%.2f (cap 100)." % [a.review_tenths/10.0,a.actual_units,"success" if a.passed else "miss",10 if a.passed else 0,credit/100.0]
	else: text += "Assessment pending at earning cycle 6: Review 7.0 AND 1,000 actual units; success requests +10 Investment."
	return text
