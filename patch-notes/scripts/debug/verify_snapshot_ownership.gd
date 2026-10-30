extends SceneTree
const WorldCodec=preload("res://scripts/market/rival_world_checkpoint.gd")
const Migration=preload("res://scripts/market/market_save_migration_trial.gd")
var failures:=0
var checks:=0
var development_probes:=0
func expect(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func plain(value:Variant) -> bool:
 if value is Object or value is Callable:return false
 if value is Dictionary:
  for key in value:
   if not plain(key) or not plain(value[key]):return false
 if value is Array:
  for child in value:
   if not plain(child):return false
 return true
func clear_containers(value:Variant) -> void:
 if value is Dictionary:
  if value.is_read_only():return
  for child in value.values():clear_containers(child)
  value.clear()
 elif value is Array:
  if value.is_read_only():return
  for child in value:clear_containers(child)
  value.clear()
func clear_development(session:RefCounted) -> void:
 if session.development==null:return
 development_probes+=1
 var dev:RefCounted=session.development
 for field in WorldCodec.PROJECT_ID_ARRAYS+["_core_scores","_genre_ratios","_market_standards","_market_details"]:clear_containers(dev.project.get(field))
 for field in WorldCodec.HAND_COMMON+["_candidate_cards"]:clear_containers(dev.hand.get(field))
 if dev.phase_index<2:
  clear_containers(dev.hand.get("_available_features"))
  clear_containers(dev.hand.get("_exhausted_card_ids" if dev.phase_index==0 else "_exhausted_feature_ids"))
  if dev.phase_index==1:clear_containers(dev.hand.get("_pending_playtest_categories"))
 else:
  clear_containers(dev.hand.get("injected_candidate_ids"))
  clear_containers(dev.hand.get("_pending_corrective_pass_ids"))
func _initialize() -> void:
 await process_frame
 var catalog:RefCounted=root.get_node("CardDatabase").get_development_catalog()
 for label:String in ["background_checkpoint_v003_c96","queue_migration_pre_alpha_v1"]:
  var path:="res://../tools/fixtures/"+label+".json"
  var provenance:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../tools/fixtures/"+label+".provenance.json"))
  expect(FileAccess.get_sha256(path)==provenance.sha256,label+": genuine fixture hash matches its recorded producer")
  var frame:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
  if label=="queue_migration_pre_alpha_v1":
   var migrated:Dictionary=Migration.new().upgrade_pair(frame.player,frame.world,catalog)
   expect(not migrated.is_empty(),"Named legacy fixture migrates before ownership checks")
   if migrated.is_empty():continue
   frame=migrated
  var adapter:=StudioCheckpoint.new()
  var run:=adapter.hydrate(frame.player)
  var codec:=WorldCodec.new()
  var world:RefCounted=codec.restore(frame.world,frame.player,run,catalog)
  expect(run!=null and world!=null,label+": genuine player/world restore")
  if run==null or world==null:continue
  var player:Dictionary=adapter.snapshot(run)
  var snapshot:Dictionary=codec.snapshot(world)
  expect(codec.snapshot(world,adapter)==snapshot,label+": shared current-revision path preserves every exact value and type")
  expect(not player.is_empty() and not snapshot.is_empty() and plain(player) and plain(snapshot),label+": snapshots contain only detached plain values")
  var player_bytes:=var_to_bytes(player)
  var world_bytes:=var_to_bytes(snapshot)
  clear_containers(player);clear_containers(snapshot)
  expect(var_to_bytes(adapter.snapshot(run))==player_bytes,label+": editing the player DTO cannot change live state")
  expect(var_to_bytes(codec.snapshot(world))==world_bytes,label+": editing the world DTO cannot change live state")
  player=adapter.snapshot(run);snapshot=codec.snapshot(world)
  for owner:RunState in [run]+world.studios.values().map(func(session):return session.run):
   for field in StudioCheckpoint.FIELDS+StudioCheckpoint.SUPPORT_FIELDS:clear_containers(owner.get(field))
  for session in world.studios.values():clear_development(session)
  clear_containers(world.market_snapshot)
  clear_containers(world.market_origin)
  clear_containers(world.historical_archive)
  clear_containers(world.live_releases)
  clear_containers(world.legacy)
  expect(var_to_bytes(player)==player_bytes,label+": live mutations cannot change the detached player DTO")
  expect(var_to_bytes(snapshot)==world_bytes,label+": live market/archive/rival/development/legacy mutations cannot change the detached world DTO")
  run._market_provider=Callable()
  for session in world.studios.values():session.run._market_provider=Callable()
 expect(development_probes>0,"Active development project and hand containers were mutated in the live-to-DTO check")
 print("SNAPSHOT_OWNERSHIP checks=%d failures=%d"%[checks,failures])
 quit(failures)
