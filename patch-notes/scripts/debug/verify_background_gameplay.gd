extends SceneTree

const WorldCodec:=preload("res://scripts/market/rival_world_checkpoint.gd")
var checks:=0
var failures:=0
var rows: Array=[]

class PrivateStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer!=null: return true
		var server:=TCPServer.new()
		if server.listen(47414,"127.0.0.1")!=OK: return false
		_writer=server
		return true

func expect(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("FAIL: "+label)

func capture(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	var target:=OS.get_environment("PN_CARD_FRAME_OUTPUT").get_base_dir().path_join(label+".png")
	root.get_texture().get_image().save_png(target)

func _initialize() -> void:
	await process_frame
	for size: Vector2i in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=size
		root.content_scale_size=size
		var game: Control=load("res://scenes/gameplay.tscn").instantiate()
		root.add_child(game)
		await process_frame
		# HUD settings applies the saved/default window size during _ready.
		# Restore the acceptance size afterwards, before measuring/capturing.
		root.size=size
		root.content_scale_size=size
		expect(root.size==size and root.content_scale_size==size,"Actual window and logical viewport use the requested supported size")
		expect(game.checkpoints.background_saves,"Normal Gameplay enables background saves")
		game._onboarding.answer(true)
		var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_BG_FIXTURE")))
		var run:=StudioCheckpoint.new().hydrate(data.player)
		var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
		var world:=WorldCodec.new().restore(data.world,data.player,run,catalog)
		game.checkpoints.store=PrivateStore.new("user://ui-background-"+str(size.x),game.checkpoints._validate_payload)
		game.run_state=run
		game.rival_world=world
		game.checkpoints.attach(run)
		expect(game.checkpoints.attach_rivals(world,catalog),"Actual Gameplay binds restored world")
		game._connect_rival_calendar()
		game.get_node("%GameplayHUD").setup(null,run)
		expect(game._enter_initial_studio(true),"Actual late-game Studio mounts")
		await process_frame
		var studio: StudioPhase=game._active_phase
		# Attribute save stalls separately from this host's native render cadence
		# and first-frame font/shader/layout warmup.
		for _warmup in 12: await process_frame
		var baseline_max:=0
		var baseline_last:=Time.get_ticks_usec()
		for _baseline in 16:
			await process_frame
			var now:=Time.get_ticks_usec()
			baseline_max=maxi(baseline_max,now-baseline_last)
			baseline_last=now
		expect(run.add_cash(1),"Real Studio action triggers background save")
		var kickoff_started:=Time.get_ticks_usec()
		game.checkpoints._request_save()
		var kickoff_ms: float=(Time.get_ticks_usec()-kickoff_started)/1000.0
		await process_frame
		expect(game._save_label.text=="Saving Studio…" and game.checkpoints.is_saving(),"HUD distinguishes in-flight save from durable Saved")
		studio._open_market()
		expect(studio._market_browser.visible and game.checkpoints.is_saving(),"Market remains interactive while the save worker owns publication")
		studio._market_browser.close()
		var started:=Time.get_ticks_usec()
		var maximum:=0
		var frames:=0
		await capture("saving-"+str(size.x))
		var last:=Time.get_ticks_usec()
		while game.checkpoints.is_saving():
			await process_frame
			var now:=Time.get_ticks_usec()
			maximum=maxi(maximum,now-last)
			last=now
			frames+=1
		expect(game.checkpoints.failure.is_empty() and game._save_label.text=="Studio saved","HUD reports Saved only after durable publication")
		expect(kickoff_ms<100.0,"Real Studio save kickoff stays within100ms")
		var native: bool=DisplayServer.get_name()!="headless"
		# Native GPU/present cadence is noisy even while idle on this host. Keep
		# those measurements explicit; do not mislabel them as CPU-save latency
		# or turn an unreliable native frame budget into a passing performance gate.
		expect(frames>1 and (native or maximum<150000),"Frames and interaction continue during publication; headless frame budget stays below150ms")
		rows.append({"size":str(size),"actual_window":str(root.size),"render_pixels":str(root.get_texture().get_size()),"save_wall_ms":(Time.get_ticks_usec()-started)/1000.0,"max_frame_gap_ms":maximum/1000.0,"baseline_max_frame_gap_ms":baseline_max/1000.0,"kickoff_ms":kickoff_ms,"frames":frames,"native_frame_budget":"NOT_ESTABLISHED" if native else "not_applicable"})
		await capture("saved-"+str(size.x))
		# Begin requested during another write must wait, accept one intent, then
		# enter Design only after its preceding Studio generation is durable.
		expect(run.add_cash(1),"Departure fixture commits newer Studio state")
		await process_frame
		game._on_development_requested(studio,"Background proof",&"action",&"fantasy")
		game._on_development_requested(studio,"Duplicate",&"action",&"fantasy")
		expect(game._active_phase==studio and game._save_navigation_pending,"Development intent waits while the save is running")
		while game._save_navigation_pending: await process_frame
		expect(game._active_phase is DesignPhase and not game.checkpoints.in_studio,"Exactly one development departure follows durable save")
		expect(not game.checkpoints.pending and not game.checkpoints.is_saving(),"No Studio publication remains when development starts")
		var current: Dictionary=game.checkpoints.store.inspect()
		expect(current.status==&"valid" and current.payload.run.completed_run_cycles=="96","Development did not replace the last committed Studio")
		game.free()
		await process_frame
	var report: Dictionary={"ok":failures==0,"checks":checks,"failures":failures,"rows":rows}
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(report))
	print(JSON.stringify(report))
	quit(failures)
