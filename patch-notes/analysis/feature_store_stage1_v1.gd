## Isolated read-only schema capability probe. No live data files are mutated.
extends SceneTree

const OUT := "res://design-logs/feature-store-staged-v1/stage1_live_capabilities_v1.json"
const CORE := {&"graphics": ProjectState.CoreScore.GRAPHICS, &"sound": ProjectState.CoreScore.SOUND, &"technology": ProjectState.CoreScore.TECHNOLOGY, &"design": ProjectState.CoreScore.DESIGN}
var checks: Array = []
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks.append({"case": label, "passed": ok, "kind": "actual_godot_isolated_fixture"})
	if not ok:
		failures += 1
		push_error(label)

func definition(node: Dictionary) -> Dictionary:
	var d := {"id": node.id, "name": node.name, "type": "feature", "phase": node.phase, "department": node.department, "scope": int(node.scope), "renewable": false, "primary_stat": "", "primary_value": 0, "secondary_stat": "", "secondary_value": 0, "purchase_parent": node.parents[0] if not node.parents.is_empty() else "", "purchase_parents": node.parents, "gameplay_features_required": int(node.gameplay_features_required), "base_price_cents": 170000}
	for index in node.ordered_core.size():
		var prefix: String = ["primary", "secondary", "tertiary"][index]
		d[prefix + "_stat"] = node.ordered_core[index].stat
		d[prefix + "_value"] = int(node.ordered_core[index].value)
	return d

func snapshot(run: RunState) -> Array:
	return [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_available_redraws(), run.get_owned_feature_ids(), run.get("_familiarity").duplicate(true), run.get("_released_games").duplicate(true)]

func _run() -> void:
	var db: Node = root.get_node("CardDatabase")
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://design-logs/feature-store-staged-v1/stage1_catalog_v1.json"))
	var by_id := {}
	for node: Dictionary in catalog.nodes: by_id[node.id] = node
	var rows: Array = []
	var design := DesignPhase.new()
	var alpha := AlphaPhase.new()
	design.set("_project_state", ProjectState.new(30))
	alpha.set("_project_state", ProjectState.new(30))
	var priorities := {ProjectState.CoreScore.GRAPHICS: 10, ProjectState.CoreScore.SOUND: 20, ProjectState.CoreScore.TECHNOLOGY: 30, ProjectState.CoreScore.DESIGN: 40}
	for node: Dictionary in catalog.nodes:
		var d := definition(node)
		var card: CardData = db.call("_create_card", d)
		var expected_weight := 0.0
		for e: Dictionary in node.ordered_core: expected_weight += int(e.value) * int(priorities[CORE[StringName(e.stat)]])
		var weight := WeightedCandidateMath.calculate_printed_score_weight(card, priorities, CORE)
		var expected_pressure := float(node.printed_core_sum) * int(node.scope) / 18.0
		var pressure := float(design.call("_calculate_feature_bug_pressure", card)) if node.phase == "design" else float(alpha.call("_calculate_feature_alpha_bug_pressure", card))
		var schema_ok: bool = node.ordered_core.size() <= 2
		var cards: Array[CardData] = [card]
		var additions := {}
		for e: Dictionary in node.ordered_core.slice(0, 2): additions[CORE[StringName(e.stat)]] = int(e.value)
		for i in 3:
			var pass_card: CardData = db.get_card(StringName(str(card.primary_stat) + "_pass"))
			cards.append(pass_card)
			additions[CORE[card.primary_stat]] = int(additions.get(CORE[card.primary_stat], 0)) + pass_card.primary_value
		var result: Dictionary = (design if node.phase == "design" else alpha).call("_calculate_final_action_production", {"cards": cards, "score_additions": additions, "scope": card.scope, "has_feature": true})
		check(result.specialization_stat == card.primary_stat, node.name + " primary controls Specialization")
		for stat in additions: check(result.score_additions[stat] == roundi(int(additions[stat]) * 1.5), node.name + " actual specialization resolved " + str(stat))
		if schema_ok:
			check(is_equal_approx(weight, expected_weight) and is_equal_approx(pressure, expected_pressure) and card.scope == int(node.scope), node.name + " ordered effects weight Scope Bug Pressure represented")
		else:
			check(weight < expected_weight and pressure < expected_pressure, node.name + " unsupported tertiary loss detected before gameplay scoring")
		rows.append({"id": node.id, "schema_supported": schema_ok, "primary": card.primary_stat, "secondary": card.secondary_stat, "expected_weight": expected_weight, "live_weight": weight, "expected_bug_pressure": expected_pressure, "live_bug_pressure": pressure, "validation_error": db.call("validate_card_definition", d), "resolution_kind": "actual_two_field_calculation" if schema_ok else "capability_failure_not_valid_gameplay_score", "specialization_scores": result.score_additions})
	design.free()
	alpha.free()
	var run := RunState.new()
	run.initialize_cash_cents(1000001)
	var original_contract_ids: Array = run.call("_primitive_contract_eligible_ids")
	var original_count: int = db.get_card_count()
	var multi := definition(by_id.character_classes)
	var definitions: Dictionary = run.get("_feature_definitions")
	definitions[&"character_classes"] = multi
	var offers: Dictionary = run.get("_feature_offers")
	offers[&"character_classes"] = multi
	var missing := run.get_feature_store_offer(&"character_classes")
	check(missing.unlocked, "Capability failure observed: live quote ignores second AND parent Save Files")
	run.get("_owned_features")[&"save_files"] = true
	run.get("_familiarity")[&"general_combat"] = 2
	run.get("_familiarity")[&"save_files"] = 3
	var both := run.get_feature_store_offer(&"character_classes")
	check(both.discount_percent == 20 and both.price_cents == 136000, "Capability failure observed: live familiarity takes only first parent instead of50percent")
	var clean := RunState.new()
	clean.initialize_cash_cents(1000001)
	var before := snapshot(clean)
	check(not clean.purchase_feature(&"branching_nodes") and snapshot(clean) == before, "Live locked purchase preserves all tracked state")
	check(clean.purchase_feature(&"save_files") and clean.get_cash_cents() == 780001 and clean.get_completed_run_cycles() == 1, "Live exact-cent purchase one productive cycle")
	check(clean.get_feature_store_offer(&"branching_nodes").unlocked, "Live ownership opens branch without play")
	before = snapshot(clean)
	check(not clean.purchase_feature(&"save_files") and snapshot(clean) == before, "Live duplicate no-op")
	var project := ProjectState.new(30)
	check(clean.record_resolved_feature(project, &"text", &"design") and not clean.record_resolved_feature(project, &"text", &"design"), "Live once per parent per project")
	check(not clean.record_resolved_feature(project, &"text", &"contract") and clean.get_feature_familiarity(&"text") == 1, "Live Contract no familiarity")
	var discount_grid := []
	for i in 8:
		var fixture := RunState.new()
		fixture.initialize_cash_cents(1000001)
		for j in i: fixture.record_resolved_feature(ProjectState.new(30), &"text", &"design")
		var quote := fixture.get_feature_store_offer(&"colored_text")
		check(quote.discount_percent == mini(i, 5) * 10 and quote.price_cents == 65000 * (10 - mini(i, 5)) / 10, "Live exact quote credits" + str(i))
		discount_grid.append({"credits": i, "price_cents": quote.price_cents, "discount_percent": quote.discount_percent})
	var poor := RunState.new()
	poor.initialize_cash_cents(64999)
	before = snapshot(poor)
	check(not poor.purchase_feature(&"colored_text") and snapshot(poor) == before, "Live insufficient cash rollback")
	clean.set("_completed_run_cycles", RunState.MAX_SIGNED_INT)
	before = snapshot(clean)
	check(not clean.purchase_feature(&"colored_text") and snapshot(clean) == before, "Live cycle overflow rollback")
	var difficulty := RunState.new()
	difficulty.initialize_cash_cents(0)
	difficulty.set_studio_name("Scope fixture")
	check(not difficulty.get_feature_store_offer(&"difficulty_levels").unlocked, "Live initial oneGameplay gate locked")
	difficulty.purchase_starter_feature(&"enemies")
	difficulty.purchase_starter_feature(&"power_ups")
	for i in 7: difficulty.record_resolved_feature(ProjectState.new(30), &"enemies", &"alpha")
	check(difficulty.get_feature_store_offer(&"difficulty_levels").unlocked and difficulty.get_feature_store_offer(&"difficulty_levels").discount_percent == 0, "Live threeGameplay gate no discount")
	var after_contract_ids: Array = run.call("_primitive_contract_eligible_ids")
	check(original_contract_ids == after_contract_ids and original_contract_ids.size() == 27 and not original_contract_ids.has(&"save_files") and not original_contract_ids.has(&"character_classes"), "Live fixed Primitive Contract pool unchanged by candidate localdefinitions or purchased later root")
	check(db.get_card_count() == original_count and db.get_card(&"boss_battles") == null and db.get_card(&"character_classes") == null, "Live global card databases never receive proposed definitions")
	var output := {"source_head": catalog.source_head, "kind": "actual_Godot_capability_fixtures_not_candidate_gameplay", "failures": failures, "checks": checks, "card_capabilities": rows, "missing_parent_live_quote": missing, "combined_credit_live_quote": both, "live_discount_grid": discount_grid, "notes": ["Expected capability failures are asserted as observed; they do not authorize unsupported cards.", "Full finitephase/rollback/settlement regression suites were run by parent baseline gate."]}
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	file.store_string(JSON.stringify(output, "  "))
	file.close()
	print("STAGE1 LIVE CAPABILITY: %d checks; %d unexpected failures;97 definitions inspected" % [checks.size(), failures])
	quit(failures)
