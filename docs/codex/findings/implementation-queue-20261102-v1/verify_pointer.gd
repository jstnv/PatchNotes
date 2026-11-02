extends SceneTree
var failures:=0
var checks:=0
func check(ok: bool,label: String) -> void:
	checks+=1;print("PASS: " if ok else "FAIL: ",label)
	if not ok:failures+=1
func settle() -> void:
	for frame in 8:await process_frame
func click(control: Control) -> void:
	var point:=root.get_final_transform()*control.get_global_rect().get_center()
	var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;Input.parse_input_event(motion)
	await process_frame
	print("CLICK ",control.name," logical=",control.get_global_rect()," physical=",point," hovered=",root.gui_get_hovered_control()," disabled=",control.get("disabled"))
	for down in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0;Input.parse_input_event(event);await process_frame
	await settle()
func _initialize() -> void:go.call_deferred()
func go() -> void:
	await process_frame
	var run:=RunState.new();run.initialize_cash(0);run.create_studio_with_traits("Queue pointer",&"action",[])
	var a:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Engine 1"))
	check(a.get("ok",false),"Legal engine")
	var host:=Control.new();root.add_child(host);host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var store:=FeatureStore.new();store.theme=load("res://resources/ui/workspace_theme.tres");host.add_child(store);store.setup(run);store.open_store(a.engine_id)
	for entry in [[Vector2i(1152,648),&"text"],[Vector2i(1280,720),&"keyboard_and_mouse"],[Vector2i(1906,932),&"8_bit_sound"]]:
		root.min_size=Vector2i.ZERO;root.size=entry[0];root.content_scale_size=Vector2i(1152,648);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		await settle()
		check(run.admit_feature_research(run.get_feature_research_quote(entry[1],a.engine_id)),"Legal queue admission "+str(entry[1]))
		await settle()
		check(store._research_list.is_visible_in_tree(),"Implementation queue is visible")
		check(not store._research_button.disabled,"Top implementation head enabled")
		var before:=run.get_completed_run_cycles();var cash:=run.get_cash_cents();var due:int=run.get_feature_research_quote(entry[1],a.engine_id).due_cents
		await click(store._research_button)
		check(run.owns_feature(entry[1],a.engine_id) and run.get_completed_run_cycles()==before+1 and run.get_cash_cents()==cash-due,"Physical pointer completes at "+str(entry[0]))
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(OS.get_environment("PN_CONTRACT_REPORT").get_base_dir().path_join("scaled-store.png"))
	FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}))
	host.queue_free();await process_frame;quit(failures)
