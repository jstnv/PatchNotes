class_name AnnualAwardsCeremony
extends Control

## Presentation only. The owner durably stores progress before set_stage().
signal advance_requested
signal exit_requested
signal skip_requested
signal skip_preference_changed(value: bool)

# Own the stamp's clock so the winning word can settle after the bars stop.
class PlacingStamp extends Label:
	const WORDS := ["Winner", "Second", "Third"]
	var place: int
	var elapsed := 0.0

	func _init(rank: int) -> void:
		place = rank
		text = WORDS[rank - 1]
		theme_type_variation = &"FolderHeading"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		hide()
		set_process(false)

	func reveal(animate: bool) -> void:
		if visible and (animate or not is_processing()):
			return
		show()
		elapsed = 0.0
		set_process(animate)
		_pose(0.0 if animate else 1.0)

	func _process(delta: float) -> void:
		elapsed += delta
		var phase := minf(elapsed / (0.46 if place == 1 else 0.30), 1.0)
		_pose(phase)
		if phase >= 1.0:
			set_process(false)

	func _pose(phase: float) -> void:
		pivot_offset = Vector2(size.x * 0.5, size.y * 0.8)
		var peak := Vector2(1.16, 1.13) if place == 1 else Vector2(1.08, 1.06)
		if phase < 0.4:
			scale = Vector2(0.76, 0.56).lerp(peak, 1.0 - pow(1.0 - phase / 0.4, 2))
		else:
			scale = peak.lerp(Vector2.ONE, smoothstep(0.4, 1.0, phase))
		modulate.a = lerpf(0.65, 1.0, smoothstep(0.0, 0.4, phase))
		queue_redraw()

	func _draw() -> void:
		if place != 1 or not is_processing():
			return
		var travel := clampf(elapsed / 0.46, 0.0, 1.0)
		var ink := get_theme_color(&"font_color")
		ink.a *= sin(PI * travel)
		var center := size * 0.5
		for side in [-1, 1]:
			var tip := center + Vector2(side * size.x * lerpf(0.31, 0.46, travel), 0)
			draw_line(tip, tip + Vector2(7 * side, 0), ink, 2.0)

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
var _targets: Array = []
var _bar_fills: Array = []
var _rank_labels: Array = []
var _rank_bases: Array = []
var _has_tie := false
var _neutral_bar_color := FolderUI.color(&"secondary").lerp(FolderUI.color(&"cyan"), 0.45)
const BAR_WIDTH := 128
const PLOT_HEIGHT := 156
const SCORE_GAP_ZOOM := 5.0
const RANK_HEIGHT := 32
var _maximum_score := 1
var _counter_elapsed := 0.0
var _counter_running := false
var _first_visible_frame := false
const COUNTER_SECONDS := 1.4
const THIRD_SLOWDOWN_AT := 0.8
const FINISH_SPEED_RATIO := 0.10
const MIN_FINISH_SECONDS := 1.5
const MAX_FINISH_SECONDS := 5.0

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
	_bar_fills.clear()
	_rank_labels.clear()
	_rank_bases.clear()
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
		FolderUI.label(_body, "Best Graphics · Best Sound · Best Technology · Best Design\nRising Studio · Studio of the Year · Game of the Year", &"HeadingLabel")
		FolderUI.label(_body, "Every nomination: +10 Fans. Every winner: an additional +40 Fans and +5 banked Awareness for its next successful release. Studios can earn multiple nominations and wins.")
		FolderUI.label(_body, "Category awards use released Graphics, Sound, Technology and Design scores. Game of the Year uses released Review. Rising Studio counts positive Fans recruitment; Studio of the Year uses Fans before award gifts.")
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
	_heading.text = award_title(award)
	var kind := str(award.get("metric_kind", "core"))
	var category := str(award.get("id", ""))
	var nominees: Array = award.get("nominees", [])
	if kind != "core":
		FolderUI.label(_body, "Released Review" if kind == "review_tenths" else ("Positive Fans earned this year" if kind == "gained_fans" else "Fans before award gifts"))
	podium = HBoxContainer.new()
	podium.name = "Podium"
	podium.alignment = BoxContainer.ALIGNMENT_CENTER
	podium.add_theme_constant_override("separation", 14)
	_body.add_child(podium)
	score_labels.resize(nominees.size())
	_targets.resize(nominees.size())
	_bar_fills.resize(nominees.size())
	_rank_bases.resize(nominees.size())
	_rank_labels.resize(nominees.size())
	_maximum_score = 1
	for row: Dictionary in nominees:
		_maximum_score = maxi(_maximum_score, int(row.score))
	# Name order keeps a nominee in the same lane throughout the reveal.
	var lanes := range(nominees.size())
	lanes.sort_custom(func(a: int, b: int) -> bool:
		var left: Dictionary = nominees[a]
		var right: Dictionary = nominees[b]
		if left.studio_name != right.studio_name:
			return str(left.studio_name) < str(right.studio_name)
		return str(left.title) < str(right.title))
	for lane in 3:
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		podium.add_child(column)
		var place: int = lanes[lane] if lane < lanes.size() else -1
		if place >= 0:
			_add_bar(column, place, nominees[place])
		else:
			# Match the other lanes' plot and label area above the empty card.
			var spacer := Control.new()
			spacer.custom_minimum_size.y = PLOT_HEIGHT + RANK_HEIGHT
			column.add_child(spacer)
		var card := FolderUI.surface(column, true)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var text := VBoxContainer.new()
		card.add_child(text)
		if place < 0:
			var empty := FolderUI.label(text, "No eligible nominee")
			empty.name = "EmptyPlace"
			empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			continue
		var row: Dictionary = nominees[place]
		if not str(row.title).is_empty():
			FolderUI.label(text, str(row.title), &"FolderHeading").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		FolderUI.label(text, str(row.studio_name)).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var score := FolderUI.label(text, format_score(0, kind, category), &"FolderHeading")
		score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_labels[place] = score
		_targets[place] = {"score": int(row.score), "kind": kind, "category": category}
	tie_note = FolderUI.label(_body, "Equal scores keep a deterministic order: ascending Studio ID, then ascending release ID. Sales do not break ties.")
	tie_note.name = "TieExplanation"
	_has_tie = false
	for index in range(1, nominees.size()):
		if int(nominees[index].score) == int(nominees[index - 1].score):
			_has_tie = true
	tie_note.hide()
	if nominees.is_empty(): FolderUI.label(_body, "No eligible nominees this year. No winner or award gift was created.")
	if animate_counters and not nominees.is_empty():
		_counter_elapsed=0.0
		_counter_running=true
		_first_visible_frame=false
		_counter_progress(0.0)
		set_process(true)
	else: finish_counters()

func _add_bar(column: VBoxContainer, place: int, row: Dictionary) -> void:
	var bar := VBoxContainer.new()
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar.custom_minimum_size.x = BAR_WIDTH
	bar.add_theme_constant_override("separation", 0)
	column.add_child(bar)
	var track := Control.new()
	track.name = "ScoreTrack%d" % [place + 1]
	track.custom_minimum_size.y = PLOT_HEIGHT
	bar.add_child(track)
	var fill := ColorRect.new()
	fill.name = "ScoreBar%d" % [place + 1]
	fill.color = _neutral_bar_color
	track.add_child(fill)
	fill.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_bar_fills[place] = fill

	# Give even a zero-score bar room for its rank below the plot baseline.
	var base := ColorRect.new()
	base.custom_minimum_size.y = RANK_HEIGHT
	base.color = _neutral_bar_color
	base.clip_contents = true
	bar.add_child(base)
	var caption := PlacingStamp.new(int(row.rank))
	caption.name = "PodiumRank%d" % [place + 1]
	base.add_child(caption)
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 18)
	caption.add_theme_color_override("font_color", FolderUI.color(&"background"))
	_rank_bases[place] = base
	_rank_labels[place] = caption

static func core_category(id: String) -> String:
	return {"graphics":"Graphics","sound":"Sound","technology":"Technology","design":"Design"}.get(id,"Core")

static func award_title(award: Dictionary) -> String:
	if award.get("metric_kind", "") == "core":
		return "Best " + core_category(str(award.id))
	return str(award.get("name", "Annual award"))

static func format_score(value: int, kind: String, category: String = "") -> String:
	if kind == "review_tenths": return "%d.%d / 10" % [value / 10, value % 10]
	return str(value) + (" "+core_category(category) if kind == "core" else " Fans")

func _process(delta: float) -> void:
	if not _counter_running or not panel.is_visible_in_tree(): return
	# Shared navigation starts below the window. Preserve the0 frame until the
	# actual page is in view; hidden/save/layout time cannot consume its reveal.
	if not get_viewport_rect().encloses(panel.get_global_rect().grow(-2)): return
	if not _first_visible_frame:
		_first_visible_frame=true
		_counter_progress(0.0)
		return
	var plot_pixels := _plot_pixels()
	var next_elapsed := _counter_elapsed + minf(delta, 0.05)
	var pixel_now := _shared_pixel_at(_counter_elapsed, plot_pixels)
	if _shared_pixel_at(next_elapsed, plot_pixels) > pixel_now + 1:
		# A fast count or a slow frame can cross several raster rows. Advance
		# the shared clock only to the next row so the score and fill stay together.
		var lower := _counter_elapsed
		var upper := next_elapsed
		for attempt in 24:
			next_elapsed = (lower + upper) * 0.5
			var pixel := _shared_pixel_at(next_elapsed, plot_pixels)
			if pixel == pixel_now + 1:
				break
			if pixel <= pixel_now:
				lower = next_elapsed
			else:
				upper = next_elapsed
	_counter_elapsed = next_elapsed
	var progress := _counter_position(_counter_elapsed)
	_counter_progress(progress)
	if progress >= 1.0:
		_counter_running = false
		set_process(false)

func _counter_position(seconds: float) -> float:
	var opening := 1.0 - pow(1.0 - minf(1.0, seconds / COUNTER_SECONDS), 3.0)
	if _targets.size() < 3:
		return opening
	var third := float(_targets[2].score) / float(_maximum_score)
	var threshold := THIRD_SLOWDOWN_AT * third
	# Meet the original curve at exactly the same score, time and speed.
	var remaining := pow(1.0 - threshold, 1.0 / 3.0)
	var since_threshold := seconds - COUNTER_SECONDS * (1.0 - remaining)
	if since_threshold <= 0.0:
		return opening
	var entry_speed := 3.0 * remaining * remaining / COUNTER_SECONDS
	var gap := 1.0 - third
	var finish_speed := clampf(entry_speed * FINISH_SPEED_RATIO, gap / MAX_FINISH_SECONDS, gap / MIN_FINISH_SECONDS)
	# Ease the speed down cubically. Its average over this interval is
	# (entry_speed + 3 * finish_speed) / 4, so the interval ends at third.
	var slowdown_seconds := 4.0 * (third - threshold) / (entry_speed + 3.0 * finish_speed)
	if since_threshold < slowdown_seconds:
		var u := since_threshold / slowdown_seconds
		var eased_distance := (entry_speed - finish_speed) * slowdown_seconds * (1.0 - pow(1.0 - u, 4.0)) / 4.0
		return threshold + finish_speed * since_threshold + eased_distance
	return minf(1.0, third + finish_speed * (since_threshold - slowdown_seconds))

func _counter_progress(progress: float) -> void:
	# All lanes count along one scale. A lower score stops and reveals first.
	var continuous_count := float(_maximum_score) * progress
	var count := _maximum_score if progress >= 1.0 else floori(continuous_count)
	var plot_pixels := _plot_pixels()
	for index in score_labels.size():
		var target: int = _targets[index].score
		var value := mini(count, target)
		var reached := value == target
		score_labels[index].text = format_score(value, _targets[index].kind, _targets[index].category)
		var fill: ColorRect = _bar_fills[index]
		var height := _bar_pixels(minf(continuous_count, float(target)), plot_pixels)
		fill.anchor_top = 1.0 - float(height) / plot_pixels
		if reached and (_first_visible_frame or not _counter_running):
			_rank_labels[index].reveal(_counter_running)
		fill.color = FolderUI.color(&"cyan") if reached and index == 0 else _neutral_bar_color
		_rank_bases[index].color = fill.color
	if is_instance_valid(tie_note):
		tie_note.visible = _has_tie and count == _maximum_score

func _plot_pixels() -> int:
	var raster_transform := get_viewport().get_final_transform() * get_global_transform_with_canvas()
	return maxi(1, roundi(PLOT_HEIGHT * raster_transform.y.length()))

func _shared_pixel_at(seconds: float, plot_pixels: int) -> int:
	return _bar_pixels(_counter_position(seconds) * _maximum_score, plot_pixels)

func _bar_pixels(value: float, plot_pixels: int) -> int:
	return maxi(1, roundi(_bar_height_fraction(value) * plot_pixels)) if value > 0.0 else 0

func _bar_height_fraction(value: float) -> float:
	# Every lane follows the same scale during the count. Give more of the
	# track to the range between the lowest nominee and the winner.
	var lowest: int = _targets.back().score
	if lowest == 0 or lowest == _maximum_score:
		return float(value) / _maximum_score
	var spread := _maximum_score - lowest
	var lowest_height := maxf(float(lowest) / _maximum_score / SCORE_GAP_ZOOM,
			1.0 - SCORE_GAP_ZOOM * float(spread) / _maximum_score)
	if value <= lowest:
		return lowest_height * float(value) / lowest
	return lerpf(lowest_height, 1.0, float(value - lowest) / spread)

func finish_counters() -> void:
	_counter_running=false
	set_process(false)
	_counter_progress(1.0)

func _final_results() -> void:
	for award: Dictionary in _result.get("awards", []):
		FolderUI.label(_body, award_title(award), &"HeadingLabel")
		var nominees: Array = award.get("nominees", [])
		if nominees.is_empty(): FolderUI.label(_body, "No eligible nominees")
		for row: Dictionary in nominees:
			FolderUI.label(_body, "#%d · %s%s · %s" % [int(row.rank), str(row.studio_name), " — " + str(row.title) if not str(row.title).is_empty() else "", format_score(int(row.score), str(award.metric_kind),str(award.id))])
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
	set_process(false)
