extends SceneTree
const Codec := preload("res://scripts/market/rival_world_checkpoint.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var checks := 0
func expect(ok: bool, label: String) -> void:
	assert(ok, label)
	checks += 1
	print("PASS: ", label)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var input := ""
	var output := ""
	var prior := "--prior" in OS.get_cmdline_user_args()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--input="): input = arg.trim_prefix("--input=")
		if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(input))
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var codec := Codec.new()
	var run: RunState = StudioCheckpoint.new().hydrate(data.player)
	var world := codec.restore(data.world,data.player,run,catalog)
	expect(world != null, "Previous world restores")
	var next := codec.capture(world)
	if prior:
		FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"player":StudioCheckpoint.new().capture(run),"world":next}))
		quit(); return
	var old: Dictionary = data.world.duplicate(true)
	next.erase("source_identity"); old.erase("source_identity")
	expect(next == old and StudioCheckpoint.new().capture(run) == data.player, "Every prior player/world field and RNG stays exact")
	var forged: Dictionary = data.world.duplicate(true)
	forged.source_identity = "0".repeat(64)
	expect(not codec.validate(forged,data.player).is_empty(), "Unknown world identity still rejects")
	var snapshots := PrimitiveSnapshotDatabase.new()
	snapshots.load_ledgers()
	for resolution in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size = resolution; root.content_scale_size = resolution
		var studio: StudioPhase = load("res://scenes/phases/studio_phase.tscn").instantiate()
		root.add_child(studio)
		expect(studio.setup(null,run,snapshots), "Saved Studio opens without registering another release")
		await create_timer(.1).timeout
		var button: Button = studio.get_node("%Employees")
		var before := Replay.digest(StudioCheckpoint.new().capture(run))
		expect(button.visible and button.disabled and button.tooltip_text == "Temporarily unavailable.", "Employees stays visible and disabled at "+str(resolution))
		for pressed in [true,false]:
			var click := InputEventMouseButton.new()
			click.position = button.get_global_rect().get_center()
			click.button_index = MOUSE_BUTTON_LEFT; click.pressed = pressed
			Input.parse_input_event(click); await process_frame
		button.grab_focus()
		for pressed in [true,false]:
			var key := InputEventKey.new()
			key.keycode = KEY_ENTER; key.pressed = pressed
			Input.parse_input_event(key); await process_frame
		expect(studio._employees_panel == null and before == Replay.digest(StudioCheckpoint.new().capture(run)), "Mouse/Enter cannot open Employees or mutate Studio")
		expect(not studio.get_node("%FeatureStoreButton").disabled and not studio.get_node("%StartNextGame").disabled, "Adjacent Studio actions remain enabled")
		studio.queue_free(); await process_frame
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"pass":true,"checks":checks,"source":Replay.source_identity(),"previous":data.world.source_identity}))
	quit()
