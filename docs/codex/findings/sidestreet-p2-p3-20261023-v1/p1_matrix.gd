extends SceneTree
const WorldCodec := preload("res://scripts/market/rival_world_checkpoint.gd")
var checks: Array = []
func check(ok: bool, label: String) -> void:
	checks.append({"pass":ok,"check":label});print("PASS: " if ok else "FAIL: ",label)
func _initialize() -> void: execute.call_deferred()
func old_shape(payload: Dictionary, original: Dictionary) -> Dictionary:
	var shape := payload.duplicate(true)
	shape.run.erase("sidestreet_briefs");shape.run.erase("commission_deals")
	shape.content_revision=original.content_revision
	return shape
func execute() -> void:
	var args := OS.get_cmdline_user_args()
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var adapter := StudioCheckpoint.new()
	for name in ["current-legacy.frame.json","current-world-cold.frame.json","native-export-audited.frame.json","native-export-founder-audited.frame.json"]:
		var path: String=args[0]+"/"+name
		var hash_before := FileAccess.get_sha256(path)
		var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
		var run:=adapter.hydrate(old.player)
		check(run!=null,"retained actual P1 player hydrates: "+name+" "+adapter.error)
		if run==null:continue
		var current:=adapter.capture(run)
		check(old_shape(current,old.player)==old.player and run._sidestreet_briefs.is_empty() and run._commission_deals.is_empty(),"old P1 finance/employees/ownership/RNG exact; no backfill: "+name)
		var codec:=WorldCodec.new()
		var world:=codec.restore(old.world,old.player,run,catalog)
		check(world!=null,"retained P1 world including active rivals/Founder restores: "+name+" "+codec.error)
		if world==null:continue
		var restored: Dictionary=codec.capture(world)
		var projection:=restored.duplicate(true)
		projection.source_identity=old.world.source_identity
		for i in range(projection.studios.size()):projection.studios[i].run=old_shape(projection.studios[i].run,old.world.studios[i].run)
		check(projection==old.world,"every old world field including active projects and cap tables survives: "+name)
		for i in range(old.world.studios.size()):
			var row: Dictionary=old.world.studios[i]
			var active: bool=row.development!=null
			if not active:continue
			var previous:=StudioCheckpoint.CommissionPrevious.new()
			var native: Dictionary=previous._decode_payload(row.run,true)
			for kind: StringName in [&"sidestreet_brief_completion_v1",&"sidestreet_commission_completion_v1",&"unknown"]:
				var bad:=native.duplicate(true)
				bad.run.publisher_relationships.events.append({"ordinal":1,"event_id":&"forged:event","source_id":&"renamed:source","publisher_id":&"sidestreet","kind":kind,"cycle":0,"requested_reputation_bp":0,"requested_investment_bp":0,"credited_reputation_bp":0,"credited_investment_bp":0})
				var encoded: Dictionary=CheckpointCodec.new().encode(bad,StudioCheckpoint.CommissionPrevious.PreviousCommissionSchema.root(true,true))
				check(not adapter.validate_active_rival(encoded).is_empty(),"dormant actual P1 active rival rejects typed fake source cleanly: "+str(kind))
		check(FileAccess.get_sha256(path)==hash_before,"retained P1 disk artifact unchanged: "+name)
	var failures:=checks.filter(func(row: Dictionary) -> bool:return not row["pass"]).size()
	FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	quit(0 if failures==0 else 1)
