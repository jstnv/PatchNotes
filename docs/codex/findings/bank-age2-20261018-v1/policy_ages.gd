extends "res://scripts/debug/verify_outstanding_expenses.gd"

func _initialize() -> void:
	_creation_and_months()
	_typed_ages_and_recovery()
	_provenance_and_overflow()
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify({"scope":"maintained synthetic policy fixtures; not a legal age2 Bank route","checks":checks,"failures":failures,"traces":traces},"\t"))
	print("EXPENSE_POLICY_FIXTURES checks=%d failures=%d"%[checks,failures]);quit(failures)
