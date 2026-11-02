extends SceneTree

const Map := preload("res://scripts/audio/theme_map.gd")
const Blend := preload("res://scripts/audio/theme_blend.gd")
const Grid := preload("res://scripts/audio/music_grid.gd")
var checks := 0
var failures := 0
var trace: Array = []

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + message)

func studio_stream_index(music: Node) -> int:
	return [1,4,5,6,7,8][music.studio_pool.selected]

func run() -> void:
	var music := root.get_node("Soundtrack")
	var paths: Array = [Map.MAIN_A, Map.MAIN_B, Map.MENU, Map.MENU_OPENER]
	paths.append_array(Map.STUDIO_POOL)
	for path in paths:
		check(Map.compatible(load(path)), "Theme WAV matches the common frame count/rate: " + path)
	var wrong := AudioStreamWAV.new()
	wrong.mix_rate = 22050
	check(not Map.compatible(wrong), "Reject incompatible future arrangement")
	check(Map.HARMONY.size() == Map.BARS and Map.STEPS_PER_LOOP == 64 and Map.STEP == 60.0 / 140.0, "Shared harmony and card tempo contract")
	check(music.themes.stream_count == 9, "Opener, menu, main and six Studio arrangements share one playback")
	for i in range(9):
		check(music.themes.get_sync_stream(i).loop_end == Map.FRAMES, "Exact common sample endpoint")
	check(music.requested_theme == &"menu" and is_equal_approx(db_to_linear(music.themes.get_sync_stream_volume(3)), 1.0), "One-time opener starts audible at the shared phrase origin")
	check(not music.request_theme(&"unknown"), "Unknown theme rejected without mutation")
	check(music.requested_theme == &"menu", "Unknown request leaves menu selected")
	music.player.seek(Map.LENGTH-0.12)
	music.grid=Grid.new()
	music.last_sample_usec=0
	music.presentation_seconds()
	await observe(music,0.25)
	check(music.opener_retired and music.menu_blend.weight==1.0,"Opener retires after its first phrase")
	check(is_equal_approx(db_to_linear(music.themes.get_sync_stream_volume(2)),1.0) and db_to_linear(music.themes.get_sync_stream_volume(3))==0.0,"Echo Reverb takes the repeating menu slot")
	verify_quick_entry()
	# Repeated loop transitions and sparse frames use an absolute-position fade.
	for frame_step in [1.0 / 60.0, 0.2, 1.1, 5.0]:
		var b := Blend.new()
		for loop in range(80):
			var start := (loop * Map.STEPS_PER_LOOP + 63.25) * Map.STEP
			var target := loop % 2 == 0
			b.request(target, start)
			var boundary := (loop + 1) * Map.STEPS_PER_LOOP * Map.STEP
			check(is_equal_approx(b.boundary, boundary), "Next bar at loop wrap")
			b.request(target, start + Map.STEP / 4.0)
			check(is_equal_approx(b.boundary, boundary), "Repeated cue does not postpone boundary")
			var prior := 0.0 if target else 1.0
			check(is_equal_approx(b.sample(boundary - 0.001), prior), "No early switch")
			var now := boundary
			while now < boundary + Blend.FADE + frame_step:
				var fraction := clampf((now - boundary) / Blend.FADE, 0.0, 1.0)
				var expected := fraction if target else 1.0 - fraction
				check(is_equal_approx(b.sample(now), expected), "Frame skip catches up without shifting the map")
				now += frame_step
			check(is_equal_approx(b.sample(boundary + Blend.FADE + frame_step), 1.0 if target else 0.0), "Fade completes once")
	var cancel := Blend.new()
	cancel.request(true, 0.1)
	cancel.request(false, 0.2)
	check(not cancel.pending and cancel.sample(Blend.BAR * 3.0) == 0.0, "Leaving Studio before cue cancels stale transition")
	var reverse := Blend.new()
	reverse.request(true, 0.1)
	check(is_equal_approx(reverse.sample(Blend.BAR + Blend.FADE / 2.0), 0.5), "Half fade")
	reverse.request(false, Blend.BAR + Blend.FADE / 2.0)
	check(reverse.sample(Blend.BAR + Blend.FADE) == 1.0, "In-flight fade finishes while reverse waits for next bar")
	check(reverse.sample(2.0 * Blend.BAR + Blend.FADE) == 0.0, "Reverse completes on mapped bar")
	# Real WAV backend: no synthetic clock or timer drives the mixer gains.
	music.player.seek(Map.LENGTH - 0.25)
	music.grid = Grid.new()
	music.blend = Blend.new()
	music.last_sample_usec = 0
	music.request_theme(&"studio")
	var playback: AudioStreamPlayback = music.player.get_stream_playback()
	await observe(music, 1.6)
	check(music.blend.weight == 1.0, "Real backend fades into Studio across loop wrap")
	check(music.grid.loops >= 1, "Common WAV clock unwraps on transition")
	check(music.player.get_stream_playback() == playback, "Theme transition retains playback instance")
	check(db_to_linear(music.themes.get_sync_stream_volume(0)) == 0.0, "Main fully silent in Studio")
	check(is_equal_approx(db_to_linear(music.themes.get_sync_stream_volume(studio_stream_index(music))), 1.0), "Selected Studio track fully audible")
	music.request_theme(&"main")
	music.set_paused(true)
	var held: float = music.presentation_seconds()
	var mix_held: float = music.grid.mix_seconds
	await create_timer(0.15).timeout
	check(music.presentation_seconds() == held and music.grid.mix_seconds == mix_held, "Manual pause freezes heard and mix positions")
	check(music.blend.weight == 1.0, "Pending cue waits during pause")
	music.set_paused(false)
	Engine.max_fps = 5
	await observe(music, 4.5)
	check(music.blend.weight == 0.0, "Reverse transition completes at five FPS")
	check(music.presentation_seconds() > held, "Card clock remains forward through transition")
	Engine.max_fps = 0
	music.request_theme(&"studio")
	paused = true
	await create_timer(0.05).timeout
	held = music.presentation_seconds()
	mix_held = music.grid.mix_seconds
	await create_timer(0.15).timeout
	check(music.presentation_seconds() > held and music.grid.mix_seconds > mix_held, "SceneTree pause advances both clocks and queued transitions")
	paused = false
	if OS.get_environment("PN_AUDIO_LONG") == "1":
		var laps: int = music.grid.loops
		await observe(music, Map.LENGTH + 0.2)
		music.request_theme(&"main")
		await observe(music, Map.LENGTH + 0.2)
		check(music.grid.loops >= laps + 2, "Two real loop boundaries with theme changes")
		check(music.blend.weight == 0.0, "Second real loop returns to main")
	await verify_phase_routes(music)
	verify_prior_world()
	var output := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if not output.is_empty():
		var file := FileAccess.open(output, FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"trace":trace},"\t"))
	print("Studio soundtrack: %d checks, %d failures" % [checks, failures])
	quit(failures)

func observe(music: Node, duration: float) -> void:
	var end := Time.get_ticks_msec() + int(duration * 1000)
	var previous: float = music.presentation_seconds()
	while Time.get_ticks_msec() < end:
		await create_timer(0.05).timeout
		var now: float = music.presentation_seconds()
		check(now >= previous, "Native card clock never rewinds")
		previous = now
		trace.append({"heard":now,"mix":music.grid.mix_seconds,"step":now/Map.STEP,"loops":music.grid.loops,"requested":str(music.requested_theme),"studio_weight":music.blend.weight,"driver":AudioServer.get_driver_name()})

func verify_quick_entry() -> void:
	# Every position in the phrase, including a wrap, retains the same grid.
	for step in range(64):
		for offset in [0.0,0.25,0.999]:
			var b := Blend.new()
			var start: float=(step+offset)*Map.STEP
			b.request(true,start,true)
			var boundary: float=b.boundary
			check(boundary>start and boundary-start<=Map.STEP+0.000001,"Title entry waits at most one eighth note")
			check(is_equal_approx(boundary/Map.STEP,roundf(boundary/Map.STEP)),"Title cue lands on the existing card grid")
			b.request(true,start+0.00001,true)
			check(b.boundary==boundary,"Repeated title cue never postpones transition")
			check(b.sample(boundary-0.000001)==0.0,"Quick cue does not start early")
			check(is_equal_approx(b.sample(boundary+Blend.ENTRY_FADE/2.0),0.5),"Quick cue uses a half-second-or-shorter envelope")
			check(b.sample(boundary+Blend.ENTRY_FADE)==1.0,"Quick entry completes within two eighth notes")
	var cancel := Blend.new()
	cancel.request(true,0.1,true)
	cancel.request(false,0.2)
	check(not cancel.pending and cancel.sample(1.0)==0.0,"Rapid return to title cancels quick entry")
	var reverse := Blend.new()
	reverse.request(true,0.1,true)
	reverse.request(false,Map.STEP*1.5)
	check(reverse.sample(Map.STEP*2.0)==1.0,"Quick fade finishes before normal reverse boundary")
	check(reverse.sample(Blend.BAR+Blend.FADE)==0.0,"Reverse retains ordinary bar timing")
	var sparse := Blend.new()
	sparse.request(true,63.9*Map.STEP,true)
	check(sparse.sample(66.0*Map.STEP)==1.0,"Missed frames catch up through a loop-wrapped quick cue")

func verify_prior_world() -> void:
	# Optional source-pinned pre-edit checkpoint, generated by the isolated runner.
	var path := OS.get_environment("PN_TITLE_PRIOR_WORLD")
	if path.is_empty(): return
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	check(data is Dictionary and data.has("player") and data.has("world"),"Prior audio-revision checkpoint exists")
	if not data is Dictionary or not data.has("player") or not data.has("world"): return
	var adapter:=StudioCheckpoint.new()
	var codec:=preload("res://scripts/market/rival_world_checkpoint.gd").new()
	var run: RunState=adapter.hydrate(data.player)
	var world: RivalWorld=codec.restore(data.world,data.player,run,root.get_node("CardDatabase").get_development_catalog())
	check(world!=null,"Pre-edit AI/Founder checkpoint remains compatible: "+codec.error)
	if world==null: return
	check(adapter.capture(world.player)==data.player,"Audio timing preserves player state exactly")
	var expected: Dictionary=data.world.duplicate(true)
	var actual: Dictionary=codec.capture(world)
	expected.source_identity=actual.source_identity
	check(actual==expected,"Audio timing preserves entire rival/Founder state except source marker")
	var bad: Dictionary=data.world.duplicate(true)
	bad.source_identity="unrecognized-audio-source"
	check(codec.restore(bad,data.player,adapter.hydrate(data.player),root.get_node("CardDatabase").get_development_catalog())==null,"Unknown source still rejected")

func verify_phase_routes(music: Node) -> void:
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	var state := RunState.new()
	state.initialize_cash(0)
	check(state.create_studio_with_traits("Music route", &"action", []), "Create Studio fixture")
	game.run_state = state # In-memory fixture; never acquires the player's save writer.
	root.add_child(game)
	await process_frame
	var studio: Control = game.get("_active_phase")
	check(studio is StudioPhase and music.requested_theme == &"studio", "Initial Studio cues its theme")
	var before := [state.get_cash_cents(), state.get_completed_run_cycles()]
	var boundary: float = music.blend.boundary
	game.get_node("%GameplayHUD").set_phase(studio)
	check(music.blend.boundary == boundary, "Rebinding Studio does not reschedule music")
	check(before == [state.get_cash_cents(), state.get_completed_run_cycles()], "Music navigation has no economic effect")
	check(not game._begin_next_project(studio, "", &"action", &"fantasy"), "Rejected development fixture")
	check(music.requested_theme == &"studio", "Rejected transition retains Studio music")
	check(game._begin_next_project(studio, "Music project", &"action", &"fantasy"), "Begin development fixture")
	await process_frame
	check(music.requested_theme == &"main", "Development cues main theme")
	# Construct the established launch-boundary fixture; do not claim a campaign.
	var project: ProjectState = game.project_state
	project.add_core_scores_and_scope({0:20,1:21,2:22,3:23},30)
	project.finalize_design_bugs(false,0,[&"text"],[])
	project.finalize_alpha(0,[],[])
	var old: Control = game.get("_active_phase")
	var beta: BetaPhase = load("res://scenes/phases/beta_phase.tscn").instantiate()
	check(beta.setup(project,state,game.get_snapshot_database()), "Beta presentation fixture accepts finalized Alpha")
	project.finalize_beta()
	game.get_node("%PhaseRoot").add_child(beta)
	game.set("_active_phase",beta)
	game.get_node("%GameplayHUD").set_phase(beta)
	old.queue_free()
	before = [state.get_cash_cents(),state.get_completed_run_cycles()]
	check(game._replace_beta_with_launch(beta,load("res://scenes/phases/launch_phase.tscn")), "Real launch-to-Studio controller boundary")
	check(game.get("_active_phase") is StudioPhase and music.requested_theme == &"studio", "Launch cues Studio after results commit")
	check(before == [state.get_cash_cents(),state.get_completed_run_cycles()], "Music adds no launch cycle/payment")
	var contract: ContractState = state.accept_primitive_contract()
	check(contract != null, "Legal first Contract fixture")
	if contract != null:
		game._on_contract_requested(game.get("_active_phase"),contract)
		check(game.get("_active_phase") is ContractPhase and music.requested_theme == &"main", "Contract play cues main music")
	game._enter_initial_studio(true)
	check(music.requested_theme == &"studio", "Restored Studio presentation cues Studio")
	trace.append({"phase":"restored_studio","music":str(music.requested_theme),"beat":music.presentation_seconds()/Map.STEP,"mix":music.grid.mix_seconds})
	game.queue_free()
	await process_frame
	var identity: int = music.player.get_stream_playback().get_instance_id()
	var second: Control = load("res://scenes/gameplay.tscn").instantiate()
	second.run_state = RunState.new()
	root.add_child(second)
	await process_frame
	check(second.get("_active_phase") is MainMenu and music.requested_theme == &"menu", "New main-menu scene restores menu music")
	check(music.player.get_stream_playback().get_instance_id() == identity, "Scene replacement never restarts transport")
	# Real title controller -> Studio routes, with in-memory new/loaded states.
	# Do not claim this presentation fixture is a disk-save/Continue test.
	for restored in [false,true]:
		music.blend=Blend.new()
		music._apply_blend(0.0)
		check(second.run_state.create_studio_with_traits("Title music",&"action",[]) if not restored else true,"Title fixture has a valid Studio")
		var cash: int=second.run_state.get_cash_cents()
		var cycles: int=second.run_state.get_completed_run_cycles()
		second._enter_initial_studio(restored)
		check(music.blend.pending_duration==Blend.ENTRY_FADE and music.blend.boundary-music.grid.mix_seconds<=Map.STEP,"New/Continue title entry selects the fast cue")
		var entry_boundary: float=music.blend.boundary
		second.get_node("%GameplayHUD").set_phase(second.get("_active_phase"))
		check(music.blend.boundary==entry_boundary,"Studio rebind preserves fast cue")
		await observe(music,1.0)
		check(music.blend.weight==1.0 and music.menu_blend.weight==0.0 and music.player.get_stream_playback().get_instance_id()==identity,"Native menu-to-Studio cue completes without transport restart")
		check(is_equal_approx(db_to_linear(music.themes.get_sync_stream_volume(studio_stream_index(music))),1.0) and db_to_linear(music.themes.get_sync_stream_volume(2))==0.0,"Studio is audible and menu is silent after quick entry")
		check(second.run_state.get_cash_cents()==cash and second.run_state.get_completed_run_cycles()==cycles,"Fast title cue leaves cash and calendar unchanged")
		if not restored:
			var title:=MainMenu.new()
			second.get_node("%PhaseRoot").add_child(title)
			second.get_node("%GameplayHUD").set_phase(title)
			await observe(music,Blend.BAR+Blend.FADE+0.1)
			check(music.requested_theme==&"menu" and music.menu_blend.weight==1.0,"Return to title completes on the shared bar map")
			check(is_equal_approx(db_to_linear(music.themes.get_sync_stream_volume(2)),1.0) and db_to_linear(music.themes.get_sync_stream_volume(3))==0.0 and db_to_linear(music.themes.get_sync_stream_volume(studio_stream_index(music)))==0.0,"Echo menu is audible, opener and Studio silent after title return")
	second.queue_free()
	await process_frame
