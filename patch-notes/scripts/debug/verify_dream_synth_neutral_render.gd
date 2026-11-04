extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	root.get_node("Soundtrack").player.stop()
	var backdrop := ColorRect.new()
	backdrop.color = Color("101116")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)
	var flow = preload("res://scripts/ui/menu_circuit_background.gd").new()
	flow.size = Vector2(1280,720)
	flow.readability_right = 0.0
	root.add_child(flow)
	flow.set_active(true)
	flow.set_process(false)
	for i in 120:
		flow.field.step(1.0/60.0,Vector3.ZERO,false,null)
	flow.queue_redraw()
	await RenderingServer.frame_post_draw
	var packed: PackedVector4Array = flow._shader.get_shader_parameter("pulses")
	var neutral := 0
	var wrong := 0
	for value: Vector4 in packed:
		if value.x < 0.0: continue
		if value.w > 2.0: neutral += 1
		else: wrong += 1
	var result := root.get_texture().get_image().save_png("user://neutral.png")
	var ok: bool = neutral > 0 and wrong == 0 and result == OK
	print("NEUTRAL_RENDER neutral=%d non_neutral=%d capture=%d failures=%d" % [neutral,wrong,result,0 if ok else 1])
	flow.free()
	quit(0 if ok else 1)
