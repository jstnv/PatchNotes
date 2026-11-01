extends SceneTree

var checks := 0
var failures := 0
var advances := 0
var exits := 0
var skips := 0
var preference_changes := 0
const UI_PATH := "res://scripts/ui/annual_awards_ceremony.gd"
const OUT := "res://../docs/codex/findings/annual-awards-20261031-v1/ui-native"

func _initialize() -> void:
	go.call_deferred()

func check(value: bool, description: String) -> void:
	checks += 1
	if not value: failures += 1
	print("PASS: " if value else "FAIL: ", description)

func settle() -> void:
	for index in 8: await process_frame

func sample() -> Dictionary:
	var awards: Array = []
	var ids := ["graphics", "sound", "technology", "design", "rising", "studio", "goty"]
	var names := ["Best Graphics", "Best Sound", "Best Technology", "Best Design", "Rising Studio", "Studio of the Year", "Game of the Year"]
	for index in 7:
		var nominees: Array = []
		for place in (2 if index == 1 else 3):
			nominees.append({"studio_id": StringName("owner-%d" % place), "studio_name": "A Remarkably Long Studio Name With Many Words %d" % place,
				"release_id": StringName("game-%d" % place), "title": "The Extraordinary Adventures of a Very Long Named Game %d" % place,
				"score": 87 if index == 6 else 1234567, "rank": place + 1})
		awards.append({"id": StringName(ids[index]), "name": names[index], "metric_kind": "review_tenths" if index == 6 else ("gained_fans" if index == 4 else ("fans" if index == 5 else "core")), "nominees": nominees})
	return {"rules_version": 1, "year": 1980, "cutoff_cycle": 45, "studios": [], "games": [], "awards": awards,
		"rewards": [{"studio_id": &"owner-0", "nominations": 7, "wins": 7, "fans": 350, "awareness": 35}]}

func shot(label: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join(label + ".png"))

func finish() -> void:
	print("ANNUAL_AWARDS_UI checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

func go() -> void:
	check(DemoSettingsStore.defaults().get("skip_awards") == false, "Future ceremony skip defaults to false")
	check(ResourceLoader.exists(UI_PATH), "Standalone ceremony exists")
	if failures: finish(); return
	var old := DemoSettingsStore.defaults()
	old.erase("skip_awards")
	var config := ConfigFile.new()
	for key in old: config.set_value("settings", key, old[key])
	config.save("user://old-settings.cfg")
	var old_bytes := FileAccess.get_file_as_bytes("user://old-settings.cfg")
	var migrated := DemoSettingsStore.read_settings("user://old-settings.cfg")
	check(migrated.error.is_empty() and migrated.values.skip_awards == false, "Missing-only skip key migrates old settings")
	check(FileAccess.get_file_as_bytes("user://old-settings.cfg") == old_bytes, "Reading migration preserves original bytes")
	config.set_value("settings", "skip_awards", "wrong")
	config.save("user://bad-settings.cfg")
	check(not DemoSettingsStore.read_settings("user://bad-settings.cfg").error.is_empty(), "Malformed skip value strictly rejects")
	config.erase_section_key("settings", "Music")
	config.save("user://bad-settings.cfg")
	check(not DemoSettingsStore.read_settings("user://bad-settings.cfg").error.is_empty(), "Missing legacy key still rejects")
	var settings := DemoSettingsMenu.new()
	settings.settings_path = "user://ui-prefs.cfg"
	root.add_child(settings)
	await settle()
	settings.open()
	check(settings.skip_awards != null and settings._focusable().has(settings.skip_awards), "Skip preference has Settings focus entry")
	settings.skip_awards.button_pressed = true
	check(settings.draft.skip_awards and not settings.committed.skip_awards, "Preference stays draft until Apply")
	settings.apply_draft()
	check(settings.committed.skip_awards and DemoSettingsStore.read_settings(settings.settings_path).values.skip_awards, "Apply persists skip")
	settings.reset_button.pressed.emit()
	check(not settings.draft.skip_awards and settings.committed.skip_awards, "Reset only resets draft skip")
	check(settings.set_skip_awards(false) and not settings.draft.skip_awards and not settings.committed.skip_awards, "Ceremony setter persists and synchronizes preference")
	settings.draft.width = 1152; settings.draft.height = 648
	settings.apply_draft()
	check(settings.previewing and settings.skip_awards.disabled, "Display preview locks preference")
	check(settings.set_skip_awards(true) and settings.previewing and settings.draft.skip_awards, "External setter preserves active display preview")
	settings.revert_display()
	check(settings.committed.skip_awards and settings.draft.skip_awards, "Preview revert retains separately committed skip")
	var good_path := settings.settings_path
	settings.settings_path = "user://missing-awards-folder/prefs.cfg"
	check(not settings.set_skip_awards(false) and settings.committed.skip_awards, "Failed setter preserves committed preference")
	settings.settings_path = good_path
	for size: Vector2i in [Vector2i(1152,648), Vector2i(1280,720)]:
		root.size = size; root.content_scale_size = size
		await settle()
		for item: Control in [settings.panel, settings.skip_awards, settings.apply_button, settings.reset_button]:
			check(root.get_visible_rect().encloses(item.get_global_rect()), "Settings fits %s at %s" % [item.name, size])
		await shot("settings-%d" % size.x)
		settings.confirmation.show()
		await settle()
		for item: Control in [settings.panel, settings.skip_awards, settings.apply_button, settings.reset_button, settings.confirmation]:
			check(root.get_visible_rect().encloses(item.get_global_rect()), "Settings confirmation fits %s at %s" % [item.name, size])
		await shot("settings-confirmation-%d" % size.x)
		settings.confirmation.hide()
	settings.close()
	settings.queue_free()
	var frozen := sample()
	var before := frozen.duplicate(true)
	var ceremony = load(UI_PATH).new()
	ceremony.configure(frozen, 0, true, true)
	root.add_child(ceremony)
	ceremony.advance_requested.connect(func(): advances += 1)
	ceremony.exit_requested.connect(func(): exits += 1)
	ceremony.skip_requested.connect(func(): skips += 1)
	ceremony.skip_preference_changed.connect(func(_value: bool): preference_changes += 1)
	await settle()
	check(ceremony.stage == 0 and not ceremony.skip_button.visible, "First ceremony overrides skip preference")
	var accept := InputEventKey.new()
	accept.keycode = KEY_ENTER; accept.pressed = true
	Input.parse_input_event(accept)
	await process_frame
	accept = accept.duplicate(); accept.pressed = false
	Input.parse_input_event(accept)
	await process_frame
	check(advances == 1, "Keyboard Enter activates focused Next")
	ceremony.next_button.pressed.emit()
	check(advances == 1 and ceremony.stage == 0 and ceremony.next_button.disabled, "Duplicate advance is locked until owner saves stage")
	ceremony.set_busy(false)
	ceremony.set_stage(1)
	check(ceremony.stage == 1, "Owner alone advances stage")
	for size: Vector2i in [Vector2i(1152,648), Vector2i(1280,720)]:
		root.size = size; root.content_scale_size = size
		for stage in 10:
			ceremony.set_stage(stage)
			await settle()
			ceremony.finish_counters()
			for item: Control in [ceremony.panel, ceremony.next_button, ceremony.scroll]:
				check(root.get_visible_rect().encloses(item.get_global_rect()), "Stage%d %s fits %s" % [stage,item.name,size])
			check(not ceremony.scroll.is_ancestor_of(ceremony.next_button), "Next remains outside scroll stage%d" % stage)
			if stage >= 2 and stage <= 8:
				check(ceremony.podium.get_child_count() == 3, "Three physical podium places stage%d" % stage)
				check(ceremony.tie_note.visible and ceremony.tie_note.text.contains("Studio ID"), "Equal-score tie explanation visible")
				var labels: Array = ceremony.score_labels
				var nominees: Array = frozen.awards[stage-2].nominees
				for index in labels.size():
					if labels[index] != null: check(labels[index].text == ceremony.format_score(nominees[index].score, frozen.awards[stage-2].metric_kind), "Exact frozen score endpoint")
			if stage == 3: check(ceremony.podium.find_child("EmptyPlace",true,false) != null, "Sparse podium keeps empty third place")
			if stage == 9:
				check(ceremony.next_button.text == "Exit" and ceremony.skip_checkbox.visible, "Final Exit and future preference available")
				var all_copy := ""
				for child in ceremony._body.get_children():
					if child is Label: all_copy += child.text + "\n"
				for award in frozen.awards:
					check(all_copy.contains(award.name), "Final results retain award " + str(award.name))
					for row in award.nominees:
						check(all_copy.contains("#%d · %s — %s · %s" % [int(row.rank), row.studio_name, row.title, ceremony.format_score(int(row.score), award.metric_kind)]), "Final results retain exact frozen nominee")
				check(all_copy.contains("7 nominations · 7 wins · +350 Fans · +35 banked Awareness"), "Final results show exact recorded rewards")
			await shot("stage-%d-%d" % [stage,size.x])
			if stage == 9:
				ceremony.scroll.scroll_vertical = 100000
				await settle()
				await shot("final-rewards-%d" % size.x)
	ceremony.skip_checkbox.button_pressed = not ceremony.skip_checkbox.button_pressed
	check(preference_changes == 1, "Final future preference emits once")
	ceremony.set_busy(true); ceremony.next_button.pressed.emit()
	check(exits == 0, "Busy blocks Exit")
	ceremony.set_busy(false); ceremony.next_button.pressed.emit(); ceremony.next_button.pressed.emit()
	check(exits == 1, "Exit emits once")
	ceremony.configure(frozen, 2, false, false)
	await settle()
	check(ceremony.skip_button.visible, "Later ceremony offers Skip to results")
	ceremony.skip_button.pressed.emit(); ceremony.skip_button.pressed.emit()
	check(skips == 1 and ceremony.stage == 2, "Skip requests once and waits for owner stage save")
	ceremony.set_stage(8)
	ceremony.animate_counters = false
	ceremony.set_stage(8)
	check(ceremony.score_labels[0].text == "8.7 / 10", "Animation bypass uses exact Review tenths")
	ceremony.animate_counters = true
	ceremony.set_stage(2)
	await create_timer(0.95).timeout
	check(ceremony.score_labels[0].text == "1234567 Core", "Natural counter completion reaches exact target")
	var sparse := sample()
	sparse.awards[0].nominees = []
	ceremony.configure(sparse, 2, true, false)
	await settle()
	check(ceremony.score_labels.is_empty() and ceremony.podium.get_child_count() == 3, "Zero nominees show three placeholders without invented winner")
	await shot("zero-nominees")
	sparse.awards[0].nominees = [sample().awards[0].nominees[0]]
	sparse.awards[0].nominees[0].score = 9007199254740993
	ceremony.configure(sparse, 2, true, false)
	await settle()
	ceremony.finish_counters()
	check(ceremony.score_labels.size() == 1 and ceremony.score_labels[0].text == "9007199254740993 Core", "Single nominee and large integer endpoint stay exact")
	check(not ceremony.tie_note.visible, "No tie explanation for a sole nominee")
	await shot("single-nominee")
	var cancel := InputEventKey.new()
	cancel.keycode = KEY_ESCAPE; cancel.pressed = true
	Input.parse_input_event(cancel)
	await process_frame
	check(ceremony.visible and ceremony.stage == 2 and exits == 1, "Escape cannot abandon mandatory ceremony")
	var cancel_pad := InputEventJoypadButton.new()
	cancel_pad.button_index = JOY_BUTTON_B; cancel_pad.pressed = true
	Input.parse_input_event(cancel_pad)
	await process_frame
	check(ceremony.visible and ceremony.stage == 2 and exits == 1, "Controller B cannot abandon mandatory ceremony")
	var nav := MenuTransitions.new()
	nav.automatic_entrances = false
	root.add_child(nav)
	var background := Control.new()
	root.add_child(background)
	nav.set_root(background)
	check(nav.push_from_bottom(ceremony.panel, ceremony.next_button, Callable(), float(root.size.y)), "Shared transition accepts ceremony surface")
	root.size = Vector2i(1152,648); root.content_scale_size = root.size
	await create_timer(0.3).timeout
	await settle()
	check(not nav.busy and not root.gui_disable_input and root.get_visible_rect().encloses(ceremony.panel.get_global_rect()), "Shared animated entrance settles after resize and unlocks input")
	nav.pop()
	await create_timer(0.3).timeout
	check(not nav.busy and not ceremony.panel.visible and not root.gui_disable_input, "Shared exit hides surface and unlocks input")
	nav.animate = false
	check(nav.push(ceremony.panel, ceremony.next_button) and not nav.busy and ceremony.panel.visible, "Shared animation bypass reaches visible interactive state")
	nav.pop()
	nav.animate = true
	nav.push(ceremony.panel, ceremony.next_button)
	nav.queue_free()
	background.queue_free()
	ceremony.set_stage(2)
	ceremony.queue_free()
	await settle()
	check(not root.gui_disable_input, "Teardown during transition releases shared input ownership")
	check(frozen == before, "Presentation and teardown preserve entire frozen result")
	finish()
