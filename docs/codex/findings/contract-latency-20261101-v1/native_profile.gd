extends "res://../docs/codex/findings/contract-latency-20261101-v1/profile_fast.gd"
func record(label: String,start: int,call_ms: int) -> void:
	super.record(label,start,call_ms)
	if label=="search/save":capture_search.call_deferred()
func capture_search() -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("PN_CONTRACT_REPORT").get_base_dir().path_join("search-native.png"))
