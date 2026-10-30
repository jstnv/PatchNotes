extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: _run.call_deferred()
func expect(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; print("FAIL: ",label)
func _run() -> void:
	# Synthetic date/receipt matrix isolates access; it is not campaign solvency.
	var run:=RunState.new();run.initialize_cash_cents(0)
	run.create_studio_with_traits("Era gates",&"action",[]);run.finalize_starter_selection()
	run.add_cash(100000) # Explicitly funded date/UI fixture, not solvency evidence.
	run._feature_offers[&"colored_text"].merge({"min_year":1986,"era_year":1984},true)
	for cycle in [95,96,143,144]:
		for receipt in [false,true]:
			while run.get_completed_run_cycles()<cycle:
				if not run.complete_productive_action(): expect(false,"Funded date fixture advances legally");quit(1);return
			run.set("_store_era_receipts",{"version":1,"assignments":{1984:&"qualifying"} if receipt else {}})
			var offer:=run.get_feature_store_offer(&"colored_text")
			expect(offer.get("year_reached")== (cycle>=144) and offer.get("era_qualified")==receipt,"Separate date and qualifying-release fields")
			expect(offer.unlocked==(cycle>=144 and receipt),"Both date and receipt required, independent of owned parent")
			var quote:=run.get_feature_research_quote(&"colored_text")
			expect(quote.can_admit==(cycle>=144 and receipt),"Central Research admission cannot bypass era gates")
			for resolution in [Vector2i(1152,648),Vector2i(1280,720)]:
				root.size=resolution
				var store:=FeatureStore.new();root.add_child(store);store.setup(run)
				store._selected=&"colored_text";store._show_details()
				await process_frame
				var text:=store._details.text+store._buy.tooltip_text
				expect(cycle>=144 or "1986" in text,"Details visibly explain missing card year")
				expect(receipt or "qualifying" in text.to_lower(),"Details separately explain missing qualifying release")
				store.free()
	# A separate first-era quote fixture avoids rewinding a live calendar.
	run=RunState.new();run.initialize_cash_cents(0)
	run.create_studio_with_traits("Editor year",&"action",[]);run.finalize_starter_selection()
	run.add_cash(100000)
	while run.get_completed_run_cycles()<71: run.complete_productive_action()
	run._feature_offers[&"colored_text"].erase("era_year")
	run._feature_offers[&"colored_text"].min_year=1983
	expect(not run.get_feature_store_offer(&"colored_text").unlocked,"First-era1983 card remains year-locked at71")
	run.complete_productive_action()
	expect(run.get_feature_store_offer(&"colored_text").unlocked,"First-era1983 card needs no release receipt")

	var catalog:RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var factory=load("res://scripts/simulation/run_factory.gd")
	var player:RefCounted=factory.create_fresh_session({"schema_version":1,"studio_id":"era-rival-gate","studio_name":"Era rivals","specialty":"action","traits":[],"seed":"4417"},catalog)
	var world:RivalWorld=load("res://scripts/market/rival_trial.gd").create_world(player.run,catalog)
	expect(world!=null,"Actual rival cohort initializes under current era rules")
	if world!=null:
		var replay=load("res://scripts/simulation/development_replay.gd")
		for rival:RefCounted in world.studios.values():
			expect(rival.run.get_store_era_status(1984).receipt_id.is_empty(),"Display-only incumbent history mints no qualifying receipt")
			for id in [&"player_level_editor",&"ability_gated_exploration",&"switchable_protagonists",&"character_skill_checks"]:
				var quote:Dictionary=rival.run.get_feature_research_quote(id)
				var before:Dictionary=replay.state(rival)
				var result:Dictionary=rival.execute(rival.command(&"admit_research",{"quote":quote}))
				expect(not quote.can_admit and not result.ok and result.events.is_empty() and before==replay.state(rival),"Actual rival session cannot bypass date/receipt/owned-parent gates: "+str(id))
	print("STORE_ERA_ACCESS checks=%d failures=%d"%[checks,failures]);quit(failures)
