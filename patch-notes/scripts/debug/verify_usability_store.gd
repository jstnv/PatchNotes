extends SceneTree
var failures:=0
func _initialize() -> void: _run.call_deferred()
func check(ok:bool,message:String) -> void:
	print("PASS: " if ok else "FAIL: ",message)
	if not ok: failures+=1
func settle() -> void:
	for i in 6:await process_frame
func _run() -> void:
	for resolution:Vector2i in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=resolution;root.content_scale_size=resolution
		var session:RefCounted=preload("res://scripts/simulation/run_factory.gd").create_fresh_session({"schema_version":1,"studio_id":"store-ui","studio_name":"Store UI","specialty":"action","traits":[],"seed":"771"},root.get_node("CardDatabase").get_development_catalog())
		check(session!=null,"Create actual Studio")
		if session==null:quit(1);return
		var run:RunState=session.run
		var store:=FeatureStore.new();root.add_child(store);store.setup(run);store.open_store();await settle()
		var before:=run.get_cash_cents()
		# Controlled absent-ownership fixture exercises both AND parents without
		# pretending that a player acquired/removed these cards through this UI.
		for id:StringName in [&"turn_based_combat",&"scripted_ai",&"difficulty_levels"]:run._owned_features.erase(id)
		store._refresh();store._select_node(&"difficulty_levels");await settle()
		check(store._buy.text.contains("Missing:") and store._buy.text.contains("Turn") and store._buy.text.contains("Scripted"),"Missing button names both parents")
		check(store._buy.text_overrun_behavior==TextServer.OVERRUN_NO_TRIMMING and store._buy.autowrap_mode!=TextServer.AUTOWRAP_OFF,"Missing names wrap without ellipsis")
		check(store._map.shopping_details.text.is_empty() and not store._map.price.visible,"No acquisition essay or standalone price")
		check(store._details.text.contains("Scope") and store._details.text.contains("Play cost"),"Details show stats and play cost")
		check(not store._details.text.contains("Familiarity") and not store._details.text.contains("Base"),"Details omit pricing and familiarity prose")
		store._buy.pressed.emit();await settle()
		check(run.get_cash_cents()==before,"Missing prerequisite action cannot purchase")
		check(store._map.parent_links.get_child_count()==2,"Multi-parent action exposes both navigation targets")
		if store._map.parent_links.get_child_count()>0:
			(store._map.parent_links.get_child(0) as Button).pressed.emit();await settle()
			check(store._selected==&"turn_based_combat","Missing-parent navigation inspects prerequisite")
		store._select_node(&"text");await settle()
		check(store._buy.text.contains("owned") or store._buy.text.contains("$"),"Acquisition amount is on its action button")
		store.queue_free();await process_frame
	print("Usability Store: %d failures"%failures);quit(failures)
