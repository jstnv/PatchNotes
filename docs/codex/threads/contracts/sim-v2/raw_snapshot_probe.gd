## Narrow planner compatibility probe only. No advances are modeled.
extends SceneTree

const Finance := preload("res://scripts/finance/studio_finance_ledger.gd")

func _initialize() -> void:
	var input: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://task34-input-legacy.json"))
	var ledger: Dictionary = input.get("final", {}).get("finance", {})
	var actions: Array = ledger.get("actions", [])
	var first_action: Dictionary = actions[0] if not actions.is_empty() else {}
	var report := Finance.report(ledger, 32, 0)
	var plan := Finance.plan(ledger, 32, 0, 15000, &"publisher_receipt", 0, 0, false, &"crown_trial")
	var result := {
		"input_cycle": ledger.get("last_cycle"),
		"input_cash_cents": ledger.get("cash_cents"),
		"action_count": actions.size(),
		"first_action_kind_type": typeof(first_action.get("kind")),
		"first_action_source_id_type": typeof(first_action.get("source_id")),
		"string_name_type": TYPE_STRING_NAME,
		"report_available": report.get("available", false),
		"candidate_receipt_plan_accepted": not plan.is_empty()
	}
	FileAccess.open("res://task34-raw-snapshot-probe.json", FileAccess.WRITE).store_string(JSON.stringify(result))
	print("TASK34_RAW_SNAPSHOT_PROBE ", JSON.stringify(result))
	quit(0)
