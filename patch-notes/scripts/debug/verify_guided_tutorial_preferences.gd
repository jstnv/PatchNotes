extends SceneTree
func _initialize() -> void:
	var prefs := OnboardingPreferences.new()
	prefs.path = "user://unit-onboarding.cfg"
	assert(not prefs.read().answered)
	assert(prefs.answer(true) and prefs.read().answered and prefs.read().experienced and not prefs.read().completed)
	assert(prefs.finish() and prefs.read().completed and prefs.read().experienced)
	FileAccess.open(prefs.path,FileAccess.WRITE).store_string("broken preference")
	var old := FileAccess.get_sha256(prefs.path)
	assert(not prefs.read().answered and not prefs.error.is_empty() and old==FileAccess.get_sha256(prefs.path))
	FileAccess.open(prefs.path,FileAccess.WRITE).store_string("[tutorial]\nversion=1\nanswered=true\n")
	assert(not prefs.read().answered and not prefs.error.is_empty())
	assert(prefs.answer(false) and not prefs.read().experienced and not prefs.read().completed)
	prefs.path = "user://missing-directory/cannot-save.cfg"
	assert(not prefs.answer(false) and not prefs.error.is_empty())
	print("Guided tutorial preferences: default, answer, completion, corrupt preservation, repair and failed-write PASS")
	quit()
