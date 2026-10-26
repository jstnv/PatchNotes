extends "res://scripts/debug/contract_challenge_restore_probe.gd"
func _run() -> void:
	OS.set_environment("PN_CHALLENGE_COLD","1")
	super._run()
