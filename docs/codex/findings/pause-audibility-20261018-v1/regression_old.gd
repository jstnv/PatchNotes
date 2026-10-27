extends "res://scripts/debug/verify_pause_audibility.gd"

func _initialize() -> void:
	super._initialize()
	await process_frame
	# Restore only the captured pre-fix filter parameter in this isolated test.
	root.get_node("Soundtrack").pause_filter.resonance = 0.15
