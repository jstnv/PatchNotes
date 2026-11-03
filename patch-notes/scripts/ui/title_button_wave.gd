extends Node
## Presentation only. The title VBox still owns layout and native Buttons own input.

const TRAVEL := 7.0
const PERIOD := 3.6
const ROW_PHASE := 0.7
const STRETCH_SECONDS := 0.16
const RETURN_SECONDS := 0.18

var travel := TRAVEL
var period := PERIOD
var _buttons: Array[Button] = []
var _phases := PackedFloat64Array()
var _hover_weights := PackedFloat32Array()
var _keyboard_navigation := false
var _snap_viewport: Viewport
var _previous_gui_snap := true

func bind_buttons(layout: VBoxContainer, buttons: Array[Button]) -> void:
	_buttons=buttons
	for index in buttons.size():
		_phases.append(-index*ROW_PHASE)
		_hover_weights.append(0.0)
		# Scale from the left; hover placement expands to both wave endpoints.
		buttons[index].pivot_offset=Vector2.ZERO
	layout.sort_children.connect(_apply_poses)
	_apply_poses()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_keyboard_navigation=false
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") or event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_focus_prev") or event.is_action_pressed("ui_accept"):
		_keyboard_navigation=true

func advance(delta: float, active: bool) -> void:
	_set_subpixel_rendering(active)
	if not active:return
	for index in _buttons.size():
		var button:=_buttons[index]
		var held:=button.is_hovered() or (_keyboard_navigation and button.has_focus())
		var returning:=_hover_weights[index]>0.0
		_hover_weights[index]=move_toward(_hover_weights[index],1.0 if held else 0.0,delta/(STRETCH_SECONDS if held else RETURN_SECONDS))
		# Keep the phase (position AND direction) through hover and compression.
		# Restore its exact pose for one frame before resuming the wave.
		if not held and not returning:
			_phases[index]=fposmod(_phases[index]+TAU*delta/period,TAU)
	_apply_poses()

func _set_subpixel_rendering(active: bool) -> void:
	# Control positions are fractional, but GUI snapping otherwise rounds their
	# rendered transforms. Borrow the viewport setting only while the title is active.
	if active and _snap_viewport==null:
		_snap_viewport=get_viewport()
		_previous_gui_snap=_snap_viewport.gui_snap_controls_to_pixels
		_snap_viewport.gui_snap_controls_to_pixels=false
	elif not active and _snap_viewport!=null:
		if is_instance_valid(_snap_viewport):
			_snap_viewport.gui_snap_controls_to_pixels=_previous_gui_snap
		_snap_viewport=null

func _exit_tree() -> void:
	_set_subpixel_rendering(false)

func _apply_poses() -> void:
	for index in _buttons.size():
		var button:=_buttons[index]
		# Full-width title buttons have a layout-local left edge of zero.
		# A shifted cosine makes that edge the left turning point, never its midpoint.
		var wave_x:=travel*0.5*(1.0-cos(_phases[index]))
		var stretch:=smoothstep(0.0,1.0,_hover_weights[index])
		# Fully hovered: left=0, right=normal width+TRAVEL, independent of phase.
		button.position.x=lerpf(wave_x,0.0,stretch)
		button.scale=Vector2(1.0+travel/maxf(1.0,button.size.x)*stretch,1.0)
