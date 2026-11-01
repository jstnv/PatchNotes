extends SceneTree

const Replay := preload("res://scripts/simulation/development_replay.gd")

func _initialize() -> void:
	_check.call_deferred()

func _check() -> void:
	var expected := {
		"application/boot_splash/image": "res://assets/branding/joocebox_boot_splash.png",
		"application/boot_splash/bg_color": Color.BLACK,
		"application/boot_splash/show_image": true,
		"application/boot_splash/stretch_mode": 1,
		"application/boot_splash/use_filter": true,
		"application/boot_splash/minimum_display_time": 1200,
		"application/run/main_scene": "uid://bjuqd0td2mtbm",
		"application/config/icon": "res://assets/branding/patch_notes_paper.png",
		"application/config/name": "Patch Notes",
	}
	var failures := 0
	for key: String in expected:
		if ProjectSettings.get_setting(key) != expected[key]:
			push_error("Unexpected setting: " + key)
			failures += 1
	var picture := Image.load_from_file(expected["application/boot_splash/image"])
	if picture == null or picture.get_size() != Vector2i(1920, 1080):
		push_error("Boot PNG failed to decode at 1920x1080")
		failures += 1
	if Replay.source_identity() != "ef14cc34682dbe4ab3e739ea13396da9979c3a8efb9c057c7c8cfa25d78980f6":
		push_error("Gameplay runtime identity changed")
		failures += 1
	print("BOOT_SPLASH_SETTINGS checks=11 failures=", failures)
	quit(0 if failures == 0 else 1)
