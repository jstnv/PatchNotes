## New proprietary engine foundations; old engines and saves remain unchanged.
extends SceneTree

const BEGIN_PROJECT := preload("res://scripts/simulation/begin_project.gd")
const COMMISSION := preload("res://scripts/contracts/publisher_commission_trial.gd")
const FOUNDATIONS: Array[StringName] = [&"text", &"4_color_palette", &"8_bit_sound", &"keyboard_and_mouse"]
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", label)
	if not ok: failures += 1

func same_ids(actual: Array, expected: Array) -> bool:
	if actual.size() != expected.size(): return false
	for id: StringName in expected:
		if actual.count(id) != 1: return false
	return true

func _initialize() -> void:
	verify.call_deferred()

func verify() -> void:
	var run := RunState.new()
	check(run.initialize_cash(0) and run.create_studio_with_traits("Foundation test", &"action", []), "Create a fresh Studio")
	var public_before: Dictionary = run.get_engine_feature_state().engines[&"public_action"].duplicate(true)
	var cash := run.get_cash_cents()
	var cycle := run.get_completed_run_cycles()
	var rng: Dictionary = run.random_streams.snapshot()
	var queue_before: Array = run.get_feature_research_queue()
	var made: Dictionary = run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("New engine"))
	check(made.get("ok", false), "Create a real proprietary engine")
	if not made.get("ok", false): quit(1); return
	var id: StringName = made.engine_id
	var features: Dictionary = run.get_engine_feature_state()
	var record: Dictionary = features.engines[id]
	check(same_ids(record.initial, FOUNDATIONS), "Initial library is exactly the four foundations")
	check(same_ids(record.implemented, FOUNDATIONS), "All four foundations are already implemented")
	check(same_ids(record.committed, FOUNDATIONS), "All four foundations are available to future projects")
	check(record.capacity == 25 and record.revision == 0 and record.staged.is_empty(), "Normal capacity and clean configuration are preserved")
	check(run.get_cash_cents() == cash - 10000 and run.get_completed_run_cycles() == cycle, "Only the normal engine creation cost is charged, with no cycle")
	check(run.random_streams.snapshot() == rng and run.get_feature_research_queue() == queue_before, "Creation consumes no RNG or implementation queue actions")
	check(features.engines[&"public_action"] == public_before, "Public engine library is unchanged")
	var forged := features.duplicate(true)
	forged.engines[id].initial = [] as Array[StringName]
	run._engine_features = forged
	check(not run.valid_engine_state(), "New-origin engine cannot forge an empty initial library")
	forged = features.duplicate(true)
	forged.engines[id].initial.pop_back()
	forged.engines[id].implemented.pop_back()
	forged.engines[id].committed.pop_back()
	run._engine_features = forged
	check(not run.valid_engine_state(), "New-origin engine cannot forge a partial starter manifest")
	forged = features.duplicate(true)
	forged.engines[id].erase("initial")
	run._engine_features = forged
	check(not run.valid_engine_state(), "New-origin engine with a missing initial field is rejected cleanly")
	run._engine_features = features
	for feature: StringName in FOUNDATIONS:
		check(run.owns_feature(feature, id) and not run.get_feature_research_quote(feature, id).get("can_admit", false), "Foundation needs no second purchase: " + str(feature))
	check(run.select_engine(id) and same_ids(run.get_future_project_feature_ids(), FOUNDATIONS), "Selecting the engine supplies the four foundations")
	check(run.finalize_starter_selection(), "Studio setup finalizes")
	var adapter := StudioCheckpoint.new()
	var release_projection: Dictionary = adapter.snapshot(run).run
	var release_id: StringName = &"royalty_binding_probe"
	release_projection.release_engine_ids[release_id] = id
	check(COMMISSION._release_royalty_rate(release_projection, release_id) == 0, "New proprietary origin binds to zero release royalty")
	var invalid_projection := release_projection.duplicate(true)
	invalid_projection.engine_features.engines[id].origin = "forged-origin"
	check(COMMISSION._release_royalty_rate(invalid_projection, release_id) == -1, "Royalty projection rejects an unknown origin")
	invalid_projection = release_projection.duplicate(true)
	invalid_projection.release_engine_ids.erase(release_id)
	check(COMMISSION._release_royalty_rate(invalid_projection, release_id) == -1, "Royalty projection rejects a missing release binding")
	var saved: Dictionary = adapter.capture(run)
	check(not saved.is_empty() and adapter.validate(saved).is_empty(), "New engine saves with valid accounting")
	var restored: RunState = adapter.hydrate(saved) if not saved.is_empty() else null
	check(restored != null and restored.get_engine_feature_state().engines.get(id, {}) == record, "Save and Continue preserve the exact library")
	if restored != null:
		var snapshots := PrimitiveSnapshotDatabase.new()
		snapshots.load_ledgers()
		var result: Dictionary = BEGIN_PROJECT.execute(restored, snapshots, "Foundations project", &"action", &"fantasy")
		check(result.get("ok", false), "A project can start with the selected engine")
		if result.get("ok", false):
			var project: ProjectState = result.project
			check(project.get_engine_id() == id and same_ids(project.get_feature_supply_ids(), FOUNDATIONS), "Project freezes its engine and foundation supply")
	# This actual prior-source Studio payload was captured before the rule change.
	var path := OS.get_environment("PN_ENGINE_PRIOR_FIXTURE")
	if path.is_empty(): path = "res://../sims/new-engine-foundations-20261104/old-engine/prior.json"
	var prior: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	check(prior is Dictionary, "Captured pre-change Studio fixture is available")
	if prior is Dictionary:
		var old_id := StringName(prior.engine_id)
		var old_restored: RunState = adapter.hydrate(prior.player)
		check(old_restored != null and adapter.capture(old_restored) == prior.player, "Actual prior checkpoint restores exactly")
		if old_restored != null:
			var old_features := old_restored.get_engine_feature_state()
			var old_row: Dictionary = old_features.engines[old_id].duplicate(true)
			check(old_row.initial.is_empty() and old_row.implemented.is_empty(), "Continue does not grant Features to an existing engine")
			var forged_old := old_features.duplicate(true)
			forged_old.engines[old_id].initial = FOUNDATIONS.duplicate()
			forged_old.engines[old_id].implemented = FOUNDATIONS.duplicate()
			forged_old.engines[old_id].committed = FOUNDATIONS.duplicate()
			old_restored._engine_features = forged_old
			check(not old_restored.valid_engine_state(), "Old-origin engine cannot forge the new initial library")
			forged_old = old_features.duplicate(true)
			forged_old.engines[old_id].erase("initial")
			old_restored._engine_features = forged_old
			check(not old_restored.valid_engine_state(), "Old-origin engine with a missing initial field is rejected cleanly")
			old_restored._engine_features = old_features
			var old_snapshots := PrimitiveSnapshotDatabase.new()
			old_snapshots.load_ledgers()
			var frozen_result: Dictionary = BEGIN_PROJECT.execute(old_restored, old_snapshots, "Prior engine project", &"action", &"fantasy")
			check(frozen_result.get("ok", false), "A project starts on the continued historical engine")
			var old_project: ProjectState = frozen_result.get("project")
			if old_project != null:
				check(old_project.get_engine_id() == old_id and old_project.get_feature_supply_ids().is_empty() and prior.frozen_supply.is_empty(), "Historical engine project retains its earlier frozen empty supply")
			var next: Dictionary = old_restored.create_proprietary_engine(old_restored.get_proprietary_engine_creation_quote("Later engine"))
			check(next.get("ok", false), "A continued Studio can create another engine")
			if next.get("ok", false):
				var after: Dictionary = old_restored.get_engine_feature_state()
				var migrated_old: Dictionary = after.engines[old_id].duplicate(true)
				var enabled: Array = migrated_old.get("enabled", [])
				migrated_old.erase("enabled")
				check(migrated_old == old_row and enabled.is_empty(), "Creating a new engine preserves an older empty engine across activation-state migration")
				check(same_ids(after.engines[next.engine_id].implemented, FOUNDATIONS), "The later new engine receives all four foundations")
				if old_project != null: check(old_project.get_engine_id() == old_id and old_project.get_feature_supply_ids().is_empty(), "A previously begun project keeps its frozen engine and supply")
	# Use a real retained checkpoint with completed releases, then accept the
	# ordinary Ironclad offer through its normal gate and accounting path.
	var career: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://../docs/codex/findings/flex-hands-20261101-v1/preceding-world.json"))
	var contractor: RunState = adapter.hydrate(career.player) if career is Dictionary else null
	check(contractor != null, "Legal released-game Studio fixture restores for contract acceptance")
	if contractor != null:
		var contract_engine: Dictionary = contractor.create_proprietary_engine(contractor.get_proprietary_engine_creation_quote("Contract foundation engine"))
		check(contract_engine.get("ok", false) and contractor.select_engine(contract_engine.get("engine_id", &"")), "Create and select a new engine for a contract")
		if contract_engine.get("ok", false):
			check(contractor.is_primitive_contract_offer_available(), "Contract is offered by its normal release and availability gates")
			var accepted: ContractState = contractor.accept_primitive_contract()
			check(accepted != null, "Contract accepts through the normal payout and ownership path")
			if accepted != null:
				check(same_ids(accepted.get_eligible_feature_ids(), FOUNDATIONS), "Accepted contract freezes the selected engine's four-feature supply")
				var frozen: Array[StringName] = accepted.get_eligible_feature_ids()
				var changed := contractor.select_engine(&"public_action")
				check(changed and contractor.get_selected_engine_id() == &"public_action", "Fixture changes the selected engine after acceptance")
				check(changed and accepted.get_eligible_feature_ids() == frozen, "Contract eligible supply remains frozen after engine selection changes")
	print("NEW_ENGINE_FOUNDATIONS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
