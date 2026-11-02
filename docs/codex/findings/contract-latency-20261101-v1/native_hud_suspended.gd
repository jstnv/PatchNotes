extends "res://../docs/codex/findings/contract-latency-20261101-v1/profile_fast.gd"
var previous_mode:=0
func record(label: String,start: int,call_ms: int) -> void:
	super.record(label,start,call_ms)
	if label=="search/save":
		previous_mode=game.get_node("%GameplayHUD").process_mode
		game.get_node("%GameplayHUD").process_mode=Node.PROCESS_MODE_DISABLED
	elif label=="accept found":game.get_node("%GameplayHUD").process_mode=previous_mode
