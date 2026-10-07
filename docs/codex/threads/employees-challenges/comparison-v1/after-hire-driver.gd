## Analysis-only legal ownership chronology for a post-Game-1 hire.
extends "res://analysis/employee_optional_v1.gd"

func _begin_game(game: Control, title: String, genre: StringName, out: Dictionary) -> bool:
	staff = 0 if project_number == 0 else 1
	return super._begin_game(game,title,genre,out)

func _finance_route() -> Dictionary:
	var out := await super._finance_route()
	out["employee_reward_available_from_project"] = 2
	out["ownership_limit"] = "Shadow hire after Game-1 Contracts; no employee, training or reward during Game 1. Fee/wage are separate fixed-action overlays."
	return out
