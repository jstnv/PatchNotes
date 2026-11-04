class_name GuidedProductionTutorial
extends CanvasLayer

signal choice(experienced: bool, accepted: bool)
signal finished(completed: bool)

const CARD_SCENE := preload("res://scenes/cards/card_view.tscn")
const TITLES := ["Core quality and Scope", "Balanced Production", "Specialization", "Build a synergy with a redraw", "Play the redrawn synergy", "Alpha: expand the game", "Beta: Marketing and Awareness", "QA: find Hidden Bugs", "QA: fix Known Bugs"]
const INSTRUCTIONS := [
	"Graphics, Sound, Technology and Design are Core quality. Scope measures how much game you have built. Features add their printed Scope; Passes add Core but no Scope. Select all four cards, then Implement.",
	"Balanced Production needs a Feature and positive gains in all four categories: highest minus lowest at most 1 point, or each gain within ±15% of the average. Multiply the Core total by 1.25, round down to whole points, then share evenly. These eight points become ten: 3 Graphics, 3 Sound, 2 Tech, 2 Design. Play all four.",
	"Match all four PRIMARY Core labels for Specialization. Secondary labels do not decide the match. This Graphics hand gets ×1.5 Core gains, rounded by category; its printed Scope stays the same. Select all four.",
	"Three extra candidates now make the normal seven-card pool. Keep the three Graphics Passes. Select Sound Pass and press Redraw: this lesson guarantees the fourth Graphics Pass. Normal redraws follow priorities and are not guaranteed.",
	"The redraw used one redraw and no productive cycle. Select the four Graphics Passes, then Implement. Renewable Passes can return in later hands. A successful hand restores one redraw, up to the shared cap.",
	"Alpha continues building Core and Scope, often with Features that add two categories. Select the four supplied Alpha Features. In a real project, compare Scope with its target and Core with the chosen Genre's standards before Beta.",
	"Beta shifts to Marketing and QA. Marketing builds launch Awareness: more people can notice your game, which can help sales. It is not guaranteed sales. Select Sign Flippers, Posters, Press Release and the other Sign Flippers.",
	"This scripted example has eight Hidden Bugs: six from Design and two from Alpha. Search reveals Hidden Bugs as Known Bugs; it does NOT fix them. Select the four Search cards. Four QA cards also earn QA Specialization.",
	"Now the Bugs are Known. Debug fixes Known Bugs; using it before Search would have nothing to fix. Select the four Debug cards. Your practice Marketing stays earned while you work on QA.",
]
var model: GuidedProductionModel
var root_control: Control
var practice_background: ColorRect
var heading: Label
var progress: Label
var instruction: Label
var result_label: Label
var stats: ProductionScoreboard
var prompt: VBoxContainer
var practice: VBoxContainer
var fan: CardFan
var motion: HandPresentation
var synergy: SynergyNotification
var play_button: Button
var redraw_button: Button
var next_button: Button
var exit_button: Button
var new_button: Button
var experienced_button: Button
var start_button: Button
var skip_button: Button
var back_button: Button
var selected: Array[CardView] = []
var experienced := false
var asking := true
var closing := false
var _shown_scores: Dictionary = {}
var invitation: VBoxContainer
var guide_rows: VBoxContainer
var phase_progress: Label
var practice_footer: Label
var stage: Control
var synergy_lane: Control

func _ready() -> void:
	layer = 40
	add_to_group(PauseMenu.CANCEL_OWNER_GROUP)
	root_control = Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.theme = preload("res://resources/ui/onyx_theme.tres")
	add_child(root_control)
	var shade := ColorRect.new()
	practice_background = shade
	shade.color = FolderUI.color(&"background")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,20)
	root_control.add_child(margin)
	var layout := VBoxContainer.new()
	invitation = layout
	layout.add_theme_constant_override("separation",8)
	margin.add_child(layout)
	var top := HBoxContainer.new()
	layout.add_child(top)
	heading = _label(top,"Guided production · Practice",26)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.theme_type_variation = &"HeadingLabel"
	exit_button = _button(top,"Exit tutorial",_exit)
	progress = _label(layout,"",15)
	var guide := PanelContainer.new()
	layout.add_child(guide)
	var invitation_rows := VBoxContainer.new()
	guide.add_child(invitation_rows)
	instruction = _label(invitation_rows,"",18)
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label = _label(invitation_rows,"Your Studio's cash, calendar, rivals and releases stay unchanged.",15)
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.add_theme_color_override("font_color",FolderUI.color(&"mint"))
	prompt = VBoxContainer.new()
	prompt.add_theme_constant_override("separation",12)
	layout.add_child(prompt)
	prompt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	new_button = _button(prompt,"I'm new to Patch Notes",_experience.bind(false))
	experienced_button = _button(prompt,"I've played before",_experience.bind(true))
	start_button = _button(prompt,"Start guided tutorial",func(): choice.emit(experienced,true))
	skip_button = _button(prompt,"Skip tutorial",func(): choice.emit(experienced,false))
	back_button = _button(prompt,"Back",open_invitation)
	_build_practice()
	open_invitation()

func _build_practice() -> void:
	stats = ProductionScoreboard.new()
	stats.name = "PersistentHeader"
	stats.show_hidden_bugs = true
	stats.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	stats.offset_left = 16; stats.offset_right = -16
	stats.offset_top = 12; stats.offset_bottom = 78
	root_control.add_child(stats)
	stats.hide()
	var body := HBoxContainer.new()
	body.name = "PracticeWorkspace"
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_left = 16; body.offset_right = -16
	body.offset_top = 88; body.offset_bottom = -52
	body.add_theme_constant_override("separation",16)
	root_control.add_child(body)
	practice = VBoxContainer.new()
	practice.name = "Regions"
	practice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	practice.size_flags_vertical = Control.SIZE_EXPAND_FILL
	practice.add_theme_constant_override("separation",4)
	body.add_child(practice)
	_label(practice,"Backlog / Draw Pool",16).add_theme_color_override("font_color",FolderUI.color(&"mint"))
	# This holder stays in layout while HandPresentation hides the actual fan.
	var arena := Control.new()
	arena.name = "Playfield"
	arena.custom_minimum_size.y = 300
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	practice.add_child(arena)
	synergy_lane = Control.new()
	synergy_lane.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	synergy_lane.offset_bottom = 66
	arena.add_child(synergy_lane)
	stage = Control.new()
	stage.name = "CardStage"
	stage.clip_contents = true
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.offset_top = 82
	arena.add_child(stage)
	fan = CardFan.new()
	fan.name = "PracticeHand"
	fan.fit_groups_to_width = true
	fan.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(fan)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation",10)
	practice.add_child(actions)
	play_button = _button(actions,"Implement",play_selected)
	redraw_button = _button(actions,"Redraw",redraw_selected)
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size.x = 300
	sidebar.size_flags_horizontal = Control.SIZE_SHRINK_END
	body.add_child(sidebar)
	var guide := PanelContainer.new()
	guide.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_child(guide)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	guide.add_child(scroll)
	guide_rows = VBoxContainer.new()
	guide_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	guide_rows.add_theme_constant_override("separation",10)
	scroll.add_child(guide_rows)
	var phase_panel := PanelContainer.new()
	sidebar.add_child(phase_panel)
	var phase_info := VBoxContainer.new()
	phase_panel.add_child(phase_info)
	phase_progress = _label(phase_info,"",16)
	next_button = _button(phase_info,"Next lesson",next_lesson)
	var footer := PanelContainer.new()
	footer.name = "PersistentFooter"
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = 16; footer.offset_right = -16
	footer.offset_top = -46; footer.offset_bottom = -10
	root_control.add_child(footer)
	practice_footer = _label(footer,"",16)
	practice_footer.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	footer.hide()
	body.hide()
	motion = HandPresentation.new()
	# Practice actions already gate on busy; leave Exit reachable during motion.
	motion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	motion.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(motion)
	motion.finished.connect(_presentation_finished)
	synergy = SynergyNotification.new()
	add_child(synergy)
	synergy.layer = layer+1
	synergy.banner.reparent(synergy_lane)
	synergy_lane.resized.connect(_layout_synergy)
	_layout_synergy()

func _layout_synergy() -> void:
	var half := minf(290,synergy_lane.size.x/2.0)
	synergy.banner.offset_left = -half
	synergy.banner.offset_right = half
	synergy.banner.offset_top = 0
	synergy.banner.offset_bottom = 62

func _label(parent: Node, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",font_size)
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(180,42)
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func open_invitation() -> void:
	asking = true
	practice_background.color = Color.TRANSPARENT
	prompt.show(); practice.hide()
	progress.text = "Welcome to your Studio"
	instruction.text = "Have you played Patch Notes before?"
	new_button.show(); experienced_button.show()
	start_button.hide(); skip_button.hide(); back_button.hide()
	new_button.grab_focus()

func _experience(value: bool) -> void:
	experienced = value
	instruction.text = "Would you like to try the guided production tutorial?"
	result_label.text = "Practice Core and Scope, two production synergies, a redraw, then Marketing and QA. You can leave at any time and return to this Studio."
	new_button.hide(); experienced_button.hide()
	start_button.show(); skip_button.show(); back_button.show()
	if experienced: skip_button.grab_focus()
	else: start_button.grab_focus()

func start_practice() -> bool:
	if model != null: return false
	model = GuidedProductionModel.new()
	if not model.start(get_node("/root/CardDatabase").get_development_catalog()): return false
	asking = false
	practice_background.color = Color.TRANSPARENT
	invitation.hide()
	heading.reparent(guide_rows)
	heading.theme_type_variation=&"HeadingLabel"
	heading.add_theme_font_size_override("font_size",22)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progress.reparent(guide_rows)
	progress.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction.reparent(guide_rows)
	result_label.reparent(guide_rows)
	exit_button.reparent(stats.row)
	exit_button.custom_minimum_size.x = 132
	stats.show()
	practice.get_parent().show()
	practice.show()
	practice_footer.get_parent().show()
	_deal_views()
	_refresh()
	if not fan.card_views().is_empty(): fan.card_views()[0].input_button.grab_focus.call_deferred()
	return true

func _deal_views() -> void:
	selected.clear()
	for child: CardView in fan.card_views():
		fan.remove_child(child); child.queue_free()
	for card: CardData in model.pool:
		var view: CardView = CARD_SCENE.instantiate()
		view.set_card(card)
		view.card_pressed.connect(_select)
		fan.add_child(view)
	fan.queue_sort()

func _select(view: CardView) -> void:
	if closing or motion.busy or model.resolved: return
	if selected.has(view):
		selected.erase(view); view.set_selected(false)
	elif selected.size() < 4:
		selected.append(view); view.set_selected(true)
	_refresh()

func _slots() -> Array[int]:
	var slots: Array[int] = []
	for view: CardView in selected: slots.append(fan.card_views().find(view))
	return slots

func play_selected() -> void:
	if asking or closing or motion.busy or not model.can_play(_slots()): return
	var slots := _slots()
	var action := func():
		var resolved: Dictionary = model.play(slots)
		if not resolved.ok: return
		if resolved.balanced_production:
			motion.note_specialization(func(): synergy.show_message("Balanced Production!","1.25× Core total shared evenly"),true)
		elif not resolved.specialization_stat.is_empty():
			motion.note_specialization(func(): synergy.show_message(String(resolved.specialization_stat).capitalize()+" Specialization!","Current production/QA bonus"))
		_deal_views()
	motion.play("play",fan,selected.duplicate(),action,_snapshot,_present_scores,_restore_scores)
	_refresh()

func redraw_selected() -> void:
	if asking or closing or motion.busy or not model.can_redraw(_slots()): return
	var slots := _slots()
	var action := func():
		if model.redraw(slots).ok: _deal_views()
	motion.play("redraw",fan,selected.duplicate(),action,_snapshot,_present_scores,_restore_scores)
	_refresh()

func _snapshot() -> Dictionary:
	var values := HandPresentation.project_snapshot(model.project,model.run)
	values["_bug_total"] = model.project.get_hidden_bugs()+model.project.get_known_bugs()+model.project.get_fixed_bugs()
	return values

func _present_scores(values: Dictionary, deltas: Dictionary) -> void:
	_shown_scores = values.duplicate()
	_update_stats()
	stats.punch(deltas)

func _restore_scores() -> void:
	_shown_scores.clear()
	if not closing and model != null: _update_stats()

func _presentation_finished() -> void:
	if closing: return
	_refresh()
	if model.resolved: next_button.grab_focus()
	elif not fan.card_views().is_empty(): fan.card_views()[0].input_button.grab_focus()

func next_lesson() -> void:
	if asking or closing or motion.busy or not model.next_lesson(): return
	if model.complete:
		closing = true
		finished.emit(true)
		return
	synergy.banner.hide()
	_deal_views()
	_refresh()
	if not fan.card_views().is_empty(): fan.card_views()[0].input_button.grab_focus()

func _refresh() -> void:
	if asking or model == null: return
	var numbers := [1,2,3,4,4,5,6,7,8]
	progress.text = "%s · Lesson %d / 8 · Scripted practice"%[model.phase_name(),numbers[model.lesson]]
	phase_progress.text = "%s · Lesson %d / 8"%[model.phase_name(),numbers[model.lesson]]
	heading.text = TITLES[model.lesson]
	instruction.text = INSTRUCTIONS[model.lesson]
	if motion.busy: result_label.text = "Watch the hand resolve on the music grid."
	elif model.resolved:
		result_label.text = "Result: check the scoreboard above. Continue when you're ready."
		if model.lesson == GuidedProductionModel.Lesson.DEBUG:
			result_label.text = "Tutorial complete: eight Bugs fixed, Marketing retained. This practice project is not launched. Return to your unchanged Studio to begin a real game."
	elif model.lesson == GuidedProductionModel.Lesson.REDRAW:
		result_label.text = "Select only Sound Pass, then Redraw. Three Graphics cards are not enough for Specialization."
	else: result_label.text = "%d / 4 selected · Practice cards are supplied for this lesson; your real Studio is unchanged."%selected.size()
	play_button.text = "Play Beta hand" if model.lesson >= GuidedProductionModel.Lesson.MARKETING else "Implement"
	play_button.disabled = motion.busy or not model.can_play(_slots())
	redraw_button.text = "Redraw (%d/4)"%model.run.get_available_redraws()
	redraw_button.visible = model.lesson in [GuidedProductionModel.Lesson.REDRAW,GuidedProductionModel.Lesson.REDRAW_HAND]
	redraw_button.disabled = motion.busy or not model.can_redraw(_slots())
	next_button.visible = model.resolved
	next_button.disabled = motion.busy
	next_button.text = "Finish tutorial" if model.lesson == GuidedProductionModel.Lesson.DEBUG else "Next lesson"
	_update_stats()

func _update_stats() -> void:
	var values := _snapshot() if _shown_scores.is_empty() else _shown_scores
	stats.render(model.project,StringName(model.phase_name().to_lower()),values)
	practice_footer.text = "Practice · %s  |  Cycle %d  ·  Your Studio stays unchanged"%[model.run.get_calendar_label(),model.run.get_completed_run_cycles()]

func _exit() -> void:
	if closing: return
	closing = true
	if motion.busy: motion.cancel()
	if asking: choice.emit(experienced,false)
	else: finished.emit(false)

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_exit()
		get_viewport().set_input_as_handled()
