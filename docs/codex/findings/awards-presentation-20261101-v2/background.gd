extends "res://scripts/debug/verify_background_checkpoint.gd"
func _initialize() -> void:
	OS.set_environment("PN_BG_FIXTURE",OS.get_environment("PN_AWARDS_UI_FIXTURE"))
	OS.set_environment("PN_CARD_FRAME_OUTPUT",OS.get_environment("PN_AWARDS_REPORT_OUTPUT"))
	super._initialize()
