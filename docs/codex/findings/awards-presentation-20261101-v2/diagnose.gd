extends "res://scripts/debug/verify_annual_awards_gameplay.gd"
var report: Dictionary = {"pages":[],"max_frame_ms":0}
var last_frame := 0
func frame_sample() -> void:
	var now := Time.get_ticks_msec()
	if last_frame > 0: report.max_frame_ms = maxi(report.max_frame_ms,now-last_frame)
	last_frame=now
func shot(label: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("PN_AWARDS_REPORT_OUTPUT").get_base_dir().path_join(label+".png"))
func go() -> void:
	root.size=Vector2i(1280,720);root.content_scale_size=root.size
	process_frame.connect(frame_sample)
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_AWARDS_UI_FIXTURE")))
	var game: Control=await mount(data,"diagnosis")
	if game==null:finish();return
	await wait_for(func():return game._awards_waiting,"Saving surface exists")
	for node in game._awards_root.find_children("*","Label",true,false):
		if node.text.begins_with("Saving Annual"):
			report.saving_label={"width":node.size.x,"lines":node.get_line_count(),"rect":[node.position.x,node.position.y,node.size.x,node.size.y]}
	await shot("saving-before")
	if not await wait_for(func():return ready_ceremony(game,0),"Initial durable reveal"):finish();return
	report.runtime=game.checkpoints.last_payload.rival_world.source_identity
	for target in [1,2,3]:
		report.max_frame_ms=0
		var start := Time.get_ticks_msec()
		game.annual_awards_ceremony.next_button.pressed.emit()
		var call_ms := Time.get_ticks_msec()-start
		if not await wait_for(func():return ready_ceremony(game,target),"Durable next page"):break
		var row: Dictionary={"stage":target,"click_ms":call_ms,"ready_ms":Time.get_ticks_msec()-start,"max_frame_ms":report.max_frame_ms}
		if target>=2:
			row.initial=game.annual_awards_ceremony.score_labels[0].text
			row.bar_height=game.annual_awards_ceremony.find_child("ScoreBar1",true,false).size.y
			await create_timer(.3).timeout
			row.after_300ms=game.annual_awards_ceremony.score_labels[0].text
			row.bar_after_300ms=game.annual_awards_ceremony.find_child("ScoreBar1",true,false).size.y
			await shot("page%d-before"%target)
		report.pages.append(row)
	print("AWARDS_DIAG ",report)
	FileAccess.open(OS.get_environment("PN_AWARDS_REPORT_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	game.queue_free();await process_frame;finish()
