extends SceneTree
const Codec:=preload("res://scripts/market/rival_world_checkpoint.gd")
const Index:=preload("res://queries/market_release_index.gd")
const Migration:=preload("res://scripts/market/market_save_migration_trial.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error("Queue migration: "+label)

func pre_market_fields(value: Variant) -> Variant:
	if value is Array: return value.map(pre_market_fields)
	if value is Dictionary:
		var result := {}
		for key in value:
			if key=="store_era_receipts":
				var decoder := CheckpointCodec.new()
				var metadata: Variant=decoder.decode(value.release_metadata,CheckpointSchema.map_of("id",CheckpointSchema.metadata()))
				check(decoder.error.is_empty() and metadata is Dictionary,"Current frozen release facts strictly decode before migration projection")
				var receipts: Variant=decoder.decode(value[key],{"version":"uint","assignments":CheckpointSchema.map_of("uint","id")})
				check(decoder.error.is_empty() and metadata is Dictionary and receipts==RunState.StoreEra.from_releases(metadata),"Only fully justified era receipts are added by historical migration")
				continue
			if key=="contract_search":
				check(value[key].get("version")=="1" and value[key].get("receipts",[]).is_empty() and value[key].get("offers",[]).is_empty() and value[key].get("intro_offer_id","").is_empty(),"Historical migration adds no Search activity")
				continue
			if key in ["commission_deals", "sidestreet_briefs","support_deals","support_rights","support_assessments"]:
				check(value[key] is Array and value[key].is_empty(), "Historical comparison permits only empty prospective P2/P3 fields")
				continue
			if key in ["source_identity","content_revision","market_factors","_market_standards","_market_snapshot_id","_market_details","market","market_origin","publisher_relationships"]: continue
			result[key]=pre_market_fields(value[key])
		return result
	return value
func _initialize() -> void:
	await process_frame
	var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_OLD_WORLD_FRAME")))
	var adapter:=StudioCheckpoint.new()
	var codec:=Codec.new()
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var original_digest := preload("res://scripts/simulation/development_replay.gd").digest(old)
	var migration := Migration.new()
	var upgraded := migration.upgrade_pair(old.player,old.world,catalog)
	check(not upgraded.is_empty(),"actual prior source passes original schema then named market migration: "+migration.error)
	if upgraded.is_empty(): quit(failures);return
	var player:=adapter.hydrate(upgraded.player)
	check(player!=null,"actual prior-source player checkpoint: "+adapter.error)
	var world:=codec.restore(upgraded.world,upgraded.player,player,catalog)
	check(world!=null,"actual prior-source active rival/Founder v1 world: "+codec.error)
	if world!=null:
		for owner: RunState in preload("res://scripts/legacy/legacy_world.gd").runs(world).values():
			check(owner._publisher_relationships==RunState.RelationshipLedger.create(owner._bank_run_id),"prospective P1 migration adds only an empty Studio-owned relationship ledger")
			check(owner._commission_deals == {} and owner._sidestreet_briefs == {}, "Prospective P2/P3 migration adds no deals or Briefs")
			check(owner._support_deals == {} and owner._support_rights == {} and owner._support_assessments == {}, "Prospective P4 migration adds no Support activity")
		var now:=codec.capture(world)
		check(now.legacy==old.world.legacy,"no retroactive victory activation or rewards")
		check(now==upgraded.world,"approved migrated world roundtrips every current field")
		check(pre_market_fields(now)==pre_market_fields(old.world),"all prior rival state/RNG/finance/hands survive; only explicit market/source provenance is new")
		check(adapter.capture(world.player)==upgraded.player and pre_market_fields(upgraded.player)==pre_market_fields(old.player),"player cash/history/RNG unchanged through named upgrade")
		check(Index.query(world).ok,"query accepts restored older world")
		var bad: Dictionary=old.world.duplicate(true);bad.source_identity="unapproved"
		check(codec.restore(bad,old.player,adapter.hydrate(old.player),catalog)==null,"unknown source still rejected")
		bad=old.player.duplicate(true);bad.content_revision="unapproved"
		check(adapter.hydrate(bad)==null,"unknown catalog still rejected")
	check(preload("res://scripts/simulation/development_replay.gd").digest(old)==original_digest,"input fixture bytes/state are not rewritten")
	print("QUEUE_MIGRATION checks=%d failures=%d"%[checks,failures]);quit(failures)
