## Real Feature Store activation controls, dependency navigation and capacity.
extends SceneTree

var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ",label)
	if not ok:failures += 1

func _initialize() -> void:
	verify.call_deferred()

func implement(run: RunState,engine: StringName,id: StringName) -> bool:
	var admission := run.get_feature_research_quote(id,engine)
	if not admission.get("can_admit",false) or not run.admit_feature_research(admission):return false
	var completion := run.get_feature_research_quote(id,engine)
	return completion.get("can_research",false) and run.research_feature(completion)

func scope_with(run: RunState,engine: StringName,id: StringName) -> int:
	var pool := run.get_future_project_feature_ids(engine)
	if not id.is_empty() and id not in pool:pool.append(id)
	pool=RunState.EngineFeatures.normalize(pool,run._feature_offers)
	var value := 0
	for feature: StringName in pool:value += int(run._feature_definitions[feature].scope)
	return value

func select(store: FeatureStore,id: StringName) -> void:
	store._select_node(id)

func inspect_list_at_sizes(store: FeatureStore) -> void:
	var folder := OS.get_environment("PN_ACTIVATION_UI_CAPTURE")
	if folder.is_empty() or DisplayServer.get_name()=="headless":return
	DirAccess.make_dir_recursive_absolute(folder)
	for dimensions in [Vector2i(1280,720),Vector2i(900,600)]:
		root.size=dimensions
		root.content_scale_size=dimensions
		for frame in 5:await process_frame
		select(store,&"8_bit_sound")
		await create_timer(0.5).timeout
		store._map._activate_action()
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		var popup: Rect2=store._map.popup.get_global_rect()
		print("ACTIVATION_UI_GEOMETRY viewport=%s popup=%s toolbar=%s" % [dimensions,popup,store._toolbar.get_global_rect()])
		check(store._map.guidance_scroll.visible and Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(popup),"Scrollable dependency list fits %s viewport" % dimensions)
		check(not popup.intersects(store._toolbar.get_global_rect()),"Scrollable dependency list avoids map controls at %s" % dimensions)
		check(root.get_texture().get_image().save_png(folder.path_join("activation-children-%dx%d.png" % [dimensions.x,dimensions.y]))==OK,"Capture dependency list at %s" % dimensions)

func verify() -> void:
	root.size=Vector2i(1280,720)
	root.content_scale_size=root.size
	var run := RunState.new()
	check(run.initialize_cash(0) and run.create_studio_with_traits("Feature UI",&"action",[]),"Create Studio")
	check(run.add_cash(500000),"Fund legal purchases")
	var made := run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("UI engine"))
	check(made.get("ok",false),"Create proprietary engine")
	if not made.get("ok",false):quit(1);return
	var engine: StringName=made.engine_id
	check(run.select_engine(engine) and run.finalize_starter_selection(),"Select engine and finish setup")
	for id: StringName in [&"controller",&"sprites",&"8_color_palette",&"main_theme",&"recorded_sounds",&"16_bit_sound",&"simple_story",&"dialogue",&"character_backstories"]:
		check(implement(run,engine,id),"Implement legal Feature " + str(id))
	var store := FeatureStore.new()
	store.theme=preload("res://resources/ui/onyx_theme.tres")
	root.add_child(store)
	store.setup(run)
	store.open_store(engine)
	for frame in 3:await process_frame
	select(store,&"controller")
	await create_timer(0.8).timeout
	store._buy.grab_focus()
	check(store._buy.text=="Disable" and not store._buy.disabled,"Enabled leaf offers Disable")
	check(store._buy.has_focus(),"Activation control can receive keyboard focus")
	store._map._activate_action()
	check(not run.get_engine_feature_activation_quote(&"controller",engine).get("enabled",true),"Disable action updates actual engine")
	check(store._buy.text=="Enable" and not store._buy.disabled,"Disabled leaf offers Enable")
	store._map._activate_action()
	check(run.get_engine_feature_activation_quote(&"controller",engine).get("enabled",false),"Enable action updates actual engine")
	check(store._buy.has_focus(),"Activation preserves keyboard focus")
	select(store,&"simple_story")
	var story: Dictionary=run.get_engine_feature_activation_quote(&"simple_story",engine)
	check(story.get("active_children",[]).size()==2 and int(story.get("linked_children_count",0))==2 and store._buy.text=="(2) active child nodes" and not store._buy.disabled,"Two directly linked active children are actionable")
	store._map._activate_action()
	check(store._map.parent_links.get_child_count()==2,"Two linked children have direct navigation shortcuts")
	if store._map.parent_links.get_child_count()>0:store._map.parent_links.get_child(0).pressed.emit()
	check(store._selected in story.get("active_children",[]),"Child shortcut navigates to selected child")
	select(store,&"4_color_palette")
	var palette: Dictionary=run.get_engine_feature_activation_quote(&"4_color_palette",engine)
	check(palette.get("active_children",[]).size()==2 and int(palette.get("linked_children_count",0))>2 and store._buy.text=="(2) active child nodes" and not store._buy.disabled,"Two active children with more linked children are actionable")
	store._map._activate_action()
	check(store._map.guidance_scroll.visible and store._map.guidance_scroll.get_child(0).get_child_count()==3,"More than two linked children use a list when two are active")
	var one_child_quote: Dictionary=run.get_engine_feature_activation_quote(&"8_color_palette",engine)
	check(run.set_engine_feature_active(one_child_quote),"Disable one palette child")
	select(store,&"4_color_palette")
	check(store._buy.text=="(1) active child nodes","One active child is counted")
	store._map._activate_action()
	check(store._map.guidance_scroll.visible and store._map.guidance_scroll.get_child(0).get_child_count()==2,"More than two linked children use a list when one is active")
	check(run.set_engine_feature_active(run.get_engine_feature_activation_quote(&"8_color_palette",engine)),"Re-enable palette child")
	select(store,&"8_bit_sound")
	var sound: Dictionary=run.get_engine_feature_activation_quote(&"8_bit_sound",engine)
	check(sound.get("active_children",[]).size()>2 and store._buy.text=="(%d) active child nodes" % sound.get("active_children",[]).size(),"More than two active children are counted")
	store._map._activate_action()
	check(store._map.guidance_scroll.visible and store._map.guidance_scroll.get_child(0).get_child_count()==sound.get("active_children",[]).size()+1,"More than two children appear in a scrollable list")
	store._map.guidance_scroll.get_child(0).get_child(1).pressed.emit()
	check(store._selected in sound.get("active_children",[]),"Scrollable list navigates to its selected child")
	await inspect_list_at_sizes(store)
	for id: StringName in [&"main_theme",&"recorded_sounds"]:
		check(run.set_engine_feature_active(run.get_engine_feature_activation_quote(id,engine)),"Disable Sound child " + str(id))
	select(store,&"8_bit_sound")
	var sparse_sound: Dictionary=run.get_engine_feature_activation_quote(&"8_bit_sound",engine)
	check(sparse_sound.get("active_children",[]).size()==1 and int(sparse_sound.get("linked_children_count",0))>2,"Three linked Sound children can have one active")
	store._map._activate_action()
	check(store._map.guidance_scroll.visible and store._map.guidance_scroll.get_child(0).get_child_count()==2,"More than two linked children still use a list when one is active")
	for id: StringName in [&"main_theme",&"recorded_sounds"]:
		check(run.set_engine_feature_active(run.get_engine_feature_activation_quote(id,engine)),"Re-enable Sound child " + str(id))
	var other := run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Cross-category engine"))
	check(other.get("ok",false),"Create independent engine for cross-category dependencies")
	if other.get("ok",false):
		var cross_engine: StringName=other.engine_id
		for id: StringName in [&"menu_system",&"save_files",&"branching_nodes",&"scrolling",&"split_screen"]:
			check(implement(run,cross_engine,id),"Implement cross-category Feature " + str(id))
		store.open_store(cross_engine)
		select(store,&"scrolling")
		var scrolling: Dictionary=run.get_engine_feature_activation_quote(&"scrolling",cross_engine)
		check(&"split_screen" in scrolling.get("active_children",[]),"Cross-category active child appears in authoritative dependency list")
		store._map._activate_action()
		check(store._selected==&"split_screen","Single cross-category child navigation reaches its node")
		check(store._nodes[&"split_screen"].has_focus(),"Cross-category navigation places focus on target")
		store.open_store(engine)
	for child: StringName in palette.get("active_children",[]):
		var quote: Dictionary=run.get_engine_feature_activation_quote(child,engine)
		check(quote.get("can_toggle",false) and run.set_engine_feature_active(quote),"Disable palette child before parent: " + str(child))
	var palette_quote: Dictionary=run.get_engine_feature_activation_quote(&"4_color_palette",engine)
	check(palette_quote.get("can_toggle",false) and run.set_engine_feature_active(palette_quote),"Disable parent after children")
	select(store,&"sprites")
	check(not store._buy.disabled and store._buy.text.contains("4-Color Palette") and store._details.text.contains("parent"),"Inactive parent is explained and navigable")
	store._map._activate_action()
	check(store._selected==&"4_color_palette","Inactive parent shortcut navigates to parent")
	select(store,&"4_color_palette")
	store._map._activate_action()
	select(store,&"sprites")
	store._map._activate_action()
	select(store,&"8_color_palette")
	store._map._activate_action()
	var candidates: Array[StringName]=[&"menu_system",&"scrolling",&"colored_text",&"inventory_system",&"timer_system",&"score_system",&"levels",&"simple_story",&"lives_system",&"save_files"]
	for id: StringName in candidates:
		if scope_with(run,engine,&"")>=25:break
		var next:=scope_with(run,engine,id)
		if next<=25 and run.get_feature_research_quote(id,engine).get("can_admit",false):implement(run,engine,id)
	check(scope_with(run,engine,&"")==25,"Fill the enabled library to exactly its capacity")
	var overflow: StringName=&""
	for id: StringName in run._feature_definitions:
		if scope_with(run,engine,id)>25 and run.get_feature_research_quote(id,engine).get("can_admit",false):overflow=id;break
	check(not overflow.is_empty() and implement(run,engine,overflow),"Feature implementation is permitted above capacity")
	if not overflow.is_empty():
		select(store,overflow)
		check(store._buy.disabled and store._buy.text=="Reached scope limit","Only enabling beyond capacity shows the Scope-limit action")
		check(store._details.text.contains("25 Scope"),"Blocked enablement explains projected Scope and limit")
	check(store._owned_summary.text.contains("/ 25"),"Library summary shows current Scope and capacity")
	store.queue_free()
	await process_frame
	print("FEATURE_ACTIVATION_UI checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
