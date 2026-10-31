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
	var insufficient: Dictionary = Entitlements.plan_license(state, &"action_engine", 749999, &"incumbent-action", 0)
	check(insufficient.is_empty() and state.licensed_ids.is_empty(), "Insufficient funds cannot grant an engine license")
	check(Entitlements.plan_license(state, &"action_engine", 750000, &"wrong_owner", 0).is_empty(), "License plan rejects a mismatched creator")
	var plan: Dictionary = Entitlements.plan_license(state, &"action_engine", 750000, &"incumbent-action", 10000)
	check(not plan.is_empty() and plan.buyer_delta_cents == -750000 and plan.creator_delta_cents == 750000, "License plan balances the exact buyer debit and creator credit")
	check(Entitlements.valid(plan.next_state) and plan.next_state.licensed_ids == [&"action_engine"] and state.licensed_ids.is_empty(), "License planning is pure and grants only the requested engine")
	var forged: Dictionary = state.duplicate(true)
	forged.owned_ids.append(&"action_engine")
	check(not Entitlements.valid(forged), "Player cannot forge ownership of a rival-created engine")
	check(Entitlements.plan_license(plan.next_state, &"action_engine", 750000, &"incumbent-action", 10000).is_empty(), "An existing license cannot be purchased twice")
	check(Entitlements.plan_license(state, &"puzzle_engine", 750000, &"incumbent-puzzle", ProjectState.MAX_SIGNED_INT - 749999).is_empty(), "Creator cash overflow rejects the whole license plan")
	print("Engine entitlements: %d failures" % failures)
	quit(1 if failures else 0)
