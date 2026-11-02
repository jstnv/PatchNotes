extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize() -> void:
	await process_frame
	root.size=Vector2i(1152,648);root.content_scale_size=root.size
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_AWARDS_UI_FIXTURE")))
	var payload: Dictionary=data.player.duplicate(true)
	payload.rival_world=data.world
	var store:=StudioCheckpointStore.new("user://cache-regression")
	var codec:=CheckpointCodec.new()
	var context:=store._parse_context(codec)
	var sources: Array[String]=[]
	for stage in [1,2,3]:
		var candidate:=payload.duplicate(true)
		candidate.rival_world.annual_awards.entries[0].stage=str(stage)
		var source:=JSON.stringify(codec.envelope(candidate))
		sources.append(source)
		store._remember_parsed(source,candidate,context)
	check(store._parsed_envelopes.size()==3,"Three real-size ceremony generations fit the bounded parse cache")
	check(store._parsed_bytes<=store.PARSED_CACHE_BYTES,"Parse proof memory remains bounded")
	print("AWARDS_CACHE bytes=",store._parsed_bytes," entries=",store._parsed_envelopes.size()," per_generation=",sources[0].to_utf8_buffer().size()+var_to_bytes(payload).size())
	var rules=load("res://scripts/awards/annual_awards_rules.gd")
	var studios: Array=[{"studio_id":&"a","studio_name":"First Studio","fans":100,"gained_fans":50},{"studio_id":&"b","studio_name":"Second Studio","fans":90,"gained_fans":40},{"studio_id":&"c","studio_name":"Third Studio","fans":80,"gained_fans":30}]
	var games: Array=[]
	for i in 3:games.append({"release_id":StringName("g%d"%i),"studio_id":studios[i].studio_id,"title":"Nominee %d"%i,"cores":[50-i*2,30-i*2,40-i*2,25-i*2],"review_tenths":90-i,"release_cycle":40,"release_year":1980})
	var frozen: Dictionary=rules.rank(1980,45,studios,games)
	var ceremony=load("res://scripts/ui/annual_awards_ceremony.gd").new()
	ceremony.configure(frozen,2,true,false)
	root.add_child(ceremony)
	var fill:=ceremony.find_child("ScoreBar1",true,false) as Control
	check(fill!=null,"Nominees have actual score-driven bar fills")
	if fill!=null:check(is_zero_approx(fill.size.y),"First nominee starts at the chart baseline")
	ceremony.hide()
	await create_timer(1.1).timeout
	check(ceremony.score_labels[0].text.begins_with("0 "),"Hidden presentation does not consume its counter reveal")
	ceremony.show()
	await create_timer(.3).timeout
	var value:=str(ceremony.score_labels[0].text).get_slice(" ",0).to_int()
	check(value>0 and value<50,"Visible counter has an intermediate score")
	if fill!=null:check(fill.size.y>0,"Visible nominee bar grows upward from zero")
	ceremony.finish_counters()
	check(ceremony.score_labels[0].text=="50 Graphics","Graphics award names its actual Core category")
	for stage in range(3,6):
		ceremony.set_stage(stage);ceremony.finish_counters()
		check(ceremony.score_labels[0].text.ends_with(["Sound","Technology","Design"][stage-3]),"Each Core award names its category")
	fill=ceremony.find_child("ScoreBar1",true,false) as Control
	if fill!=null:
		root.size=Vector2i(1280,720);root.content_scale_size=root.size
		await process_frame;await process_frame
		check(is_equal_approx(fill.size.x,fill.get_parent().size.x),"Completed bar follows a resized track")
	ceremony.queue_free();await process_frame
	var immediate=load("res://scripts/ui/annual_awards_ceremony.gd").new()
	immediate.animate_counters=false
	immediate.configure(frozen,2,true,false);root.add_child(immediate)
	await process_frame;await process_frame
	var full:=immediate.find_child("ScoreBar1",true,false) as Control
	if full!=null:check(full.size.x>0 and is_equal_approx(full.size.y,full.get_parent().size.y),"Nonanimated endpoint survives first Container layout")
	immediate.queue_free();await process_frame
	print("AWARDS_PRESENTATION_REGRESSION checks=%d failures=%d"%[checks,failures])
	quit(1 if failures else 0)
