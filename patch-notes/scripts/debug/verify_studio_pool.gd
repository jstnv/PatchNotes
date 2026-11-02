extends SceneTree

const Map := preload("res://scripts/audio/theme_map.gd")
const Pool := preload("res://scripts/audio/studio_pool.gd")
const Grid := preload("res://scripts/audio/music_grid.gd")
const Blend := preload("res://scripts/audio/theme_blend.gd")
const INDICES := [1,4,5,6,7,8]
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + message)

func run() -> void:
	check(Map.STUDIO_POOL.size() == Pool.COUNT, "Exactly six Studio variations")
	for path: String in Map.STUDIO_POOL:
		check(Map.compatible(load(path)), "Studio PCM matches shared sample clock: " + path)
	var selector := Pool.new()
	selector.rng.seed = 70261101
	var seen := {}
	seen[selector.selected] = true
	selector.on_loop(0, false)
	for loop in range(1, 601):
		var old: int = selector.selected
		check(selector.on_loop(loop, true), "Select at a new eight-bar loop")
		check(selector.selected != old and selector.selected >= 0 and selector.selected < Pool.COUNT, "No immediate repeat or out-of-pool selection")
		check(not selector.on_loop(loop, true) and selector.selected != old, "No second choice within the same loop")
		seen[selector.selected] = true
	check(seen.size() == Pool.COUNT, "Fixed-seed selections cover all six tracks")
	var held: int = selector.selected
	check(not selector.on_loop(700, false) and selector.selected == held, "Outside Studio holds the selected track")
	check(not selector.on_loop(700, true) and selector.selected == held, "Re-entry does not switch mid-phrase")
	var music := root.get_node("Soundtrack")
	check(music.themes.stream_count == 9, "One synchronized transport includes all six Studio tracks")
	for i in Map.STUDIO_POOL.size():
		check(music.themes.get_sync_stream(INDICES[i]).loop_end == Map.FRAMES, "Pool stream has exact loop endpoint")
	music.player.seek(Map.LENGTH - 0.22)
	var playback: AudioStreamPlayback = music.player.get_stream_playback()
	music.grid = Grid.new()
	music.last_sample_usec = 0
	music.blend = Blend.new()
	music.blend.requested = 1.0
	music.blend.weight = 1.0
	music.blend.fade_from = 1.0
	music.blend.fade_to = 1.0
	music.menu_blend = Blend.new()
	music.requested_theme = &"studio"
	music.studio_pool_active = true
	music.presentation_seconds()
	music.studio_pool.boundary_loop = music.grid.loops
	music._apply_blend(1.0, 0.0, 0.0)
	var first: int = music.studio_pool.selected
	await create_timer(0.06).timeout
	check(music.studio_pool.selected == first and music.grid.loops == 0, "Before wrap, Studio track is unchanged")
	var deadline := Time.get_ticks_msec() + 1000
	while music.grid.loops == 0 and Time.get_ticks_msec() < deadline:
		await create_timer(0.02).timeout
		music.presentation_seconds()
	await process_frame
	check(music.grid.loops >= 1, "Real playback reaches the shared eight-bar wrap")
	check(music.studio_pool.selected != first, "Real wrap chooses a different Studio track")
	check(music.player.get_stream_playback() == playback, "Hard switch never seeks or restarts transport")
	var audible := 0
	for i in Map.STUDIO_POOL.size():
		var gain: float = db_to_linear(music.themes.get_sync_stream_volume(INDICES[i]))
		if gain > 0.0: audible += 1
		check(is_equal_approx(gain, 1.0 if i == music.studio_pool.selected else 0.0), "Exactly the selected Studio track has gain")
	check(audible == 1, "No original/bass harmony overlap at the switch")
	print("STUDIO_POOL checks=%d failures=%d first=%d next=%d" % [checks, failures, first, music.studio_pool.selected])
	quit(failures)
