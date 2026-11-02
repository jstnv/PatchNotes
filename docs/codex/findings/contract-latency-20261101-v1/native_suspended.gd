extends "res://../docs/codex/findings/contract-latency-20261101-v1/profile_fast.gd"
func record(label: String,start: int,call_ms: int) -> void:
	super.record(label,start,call_ms)
	if label=="search/save":game.process_mode=Node.PROCESS_MODE_DISABLED
	elif label=="accept found":game.process_mode=Node.PROCESS_MODE_INHERIT
