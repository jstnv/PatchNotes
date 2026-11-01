class_name AnnualAwardsCeremony
extends Control

## Presentation only. The owner durably stores progress before set_stage().
signal advance_requested
signal exit_requested
signal skip_requested
signal skip_preference_changed(value: bool)

var stage := 0
var animate_counters := true
var panel: PanelContainer
var scroll: ScrollContainer
var next_button: Button
var skip_button: Button
var skip_checkbox: CheckBox
var podium: HBoxContainer
var score_labels: Array = []
var tie_note: Label
var _result: Dictionary = {}
var _first := true
var _skip_preference := false
var _busy := false
var _body: VBoxContainer
var _heading: Label
var _progress: Label
var _counter_tween: Tween
var _targets: Array = []

func configure(result: Dictionary, initial_stage: int, first_ceremony: bool, skip_preference: bool) -> void:
	_result = result.duplicate(true)
	_first = first_ceremony
	_skip_preference = skip_preference
	stage = clampi(initial_stage, 0, 9)
	_busy = false
	if is_node_ready(): _render()

func _ready() -> void:
	name = "AnnualAwardsCeremony"
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = FolderUI.THEME
	var host := FolderUI.SurfaceHost.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(host)
	panel = FolderUI.surface(host)
	panel.name = "AwardsPanel"
	panel.set_meta("bounded_folder", true)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	panel.add_child(layout)
	_progress = FolderUI.label(layout, "", &"SecondaryLabel")
	_heading = FolderUI.label(layout, "", &"HeadingLabel")
	scroll = ScrollContainer.new()
	scroll.name = "CeremonyPages"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	layout.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 14)
	scroll.add_child(_body)
	var footer := HBoxContainer.new()
	footer.name = "FixedActions"
	footer.add_theme_constant_override("separation", 18)
	layout.add_child(footer)
	next_button = FolderUI.button(footer, "Next", _advance)
	next_button.name = "Next"
	next_button.custom_minimum_size.x = 140
	skip_button = FolderUI.button(footer, "Skip to results", _skip)
	skip_button.name = "SkipToResults"
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	skip_checkbox = CheckBox.new()
	skip_checkbox.text = "Skip future ceremonies"
	skip_checkbox.tooltip_text = "The first ceremony always plays. Rewards are always accounted for."
	footer.add_child(skip_checkbox)
	skip_checkbox.toggled.connect(func(value: bool):
		if _busy: skip_checkbox.set_pressed_no_signal(_skip_preference); return
		_skip_preference = value
		skip_preference_changed.emit(value))
	_render()

func set_stage(value: int) -> void:
	stage = clampi(value, 0, 9)
	_busy = false
	if is_node_ready(): _render()

func set_busy(value: bool) -> void:
	_busy = value
	if is_node_ready():
		next_button.disabled = value
		skip_button.disabled = value
		skip_checkbox.disabled = value

func _advance() -> void:
	if _busy: return
	set_busy(true)
	finish_counters()
	if stage == 9: exit_requested.emit()
	else: advance_requested.emit()

func _skip() -> void:
	if _busy or _first or stage == 9: return
	set_busy(true)
	finish_counters()
	skip_requested.emit()

func _render() -> void:
	finish_counters()
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	score_labels.clear()
	_targets.clear()
	podium = null
	tie_note = null
	_progress.text = "ANNUAL GAME AWARDS · %d · %d / 10" % [int(_result.get("year", 0)), stage + 1]
	next_button.text = "Exit" if stage == 9 else "Next"
	skip_button.visible = not _first and stage < 9
	skip_checkbox.visible = stage == 9
	skip_checkbox.set_pressed_no_signal(_skip_preference)
	scroll.scroll_vertical = 0
	if stage == 0:
		_heading.text = "A year of making games"
		FolderUI.label(_body, "Welcome to the %d Annual Game Awards." % int(_result.get("year", 0)), &"HeadingLabel")
		FolderUI.label(_body, "Celebrate the games and Studios that shaped this year. Seven awards, with up to three real nominees in each category.")
		FolderUI.label(_body, "This first ceremony plays in full." if _first else "You can skip this presentation and go directly to the saved results.")
		FolderUI.label(_body, "All results and rewards have already been recorded. Viewing never changes a ranking or grants another reward.")
	elif stage == 1:
		_heading.text = "The year's contenders"
		FolderUI.label(_body, "Cutoff: the completed world transaction reaching December Week 2 (cycle %d). Only current-year releases committed by that snapshot qualify. A later release in the same displayed week is excluded." % int(_result.get("cutoff_cycle", 0)))
		FolderUI.label(_body, "Graphics · Sound · Technology · Design\nRising Studio · Studio of the Year · Game of the Year", &"HeadingLabel")
		FolderUI.label(_body, "Every nomination: +10 Fans. Every winner: an additional +40 Fans and +5 banked Awareness for its next successful release. Studios can earn multiple nominations and wins.")
		FolderUI.label(_body, "Category awards use released Core. Game of the Year uses released Review. Rising Studio counts positive Fans recruitment; Studio of the Year uses Fans before award gifts.")
	elif stage == 9:
		_heading.text = "The final results"
		_final_results()
	else:
		var awards: Array = _result.get("awards", [])
		if stage - 2 < awards.size(): _award(awards[stage - 2])
		else:
			_heading.text = "No award result"
			FolderUI.label(_body, "No eligible nominees were recorded.")
	set_busy(_busy)
	next_button.grab_focus()

func _award(award: Dictionary) -> void:
	_heading.text = str(award.get("name", "Annual award"))
	var kind := str(award.get("metric_kind", "core"))
	var nominees: Array = award.get("nominees", [])
	FolderUI.label(_body, "Released Review" if kind == "review_tenths" else ("Positive Fans earned this year" if kind == "gained_fans" else ("Fans before award gifts" if kind == "fans" else "Released category Core")))
	podium = HBoxContainer.new()
	podium.name = "Podium"
	podium.alignment = BoxContainer.ALIGNMENT_CENTER
	podium.add_theme_constant_override("separation", 14)
	_body.add_child(podium)
	score_labels.resize(nominees.size())
	_targets.resize(nominees.size())
	# Spatial podium: second / first / third. Frozen rank never changes as scores animate.
	for place in [1, 0, 2]:
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.size_flags_vertical = Control.SIZE_SHRINK_END
		podium.add_child(column)
		var card := FolderUI.surface(column, true)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var text := VBoxContainer.new()
		card.add_child(text)
		if place < nominees.size():
			var row: Dictionary = nominees[place]
			var rank := FolderUI.label(text, "#%d%s" % [int(row.rank), " · WINNER" if int(row.rank) == 1 else ""], &"HeadingLabel")
			rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			if not str(row.title).is_empty(): FolderUI.label(text, str(row.title), &"HeadingLabel").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			FolderUI.label(text, str(row.studio_name)).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			var score := FolderUI.label(text, format_score(0, kind), &"MetadataLabel")
			score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			score_labels[place] = score
			_targets[place] = {"score": int(row.score), "kind": kind}
		else:
			var empty := FolderUI.label(text, "No eligible nominee")
			empty.name = "EmptyPlace"
			empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var step := PanelContainer.new()
		step.custom_minimum_size.y = [100, 64, 36][place]
		var style := StyleBoxFlat.new()
		style.bg_color = FolderUI.color(&"cyan") if place == 0 else FolderUI.color(&"secondary")
		style.border_color = FolderUI.color(&"cyan")
		style.set_border_width_all(1)
		step.add_theme_stylebox_override("panel", style)
		column.add_child(step)
		var caption := FolderUI.label(step, str(place + 1), &"HeadingLabel")
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tie_note = FolderUI.label(_body, "Equal scores keep a deterministic order: ascending Studio ID, then ascending release ID. Sales do not break ties.")
	tie_note.name = "TieExplanation"
	var tied := false
	for index in range(1, nominees.size()):
		if int(nominees[index].score) == int(nominees[index - 1].score): tied = true
	tie_note.visible = tied
	if nominees.is_empty(): FolderUI.label(_body, "No eligible nominees this year. No winner or award gift was created.")
	if animate_counters and not nominees.is_empty():
		_counter_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_counter_tween.tween_method(_counter_progress, 0.0, 1.0, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_counter_tween.tween_callback(finish_counters)
	else: finish_counters()

static func format_score(value: int, kind: String) -> String:
	if kind == "review_tenths": return "%d.%d / 10" % [value / 10, value % 10]
	return str(value) + (" Core" if kind == "core" else " Fans")

func _counter_progress(progress: float) -> void:
	for index in score_labels.size():
		if is_instance_valid(score_labels[index]):
			# Final integers come directly from the frozen result, never a float
			# round trip (large valid Fan totals may exceed float exactness).
			var value: int = _targets[index].score if progress >= 1.0 else roundi(float(_targets[index].score) * progress)
			score_labels[index].text = format_score(value, _targets[index].kind)

func finish_counters() -> void:
	if _counter_tween != null:
		_counter_tween.kill()
		_counter_tween = null
	_counter_progress(1.0)

func _final_results() -> void:
	for award: Dictionary in _result.get("awards", []):
		FolderUI.label(_body, str(award.name), &"HeadingLabel")
		var nominees: Array = award.get("nominees", [])
		if nominees.is_empty(): FolderUI.label(_body, "No eligible nominees")
		for row: Dictionary in nominees:
			FolderUI.label(_body, "#%d · %s%s · %s" % [int(row.rank), str(row.studio_name), " — " + str(row.title) if not str(row.title).is_empty() else "", format_score(int(row.score), str(award.metric_kind))])
	FolderUI.label(_body, "Recorded rewards", &"HeadingLabel")
	for reward: Dictionary in _result.get("rewards", []):
		var studio_name := str(reward.studio_id)
		for award: Dictionary in _result.get("awards", []):
			for row: Dictionary in award.get("nominees", []):
				if row.studio_id == reward.studio_id: studio_name = str(row.studio_name)
		FolderUI.label(_body, "%s · %d nominations · %d wins · +%d Fans · +%d banked Awareness" % [studio_name, int(reward.nominations), int(reward.wins), int(reward.fans), int(reward.awareness)])
	FolderUI.label(_body, "The first ceremony in each Studio always plays. The preference below only skips future presentations; rewards always remain.")

func _input(event: InputEvent) -> void:
	if is_visible_in_tree() and MenuTransitions.cancel_pressed(event): get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	finish_counters()
