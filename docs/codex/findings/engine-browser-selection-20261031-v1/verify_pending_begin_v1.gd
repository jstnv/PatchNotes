extends SceneTree
class Delayed extends CheckpointCoordinator:
	signal completed
	func is_saving() -> bool:return true
	func wait_saved() -> bool:await completed;return true
class Game extends "res://scripts/gameplay.gd":
	var starts:=0
	func _ready() -> void:pass
	func _begin_next_project(_source: Control,_title: String,_genre: StringName,_theme: StringName) -> bool:starts+=1;return true
var failures: Array=[]
func _initialize() -> void:
	await process_frame
	for mode: String in ["commission","support","normal","unchanged"]:
		var r=RunState.new();assert(r.initialize_cash(0) and r.create_studio_with_traits("Pending",&"action",[]) and r._register_proprietary_engine(&"b","B"))
		var game=Game.new();root.add_child(game);game.run_state=r
		var studio=load("res://scenes/phases/studio_phase.tscn").instantiate();game.add_child(studio);studio._run_state=r;game._active_phase=studio;studio._show_predevelopment()
		var view=studio._predevelopment;view.name_input.text="Pending game"
		view.commission_mode=mode=="commission";view.support_mode=mode=="support"
		view._commission_quote={"accepted":"commission"} if mode=="commission" else {}
		view._support_quote={"accepted":"support"} if mode=="support" else {}
		var gate=Delayed.new();gate.background_saves=true;game.add_child(gate);game.checkpoints=gate
		game._on_development_requested.call(studio,"Pending game",&"action",&"fantasy")
		await process_frame
		if mode!="unchanged":
			for i in view.engine_picker.choices.item_count:
				if view.engine_picker.choices.get_item_metadata(i)==&"b":view.engine_picker.choices.item_selected.emit(i);break
		gate.completed.emit();await process_frame
		if game.starts!=(1 if mode=="unchanged" else 0):failures.append(mode+" Begin resumed with changed engine/deal intent")
		game.queue_free();await process_frame
	FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"failures":failures,"cases":4}));quit(0 if failures.is_empty() else 1)
