## Conditional same-cycle counterfactual, not an additional played route.
extends SceneTree
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var results:Array=[]
	for policy in ["ordinary","synergy"]:
		var route:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://design-logs/lifespan-verification-v2/route_%s_0_3_repeat.json"%policy))
		var action:Dictionary=route.opportunity.action
		var cycle:=int(action.after.cycle)
		var control_paid:=0
		var campaign_paid:=0
		var extra_net:=0
		var extra_units:=0
		for json_record:Dictionary in route.opportunity.records:
			# Restore integer ledger types through the existing capture normalization path.
			var rec:Dictionary=_ints(json_record)
			rec.release_id=StringName(rec.release_id)
			var campaigns:Dictionary={}
			for key:Variant in rec.campaign_months:campaigns[int(key)]=rec.campaign_months[key]
			rec.campaign_months=campaigns
			var control:=ReleasedGameSales.next_cycle(rec,cycle,cycle%2==0,false)
			var treatment:=ReleasedGameSales.next_cycle(rec,cycle,cycle%2==0,str(rec.release_id)==str(action.id))
			if control.is_empty() or treatment.is_empty():push_error("Invalid counterfactual input");quit(1);return
			control_paid+=int(control.settled_cents)-int(rec.settled_cents)
			campaign_paid+=int(treatment.settled_cents)-int(rec.settled_cents)
			extra_net+=int(treatment.entitlement_cents)-int(control.entitlement_cents)
			extra_units+=int(treatment.earned_units)-int(control.earned_units)
		results.append({"policy":policy,"cycle":cycle,"fee_cents":10000,"settlement_without_campaign_cents":control_paid,"settlement_with_campaign_cents":campaign_paid,"extra_earned_net_cents":extra_net,"extra_units":extra_units,"incremental_cash_after_fee_cents":campaign_paid-control_paid-10000,"observed_cash_delta_cents":action.after.cash_cents-action.before.cash_cents,"observed_matches":int(action.after.cash_cents-action.before.cash_cents)==campaign_paid-10000})
	FileAccess.open("res://design-logs/lifespan-verification-v2/campaign-same-cycle-deltas.json",FileAccess.WRITE).store_string(JSON.stringify(results))
	for result:Dictionary in results:
		if not result.observed_matches:quit(1);return
	print("Native campaign same-cycle counterfactuals passed: ",results.size())
	quit(0)
func _ints(value:Variant) -> Variant:
	if value is Dictionary:
		var out:Dictionary={}
		for key:Variant in value:out[key]=_ints(value[key])
		return out
	if typeof(value)==TYPE_FLOAT and value==floor(value):return int(value)
	return value
