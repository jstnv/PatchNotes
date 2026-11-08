extends SceneTree

const Song := preload("res://scripts/audio/soundtrack.gd")
const Map := preload("res://scripts/audio/theme_map.gd")
const BootClock := preload("res://scripts/audio/boot_sequence_clock.gd")
var checks := 0
var failures := 0

func check(value: bool, label: String) -> void:
	checks += 1
	print("PASS: " if value else "FAIL: ", label)
	if not value: failures += 1

func near(a: float, b: float) -> bool: return absf(a - b) < 0.00001

func fixture() -> Dictionary:
	return {"phase": &"loop", "boot_seconds": 0.0, "switch_seconds": 0.0,
		"tail_active": false, "tail_seconds": 0.0, "menu_seconds": 0.0,
		"menu_weight": 0.0, "shared_menu": false}

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var state := fixture()
	var clocks := Song._visual_note_clock_projection(state)
	check(clocks.size() == 1 and clocks[0].timeline == &"boot" and near(clocks[0].seconds,0.0), "Startup begins on the boot timeline")
	state.boot_seconds = Map.LENGTH * 3.0 + 0.25
	clocks = Song._visual_note_clock_projection(state)
	check(clocks.size() == 1 and near(clocks[0].seconds,Map.LENGTH * 3.0 + 0.25), "Boot timeline remains unwrapped across alternating A/B loops")
	state.phase = &"switch"; state.switch_seconds = -0.05; state.tail_active = true; state.tail_seconds = 42.0
	clocks = Song._visual_note_clock_projection(state)
	check(clocks.size() == 1 and clocks[0].timeline == &"boot" and near(clocks[0].gain,1.0), "Before incoming audio is heard, only the outgoing loop has gain")
	state.switch_seconds = Song.BOOT_CROSSFADE * 0.5
	clocks = Song._visual_note_clock_projection(state)
	check(clocks.size() == 2 and clocks[0].timeline == &"boot" and clocks[1].timeline == &"switch_menu", "Both timelines are available during the splice")
	check(clocks.size() == 2 and near(clocks[0].gain,sqrt(0.5)) and near(clocks[1].gain,sqrt(0.5)), "Visual crossfade follows equal-power audio gains")
	var wrap_tail := Song._boot_tail_audible_seconds(Map.LENGTH + 0.05, Map.LENGTH * 3.0 - 0.05, 0, 0.01, 0.02)
	check(near(wrap_tail, Map.LENGTH * 3.0 + 0.04), "Outgoing A/B clock remains unwrapped if the audio loops during the splice")
	var normal_tail := Song._boot_tail_audible_seconds(Map.LENGTH + 0.2, Map.LENGTH + 0.1, 2, 0.01, 0.02)
	check(near(normal_tail, Map.LENGTH * 5.0 + 0.19), "Outgoing clock preserves the existing loop count without a wrap")
	state.switch_seconds = Song.BOOT_CROSSFADE + 0.01
	clocks = Song._visual_note_clock_projection(state)
	check(clocks.size() == 1 and clocks[0].timeline == &"switch_menu" and near(clocks[0].gain,1.0), "Outgoing timeline retires after the splice")
	var switch_end := float(BootClock.SWITCH_FRAMES) / BootClock.SAMPLE_RATE
	state.switch_seconds = switch_end
	clocks = Song._visual_note_clock_projection(state)
	var before_end: float = clocks[0].seconds
	state.phase = &"menu"; state.menu_seconds = 0.0
	clocks = Song._visual_note_clock_projection(state)
	check(clocks.size() == 1 and clocks[0].timeline == &"switch_menu" and near(clocks[0].seconds,before_end), "Switch-to-menu boundary preserves the same cursor")
	state.menu_seconds = Map.LENGTH * 2.0 + 0.2
	clocks = Song._visual_note_clock_projection(state)
	check(near(clocks[0].seconds,switch_end + Map.LENGTH * 2.0 + 0.2), "Menu cursor stays unwrapped across repeated loops")
	state.phase = &""; state.shared_menu = true; state.menu_weight = 0.4
	clocks = Song._visual_note_clock_projection(state)
	var menu_seen := false
	for entry: Dictionary in clocks:
		if entry.timeline == &"menu" and near(entry.gain,0.4): menu_seen = true
	check(menu_seen, "Shared transport exposes the audible menu blend")
	state.menu_weight = 0.0
	menu_seen = false
	for entry: Dictionary in Song._visual_note_clock_projection(state):
		if entry.timeline == &"menu": menu_seen = true
	check(not menu_seen, "No menu clock after the music has faded away")
	state.menu_weight = 1.0; state.shared_menu = false
	check(Song._visual_note_clock_projection(state).is_empty(), "Unrelated streams do not claim the menu note map")
	var song = root.get_node("Soundtrack")
	song.player.stop()
	check(song.visual_note_clocks().is_empty(), "Stopped transport emits no visual clocks")
	check(song.begin_boot_audio(), "Real isolated boot transport starts")
	await create_timer(0.15).timeout
	clocks = song.visual_note_clocks()
	check(clocks.size() == 1 and clocks[0].timeline == &"boot" and clocks[0].seconds >= 0.0, "Live boot audio exposes the audible boot clock")
	song.set_paused(true)
	check(song.visual_note_clocks().is_empty(), "Paused transport emits no visual clocks")
	song.set_paused(false)
	var original_stream = song.player.stream
	var original_phase: StringName = song.boot_phase
	song.visual_note_clocks()
	check(song.player.stream == original_stream and song.boot_phase == original_phase and song.player.playing, "Reading visual clocks leaves playback and routing untouched")
	song._boot_target = 0.0
	await create_timer(0.08).timeout
	clocks = song.visual_note_clocks()
	var switch_seen := false
	for clock in clocks:
		if clock.timeline == &"switch_menu" and float(clock.seconds) >= 0.0: switch_seen = true
	check(song.boot_phase == &"switch" and switch_seen, "Live boot switch exposes its incoming audible clock")
	song.player.stop()
	song.player.stream = null
	print("VISUAL_NOTE_CLOCKS checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
