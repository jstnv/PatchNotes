extends "res://scripts/ui/title_button_wave.gd"
## The title wave, bounded by the Studio panel's actual inside border.

var panel: PanelContainer

func add_button(button: Button) -> void:
	var index := _buttons.size()
	_buttons.append(button)
	_phases.append(-index * ROW_PHASE)
	_hover_weights.append(0.0)
	button.pivot_offset = Vector2.ZERO
	_apply_poses()

func _apply_poses() -> void:
	if not is_instance_valid(panel): return
	var style := panel.get_theme_stylebox("panel")
	var left_border := float(style.border_width_left) if style is StyleBoxFlat else 0.0
	var right_border := float(style.border_width_right) if style is StyleBoxFlat else 0.0
	var left_edge := panel.global_position.x + left_border
	var inner_width := maxf(1.0,panel.size.x - left_border - right_border)
	for index in _buttons.size():
		var button := _buttons[index]
		var row := button.get_parent() as Control
		if not is_instance_valid(row): continue
		var local_left := left_edge - row.global_position.x
		var normal_width := maxf(1.0,inner_width - 2.0 - travel)
		var hover_width := maxf(1.0,inner_width - 4.0)
		button.size = Vector2(normal_width,row.size.y)
		var wave_x := travel * 0.5 * (1.0 - cos(_phases[index]))
		var stretch := smoothstep(0.0,1.0,_hover_weights[index])
		button.position.x = lerpf(local_left + 1.0 + wave_x,local_left + 2.0,stretch)
		button.scale = Vector2(lerpf(1.0,hover_width / normal_width,stretch),1.0)
