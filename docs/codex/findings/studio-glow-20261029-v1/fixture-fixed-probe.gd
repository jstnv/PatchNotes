extends "res://scripts/debug/verify_feature_store_radial.gd"

const Factory := preload("res://scripts/simulation/run_factory.gd")
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	expect(ok, message)
func maximum(values: PackedFloat32Array) -> float:
	var value := 0.0
	for item in values: value = maxf(value,item)
	return value
func _verify() -> void:
	var bus := AudioServer.get_bus_index(&"Music")
	var effects := AudioServer.get_bus_effect_count(bus)
	var song := root.get_node("Soundtrack")
	var player_id: int = song.player.get_instance_id()
	var session: RefCounted = Factory.create_fresh_session({"schema_version":1,"studio_id":"studio-glow","studio_name":"Lowlight Studio","specialty":"action","traits":[],"seed":"2711"},root.get_node("CardDatabase").get_development_catalog())
	session.run.finalize_starter_selection()
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	game.run_state = session.run
	root.add_child(game)
	await process_frame
	await preload("res://scripts/debug/ui_test_actions.gd").finish_new_save(game)
	var hud: GameplayHUD = game.get_node("%GameplayHUD")
	var glow: Control = hud.get("studio_glow")
	check(glow != null,"Actual Studio HUD contains dim music observer")
	if glow == null: game.free();quit(failures);return
	var before := preload("res://scripts/simulation/development_replay.gd").digest(preload("res://scripts/simulation/development_replay.gd").freeze(session.run))
	check(glow.visible and glow.is_processing() and AudioServer.get_bus_effect_count(bus)==effects+1,"Studio attaches exactly one FFT observer")
	check(glow.mouse_filter==Control.MOUSE_FILTER_IGNORE and glow.focus_mode==Control.FOCUS_NONE and glow.clip_contents,"Glow cannot intercept input and stays clipped")
	check(glow.get_parent()==hud.scoreboard and glow.get_index()<hud.scoreboard.row.get_index(),"Light is inside existing header behind text and chart")
	for dimensions: Vector2i in [Vector2i(1152,648),Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size=dimensions;root.content_scale_size=dimensions
		for frame in 5:await process_frame
		check(hud.scoreboard.get_global_rect().encloses(glow.get_global_rect()),"Glow bounds fit header at "+str(dimensions))
		check(hud.header_title.visible and hud.sales_hud.get_parent()==hud.scoreboard.row,"Studio title and sales retain existing UI row")
		await create_timer(0.5).timeout
		for alpha in glow.light_alphas():check(alpha>=0.0 and alpha<=glow.MAX_ALPHA,"Each light remains below dim opacity cap")
		if dimensions.x!=1920 and DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OS.get_environment("PN_CARD_FRAME_OUTPUT")+"-%d.png"%dimensions.x)
	await create_timer(0.8).timeout
	var peak := maximum(glow.levels)
	check(peak>0.01,"Running Studio soundtrack produces genuine FFT energy")
	var first: PackedFloat32Array=glow.levels.duplicate()
	await create_timer(0.25).timeout
	check(glow.levels!=first,"Glow tracks changing audio, not a fake beat")
	for name: StringName in [&"Music",&"Master"]:
		var index:=AudioServer.get_bus_index(name);var prior:=AudioServer.is_bus_mute(index)
		AudioServer.set_bus_mute(index,true);await create_timer(0.9).timeout
		check(maximum(glow.light_alphas())<0.002,"Muted "+str(name)+" fades to darkness")
		AudioServer.set_bus_mute(index,prior);await create_timer(0.25).timeout
	var volume:=AudioServer.get_bus_volume_db(bus)
	AudioServer.set_bus_volume_db(bus,-80);await create_timer(0.9).timeout
	check(maximum(glow.light_alphas())<0.002,"Zero music volume leaves no artificial glow")
	AudioServer.set_bus_volume_db(bus,volume)
	var reverb: AudioEffect=AudioServer.get_bus_effect(bus,0)
	hud.hide();await process_frame
	check(not glow.is_processing() and AudioServer.get_bus_effect_count(bus)==effects,"Hidden HUD releases its analyzer")
	hud.show();await process_frame
	check(glow.is_processing() and AudioServer.get_bus_effect_count(bus)==effects+1 and AudioServer.get_bus_effect(bus,0)==reverb,"HUD return reacquires one observer without altering other effects")
	game.pause_menu.open();await create_timer(0.4).timeout
	var seconds: float=song.presentation_seconds()
	await create_timer(0.3).timeout
	check(paused and glow.can_process() and song.presentation_seconds()>seconds,"Paused Studio keeps music and observer running")
	game.pause_menu.close();await create_timer(0.3).timeout
	var studio: StudioPhase=game._active_phase
	studio._open_feature_store();await process_frame
	check(glow.visible and AudioServer.get_bus_effect_count(bus)==effects+1,"Studio Store browsing retains one header glow")
	check(preload("res://scripts/simulation/development_replay.gd").digest(preload("res://scripts/simulation/development_replay.gd").freeze(session.run))==before,"Decoration and passive browsing preserve all run state/RNG")
	if game.checkpoints != null and game.checkpoints.is_saving():await game.checkpoints.wait_saved()
	check(game._begin_next_project(studio,"Glow departure",&"action",&"fantasy"),"Legal project departure succeeds")
	await process_frame
	check(not glow.visible and not glow.is_processing() and AudioServer.get_bus_effect_count(bus)==effects,"Production releases Studio FFT work")
	check(song.player.get_instance_id()==player_id and song.player.playing and is_equal_approx(AudioServer.get_bus_volume_db(bus),volume),"Observer preserves player identity and mix gain")
	game.free();await process_frame
	check(AudioServer.get_bus_effect_count(bus)==effects,"Gameplay teardown leaves no owned analyzer")
	var report:={"checks":checks,"failures":failures,"peak":peak,"runtime_source":preload("res://scripts/simulation/development_replay.gd").source_identity()}
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(report))
	print("STUDIO_GLOW ",JSON.stringify(report));quit(failures)
