extends "res://scripts/debug/verify_feature_store_radial.gd"
const Replay:=preload("res://scripts/simulation/development_replay.gd")
func _verify() -> void:
	var game: Control=load("res://scenes/gameplay.tscn").instantiate();root.add_child(game);current_scene=game;await process_frame
	game._onboarding.answer(true)
	game._on_studio_created("Management predecessor",&"action",[],game._active_phase)
	await process_frame
	expect(game._active_phase is StudioPhase and game.rival_world!=null,"Canonical new-Studio handler creates real player and rival world")
	expect(await game.checkpoints.wait_saved(),"Initial combined checkpoint is durable")
	var payload: Dictionary=game.checkpoints.store.inspect().payload
	expect(payload.has("rival_world") and payload.rival_world.source_identity==Replay.source_identity(),"Genuine combined save pins executing source")
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(payload))
	print("MANAGEMENT_PREDECESSOR source=",Replay.source_identity()," failures=",failures)
	game.queue_free();await process_frame;quit(failures)
