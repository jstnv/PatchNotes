extends Control

const DESIGN_PHASE_SCENE := preload("res://scenes/phases/design_phase.tscn")
const REQUIRED_SCOPE := 30

var project_state: ProjectState

func _ready() -> void:
	project_state = ProjectState.new(REQUIRED_SCOPE)

	var design_phase := DESIGN_PHASE_SCENE.instantiate()
	design_phase.call(&"setup", project_state)
	%PhaseRoot.add_child(design_phase)
