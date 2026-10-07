class_name MainMenu
extends Control

signal studio_created(name: String, specialty: StringName, background: StringName, secondary_ids: Array)
signal tutorial_requested
signal settings_requested

var _name_input: LineEdit
var _error: Label
var _setup: VBoxContainer
var _specialty: OptionButton
var _preview: Label
var _emphasis: Label
var _traits_step: VBoxContainer
var _review_step: VBoxContainer
var _background: OptionButton
var _trait_checks: Dictionary = {}
var _trait_error: Label
var _points: Label
var _review: Label
var _submitted := false

func _ready() -> void:
	theme = preload("res://resources/ui/workspace_theme.tres")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.name = "CenterContainer"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var layout := VBoxContainer.new()
	layout.name = "MenuLayout"
	layout.custom_minimum_size = Vector2(720, 0)
	layout.add_theme_constant_override("separation", 10)
	center.add_child(layout)
	var title := Label.new()
	title.text = "Patch Notes"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	layout.add_child(title)
	var start := Button.new()
	start.name = "StartGame"
	start.text = "Start Game"
	start.custom_minimum_size.y = 52
	layout.add_child(start)
	var tutorial := Button.new()
	tutorial.name = "HowToPlay"
	tutorial.text = "How to Play"
	tutorial.tooltip_text = "Open the optional tutorial reference."
	tutorial.custom_minimum_size.y = 44
	tutorial.pressed.connect(func(): tutorial_requested.emit())
	layout.add_child(tutorial)
	var settings := _button(layout, "Settings", "Settings", func(): settings_requested.emit())
	start.grab_focus.call_deferred()
	_setup = VBoxContainer.new()
	_setup.name = "StudioSetup"
	_setup.add_theme_constant_override("separation", 8)
	layout.add_child(_setup)
	var prompt := Label.new()
	prompt.text = "Name your studio"
	_setup.add_child(prompt)
	_name_input = LineEdit.new()
	_name_input.name = "StudioName"
	_name_input.placeholder_text = "Studio name"
	_name_input.max_length = 80
	_name_input.tooltip_text = "Name your studio. You can start producing games after entering Studio."
	_setup.add_child(_name_input)
	_specialty = OptionButton.new()
	_specialty.name = "StudioSpecialty"
	_specialty.add_item("Choose your permanent Genre specialty")
	_specialty.set_item_disabled(0, true)
	for genre: Dictionary in PrimitivePredevelopment.catalog().genres:
		_specialty.add_item(genre.name)
		_specialty.set_item_metadata(_specialty.item_count - 1, StringName(genre.id))
	_specialty.select(0)
	_specialty.item_selected.connect(func(_index: int): _refresh_preview())
	_setup.add_child(_specialty)
	_emphasis = Label.new()
	_emphasis.name = "SpecialtyEmphasis"
	_setup.add_child(_emphasis)
	var preview_scroll := ScrollContainer.new()
	preview_scroll.custom_minimum_size = Vector2(700, 130)
	_setup.add_child(preview_scroll)
	_preview = Label.new()
	_preview.name = "SpecialtyRoster"
	_preview.custom_minimum_size.x = 670
	_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_scroll.add_child(_preview)
	_refresh_preview()
	_error = Label.new()
	_error.name = "ErrorLabel"
	_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_setup.add_child(_error)
	var enter := Button.new()
	enter.name = "EnterStudio"
	enter.text = "Next: Studio Traits"
	enter.custom_minimum_size.y = 44
	_setup.add_child(enter)
	var back := Button.new()
	back.name = "Back"
	back.text = "Back"
	_setup.add_child(back)
	_setup.hide()
	_build_traits(layout)
	start.pressed.connect(func():
		start.hide()
		tutorial.hide()
		settings.hide()
		_setup.show()
		_name_input.grab_focus())
	back.pressed.connect(func():
		_setup.hide()
		_specialty.select(0)
		_refresh_preview()
		_error.text = ""
		_clear_trait_draft()
		tutorial.show()
		settings.show()
		start.show()
		start.grab_focus())
	enter.pressed.connect(_submit)
	_name_input.text_submitted.connect(func(_text: String): _submit())

func _submit() -> void:
	if _submitted or not is_inside_tree(): return
	var value := _name_input.text.strip_edges()
	if value.is_empty():
		_error.text = "Enter a studio name."
		return
	if _specialty.selected <= 0:
		_error.text = "Choose one permanent Genre specialty."
		return
	_error.text = ""
	_setup.hide()
	_traits_step.show()
	_background.grab_focus()
	_refresh_traits()

func _refresh_preview() -> void:
	if _specialty.selected <= 0:
		_emphasis.text = "Your specialty grants a free starting Feature roster."
		_preview.text = "Choose a specialty to preview every starting Feature.\nEach game can use any Genre. The specialty provides no score or sales bonus."
		return
	var preview := StudioSpecialties.preview(_specialty.get_item_metadata(_specialty.selected))
	if preview.is_empty():
		_emphasis.text = "Specialty roster unavailable."
		_preview.text = ""
		return
	_emphasis.text = "%s · %d Features · %d printed Scope · Free" % [preview.emphasis, preview.count, preview.scope]
	_preview.text = ", ".join(preview.names) + "\n\nPermanent studio specialty; each game's Genre is chosen separately.\nStarting cards only: no bonus to scores or sales."

func show_error(message: String) -> void:
	_submitted = false
	_error.text = message
	_review_step.hide()
	_setup.show()


func _label(parent: Node, value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


func _button(parent: Node, node_name: String, caption: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = caption
	button.custom_minimum_size.y = 36
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _build_traits(layout: VBoxContainer) -> void:
	_traits_step = VBoxContainer.new()
	_traits_step.name = "StudioTraits"
	_traits_step.add_theme_constant_override("separation", 8)
	layout.add_child(_traits_step)
	_label(_traits_step, "Studio Traits · Choose one background").add_theme_font_size_override("font_size", 24)
	_background = OptionButton.new()
	_background.name = "Background"
	_background.add_item("Choose a background — no default")
	_background.set_item_disabled(0, true)
	for id: StringName in StudioTraits.BACKGROUNDS:
		_background.add_item(StudioTraits.BACKGROUNDS[id])
		_background.set_item_metadata(_background.item_count - 1, id)
	_background.select(0)
	_background.item_selected.connect(func(_index: int): _refresh_traits())
	_traits_step.add_child(_background)
	_label(_traits_step, "Background and secondary effects are PREVIEW ONLY. Choices are saved;\nno cash, fans, publisher bonus, discounts, Awareness or bills are granted by them.")
	_label(_traits_step, "Optional previews · At most two positives and one negative")
	var scroll := ScrollContainer.new()
	scroll.name = "TraitScroll"
	scroll.custom_minimum_size.y = 174
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_traits_step.add_child(scroll)
	var roster := VBoxContainer.new()
	roster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(roster)
	for id: StringName in StudioTraits.SECONDARIES:
		var entry: Dictionary = StudioTraits.SECONDARIES[id]
		var check := CheckBox.new()
		check.name = String(id)
		check.text = "%s %s · %s · Preview" % ["+" if entry.positive else "−", entry.name, entry.price]
		check.tooltip_text = entry.description
		roster.add_child(check)
		var description := _label(roster, entry.description)
		description.add_theme_font_size_override("font_size", 14)
		_trait_checks[id] = check
		check.toggled.connect(func(_on: bool): _refresh_traits())
	_points = _label(_traits_step, "")
	_points.name = "Points"
	_trait_error = _label(_traits_step, "")
	_trait_error.name = "TraitError"
	_button(_traits_step, "ReviewChoices", "Review choices", _show_review)
	_button(_traits_step, "Back", "Back to Studio / Genre", func():
		_traits_step.hide()
		_setup.show()
		_specialty.grab_focus())
	_traits_step.hide()
	_review_step = VBoxContainer.new()
	_review_step.name = "CreationReview"
	_review_step.add_theme_constant_override("separation", 12)
	layout.add_child(_review_step)
	_label(_review_step, "Create your Studio").add_theme_font_size_override("font_size", 24)
	_review = _label(_review_step, "")
	_review.name = "Summary"
	_button(_review_step, "ConfirmStudio", "Confirm and Enter Studio", _confirm_studio)
	_button(_review_step, "Back", "Back to Traits", func():
		_review_step.hide()
		_traits_step.show())
	_review_step.hide()
	_refresh_traits()


func _secondary_ids() -> Array:
	var ids: Array = []
	for id: StringName in _trait_checks:
		if _trait_checks[id].button_pressed: ids.append(id)
	return ids


func _selection() -> Dictionary:
	var background: StringName = &"" if _background.selected <= 0 else _background.get_item_metadata(_background.selected)
	return StudioTraits.evaluate(background, _secondary_ids())


func _refresh_traits() -> void:
	var selection := _selection()
	_points.text = "4 / 4 active points remain · previews spend/refund 0\nUnused-point cash: $200 once ($50/point, $300 cap). Base funding: $5,500."
	_trait_error.text = selection.reason
	_traits_step.get_node("ReviewChoices").disabled = not selection.valid


func _show_review() -> void:
	var selection := _selection()
	if not selection.valid:
		_refresh_traits()
		return
	_review.text = "%s\nGenre specialty: %s · free roster, no trait points\n%s\n\n4 unspent points × $50 = $200 startup receipt\nBase funding $5,500 + point cash $200 = $5,700\nMonthly rent: $500 · first due after two productive cycles\n\nOnly the roster and point cash are active. All trait effects remain previews." % [_name_input.text.strip_edges(), _specialty.get_item_text(_specialty.selected), StudioTraits.summary(selection)]
	_traits_step.hide()
	_review_step.show()
	_review_step.get_node("ConfirmStudio").grab_focus()


func _confirm_studio() -> void:
	if _submitted: return
	var selection := _selection()
	if not selection.valid or _specialty.selected <= 0 or _name_input.text.strip_edges().is_empty(): return
	_submitted = true
	studio_created.emit(_name_input.text.strip_edges(), _specialty.get_item_metadata(_specialty.selected), selection.background_id, selection.secondary_ids)


func _clear_trait_draft() -> void:
	_background.select(0)
	for check: CheckBox in _trait_checks.values(): check.set_pressed_no_signal(false)
	_submitted = false
	_refresh_traits()


func _input(event: InputEvent) -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused == null or not is_ancestor_of(focused): return
	if focused is OptionButton and focused.get_popup().visible: return
	if not is_visible_in_tree() or not event.is_action_pressed("ui_cancel"): return
	if _review_step.visible: _review_step.get_node("Back").pressed.emit()
	elif _traits_step.visible: _traits_step.get_node("Back").pressed.emit()
	elif _setup.visible: _setup.get_node("Back").pressed.emit()
	else: return
	get_viewport().set_input_as_handled()
