from pathlib import Path
P=Path(__file__).parent/'simulators/rival-quality-1977-20261030-v9/project'
def edit(path,old,new,count=1):
 f=P/path;s=f.read_text(encoding='utf-8');assert old in s,(path,old[:50]);f.write_bytes(s.replace(old,new,count).encode())
job='''## Pure data hydration job. No scene, UI, save writes or live player mutation.
extends RefCounted
var player_payload: Dictionary
var world_payload: Dictionary
var catalog: RefCounted
var player: RunState
var world: RivalWorld
var error:=""
var _task:=-1
func start(payload: Dictionary,definitions: RefCounted,saved_world: Dictionary={}) -> void:
	player_payload=payload.duplicate(true);world_payload=saved_world.duplicate(true)
	catalog=preload("res://scripts/market/rival_opening_loader.gd").copy_catalog(definitions)
	_task=WorkerThreadPool.add_task(_work,false,"Hydrate rival world")
func poll() -> bool:
	if _task<0:return false
	if not WorkerThreadPool.is_task_completed(_task):return false
	WorkerThreadPool.wait_for_task_completion(_task);_task=-2;return true
func _work() -> void:
	var adapter:=StudioCheckpoint.new();player=adapter.hydrate(player_payload)
	if player==null:error=adapter.error;return
	if world_payload.is_empty():
		var loader:=preload("res://scripts/market/rival_opening_loader.gd").new()
		world=loader.create(player,catalog);error=loader.error
	else:
		var codec:=preload("res://scripts/market/rival_world_checkpoint.gd").new()
		world=codec.restore(world_payload,player_payload,player,catalog);error=codec.error
'''
(P/'scripts/persistence/rival_hydration_job.gd').write_bytes(job.encode())
edit('scripts/gameplay.gd','''if not _commit_new_studio(name,specialty,trait_ids,source):
		overlay.free()
		_transition_in_progress = false
		return''','''if not run_state.create_studio_with_traits(name,specialty,trait_ids):
		source.show_error("Enter a valid name and Genre; check the trait balance.")
		overlay.free();_transition_in_progress=false;return
	var job:=preload("res://scripts/persistence/rival_hydration_job.gd").new()
	var player_payload:=StudioCheckpoint.new().capture(run_state)
	job.start(player_payload,checkpoints.rival_catalog)
	while not job.poll():await get_tree().process_frame
	if job.world!=null:
		# Worker owns a detached player. Bind the live one only after joining.
		job.world.player=run_state;job.world.bind_market_providers()
	if not _adopt_new_studio_world(job.world):
		overlay.free();_transition_in_progress=false;return''')
edit('scripts/gameplay.gd','''rival_world = RivalTrial.create_world(run_state,checkpoints.rival_catalog)
	if rival_world == null''','''return _adopt_new_studio_world(RivalTrial.create_world(run_state,checkpoints.rival_catalog))

func _adopt_new_studio_world(world: RivalWorld) -> bool:
	rival_world=world
	if rival_world == null''')
f=P/'scripts/persistence/checkpoint_load.gd';s=f.read_text(encoding='utf-8');s+='''
var _hydrate_job: RefCounted
func advance_async() -> void:
	if done:return
	if stage!=2 or not _candidate.has("rival_world"):
		advance();return
	if _owner.rival_catalog==null:_reject("Rival definitions unavailable for Continue");return
	if _hydrate_job==null:
		_hydrate_job=preload("res://scripts/persistence/rival_hydration_job.gd").new()
		_hydrate_job.start(_player_payload,_owner.rival_catalog,_candidate.rival_world)
		return
	if not _hydrate_job.poll():return
	if _hydrate_job.world==null:
		_reject("Rival world Continue rejected: "+_hydrate_job.error);return
	_run=_hydrate_job.player;_world=_hydrate_job.world;_hydrate_job=null;stage+=1
''';f.write_bytes(s.encode())
edit('scripts/gameplay.gd','operation.advance()\n\t\tif operation.inspected','operation.advance_async()\n\t\tif operation.inspected')
# Exact raw-byte-keyed material proof cache. Metadata can be resealed without
# a circular identity; changes to any material state still change the identity.
edit('scripts/simulation/development_replay.gd','const SCHEMA_VERSION := 1','const SCHEMA_VERSION := 1\nstatic var _opening_proofs: Dictionary={}\nstatic var _opening_lock:=Mutex.new()')
edit('scripts/simulation/development_replay.gd','''var certificate: Variant=JSON.parse_string(FileAccess.get_file_as_string(opening))
		var material: Dictionary=certificate.get("fixture",{}).duplicate(true) if certificate is Dictionary and certificate.get("fixture") is Dictionary else {}
		if material.get("world") is Dictionary:material.world.erase("source_identity")
		rows.append([opening+"@material-v1",var_to_bytes(_canonical_data(material)).hex_encode().sha256_text()])''','''var raw:=FileAccess.get_sha256(opening)
		_opening_lock.lock();var known: Dictionary=_opening_proofs.get(opening,{}).duplicate();_opening_lock.unlock()
		if known.get("raw")!=raw:
			var certificate: Variant=JSON.parse_string(FileAccess.get_file_as_string(opening))
			var material: Dictionary=certificate.get("fixture",{}).duplicate(true) if certificate is Dictionary and certificate.get("fixture") is Dictionary else {}
			if material.get("world") is Dictionary:material.world.erase("source_identity")
			known={"raw":raw,"material":var_to_bytes(_canonical_data(material)).hex_encode().sha256_text()}
			_opening_lock.lock();_opening_proofs[opening]=known.duplicate();_opening_lock.unlock()
		rows.append([opening+"@material-v1",known.material])''')
print('Detached fresh-world hydration and asynchronous Continue market hydration wired; source material cache is exact-byte-keyed.')
