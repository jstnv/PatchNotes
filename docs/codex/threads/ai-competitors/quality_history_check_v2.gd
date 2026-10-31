extends SceneTree

const Factory := preload("res://scripts/simulation/run_factory.gd")
const Trial := preload("res://scripts/market/rival_trial.gd")
const Model := preload("res://scripts/ui/market_browser_model.gd")
const Codec := preload("res://scripts/market/rival_world_checkpoint.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var checks := 0
var failures: Array[String] = []

class TestStore extends StudioCheckpointStore:
	func acquire() -> bool:return true

func expect(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)

func _initialize() -> void:
	node_added.connect(func(node: Node):
		if node is CheckpointCoordinator: node.store = TestStore.new("user://saves/studio",node._validate_payload))
	await process_frame
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var cases: Array = []
	for seed in [4417,5607]:
		var player: RefCounted = Factory.create_fresh_session({"schema_version":1,"studio_id":"history-player-"+str(seed),"studio_name":"History Check","specialty":"action","traits":[],"seed":str(seed)},catalog)
		var world := Trial.create_world(player.run,catalog)
		var before := Replay.digest(Codec.new().capture(world))
		var result := Model.query(player.run,world)
		var historical: Array = result.get("historical_rows",[])
		expect(result.ok and result.rows.is_empty(),"cycle0 no live releases")
		expect(historical.size()==24,"cycle0 twenty-four historical rows seed"+str(seed))
		var reviews: Array = []
		for row: Dictionary in historical:
			reviews.append(int(row.review_tenths))
			expect(row.get("record_type")=="historical" and not row.player_owned,"typed historical ownership")
			expect(not row.has("earned_units"),"no invented historical sales")
		reviews.sort()
		var expected_reviews: Array=[]
		for archive: Array in world.historical_archive.values():
			for item: Dictionary in archive:expected_reviews.append(int(item.review_tenths))
		expected_reviews.sort()
		expect(reviews==expected_reviews,"exact generated saved Reviews")
		if historical.size()==24:
			expect(historical.all(func(row):return row.release_year>=1977 and row.release_year<=1979),"actual three-year history dates")
			var original := world.historical_archive.duplicate(true)
			var owner: StringName = &"incumbent-action"
			world.historical_archive[owner][0]["cores"]=[1,2,3,4]
			world.historical_archive[owner][0]["release_cycle"]=20
			world.historical_archive[owner].append(world.historical_archive[owner][0].duplicate(true))
			world.historical_archive[owner].append({"id":"bad","title":"Invalid","year":1981,"genre":"action","theme":"fantasy","review_tenths":99})
			world.historical_archive["unknown-owner"]=[original[owner][0]]
			expect(Model.query(player.run,world).historical_rows==historical,"extra typed fields tolerated; invalid/duplicate/unknown rows excluded")
			world.historical_archive = original
			historical[0].release_title = "Modified output"
			expect(Model.query(player.run,world).historical_rows[0].release_title!="Modified output","projection output detached")
			historical = Model.query(player.run,world).historical_rows
		expect(Model.query(player.run).get("historical_rows",[]).is_empty(),"no-world empty archive")
		var browser := MarketBrowser.new()
		root.add_child(browser)
		browser.open(player.run,world)
		expect(browser.rows.size()==24,"All Studios shows history")
		if not browser.rows.is_empty():
			expect(browser.games.get_root().get_first_child().get_text(0).contains("Historical"),"visible historical label")
			expect(browser.games.get_root().get_first_child().get_text(4)=="—","historical units unavailable")
			expect(browser.details.text.contains("historical") or browser.details.text.contains("Historical"),"frozen detail copy")
		browser.filter.select(1);browser.refresh()
		expect(browser.rows.is_empty(),"Your Studio excludes history")
		browser.filter.select(2);browser.refresh()
		expect(browser.rows.size()==24,"AI Studios shows history")
		browser.close();browser.queue_free();await process_frame
		expect(before==Replay.digest(Codec.new().capture(world)),"query/UI preserve complete world and RNG")
		var codec := Codec.new()
		var player_saved := StudioCheckpoint.new().capture(player.run)
		var saved := codec.capture(world)
		var resumed := codec.restore(saved,player_saved,StudioCheckpoint.new().hydrate(player_saved),catalog)
		expect(resumed!=null and Model.query(resumed.player,resumed).historical_rows==historical,"Continue preserves row identities/order")
		if seed==4417: await layout_cases(player.run,world)
		cases.append({"seed":seed,"historical_rows":historical,"before":before,"after":Replay.digest(Codec.new().capture(world))})
	var report := {"checks":checks,"failures":failures,"source":Replay.source_identity(),"cases":cases}
	var path := output_path()
	if not path.is_empty(): FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("HISTORICAL_MARKET "+JSON.stringify({"checks":checks,"failures":failures,"source":report.source}))
	quit(0 if failures.is_empty() else 1)

func layout_cases(run: RunState,world: RivalWorld) -> void:
	for resolution in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size = resolution;root.content_scale_size = resolution
		var game: Control = load("res://scenes/gameplay.tscn").instantiate()
		game.run_state = run;game.rival_world = world;game._onboarding.answer(true)
		root.add_child(game)
		await create_timer(0.4).timeout
		# The normal game applies saved window settings during _ready.
		root.size = resolution;root.content_scale_size = resolution
		await process_frame
		var studio: StudioPhase = game._active_phase
		var hud: GameplayHUD = game.get_node("%GameplayHUD")
		hud.contextual_tip.dismiss()
		var before := Replay.digest(Codec.new().capture(world))
		studio._market_button.pressed.emit()
		await create_timer(0.35).timeout
		var browser: MarketBrowser = studio._market_browser
		expect(browser.visible and browser.rows.size()==24,"actual Studio cycle0 Market opens")
		expect(not browser.get_global_rect().intersects(hud.get_node("PersistentHeader").get_global_rect()),"history clears top HUD")
		expect(browser.get_global_rect().end.y<=hud.footer_panel.get_global_rect().position.y,"history clears footer")
		expect(browser.get_global_rect().encloses(browser.games.get_global_rect()) and browser.get_global_rect().encloses(browser.details.get_global_rect()) and browser.get_global_rect().encloses(browser.back_button.get_global_rect()),"history controls fit supported size")
		var directory := output_path().get_base_dir()
		if not directory.is_empty() and DisplayServer.get_name()!="headless":
			var motion := InputEventMouseMotion.new();motion.position=Vector2(4,4);motion.global_position=Vector2(4,4)
			Input.parse_input_event(motion)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(directory+"/history-%dx%d.png" % [resolution.x,resolution.y])
		var escape := InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true
		Input.parse_input_event(escape)
		await process_frame
		expect(not browser.visible and studio._market_button.has_focus() and not paused,"history Escape returns focus without pause")
		studio._market_button.pressed.emit()
		var cancel := InputEventJoypadButton.new();cancel.button_index=JOY_BUTTON_B;cancel.pressed=true
		Input.parse_input_event(cancel)
		await process_frame
		expect(not browser.visible and studio._market_button.has_focus() and not paused,"controller Back returns Studio focus")
		studio._market_button.pressed.emit();browser.back_button.pressed.emit()
		expect(not browser.visible and studio._market_button.has_focus(),"Back button returns Studio focus")
		expect(before==Replay.digest(Codec.new().capture(world)),"actual Market open/select/close preserves complete world")
		game.queue_free()
		await process_frame

func output_path() -> String:
	for item: String in OS.get_cmdline_user_args():
		if item.begins_with("--output="):return item.trim_prefix("--output=")
	return ""
