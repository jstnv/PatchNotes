extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var pair: Variant=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_CURRENT_PAIR")))
	if not pair is Dictionary:push_error("Invalid private fixture");quit(2);return
	var source: Dictionary=pair.player.duplicate(true);source.rival_world=pair.world
	var before:=var_to_bytes(source)
	var player: Dictionary=source.duplicate(false);player.erase("rival_world")
	if OS.get_environment("PN_ALIAS_ARM")=="safe":player=player.duplicate(true)
	player.run.studio_traits["private-test-sentinel"]="changed"
	var ok:=var_to_bytes(source)==before
	print("PLAYER_COPY_ALIAS arm=",OS.get_environment("PN_ALIAS_ARM")," unchanged=",ok)
	quit(0 if ok else 1)
