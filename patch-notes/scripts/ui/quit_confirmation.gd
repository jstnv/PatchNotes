extends ConfirmationDialog

## Local presentation only: retain the native modal and confirmation signals.
var _entrance: Tween
var content_host: VBoxContainer

func _init() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	theme = FolderUI.THEME.duplicate()
	var surface: StyleBoxFlat = FolderUI.THEME.get_stylebox("panel", "FolderPanel").duplicate()
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		surface.set_content_margin(side, 24.0)
	theme.set_stylebox("panel", "AcceptDialog", surface)
	borderless = true
	transparent = true
	transparent_bg = true
	theme.set_constant("buttons_separation", "AcceptDialog", 20)
	theme.set_constant("buttons_min_height", "AcceptDialog", 44)
	theme.set_constant("buttons_min_width", "AcceptDialog", 140)
	dialog_autowrap = true
	ok_button_text = "Confirm"
	size = Vector2i(680, 220)
	about_to_popup.connect(_update_copy)
	visibility_changed.connect(_visibility_changed)

func _ready() -> void:
	# Exclude the native wrapped label before the first popup minimum is read.
	# Our visible copy carries the same text and settles at its bounded width.
	get_label().hide()
	get_ok_button().theme_type_variation = &"PrimaryButton"
	for button in [get_ok_button(), get_cancel_button()]:
		button.custom_minimum_size = Vector2(140, 44)
	var copy := VBoxContainer.new()
	content_host=copy
	copy.name = "QuitCopy"
	copy.custom_minimum_size.x = 560
	copy.size.x = 560
	copy.add_theme_constant_override("separation", 14)
	add_child(copy)
	var header := HBoxContainer.new()
	header.name = "Header"
	copy.add_child(header)
	var heading := FolderUI.label(header, title, &"FolderHeading")
	heading.name = "Heading"
	heading.autowrap_mode = TextServer.AUTOWRAP_OFF
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	FolderUI.button(header, "×", func(): get_cancel_button().pressed.emit()).name = "Close"
	var warning := FolderUI.label(copy, dialog_text, &"Label")
	warning.name = "Warning"
	warning.visible=not dialog_text.is_empty()
	warning.custom_minimum_size.x = 560
	warning.size.x = 560
	warning.add_theme_constant_override("line_spacing", 5)

func _update_copy() -> void:
	get_label().hide()
	get_node("QuitCopy/Header/Heading").text = title
	get_node("QuitCopy/Warning").text = dialog_text
	get_node("QuitCopy/Warning").visible=not dialog_text.is_empty()
	_settle_copy.call_deferred()

func _visibility_changed() -> void:
	if _entrance != null and _entrance.is_valid(): _entrance.kill()
	if visible: _slide_in.call_deferred()

func _slide_in() -> void:
	if not visible: return
	var rest := position
	position = rest + Vector2i(32, 0)
	_entrance = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)
	_entrance.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_entrance.tween_method(func(offset: float): position = rest + Vector2i(roundi(offset), 0), 32.0, 0.0, MenuTransitions.ENTRANCE_SECONDS)

func _exit_tree() -> void:
	if _entrance != null and _entrance.is_valid(): _entrance.kill()

func _settle_copy() -> void:
	# Autowrap can report a transient one-word-wide minimum on first popup.
	# Fit only after containers have laid out; this bound callback is removed on free.
	if not visible or not is_inside_tree(): return
	if not get_tree().process_frame.is_connected(_fit_copy):
		get_tree().process_frame.connect(_fit_copy,CONNECT_ONE_SHOT)

func _fit_copy() -> void:
	if not visible or not is_inside_tree() or get_parent()==null: return
	if _entrance != null and _entrance.is_valid():_entrance.kill()
	var fitted_width:=maxi(size.x,680)
	reset_size()
	size.x=maxi(size.x,fitted_width)
	var parent_window:=get_parent().get_window()
	if is_embedded():position=Vector2i((parent_window.get_visible_rect().size-Vector2(size))*0.5)
	else:position=parent_window.position+(parent_window.size-size)/2
	_slide_in()

func add_content(content: Control) -> void:
	content_host.add_child(content)
