## Optional detached study measurements, never policy input or game authority.
## Samples share the existing replay tape's command-boundary state digests.
extends RefCounted

static func sample(session: RefCounted,step: int,state_digest: String,request: Dictionary = {},outcome: Dictionary = {},previous_transactions: int = -1) -> Dictionary:
	var run: RunState = session.run
	var finance := run.get_studio_finance_report()
	var available: bool = finance.get("available",false)
	var releases: Array = []
	for id: StringName in run.get_released_game_ids():
		var metadata := run.get_release_metadata(id)
		releases.append({"id":str(id),"release_cycle":metadata.get("release_cycle"),"review":metadata.get("review",{}).get("final_review")})
	var transaction_count := -1
	var observed_transactions := 0
	var transaction_low: Variant = null
	if available:
		var ledger := run.get_studio_finance_snapshot()
		transaction_count = ledger.transactions.size()
		var low := run.get_cash_cents()
		# A checkpoint may contain years of prior finance history. Only measure
		# transactions appended since this study's preceding command boundary.
		var start := transaction_count if previous_transactions < 0 else previous_transactions
		if start <= transaction_count:
			for index in range(start,transaction_count):
				var transaction: Dictionary = ledger.transactions[index]
				low = mini(low,mini(int(transaction.cash_before_cents),int(transaction.cash_after_cents)))
			observed_transactions = transaction_count-start
			transaction_low = str(low)
	return {"step":step,"sequence":session.sequence,"run_cycle":run.get_completed_run_cycles(),"cash_cents":str(run.get_cash_cents()),"fans":str(run.get_fans()),"overdue_cents":str(finance.total_overdue_cents) if available else null,"finance_available":available,"financially_blocked":finance.get("financially_blocked") if available else null,"phase":str(session.phase()),"in_studio":session.in_studio,"release_count":releases.size(),"releases":releases,"owned_features":run.get_owned_feature_ids(),"research_queue":run.get_feature_research_queue(),"command_type":str(request.get("type","")),"request":request.duplicate(true),"accepted":outcome.get("ok") if not outcome.is_empty() else null,"error":str(outcome.get("error","")),"state_digest":state_digest,"transaction_count":transaction_count,"transactions_observed":observed_transactions,"transaction_cash_low_cents":transaction_low}
