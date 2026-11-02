extends Control

const ENTER_SECONDS := 0.20
const HOLD_SECONDS := 2.40
const EXIT_SECONDS := 0.25
const SLIDE_PIXELS := 12.0

var message: Label
var _surface: PanelContainer
var _animation: Tween
var _last_publication := 0
var _kind: StringName = &"idle"
var _failure := ""
var _success_context := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = FolderUI.THEME
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	offset_left = -280
	offset_right = -16
	offset_top = -124
	offset_bottom = -76
	_surface = PanelContainer.new()
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)
	_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	message = Label.new()
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_surface.add_child(message)
	modulate.a = 0.0
	hide()

func update_status(saving: bool, failure: String, publications: int) -> void:
	message.text = "Not saved" if not failure.is_empty() else ("Saving Studio…" if saving else "Studio saved")
	message.tooltip_text = failure
	if not failure.is_empty():
		if _kind != &"failure" or _failure != failure: _present(false)
		_kind = &"failure"
		_failure = failure
	elif saving:
		if _kind != &"saving": _present(false)
		_kind = &"saving"
	elif publications > _last_publication:
		_last_publication = publications
		_kind = &"saved"
		_failure = ""
		if _success_context: _present(true)
		else: _dismiss()
	elif _kind in [&"saving", &"failure"]:
		_kind = &"idle"
		_dismiss()

func set_success_context(value: bool) -> void:
	_success_context = value
	# This receipt describes the Studio checkpoint, not unsaved development.
	# Keep saving/failure feedback available; only the completed toast is scoped.
	if not value and _kind == &"saved":
		if _animation != null and _animation.is_valid(): _animation.kill()
		modulate.a = 0.0
		hide()

func _present(transient: bool) -> void:
	if _animation != null and _animation.is_valid(): _animation.kill()
	if not visible:
		modulate.a = 0.0
		_surface.position.y = SLIDE_PIXELS
		show()
	_animation = create_tween().set_parallel().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_animation.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_animation.tween_property(self,"modulate:a",1.0,ENTER_SECONDS)
	_animation.tween_property(_surface,"position:y",0.0,ENTER_SECONDS)
	if transient:
		_animation.chain().tween_interval(HOLD_SECONDS)
		_animation.chain().tween_property(self,"modulate:a",0.0,EXIT_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_animation.parallel().tween_property(_surface,"position:y",SLIDE_PIXELS,EXIT_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_animation.chain().tween_callback(hide)

func _dismiss() -> void:
	if _animation != null and _animation.is_valid(): _animation.kill()
	_animation = create_tween().set_parallel().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_animation.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_animation.tween_property(self,"modulate:a",0.0,EXIT_SECONDS)
	_animation.tween_property(_surface,"position:y",SLIDE_PIXELS,EXIT_SECONDS)
	_animation.chain().tween_callback(hide)
