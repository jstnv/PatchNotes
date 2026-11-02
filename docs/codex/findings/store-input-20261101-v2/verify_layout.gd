extends SceneTree
var failures:=0
var checks:=0
func expect(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func settle() -> void:
	for i in 8:await process_frame
func mouse(point: Vector2,pressed: bool,button: MouseButton=MOUSE_BUTTON_LEFT) -> void:
	var event:=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=button;event.pressed=pressed
	event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed and button==MOUSE_BUTTON_LEFT else 0
	root.push_input(event,true)
func click(button: Button) -> void:
	var point:=button.get_global_rect().get_center();var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;root.push_input(motion,true);print("POINTER_BUTTON ",button.name," ",button.get_global_rect()," hover=",root.gui_get_hovered_control()," root=",root.size," modals=",root.get_embedded_subwindows().filter(func(w):return w.visible).map(func(w):return [w.name,w.get_class()]));mouse(point,true);mouse(point,false)
func chrome_bounds(store: FeatureStore) -> void:
	for control: Control in [store._close,store._owned_summary,store._cash,store._debug,store._map.zoom_label]:
		expect(store.get_global_rect().encloses(control.get_global_rect()),"Floating control remains in bounds: "+str(control.name))
func _initialize() -> void:go.call_deferred()
func go() -> void:
	await process_frame
	var run:=RunState.new()
	expect(run.initialize_cash(0) and run.create_studio_with_traits("Engine Layout",&"action",[]),"Legal Studio")
	var public_engine:=run.get_selected_engine_id()
	var a:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Layout A"))
	var b:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Layout B — "+"LongName".repeat(8)))
	expect(a.get("ok",false) and b.get("ok",false),"Two owned engine fixtures")
	if a.is_empty() or b.is_empty():quit(1);return
	expect(run.select_engine(a.engine_id) and run.finalize_starter_selection(),"Selected engine remains independent of browsing")
	expect(run.admit_feature_research(run.get_feature_research_quote(&"text",a.engine_id)),"Queue first engine")
	expect(run.admit_feature_research(run.get_feature_research_quote(&"keyboard_and_mouse",b.engine_id)),"Queue second engine")
	# A real Studio supplies a GUI root. Keep that relationship in this focused
	# fixture rather than making the gesture-transparent Store the Window root.
	var host:=Control.new();root.add_child(host);host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var store:=FeatureStore.new();store.theme=load("res://resources/ui/workspace_theme.tres");host.add_child(store);store.setup(run);store.open_store(a.engine_id)
	var snapshot:=StudioCheckpoint.new().capture(run)
	for dimensions in [Vector2i(1152,648),Vector2i(1280,720),Vector2i(900,600)]:
		root.min_size=Vector2i.ZERO;root.size=dimensions;root.content_scale_size=dimensions
		await settle()
		expect(root.size==dimensions,"Actual requested viewport "+str(dimensions))
		expect(store._scroll.get_global_rect().position.y<=store.global_position.y+16 and store._scroll.size.y>=store.size.y-32,"Graph fills Store instead of reserving header/toolbar bands")
		expect(is_equal_approx(store._map.zoom,0.74),"Readable initial 74 percent view")
		expect(store._research_list.name==&"ImplementationQueue" and store._research_button.name==&"ImplementFeature","Implementation controls have current semantic identities")
		expect(store.find_child("ImplementationControls",true,false)!=null,"Engine implementation controls float as one coherent group")
		expect(store._toolbar.get_global_rect().end.y>=store.get_global_rect().end.y-24,"Compact controls float at bottom")
		expect(store._research_list.item_count==1 and store._research_list.get_item_text(0).contains("Layout A"),"Queue shows only the viewed engine")
		expect(store._research_button.text.begins_with("Implement") and not store._research_button.disabled,"Global head can implement")
		for control: Control in [store._close,store._owned_summary,store._debug,store._map.zoom_label]:
			expect(store.get_global_rect().encloses(control.get_global_rect()),"Floating control remains in bounds: "+str(control.name))
			var style:=control.get_theme_stylebox("normal") as StyleBoxFlat
			expect(style!=null and style.bg_color.a>=0.99,"Individual floating control has opaque backing: "+str(control.name))
		if store.has_method("_over_floating_control"):
			expect(store.call("_over_floating_control",store._cash.get_global_rect().get_center()),"Engine title shields graph gestures")
			expect(not store.call("_over_floating_control",store.get_global_rect().get_center()),"Empty map center accepts graph gestures")
		else:expect(false,"Floating controls expose precise input footprints")
		store._toggle_debug();await settle()
		expect(store.get_global_rect().encloses(store._debug_popup.get_global_rect()),"Debug opens within map bounds above bottom controls")
		store._close_debug()
		for control: Control in store.find_children("*","Control",true,false):
			if control.is_visible_in_tree() and (control is Label or control is Button):expect(not str(control.text).to_lower().contains("research"),"Player-facing tree uses implementation terminology")
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OS.get_environment("PN_CONTRACT_REPORT").get_base_dir().path_join("tree-%dx%d.png"%[dimensions.x,dimensions.y]))
		store.open_store(b.engine_id);await settle();chrome_bounds(store)
		expect(store._cash.text.contains("LongName"),"Long engine name remains engine-specific and wraps")
		store.open_store(a.engine_id);await settle()
	var zoom_before:=store._map.zoom
	for control: Control in [store._cash,store._owned_summary]:
		mouse(control.get_global_rect().get_center(),true,MOUSE_BUTTON_WHEEL_UP)
		mouse(control.get_global_rect().get_center(),false,MOUSE_BUTTON_WHEEL_UP);await settle()
		expect(is_equal_approx(store._map.zoom,zoom_before) and not store._map.dragging,"Wheel over floating label/button does not leak to map")
	var plus: Button
	for button: Node in store._toolbar.find_children("*","Button",true,false):
		if button.text=="+":plus=button
	click(plus);await settle()
	expect(store._map.zoom>zoom_before and not store._map.dragging,"Pointer zoom button works without starting a map drag")
	var zoom_after:=store._map.zoom;click(store._debug);await settle()
	expect(store._debug_popup.visible and is_equal_approx(store._map.zoom,zoom_after) and not store._map.dragging,"Pointer Debug opens without map leakage")
	for button: Node in store._debug_popup.find_children("*","Button",true,false):
		if button.text=="Close Debug":click(button)
	await settle();expect(not store._debug_popup.visible,"Pointer closes Debug")
	var gap:=Vector2((store._close.get_global_rect().end.x+store._cash.get_global_rect().position.x)/2.0,store._close.get_global_rect().get_center().y)
	var offset:=Vector2(store._scroll.scroll_horizontal,store._scroll.scroll_vertical)
	mouse(gap,true)
	var motion:=InputEventMouseMotion.new();motion.position=gap-Vector2(45,30);motion.global_position=motion.position;motion.relative=Vector2(-45,-30);motion.button_mask=MOUSE_BUTTON_MASK_LEFT;root.push_input(motion,true)
	expect(store._map.dragging,"Gap between floating controls starts map pan")
	mouse(motion.position,false);await settle()
	expect(not store._map.dragging and Vector2(store._scroll.scroll_horizontal,store._scroll.scroll_vertical)!=offset,"Gap pan changes camera and releases cleanly")
	var dimensions:=Vector2i(1152,648);root.size=dimensions;root.content_scale_size=dimensions
	store.open_store(b.engine_id);await settle()
	expect(store._research_list.item_count==1 and store._research_list.get_item_text(0).contains("Layout B"),"Switching engine refreshes its queue")
	expect(store._research_button.disabled and store._research_button.text=="Other engine first","Other engine FIFO head cannot be bypassed")
	expect(StudioCheckpoint.new().capture(run)==snapshot,"Free browsing/resize preserves all state, finance and RNG")
	store.open_store(a.engine_id);await settle()
	var cycle:=run.get_completed_run_cycles();var cash:=run.get_cash_cents();var due: int=run.get_feature_research_quote(&"text",a.engine_id).due_cents
	store._map._focus_node(&"text");await create_timer(0.75).timeout
	click(store._buy);await settle()
	expect(run.get_completed_run_cycles()==cycle+1 and run.get_cash_cents()==cash-due,"Implement pays exact due and consumes one cycle")
	expect(&"text" in run.get_future_project_feature_ids(a.engine_id) and &"text" not in run.get_future_project_feature_ids(b.engine_id),"Completion automatically supplies only the target engine")
	expect(store._research_list.disabled,"Empty queue is noninteractive and cannot create a modal dropdown")
	var selected:=store._selected;store._research_list.item_selected.emit(0);expect(store._selected==selected,"Empty queue placeholder cannot select a null Feature")
	store.open_store(b.engine_id);await settle();expect(not store._research_button.disabled,"Next engine head becomes actionable")
	store.hide();store.open_store(public_engine);expect(not store.visible,"Public fixed library cannot enter implementation tree")
	var report:={"checks":checks,"failures":failures};store.queue_free();await process_frame
	FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("ENGINE_STORE_LAYOUT checks=",checks," failures=",failures);quit(1 if failures else 0)
