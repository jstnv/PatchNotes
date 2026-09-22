## Focused Primitive Beta card-data verification.
## Run with: godot --headless --path . --script res://scripts/debug/verify_beta_card_data.gd
extends SceneTree

const CARD_DATABASE_SCRIPT := preload("res://scripts/cards/card_database.gd")
const LEDGER_PATH := "res://data/card_ledger.json"
const EXPECTED_BETA := {
	&"search_for_bugs": ["Search for Bugs", CardData.BETA_CATEGORY_QA, 1, true, CardData.QA_OPERATION_SEARCH],
	&"debug": ["Debug", CardData.BETA_CATEGORY_QA, 1, true, CardData.QA_OPERATION_DEBUG],
	&"sign_flippers": ["Sign Flippers", CardData.BETA_CATEGORY_MARKETING, 1, true, &""],
	&"posters": ["Posters", CardData.BETA_CATEGORY_MARKETING, 1, true, &""],
	&"press_release": ["Press Release", CardData.BETA_CATEGORY_MARKETING, 2, true, &""],
	&"press_interview": ["Press Interview", CardData.BETA_CATEGORY_MARKETING, 3, false, &""],
	&"playtest_rival_games": ["Playtest Rival Games", CardData.BETA_CATEGORY_INSIDER, 1, false, &""],
	&"study_competition": ["Study Competition", CardData.BETA_CATEGORY_INSIDER, 2, false, &""],
	&"predict_market_trends": ["Predict Market Trends", CardData.BETA_CATEGORY_INSIDER, 2, false, &""],
}
const LEGACY_IDS: Array[StringName] = [
	&"text", &"sprites", &"4_color_palette", &"8_bit_sound", &"8_bit_music", &"keyboard_and_mouse", &"controller", &"scrolling", &"menu_system", &"local_leaderboards", &"split_screen", &"score_system", &"lives_system", &"graphics_pass", &"sound_pass", &"technology_pass", &"design_pass", &"simple_story", &"dialogue", &"character_backstories", &"multiple_endings", &"controls", &"enemies", &"power_ups", &"general_combat", &"levels", &"maps", &"exploration", &"secrets", &"sound_effects", &"music",
]

var _failures := 0


func _initialize() -> void:
	var before_state := _project_snapshot(ProjectState.new(30))
	var file := FileAccess.open(LEDGER_PATH, FileAccess.READ)
	var definitions: Array = JSON.parse_string(file.get_as_text())
	var database := CARD_DATABASE_SCRIPT.new()
	database.name = "CardDatabase"
	root.add_child(database)
	await process_frame
	_expect(database.get_card_count() == 40, "Expanded ledger loads exactly 40 definitions")
	var loaded_ids: Array[StringName] = []
	for card: CardData in database.get_all_cards():
		loaded_ids.append(card.id)
	_expect(LEGACY_IDS.all(func(id: StringName) -> bool: return id in loaded_ids), "All 31 preexisting stable IDs remain loaded")
	var beta_cards: Array[CardData] = database.get_cards_by_phase(CardData.PHASE_BETA)
	_expect(beta_cards.size() == 9, "Exactly nine Primitive Beta cards load")
	_expect(database.get_cards_by_phase(CardData.PHASE_DESIGN).size() == 17 and database.get_cards_by_phase(CardData.PHASE_ALPHA).size() == 14, "Design and Alpha phase counts remain 17 and 14")
	_verify_roster(database, beta_cards)
	_verify_safe_queries(database)
	_verify_malformed_definitions(database, definitions[31].duplicate(true))
	_expect(_project_snapshot(ProjectState.new(30)) == before_state, "Loading and querying definitions cannot mutate project gameplay state")
	database.queue_free()
	_finish()


func _verify_roster(database: Node, beta_cards: Array[CardData]) -> void:
	var ids: Array[StringName] = []
	for card: CardData in beta_cards:
		ids.append(card.id)
		_expect(EXPECTED_BETA.has(card.id), "No undocumented Beta definition loads: %s" % card.id)
		var expected: Array = EXPECTED_BETA[card.id]
		_expect(card.card_name == expected[0] and card.beta_category == expected[1] and card.beta_value == expected[2], "%s has its locked name, category, and value" % card.id)
		_expect(card.phase == CardData.PHASE_BETA and card.card_type == &"beta" and card.scope == 0 and card.renewable == expected[3], "%s has Beta phase, Scope 0, and locked lifecycle" % card.id)
		_expect(card.qa_operation == expected[4], "%s has its applicable QA operation only" % card.id)
		_expect(card.primary_stat.is_empty() and card.primary_value == 0 and card.secondary_stat.is_empty() and card.secondary_value == 0, "%s has no fake Core production fields" % card.id)
		_expect(database.get_card(card.id) == card, "%s is retrievable by stable id" % card.id)
	_expect(ids.size() == EXPECTED_BETA.size() and EXPECTED_BETA.keys().all(func(id: StringName) -> bool: return id in ids), "Complete locked Beta roster exists exactly once")
	_expect(database.get_beta_cards_by_category(CardData.BETA_CATEGORY_QA).size() == 2, "QA query returns exactly two cards")
	_expect(database.get_beta_cards_by_category(CardData.BETA_CATEGORY_MARKETING).size() == 4, "Marketing query returns exactly four cards")
	_expect(database.get_beta_cards_by_category(CardData.BETA_CATEGORY_INSIDER).size() == 3, "Insider query returns exactly three cards")


func _verify_safe_queries(database: Node) -> void:
	var cards: Array[CardData] = database.get_cards_by_phase(CardData.PHASE_BETA)
	cards.clear()
	var category_cards: Array[CardData] = database.get_beta_cards_by_category(CardData.BETA_CATEGORY_QA)
	category_cards.clear()
	_expect(database.get_cards_by_phase(CardData.PHASE_BETA).size() == 9 and database.get_beta_cards_by_category(CardData.BETA_CATEGORY_QA).size() == 2, "Returned arrays cannot mutate CardDatabase collections")


func _verify_malformed_definitions(database: Node, valid: Dictionary) -> void:
	var cases: Array[Dictionary] = []
	for key: String in ["id", "name", "type", "phase", "beta_category", "beta_value", "scope", "renewable", "qa_operation"]:
		var missing := valid.duplicate(true)
		missing.erase(key)
		cases.append(missing)
	for mutation: Dictionary in [
		{"phase": "invalid"}, {"phase": "alpha"}, {"beta_category": "unknown"},
		{"beta_value": "1"}, {"beta_value": -1}, {"beta_value": 1.5},
		{"scope": -1}, {"scope": 0.5}, {"scope": 1}, {"renewable": false},
		{"qa_operation": "unknown"}, {"qa_operation": "debug"}, {"primary_stat": "design"},
	]:
		var malformed := valid.duplicate(true)
		malformed.merge(mutation, true)
		cases.append(malformed)
	var unknown := valid.duplicate(true)
	unknown["id"] = "undocumented_beta"
	cases.append(unknown)
	var non_beta_field := {"id": "legacy", "phase": "design", "beta_value": 1}
	cases.append(non_beta_field)
	var reversed_debug := valid.duplicate(true)
	reversed_debug["id"] = "debug"
	reversed_debug["name"] = "Debug"
	reversed_debug["qa_operation"] = "search"
	cases.append(reversed_debug)
	for malformed: Dictionary in cases:
		_expect(not database.validate_card_definition(malformed).is_empty(), "Malformed Beta/cross-phase definition rejects deterministically")
	var duplicate_errors: Array[String] = database.validate_card_definitions([valid, valid.duplicate(true)])
	_expect(duplicate_errors.size() == 1 and "duplicate stable id" in duplicate_errors[0], "Duplicate stable ids reject deterministically")


func _project_snapshot(state: ProjectState) -> Array:
	return [state.get_current_cycle(), state.get_current_scope(), state.get_accumulated_bug_pressure(), state.get_accumulated_alpha_bug_pressure(), state.get_hidden_bugs(), state.get_known_bugs()]


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: " + message)
	else:
		_failures += 1
		push_error("FAIL: " + message)


func _finish() -> void:
	if _failures == 0:
		print("Primitive Beta card-data verification passed.")
		quit(0)
	else:
		push_error("Primitive Beta card-data verification failed with %d error(s)." % _failures)
		quit(1)
