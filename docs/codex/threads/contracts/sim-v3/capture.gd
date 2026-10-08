## Capture native typed state before JSON; no gameplay changes or candidate cash.
extends "res://analysis/feature_store_rebaseline_v1.gd"

const F := preload("res://scripts/finance/studio_finance_ledger.gd")
var typed_checkpoints: Array = []
var parity_checks := 0
var destination := ""

func _run() -> void:
	startup_mode = _arg("--startup=", "legacy")
	destination = _arg("--out=", "")
	era_policy = "synergy"
	release_band = "early"
	declared_seed = 4417
	specialty_id = &"action"
	store_arm = "existing_sound"
	campaign_sensitivity = false
	route_case = declared_seed
	project_number = 0
	max_games = 4
	action_limit = 120
	era_cap = 0
	first_store_cycle = 0
	random_inputs.seed = declared_seed
	var out := await _matched_route()
	out["parity_checks"] = parity_checks
	FileAccess.open(destination + ".json", FileAccess.WRITE).store_string(JSON.stringify(out))
	FileAccess.open(destination + ".bin", FileAccess.WRITE).store_var(typed_checkpoints)
	var restored: Array = FileAccess.open(destination + ".bin", FileAccess.READ).get_var()
	assert(restored == typed_checkpoints, "Lossless native typed capture")
	for entry: Dictionary in restored:
		assert(F.report(entry.ledger, entry.cycle, entry.cash) == entry.report)
		for id: StringName in entry.records:
			assert(ReleasedGameSales.is_valid(entry.records[id]))
	print("TASK34_TYPED_CAPTURE ", startup_mode, " valid=", out.valid, " parity_checks=", parity_checks, " checkpoints=", restored.size())
	quit(0 if out.valid else 1)

func _capture_cycle(game: Control) -> void:
	super._capture_cycle(game)
	if game.run_state.get_completed_run_cycles() == 32:
		_capture_typed(game, "cycle32")

func _visit(game: Control, out: Dictionary, reason: String) -> void:
	super._visit(game, out, reason)
	if reason == "committed release":
		_capture_typed(game, "release%d" % out.releases.size())

func _capture_typed(game: Control, label: String) -> void:
	var run: RunState = game.run_state
	var ledger := run.get_studio_finance_snapshot()
	var cycle := run.get_completed_run_cycles()
	var cash := run.get_cash_cents()
	var report := run.get_studio_finance_report()
	assert(F.report(ledger, cycle, cash) == report and report.available)
	var records := {}
	for id: StringName in run.get_released_game_ids():
		records[id] = run.get_released_game_sales(id)
		assert(ReleasedGameSales.is_valid(records[id]))
	var before := var_to_bytes(ledger)
	var receipt := F.plan(ledger, cycle, cash, 15000, &"publisher_receipt", 0, 0, false, &"task34_candidate_probe")
	assert(not receipt.is_empty(), "Typed candidate receipt planner accepts")
	assert(var_to_bytes(ledger) == before, "Pure probe preserves native ledger")
	assert(F.report(receipt.ledger, cycle, receipt.cash_cents).available)
	parity_checks += 4
	typed_checkpoints.append({"label": label, "cycle": cycle, "cash": cash, "ledger": ledger,
		"report": report, "records": records, "owned": run.get_owned_feature_ids(),
		"publishers": _publishers(run), "redraws": run.get_available_redraws(),
		"ironclad_available": run.is_primitive_contract_offer_available(),
		"sidestreet_available": run.is_sidestreet_offer_available()})
