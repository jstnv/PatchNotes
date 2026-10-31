extends RefCounted

## Worker-owned semantic validation; never accesses the SceneTree or live Run.
var adapter := StudioCheckpoint.new()
var rival_catalog: RefCounted
var _publishing_source_identity := ""
var _migration_input := ""
var _migration_output: Dictionary = {}

func _validate_uncached(payload: Dictionary) -> String:
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


## Bounded exact positive predicate proofs for already-validated generations.
## Unknown/mutated DTOs still run the full validator; no native objects, failed
## predicates or migrations are stored. Worker catalogs are detached/immutable.
const Replay:=preload("res://scripts/simulation/development_replay.gd")
const BaseCatalog:=preload("res://scripts/simulation/development_catalog.gd")
const PROOF_LIMIT:=3
const PROOF_BYTES:=32*1024*1024
static var _proofs: Array[PackedByteArray]=[]
static var _proof_bytes:=0
static var _proof_mutex:=Mutex.new()
func _validate_payload(payload: Dictionary) -> String:
	if rival_catalog==null or rival_catalog.get_script()!=BaseCatalog or adapter.get_script()!=preload("res://scripts/persistence/studio_checkpoint.gd"):return _validate_uncached(payload)
	var source:=Replay.source_identity() if _publishing_source_identity.is_empty() else _publishing_source_identity
	var data_revision: String=adapter._rules_revision(adapter.RULES)
	if payload.get("content_revision")!=data_revision or not payload.get("rival_world") is Dictionary or payload.rival_world.get("source_identity")!=source:return _validate_uncached(payload)
	var generation:=CheckpointCodec.new()
	var sequence: Variant=generation.integer(payload.get("sequence"))
	if not generation.error.is_empty() or sequence<1 or sequence>RunState.MAX_SIGNED_INT:return _validate_uncached(payload)
	var identity: Dictionary=payload.duplicate();identity.sequence="1"
	var catalog_identity:=_catalog_content()
	var script: Script=get_script()
	var key:=var_to_bytes([script.get_instance_id(),script.get_source_code().sha256_text(),source,data_revision,_publishing_source_identity,catalog_identity,identity])
	_proof_mutex.lock();var index:=_proofs.find(key)
	if index>=0:
		_proofs.remove_at(index);_proofs.append(key);_proof_mutex.unlock();return ""
	_proof_mutex.unlock()
	var reason:=_validate_uncached(payload)
	if not reason.is_empty() or key.size()>PROOF_BYTES:return reason
	_proof_mutex.lock()
	if not _proofs.has(key):_proofs.append(key);_proof_bytes+=key.size()
	while _proofs.size()>PROOF_LIMIT or _proof_bytes>PROOF_BYTES:_proof_bytes-=_proofs.pop_front().size()
	_proof_mutex.unlock();return ""

func _catalog_content() -> PackedByteArray:
	var definitions: Dictionary={}
	for id: StringName in rival_catalog.cards:
		var card: CardData=rival_catalog.cards[id];var fields: Dictionary={}
		for property: Dictionary in card.get_property_list():
			if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:fields[property.name]=card.get(property.name)
		definitions[id]=fields
	var primitive: Array=[]
	for card: CardData in rival_catalog.primitive:primitive.append(card.id)
	return var_to_bytes([definitions,primitive])
