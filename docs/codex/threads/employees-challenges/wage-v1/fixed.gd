extends SceneTree

func _initialize() -> void:
	var inputs: Array = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("FIXED_INPUT")))
	var results: Array = []
	for item: Dictionary in inputs:
		var source: Dictionary = item.finance
		var ledger := StudioFinanceLedger.create(int(source.initial_cash_cents),int(source.monthly_rent_cents))
		var count := 0
		var stop := {}
		for a: Dictionary in source.actions:
			var step: Dictionary = {}
			if a.has("operation"):
				var op: Dictionary = a.operation
				if op.type == "hire":
					var id := StringName(op.run_id)
					step = StudioFinanceLedger.hire_employee(ledger,StudioFinanceLedger.hire_quote(ledger,id),id)
				else:
					stop={"unsupported_operation":op.type}
					break
			else:
				step=StudioFinanceLedger.plan(ledger,int(a.cycle),int(ledger.cash_cents),int(a.direct_delta),StringName(a.kind),int(a.sales_earned),int(a.settled),bool(a.productive),StringName(a.source_id))
			if step.is_empty():
				stop={"action_index":count,"cycle":a.cycle,"kind":a.kind,"cash_before":ledger.cash_cents,"direct_delta":a.direct_delta,"unpaid":StudioFinanceLedger.get_unpaid(ledger)}
				break
			ledger=step.ledger
			count+=1
		results.append({"case":item.name,"wage":int(OS.get_environment("WAGE_CENTS")),"committed":count,"source_actions":source.actions.size(),"stop":stop,"finance":ledger,"valid":StudioFinanceLedger._is_valid(ledger)})
	var file := FileAccess.open(OS.get_environment("FIXED_OUTPUT"),FileAccess.WRITE)
	file.store_string(JSON.stringify(results))
	file.close()
	quit()
