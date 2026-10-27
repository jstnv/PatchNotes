extends "res://scripts/debug/verify_contract_presentation.gd"
func capture(label: String, resolution: Vector2i) -> void:
	if label != "completion": return
	await create_timer(MenuTransitions.ENTRANCE_SECONDS + 0.12).timeout
	var output := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output=arg.trim_prefix("--out=")
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output.path_join("completion-%dx%d.png" % [resolution.x,resolution.y]))==OK)
