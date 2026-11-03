extends SceneTree
class UnfinishedGame extends Node:
 var _transition_in_progress:=true
 var _active_phase: Node
 var guided_tutorial=null
func _initialize()->void:go.call_deferred()
func go()->void:
 Engine.max_fps=60
 var game:=UnfinishedGame.new();root.add_child(game)
 game._active_phase=Control.new();game.add_child(game._active_phase)
 var mode:=OS.get_environment("PN_FOCUS_SIZE")
 if mode=="wrong-phase":game._transition_in_progress=false
 print("EXPECTED_FIXTURE_GUARD=",mode)
 create_timer(65.0).timeout.connect(func():push_error("Expected fixture assertion was not observed");quit(1))
 preload("res://scripts/debug/ui_test_actions.gd").finish_new_save(game)
