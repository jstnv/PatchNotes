## Run with Godot --headless --path patch-notes --script res://scripts/debug/verify_engine_scope.gd
extends SceneTree

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var legacy := ProjectState.new(30)
	check(legacy.get_engine_id() == &"legacy_engine" and legacy.add_scope(30), "Built-in engine retains the current 30-Scope behavior")
	var action := ProjectState.new(30)
	check(action.set_engine_id(&"action_engine") and action.get_engine_max_scope() == 25, "Marketplace engine freezes a 25-Scope capacity without changing the requirement")
	check(action.add_scope(24) and not action.add_scope(2) and action.get_current_scope() == 24, "Overshooting Scope is rejected atomically")
	check(action.add_scope(1) and not action.add_scope(1) and action.get_current_scope() == 25, "Exactly 25 Scope is permitted")
	print("Engine Scope: %d failures" % failures)
	quit(1 if failures else 0)
