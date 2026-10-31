from pathlib import Path
P=Path(__file__).parent/'simulators/rival-quality-1977-20261030-v14/project'
f=P/'scripts/persistence/studio_checkpoint.gd';s=f.read_text(encoding='utf-8');assert 'VALIDATION_PROOF_BYTES := 8 * 1024 * 1024' in s;s=s.replace('VALIDATION_PROOF_BYTES := 8 * 1024 * 1024','VALIDATION_PROOF_BYTES := 32 * 1024 * 1024',1);f.write_bytes(s.encode())
f=P/'scripts/market/rival_world_checkpoint.gd';s=f.read_text(encoding='utf-8')
marker='func _read(payload: Dictionary, player_payload: Dictionary, captured_source_identity: String = "") -> Dictionary:';assert marker in s
s=s.replace(marker,'func _read_checked(payload: Dictionary, player_payload: Dictionary, captured_source_identity: String = "") -> Dictionary:',1)
s=s.replace('adapter._decode_payload(', '_decode_run(adapter,')
s=s.replace('StudioCheckpoint.new()._decode_payload(', '_decode_run(StudioCheckpoint.new(),')
s+='''
## Scoped read-only decode reuse. Never retained across reads or exposed as a
## mutable global DTO. Every semantic predicate still executes as before.
var _decode_scope:=false
var _decoded_runs: Dictionary={}
func _read(payload: Dictionary,player_payload: Dictionary,captured_source_identity: String="") -> Dictionary:
	_decoded_runs.clear();_decode_scope=true
	var result:=_read_checked(payload,player_payload,captured_source_identity)
	_decode_scope=false;_decoded_runs.clear();return result
func _decode_run(adapter: StudioCheckpoint,payload: Dictionary,active: bool=false) -> Dictionary:
	if not _decode_scope:return adapter._decode_payload(payload,active)
	var key:=var_to_bytes([payload,active])
	if _decoded_runs.has(key):adapter.error="";return _decoded_runs[key]
	var native:=adapter._decode_payload(payload,active)
	if not native.is_empty():_decoded_runs[key]=native
	return native
''';f.write_bytes(s.encode())
f=P/'scripts/persistence/checkpoint_write_validator.gd';s=f.read_text(encoding='utf-8');marker='func _validate_payload(payload: Dictionary) -> String:';assert marker in s
s=s.replace(marker,'func _validate_uncached(payload: Dictionary) -> String:',1)
s+='''
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
	var source:=Replay.source_identity()
	if payload.get("content_revision")!=adapter.revision() or not payload.get("rival_world") is Dictionary or payload.rival_world.get("source_identity")!=source:return _validate_uncached(payload)
	var catalog_identity:=Replay.digest(rival_catalog)
	var script: Script=get_script()
	var key:=var_to_bytes([script.get_instance_id(),script.get_source_code().sha256_text(),source,adapter.revision(),_publishing_source_identity,catalog_identity,payload])
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
''';f.write_bytes(s.encode())
(P/'export_presets.cfg').write_bytes((P.parents[1]/'rival-quality-1977-20261030-v13/project/export_presets.cfg').read_bytes())
print('Bounded exact predicate proofs + per-read decode reuse; no gameplay/finance validation removed.')
