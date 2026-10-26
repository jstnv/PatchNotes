extends RefCounted

## Worker-owned semantic validation; never accesses the SceneTree or live Run.
var adapter := StudioCheckpoint.new()
var rival_catalog: RefCounted
var _publishing_source_identity := ""
var _migration_input := ""
var _migration_output: Dictionary = {}

func _validate_payload(payload: Dictionary) -> String:
	var candidate := _market_compatible_payload(payload)
	if candidate.is_empty(): return "Invalid pre-market migration payload"
	if not candidate.has("rival_world"): return adapter.validate(candidate)
	if not candidate.rival_world is Dictionary: return "Malformed rival world field"
	var player_payload := candidate.duplicate(true)
	player_payload.erase("rival_world")
	var restored := adapter.hydrate(player_payload)
	if restored==null: return adapter.error
	if rival_catalog==null: return "Rival definitions unavailable for validation"
	var codec: RefCounted=load("res://scripts/market/rival_world_checkpoint.gd").new()
	if codec.restore(candidate.rival_world,player_payload,restored,rival_catalog,_publishing_source_identity)==null: return codec.error
	return ""

func _market_compatible_payload(payload: Dictionary) -> Dictionary:
	if payload.get("content_revision")==adapter.revision(): return payload.duplicate(true)
	var key:=JSON.stringify(payload).sha256_text()
	if key==_migration_input and not _migration_output.is_empty(): return _migration_output.duplicate(true)
	var migration: RefCounted=load("res://scripts/market/market_save_migration_trial.gd").new()
	if not payload.has("rival_world"):
		var player_only: Dictionary=migration.upgrade_store_player(payload)
		if not player_only.is_empty() and migration.error.is_empty():
			_migration_input=key;_migration_output=player_only.duplicate(true)
		return player_only
	if not payload.rival_world is Dictionary or payload.rival_world.has("market"): return payload.duplicate(true)
	var player := payload.duplicate(true)
	player.erase("rival_world")
	var upgraded: Dictionary=migration.upgrade_pair(player,payload.rival_world,rival_catalog)
	if upgraded.is_empty(): return {}
	var combined: Dictionary=upgraded.player
	combined.rival_world=upgraded.world
	_migration_input=key;_migration_output=combined.duplicate(true)
	return combined

