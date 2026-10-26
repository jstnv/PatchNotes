extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void: _run.call_deferred()
func expect(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", label)
	if not ok: failures += 1
func check_padding(panel: PanelContainer, content: Control) -> void:
	var style := panel.get_theme_stylebox("panel")
	print("PADDING_BOUNDS ",panel.name," content=",content.get_rect()," panel=",panel.size," expected=",style.get_content_margin(SIDE_LEFT),"/",style.get_content_margin(SIDE_RIGHT))
	expect(is_equal_approx(content.position.x,style.get_content_margin(SIDE_LEFT)),str(panel.name)+" retains left inset")
	expect(is_equal_approx(panel.size.x-content.get_rect().end.x,style.get_content_margin(SIDE_RIGHT)),str(panel.name)+" retains right inset")
	expect(is_equal_approx(content.position.y,style.get_content_margin(SIDE_TOP)),"Entrance never changes vertical inset")
func settled(transitions: MenuTransitions) -> void:
	# Native startup/resize can take multiple long frames. Wait for the actual
	# deferred entrance and tween, rather than sampling an in-flight 0.4s frame.
	for i in range(6): await process_frame
	var deadline := Time.get_ticks_msec() + 4000
	while not transitions._motions.is_empty() and Time.get_ticks_msec() < deadline:
		await process_frame
	expect(transitions._motions.is_empty(),"Entrance completes within bounded wait")
	for i in range(2): await process_frame
func _run() -> void:
	var transitions := MenuTransitions.new()
	root.add_child(transitions)
	for caption in ["ContractModal","SummaryPanel","Dashboard"]:
		var host := CenterContainer.new()
		host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(host)
		var panel := PanelContainer.new()
		panel.name = caption
		panel.custom_minimum_size = Vector2(560,240)
		var style := StyleBoxFlat.new()
		style.set_content_margin_all(24)
		panel.add_theme_stylebox_override("panel",style)
		host.add_child(panel)
		var content := VBoxContainer.new()
		panel.add_child(content)
		var label := Label.new()
		label.text = caption
		content.add_child(label)
		await settled(transitions)
		check_padding(panel,content)
		panel.hide();panel.show();panel.hide();panel.show()
		await create_timer(0.08).timeout
		root.size = Vector2i(1280,720)
		await settled(transitions)
		check_padding(panel,content)
		panel.hide();panel.show()
		await create_timer(0.08).timeout
		host.queue_free()
		await process_frame
		await create_timer(0.3).timeout
		expect(transitions._motions.is_empty() and transitions._entrance_requests.is_empty(),"Teardown clears active and deferred entrance state")
	print("MENU_PADDING checks=%d failures=%d" % [checks,failures])
	quit(failures)
