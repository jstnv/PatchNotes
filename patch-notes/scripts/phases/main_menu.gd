class_name MainMenu
extends Control

signal studio_created(name: String, specialty: StringName, trait_ids: Array)
signal tutorial_requested
signal settings_requested
signal continue_requested
signal recovery_requested
signal quit_requested
var checkpoint_info: Dictionary = {"status":&"empty"}
var _replace_dialog: ConfirmationDialog

var _name_input: LineEdit
var _error: Label
var _setup: VBoxContainer
var _specialty: OptionButton
var _preview: Label
var _emphasis: Label
var _traits_step: VBoxContainer
var _review_step: VBoxContainer
var _trait_checks: Dictionary = {}
var _trait_error: Label
var _points: Label
var _review: Label
var _submitted := false
var _folder_buttons: Dictionary = {}
var _folder_panels: Dictionary = {}
var _visited: Dictionary = {}
var _review_signature: Array = []
var _folder_surface: PanelContainer
var _active_folder: StringName = &"genre"
var _bounces: Dictionary = {}
var _play: Button

const FOLDERS := {&"genre": "Genre Specializations", &"traits": "Traits", &"overview": "Overview"}

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
	var resume := Button.new()
	resume.name = "Continue"
	resume.text = "Continue"
	resume.custom_minimum_size.y = 44
	resume.disabled = checkpoint_info.status != &"valid"
	if not resume.disabled:
		var saved: Dictionary = checkpoint_info.payload.run
		resume.text = "Continue — %s · %d, Month %d" % [saved.studio_name,1980+int(saved.completed_run_cycles)/24,(int(saved.completed_run_cycles)/2)%12+1]
	resume.pressed.connect(func(): continue_requested.emit())
	layout.add_child(resume)
	var recovery := Button.new()
	recovery.name = "CheckpointRecovery"
	recovery.text = "Saved Studio needs attention"
	recovery.visible = checkpoint_info.status not in [&"empty",&"valid"]
	recovery.pressed.connect(func(): recovery_requested.emit())
	layout.add_child(recovery)
	var quit_button := _button(layout,"Quit","Quit",func(): quit_requested.emit())
	if checkpoint_info.status != &"empty": start.text = "New Run"
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
	_build_folders(enter)
	var begin_setup := func():
		title.hide()
		start.hide()
		resume.hide()
		recovery.hide()
		quit_button.hide()
		tutorial.hide()
		settings.hide()
		_setup.show()
		_open_folder(&"genre")
		_name_input.grab_focus()
	start.pressed.connect(func():
		if checkpoint_info.status == &"empty":
			begin_setup.call()
			return
		if is_instance_valid(_replace_dialog) and _replace_dialog.visible: return
		var confirm := ConfirmationDialog.new()
		_replace_dialog = confirm
		confirm.title = "Replace saved Studio?"
		confirm.dialog_text = "Your existing checkpoint will be archived. Replacement happens only after the new Studio is created."
		add_child(confirm)
		confirm.confirmed.connect(begin_setup)
		confirm.popup_centered()
		confirm.get_cancel_button().grab_focus())
	back.pressed.connect(func():
		title.show()
		_setup.hide()
		_name_input.clear()
		_visited.clear()
		_review_signature.clear()
		_specialty.select(0)
		_refresh_preview()
		_error.text = ""
		_clear_trait_draft()
		tutorial.show()
		settings.show()
		start.show()
		resume.show()
		recovery.visible = checkpoint_info.status not in [&"empty",&"valid"]
		quit_button.show()
		start.grab_focus())
	enter.pressed.connect(_submit)
	_name_input.text_submitted.connect(func(_text: String): _submit())

func _submit() -> void:
	_confirm_studio()


func _build_folders(enter: Button) -> void:
	var tabs := HBoxContainer.new()
	tabs.name = "Folders"
	_setup.add_child(tabs)
	_setup.move_child(tabs, 2)
	var group := ButtonGroup.new()
	for id: StringName in FOLDERS:
		var button := _button(tabs, String(id), FOLDERS[id], func(): _open_folder(id))
		button.toggle_mode = true
		button.button_group = group
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 42
		var style := StyleBoxFlat.new()
		style.bg_color = Color("253348")
		style.border_color = Color("9bbde0")
		style.set_border_width_all(1)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.content_margin_left = 14
		style.content_margin_right = 14
		button.add_theme_stylebox_override("normal", style)
		var selected := style.duplicate() as StyleBoxFlat
		selected.bg_color = Color("435d7b")
		selected.border_width_bottom = 3
		button.add_theme_stylebox_override("pressed", selected)
		_folder_buttons[id] = button
	_folder_surface = PanelContainer.new()
	_folder_surface.name = "FolderContent"
	_folder_surface.custom_minimum_size = Vector2(720, 330)
	_setup.add_child(_folder_surface)
	_setup.move_child(_folder_surface, 3)
	var genre := VBoxContainer.new()
	genre.name = "Genre"
	var preview_scroll := _preview.get_parent()
	for node in [_specialty, _emphasis, preview_scroll]: node.get_parent().remove_child(node)
	genre.add_child(_specialty)
	genre.add_child(_emphasis)
	genre.add_child(preview_scroll)
	for pair in [[&"genre", genre], [&"traits", _traits_step], [&"overview", _review_step]]:
		var panel: VBoxContainer = pair[1]
		if panel.get_parent() != null: panel.get_parent().remove_child(panel)
		var scroll := ScrollContainer.new()
		scroll.name = String(pair[0])
		scroll.follow_focus = true
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_folder_surface.add_child(scroll)
		scroll.add_child(panel)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.show()
		_folder_panels[pair[0]] = scroll
	_play = enter
	_play.text = "Play"
	_name_input.text_changed.connect(func(_value: String): _draft_changed())
	_specialty.item_selected.connect(func(_index: int): _draft_changed())
	_open_folder(&"genre")


func _draft_signature() -> Array:
	return [_name_input.text, _specialty.selected, _secondary_ids()]


func _needs_attention(id: StringName) -> bool:
	if not _visited.get(id, false): return true
	match id:
		&"genre": return _specialty.selected <= 0
		&"traits": return not _selection().valid
		&"overview": return _review_signature != _draft_signature()
	return false


func _refresh_attention() -> void:
	for id: StringName in _folder_buttons:
		_folder_buttons[id].text = FOLDERS[id] + (" *" if _needs_attention(id) else "")
		_folder_buttons[id].tooltip_text = "Needs attention" if _needs_attention(id) else "Reviewed"


func _draft_changed() -> void:
	_review_signature.clear()
	if is_instance_valid(_error): _error.text = ""
	_refresh_attention()
	if _active_folder == &"overview": _refresh_review()


func _open_folder(id: StringName) -> void:
	_active_folder = id
	_visited[id] = true
	for key: StringName in _folder_panels:
		_folder_panels[key].visible = key == id
		_folder_buttons[key].set_pressed_no_signal(key == id)
	if id == &"overview":
		_refresh_review()
		_review_signature = _draft_signature().duplicate(true)
	_refresh_attention()


func _bounce(id: StringName) -> void:
	var button: Button = _folder_buttons[id]
	if _bounces.has(id): _bounces[id].kill()
	button.scale = Vector2.ONE
	button.pivot_offset = button.size / 2
	var tween := create_tween()
	_bounces[id] = tween
	tween.tween_property(button, "scale", Vector2(1.035, 1.10), 0.10)
	tween.tween_property(button, "scale", Vector2.ONE, 0.16)


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
	_label(_traits_step, "Studio Traits · Optional choices").add_theme_font_size_override("font_size", 24)
	_label(_traits_step, "Choose at most two positives and one negative; none is required.")
	_points = _label(_traits_step, "")
	_points.name = "Points"
	_trait_error = _label(_traits_step, "")
	_trait_error.name = "TraitError"
	var groups := HBoxContainer.new()
	groups.add_theme_constant_override("separation", 18)
	_traits_step.add_child(groups)
	for positive: bool in [true, false]:
		var roster := VBoxContainer.new()
		roster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		groups.add_child(roster)
		_label(roster, "Positive" if positive else "Negative").add_theme_font_size_override("font_size", 20)
		for id: StringName in StudioTraits.TRAITS:
			var entry: Dictionary = StudioTraits.TRAITS[id]
			if entry.positive != positive: continue
			var check := CheckBox.new()
			check.name = String(id)
			check.text = "%s · %s" % [entry.name, entry.price]
			check.tooltip_text = entry.description
			roster.add_child(check)
			var description := _label(roster, entry.description)
			description.add_theme_font_size_override("font_size", 14)
			_trait_checks[id] = check
			check.toggled.connect(func(_on: bool): _refresh_traits())
	_review_step = VBoxContainer.new()
	_review_step.name = "CreationReview"
	_review_step.add_theme_constant_override("separation", 12)
	layout.add_child(_review_step)
	_label(_review_step, "Your Studio · Overview").add_theme_font_size_override("font_size", 24)
	_review = _label(_review_step, "")
	_review.name = "Summary"
	_refresh_traits()


func _secondary_ids() -> Array:
	var ids: Array = []
	for id: StringName in _trait_checks:
		if _trait_checks[id].button_pressed: ids.append(id)
	return ids


func _selection() -> Dictionary:
	return StudioTraits.evaluate_traits(_secondary_ids())


func _refresh_traits() -> void:
	var selection := _selection()
	_points.text = "%d points remain · $50 per unused point, no cap\nBase funding: $5,500. Preview choices spend/refund no points." % selection.get("remaining_points", 0)
	_trait_error.text = selection.reason
	_draft_changed()


func _show_review() -> void:
	_open_folder(&"overview")


func _refresh_review() -> void:
	var selection := _selection()
	if not selection.valid:
		_review.text = "Review your Traits: " + selection.reason
		return
	_review.text = "%s\nGenre specialty: %s · free roster\n%s\n\n%d unused points × $50 = %s\nFamily Funding: %s\nStarting cash: %s\nMonthly rent: %s · first due after two productive cycles" % [_name_input.text.strip_edges(), _specialty.get_item_text(_specialty.selected), StudioTraits.summary(selection), selection.remaining_points, CashFormatter.format_exact_cents(selection.point_cash_cents), CashFormatter.format_exact_cents(selection.get("family_funding_cents", 0)), CashFormatter.format_exact_cents(550000 + selection.point_cash_cents + selection.get("family_funding_cents", 0)), CashFormatter.format_exact_cents(51500 if StudioTraits.is_active(selection, &"expensive_lease") else 50000)]


func _confirm_studio() -> void:
	if _submitted or not is_inside_tree(): return
	_refresh_attention()
	var blocked := false
	for id: StringName in FOLDERS:
		if _needs_attention(id):
			blocked = true
			_bounce(id)
	if _name_input.text.strip_edges().is_empty():
		_error.text = "Enter a studio name."
		_name_input.grab_focus()
		return
	if blocked:
		_error.text = "Review the folders marked with an asterisk before playing."
		return
	_error.text = ""
	var selection := _selection()
	if not selection.valid or _specialty.selected <= 0 or _name_input.text.strip_edges().is_empty(): return
	_submitted = true
	studio_created.emit(_name_input.text.strip_edges(), _specialty.get_item_metadata(_specialty.selected), selection.trait_ids)


func _clear_trait_draft() -> void:
	for check: CheckBox in _trait_checks.values(): check.set_pressed_no_signal(false)
	_submitted = false
	_refresh_traits()


func _input(event: InputEvent) -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused == null or not is_ancestor_of(focused): return
	if focused is OptionButton and focused.get_popup().visible: return
	if not is_visible_in_tree() or not event.is_action_pressed("ui_cancel"): return
	if _setup.visible: _setup.get_node("Back").pressed.emit()
	else: return
	get_viewport().set_input_as_handled()
