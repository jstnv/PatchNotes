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
	var names := ["Graphics", "Sound", "Technology", "Design", "Rising Studio", "Studio of the Year", "Game of the Year"]
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

func check_pace(ui: AnnualAwardsCeremony, result: Dictionary) -> void:
	var nominees: Array = result.awards[0].nominees
	for i in 3: nominees[i].score = [50, 48, 46][i]
	ui.configure(result, 2, true, false)
	# At 80% of 46 the shared counter has covered 36.8 of 50 points.
	var boundary := 1.4 * (1.0 - pow(1.0 - 36.8 / 50.0, 1.0 / 3.0))
	check(is_equal_approx(ui._counter_position(0.3), 1.0 - pow(1.0 - 0.3 / 1.4, 3.0)) and is_equal_approx(ui._counter_position(boundary), 36.8 / 50.0), "Existing opening pace reaches the third-place threshold at its original time")
	var early := ui._counter_position(boundary + 0.1) - ui._counter_position(boundary)
	var middle := ui._counter_position(boundary + 0.3) - ui._counter_position(boundary + 0.2)
	var late := ui._counter_position(boundary + 0.5) - ui._counter_position(boundary + 0.4)
	check(early > middle and middle > late and late > 0.0, "Shared count slows progressively on the approach to third")
	var a := ui._counter_position(1.4)
	var b := ui._counter_position(1.9)
	var c := ui._counter_position(2.4)
	check(a >= 46.0 / 50.0 and a < 48.0 / 50.0 and c >= 48.0 / 50.0 and c < 1.0 and is_equal_approx(b - a, c - b), "The settled third-place pace stays constant through second place")
	nominees[2].score = 0
	ui.configure(result, 2, true, false)
	check(ui._counter_position(0.5) > 0.0 and is_equal_approx(ui._counter_position(1.0), 2.0 * ui._counter_position(0.5)), "Zero third-place score starts at the steady finish pace")
	nominees.resize(2)
	ui.configure(result, 2, true, false)
	check(is_equal_approx(ui._counter_position(1.0), 1.0 - pow(1.0 - 1.0 / 1.4, 3.0)) and ui._counter_position(1.4) == 1.0, "Without third place the original pacing runs to completion")

func check_bar_scale(ui: AnnualAwardsCeremony) -> void:
	var result := sample()
	var nominees: Array = result.awards[0].nominees
	for scores: Array in [[50,48,46], [50,48,5], [50,50,0], [0,0,0]]:
		for i in 3: nominees[i].score = scores[i]
		ui.configure(result, 2, true, false)
		await settle()
		ui.finish_counters()
		var heights := PackedFloat64Array()
		for i in 3:
			var fill: ColorRect = ui.find_child("ScoreBar%d" % (i + 1), true, false)
			check(fill.get_parent().get_global_rect().encloses(fill.get_global_rect()), "Bar stays inside its track at score %d" % scores[i])
			heights.append(fill.size.y)
		if scores == [50,48,46]:
			var expected := ui.PLOT_HEIGHT * (2.0 / 50.0) * 5.0
			check(absf(heights[0] - heights[1] - expected) <= 1.0 and absf(heights[1] - heights[2] - expected) <= 1.0, "Two-point gaps take five times their former height")
		elif scores == [50,48,5]:
			check(heights[0] > heights[1] and heights[1] > heights[2] and heights[2] > 0, "A wide spread keeps all positive scores distinct and visible")
		elif scores == [50,50,0]:
			check(heights[0] == heights[1] and heights[2] == 0.0, "Equal scores have equal height and a zero score has no fill")
		else:
			check(heights == PackedFloat64Array([0,0,0]), "An all-zero podium stays at the baseline")

func finish() -> void:
	print("ANNUAL_AWARDS_UI checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

func check_pixel_motion(ui: AnnualAwardsCeremony) -> void:
	var result := sample()
	for i in 3:
		result.awards[0].nominees[i].score = [50, 48, 46][i]
	for fps in [30, 120]:
		ui.configure(result, 2, true, false)
		# Run the animation clock in controlled frame intervals after layout.
		ui.set_process(false)
		await settle()
		var previous := [0, 0, 0]
		var last_score := ""
		var moved_within_point := false
		var single_steps := true
		var plot_pixels := ui._plot_pixels()
		for frame in 900:
			ui._process(1.0 / fps)
			var score: String = ui.score_labels[0].text
			for i in 3:
				var height := (1.0 - float(ui._bar_fills[i].anchor_top)) * plot_pixels
				var row := roundi(height)
				var step: int = row - int(previous[i])
				single_steps = single_steps and absf(height - row) < 0.001 and step in [0, 1]
				if i == 0 and ui._rank_labels[2].visible and score == last_score and step == 1:
					moved_within_point = true
				previous[i] = row
			last_score = score
			if not ui._counter_running: break
		check(single_steps and moved_within_point, "Late bars climb one pixel between displayed points at %d fps" % fps)
		check(not ui._counter_running and previous[0] == plot_pixels and ui._rank_labels[0].visible, "Winner reaches its score and full bar together at %d fps" % fps)
		check(ui._rank_labels[0].is_processing() and ui._rank_labels[0].scale.y < 1.0, "Winning stamp starts when the final counter naturally stops")

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
		await check_bar_scale(ceremony)
		root.content_scale_size = Vector2i(1152, 648)
		await check_pixel_motion(ceremony)
		root.content_scale_size = size
		ceremony.configure(frozen, 0, true, true)
		for stage in 10:
			ceremony.set_stage(stage)
			await settle()
			ceremony.finish_counters()
			for item: Control in [ceremony.panel, ceremony.next_button, ceremony.scroll]:
				check(root.get_visible_rect().encloses(item.get_global_rect()), "Stage%d %s fits %s" % [stage,item.name,size])
			check(not ceremony.scroll.is_ancestor_of(ceremony.next_button), "Next remains outside scroll stage%d" % stage)
			if stage >= 2 and stage <= 8:
				if stage <= 5:
					check(ceremony._heading.text == "Best " + str(frozen.awards[stage-2].name) and ceremony._body.get_child(0) == ceremony.podium, "Core page shows Best category heading directly above the podium")
				check(ceremony.podium.get_child_count() == 3, "Three physical podium places stage%d" % stage)
				check(ceremony.tie_note.visible and ceremony.tie_note.text.contains("Studio ID"), "Equal-score tie explanation visible")
				var labels: Array = ceremony.score_labels
				var nominees: Array = frozen.awards[stage-2].nominees
				for index in labels.size():
					if labels[index] != null: check(labels[index].text == ceremony.format_score(nominees[index].score, frozen.awards[stage-2].metric_kind,str(frozen.awards[stage-2].id)), "Exact frozen score endpoint")
			if stage == 3: check(ceremony.podium.find_child("EmptyPlace",true,false) != null, "Sparse podium keeps empty third place")
			if stage == 9:
				check(ceremony.next_button.text == "Exit" and ceremony.skip_checkbox.visible, "Final Exit and future preference available")
				var all_copy := ""
				for child in ceremony._body.get_children():
					if child is Label: all_copy += child.text + "\n"
				for award in frozen.awards:
					var title := "Best " + str(award.name) if award.metric_kind == "core" else str(award.name)
					check(all_copy.split("\n").has(title), "Final results retain award " + title)
					for row in award.nominees:
						check(all_copy.contains("#%d · %s — %s · %s" % [int(row.rank), row.studio_name, row.title, ceremony.format_score(int(row.score), award.metric_kind,str(award.id))]), "Final results retain exact frozen nominee")
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
	check(ceremony._rank_labels.all(func(stamp): return stamp.visible and not stamp.is_processing() and stamp.scale == Vector2.ONE), "Bypass shows settled placings immediately")
	ceremony.animate_counters = true
	ceremony.set_stage(2)
	var reveal_deadline:=Time.get_ticks_msec()+8000
	while ceremony._counter_running and Time.get_ticks_msec()<reveal_deadline:await process_frame
	check(not ceremony._counter_running and ceremony.score_labels[0].text == "1234567 Graphics", "Natural counter completion reaches exact target")
	var sparse := sample()
	var staggered := sample()
	check_pace(ceremony, staggered.duplicate(true))
	for index in 3:
		staggered.awards[0].nominees[index].score = [50, 30, 0][index]
		staggered.awards[0].nominees[index].studio_name = ["Zulu", "Alpha", "Bravo"][index]
	ceremony.configure(staggered, 2, true, false)
	await settle()
	ceremony._counter_progress(0.0)
	var winner: Label = ceremony.find_child("PodiumRank1", true, false)
	var second: Label = ceremony.find_child("PodiumRank2", true, false)
	var third: Label = ceremony.find_child("PodiumRank3", true, false)
	var first_fill: ColorRect = ceremony.find_child("ScoreBar1", true, false)
	var second_fill: ColorRect = ceremony.find_child("ScoreBar2", true, false)
	check(not winner.visible and not second.visible and third.visible, "Only the zero-score nominee reveals at the starting count")
	check(winner.text == "Winner" and second.text == "Second" and third.text == "Third", "Podium uses the three requested placing words")
	check(first_fill.color == second_fill.color and ceremony.podium.get_child(0).is_ancestor_of(second), "Opening colors and name order conceal the winning lane")
	ceremony._counter_progress(0.59)
	check(not second.visible and ceremony.score_labels[1].text == "29 Graphics", "Runner-up hides place one count before its score")
	ceremony._counter_progress(0.60)
	check(second.visible and not winner.visible and ceremony.score_labels[1].text == "30 Graphics", "Runner-up reveals exactly at its score while winner keeps counting")
	check(second.is_processing() and second.scale.y < 1.0, "Second starts visibly compressed on its score frame")
	second._process(0.12)
	var landed_scale := second.scale
	ceremony._counter_progress(0.70)
	check(landed_scale.x > 1.0 and second.scale == landed_scale, "Second stamps in once while the other counter continues")
	second._process(0.30)
	check(not second.is_processing() and second.scale == Vector2.ONE, "Second settles at full size")
	ceremony.finish_counters()
	check(winner.visible and winner.text == "Winner" and first_fill.color != second_fill.color, "Winner nameplate and accent reveal together")
	check(winner.get_parent().get_global_rect().encloses(winner.get_global_rect()), "Winner label fits inside bar base")
	var winner_card: Control = ceremony.score_labels[0].get_parent().get_parent()
	check(first_fill.size.x < winner_card.size.x * 0.5 and winner_card.global_position.y >= winner.get_global_rect().end.y, "Narrow bar sits above its nominee card")
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
	check(ceremony.score_labels.size() == 1 and ceremony.score_labels[0].text == "9007199254740993 Graphics", "Single nominee and large integer endpoint stay exact")
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
