class_name PriorityBudgetFeedback
extends Node

## Draft-only feedback. Never changes weights, commands, time or gameplay.
var controls: Array = []
var over_budget := false
var intensity := 0.0
var elapsed := 0.0
const PERIOD := 1.4

func bind_controls(values: Array) -> void:
	controls = values.duplicate()
	for control: Range in controls: control.value_changed.connect(_changed)
	refresh()

func _changed(_value: float) -> void: refresh()

func refresh() -> void:
	var total := 0.0
	for control: Range in controls: total += control.value
	var exceeded := total > 100.0
	if exceeded != over_budget:
		elapsed = 0.0
		intensity = 0.0
	over_budget = exceeded
	set_process(over_budget)
	_apply()

func _process(delta: float) -> void: advance(delta)

func advance(delta: float) -> void:
	if not over_budget: return
	elapsed = fposmod(elapsed + maxf(0,delta),PERIOD)
	intensity = (1.0-cos(TAU*elapsed/PERIOD))/2.0
	_apply()

func _apply() -> void:
	for control: Control in controls:
		control.self_modulate = Color.WHITE.lerp(Color.RED,intensity) if over_budget else Color.WHITE
