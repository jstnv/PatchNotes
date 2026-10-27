extends "res://scripts/debug/verify_priority_influence.gd"

func _capture(label: String, resolution: Vector2i) -> void:
	if DisplayServer.get_name() == "headless": return
	var directory := OS.get_environment("PN_CARD_FRAME_OUTPUT").get_base_dir().path_join("captures")
	DirAccess.make_dir_recursive_absolute(directory)
	await RenderingServer.frame_post_draw
	var path := directory.path_join("%s-%dx%d.png" % [label,resolution.x,resolution.y])
	expect(root.get_texture().get_image().save_png(path) == OK,"Fresh rendered evidence: "+path)
