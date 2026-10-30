extends SceneTree
const EXPECTED := {
	&"player_level_editor":["Player Level Editor","design","", "technology",4,"design",1,1983,0,[&"save_files",&"levels"],&"Technology & Tools"],
	&"ability_gated_exploration":["Ability-Gated Exploration","alpha","world_design","graphics",2,"design",3,1986,1984,[&"exploration",&"power_ups"],&"Story & World"],
	&"switchable_protagonists":["Switchable Protagonists","alpha","story","technology",3,"design",2,1987,1984,[&"character_backstories",&"controls"],&"Story & World"],
	&"character_skill_checks":["Character Skill Checks","alpha","story","design",4,"technology",1,1988,1984,[&"character_development",&"exploration"],&"Story & World"],
}
var failures:=0
var checks:=0
func _initialize() -> void: _run.call_deferred()
func expect(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;print("FAIL: ",label)
func _run() -> void:
	root.theme=load("res://resources/ui/workspace_theme.tres")
	RenderingServer.set_default_clear_color(Color("10080b"))
	var run:=RunState.new()
	for id in EXPECTED: expect(run._feature_offers.has(id),"New finite Store child exists: "+str(id))
	if failures>0: quit(failures);return
	var database:=root.get_node("CardDatabase")
	var graph:=FeatureStoreCatalog.graph(run._feature_definitions,run._feature_offers)
	expect(not graph.has("error"),"All old/new parents form a valid acyclic graph")
	for id: StringName in EXPECTED:
		var spec:Array=EXPECTED[id];var entry:Dictionary=run._feature_offers[id]
		expect([entry.name,entry.phase,entry.department,entry.primary_stat,int(entry.primary_value),entry.secondary_stat,int(entry.secondary_value)]==spec.slice(0,7),"Exact phase, department and ordered Core: "+str(id))
		expect(int(entry.scope)==2 and not entry.renewable and int(entry.base_price_cents)==170000 and int(entry.play_cost_cents)==0,"Exact finite Scope and trial prices: "+str(id))
		expect(int(entry.min_year)==spec[7] and int(entry.get("era_year",0))==spec[8],"Exact year and independent era: "+str(id))
		expect(graph.parents[id]==spec[9] and StringName(entry.purchase_parent)==spec[9][0],"Exact AND parents/anchor: "+str(id))
		expect(database.get_card(id)!=null and not database.get_card(id).renewable,"Canonical CardDatabase loads finite child")
		var membership:=0
		for lane in FeatureStore.LANE_MEMBERS:
			if id in FeatureStore.LANE_MEMBERS[lane]: membership+=1;expect(lane==spec[10],"Correct map lane")
		expect(membership==1,"Exactly one map lane")
		for genre in StudioSpecialties.RULES:
			expect(id not in StudioSpecialties.preview(StringName(genre)).ids,"No new starter grant")
	for resolution in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=resolution
		var store:=FeatureStore.new();root.add_child(store);store.setup(run)
		await process_frame;await process_frame
		for id: StringName in EXPECTED:
			expect(store._nodes.has(id),"Visible locked future node")
			store._selected=id;store._show_details();await process_frame
			if DisplayServer.get_name() != "headless":
				store._map._focus_node(id)
				await create_timer(0.7).timeout
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(OS.get_environment("PN_CARD_FRAME_OUTPUT")+".%s-%d.png"%[id,resolution.x])
			expect("$0.00" in store._details.text,"Approved play cost is explicit")
			var node:Control=store._nodes[id]
			for other: StringName in store._nodes:
				if other!=id: expect(not store._map.node_footprint(node).intersects(store._map.node_footprint(store._nodes[other])),"New node "+str(id)+" at "+str(node.position)+" does not overlap "+str(other)+" at "+str(store._nodes[other].position))
		store.free()
	print("STORE_FOUR_CHILDREN checks=%d failures=%d"%[checks,failures]);quit(failures)
