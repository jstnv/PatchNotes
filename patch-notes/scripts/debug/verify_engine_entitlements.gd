## Run with Godot --headless --path patch-notes --script res://scripts/debug/verify_engine_entitlements.gd
extends SceneTree

const Entitlements := preload("res://scripts/engines/engine_entitlements.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var state: Dictionary = Entitlements.create(&"player")
	check(Entitlements.valid(state) and state.licensed_ids.is_empty() and state.owned_ids == [&"legacy_engine"] and state.selected_engine_id == &"legacy_engine", "New studio starts with a built-in legacy engine and no marketplace license")
	var insufficient: Dictionary = Entitlements.plan_license(state, &"puzzle_engine", 249999, &"incumbent-puzzle", 0)
	check(insufficient.is_empty() and state.licensed_ids.is_empty(), "Insufficient funds cannot grant an engine license")
	check(Entitlements.plan_license(state, &"action_engine", 250000, &"incumbent-action", 0).is_empty(), "Retired Action cannot be newly licensed")
	check(Entitlements.plan_license(state, &"puzzle_engine", 250000, &"wrong_owner", 0).is_empty(), "License plan rejects a mismatched creator")
	var plan: Dictionary = Entitlements.plan_license(state, &"puzzle_engine", 250000, &"incumbent-puzzle", 10000)
	check(not plan.is_empty() and plan.buyer_delta_cents == -250000 and plan.creator_delta_cents == 250000, "License plan balances the exact buyer debit and creator credit")
	check(Entitlements.valid(plan.next_state) and plan.next_state.licensed_ids == [&"puzzle_engine"] and state.licensed_ids.is_empty(), "License planning is pure and grants only the requested engine")
	var forged: Dictionary = state.duplicate(true)
	forged.owned_ids.append(&"puzzle_engine")
	check(not Entitlements.valid(forged), "Player cannot forge ownership of a rival-created engine")
	check(Entitlements.plan_license(plan.next_state, &"puzzle_engine", 250000, &"incumbent-puzzle", 10000).is_empty(), "An existing license cannot be purchased twice")
	check(Entitlements.plan_license(state, &"adventure_engine", 250000, &"incumbent-adventure", ProjectState.MAX_SIGNED_INT - 249999).is_empty(), "Creator cash overflow rejects the whole license plan")
	var old_run:=RunState.new()
	check(old_run.initialize_cash(0) and old_run.create_studio_with_traits("Legacy engines",&"action",[]),"Legacy migration fixture creates")
	old_run._engine_entitlements=Entitlements.create(old_run._bank_run_id)
	old_run._engine_entitlements.licensed_ids.append_array([&"action_engine",&"puzzle_engine"])
	old_run._engine_entitlements.selected_engine_id=&"puzzle_engine"
	var old_owned: Array[StringName]=[];old_owned.assign(old_run._owned_features.keys())
	var old_ids: Array[StringName]=Entitlements.accessible_ids(old_run._engine_entitlements)
	old_run._engine_features=old_run.EngineFeatures.create(old_owned,old_ids,old_run._bank_run_id,old_run._feature_offers)
	check(old_run.valid_engine_state() and old_run.get_selected_engine_capacity()==25,"Existing Action/Puzzle entitlements retain legacy 25-Scope records")
	var codec:=StudioCheckpoint.new()
	var encoded: Dictionary=codec.capture(old_run)
	var restored: RunState=codec.hydrate(encoded) if not encoded.is_empty() else null
	check(restored!=null and restored.get_selected_engine_id()==&"puzzle_engine" and restored.get_selected_engine_capacity()==25 and restored.get_engine_entitlements().licensed_ids.has(&"action_engine"),"Existing Action/Puzzle entitlements survive Studio checkpoint round trip")
	print("Engine entitlements: %d failures" % failures)
	quit(1 if failures else 0)
