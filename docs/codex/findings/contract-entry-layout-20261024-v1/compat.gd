extends SceneTree
const WorldCodec := preload("res://scripts/market/rival_world_checkpoint.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var checks := 0
var failures := 0
func _initialize() -> void: execute.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func execute() -> void:
	var args := OS.get_cmdline_user_args()
	var root_path := args[0]
	var adapter := StudioCheckpoint.new()
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var inputs: Array = []
	for kind in ["world-operator", "compiled-world"]:
		for suffix in [".fixture.json", ".operator-fixture.json"]:
			var path: String = root_path + "/" + kind + "/result.json" + suffix
			var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
			var original: Dictionary = fixture.duplicate(true)
			inputs.append({"path":path, "source":fixture.world.source_identity})
			check(adapter.validate(fixture.player).is_empty(),"Actual previous player payload validates")
			var player := adapter.hydrate(fixture.player)
			var codec := WorldCodec.new()
			var restored := codec.restore(fixture.world,fixture.player,player,catalog)
			check(restored != null, "Actual unmodified prior world restores: " + codec.error)
			if restored != null:
				var current := codec.capture(restored)
				current.source_identity = fixture.world.source_identity
				check(current == fixture.world,"Every persisted world/Founder/rights/market/RNG field remains exact")
				check(adapter.capture(player) == fixture.player,"Restoration preserves all player fields")
			var unknown: Dictionary = fixture.world.duplicate(true)
			unknown.source_identity = "unknown-presentation-source"
			check(codec.restore(unknown,fixture.player,player,catalog) == null,"Unknown source still rejects")
			var jointly_wrong: Dictionary = fixture.world.duplicate(true)
			var wrong_player: Dictionary = fixture.player.duplicate(true)
			wrong_player.content_revision = "wrong-rules"
			for row: Dictionary in jointly_wrong.studios: row.run.content_revision = "wrong-rules"
			check(codec.restore(jointly_wrong,wrong_player,player,catalog) == null,"Joint source/rules mismatch rejects")
			var wrong_rival: Dictionary = fixture.world.duplicate(true)
			wrong_rival.studios[0].run.content_revision = "wrong-rules"
			check(codec.restore(wrong_rival,fixture.player,player,catalog) == null,"Rival source/rules mismatch rejects")
			check(fixture == original,"Restore/rejection leaves all input bytes represented exactly")
	var result := {"checks":checks,"failures":failures,"source":Replay.source_identity(),"inputs":inputs}
	FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print(JSON.stringify(result))
	quit(0 if failures==0 else 1)
