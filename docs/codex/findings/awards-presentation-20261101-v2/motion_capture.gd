extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func shot(label: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("PN_AWARDS_REPORT_OUTPUT").get_base_dir().path_join(label+".png"))
func _initialize() -> void:
	await process_frame
	var studios: Array=[{"studio_id":&"a","studio_name":"Wayfinder Works","fans":100,"gained_fans":50},{"studio_id":&"b","studio_name":"Mythweaver Games","fans":90,"gained_fans":40},{"studio_id":&"c","studio_name":"Arcade Foundry","fans":80,"gained_fans":30}]
	var games: Array=[]
	for i in 3:games.append({"release_id":StringName("g%d"%i),"studio_id":studios[i].studio_id,"title":str(studios[i].studio_name)+" 4","cores":[50-i*2,30-i*2,40-i*2,25-i*2],"review_tenths":90-i,"release_cycle":40,"release_year":1980})
	var frozen: Dictionary=load("res://scripts/awards/annual_awards_rules.gd").rank(1980,45,studios,games)
	for size in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=size;root.content_scale_size=size
		var ui=load("res://scripts/ui/annual_awards_ceremony.gd").new()
		ui.configure(frozen,2,true,false);ui.hide();root.add_child(ui)
		await process_frame;await process_frame
		ui.show();await shot("graphics-%d-zero"%size.x)
		check(ui.score_labels[0].text=="0 Graphics","First visible frame starts at zero")
		var bars: Array=[]
		for i in 3:
			var bar: Control=ui.find_child("ScoreBar%d"%[i+1],true,false);bars.append(bar)
			check(is_zero_approx(bar.size.y),"Each nominee starts at the same baseline")
		await create_timer(.45).timeout
		await shot("graphics-%d-mid"%size.x)
		for i in 3:check(bars[i].size.y>0 and bars[i].size.y<bars[i].get_parent().size.y,"Each real nominee grows gradually")
		var deadline:=Time.get_ticks_msec()+8000
		while ui._counter_running and Time.get_ticks_msec()<deadline:await process_frame
		check(not ui._counter_running,"Visible reveal reaches its final frame")
		await shot("graphics-%d-final"%size.x)
		check(ui.score_labels[0].text=="50 Graphics" and ui.score_labels[1].text=="48 Graphics" and ui.score_labels[2].text=="46 Graphics","Exact frozen integer endpoints")
		check(is_equal_approx(bars[1].size.y/bars[0].size.y,48.0/50.0) and is_equal_approx(bars[2].size.y/bars[0].size.y,46.0/50.0),"Bar heights encode relative scores, not fixed ranks")
		var baseline: float=bars[0].get_global_rect().end.y
		for bar: Control in bars:check(is_equal_approx(bar.get_global_rect().end.y,baseline),"Chart baseline stays aligned")
		check(root.get_visible_rect().encloses(ui.next_button.get_global_rect()) and not ui.scroll.is_ancestor_of(ui.next_button),"Fixed Next remains visible and outside scroll")
		for stage in [3,4,5]:
			ui.set_stage(stage);ui.finish_counters()
			check(ui.score_labels[0].text.ends_with(["Sound","Technology","Design"][stage-3]),"Actual Core category unit")
		ui.queue_free();await process_frame
	print("AWARDS_NATIVE_MOTION checks=%d failures=%d"%[checks,failures])
	quit(1 if failures else 0)
