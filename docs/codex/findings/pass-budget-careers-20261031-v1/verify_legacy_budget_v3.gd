extends SceneTree
const Codec=preload("res://scripts/market/rival_world_checkpoint.gd")
const Replay=preload("res://scripts/simulation/development_replay.gd")
var checks:=0
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func existing_equal(old: Variant,current: Variant) -> bool:
	if old is Dictionary:
		if not current is Dictionary:return false
		for key: Variant in old:
			if key=="content_revision":continue # Explicit validated calendar/Engine schema migration.
			if not current.has(key) or not existing_equal(old[key],current[key]):return false
		return true
	if old is Array:
		if not current is Array or current.size()!=old.size():return false
		for index in range(old.size()):
			if not existing_equal(old[index],current[index]):return false
		return true
	return old==current
func _initialize() -> void:
	await process_frame
	var args:=OS.get_cmdline_user_args();var input: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]));var original:=JSON.stringify(input)
	if input.has("payload_utf8"):
		var opened:=CheckpointCodec.new().open_envelope(JSON.stringify(input));var p:=opened.duplicate(true);p.erase("rival_world");input={"player":p,"world":opened.rival_world};original=JSON.stringify(input)
	var codec:=Codec.new();var adapter:=StudioCheckpoint.new()
	for origin: String in codec.STUDIO_MANAGEMENT_PREDECESSORS+codec.RIVAL_POOL_PREDECESSORS+codec.MARKET_HISTORY_PREDECESSORS:
		check(codec._known_budget_origin(origin),"Retain exact previously admitted origin "+origin)
	check(not codec._known_budget_origin("unapproved-source"),"Unknown legacy origin still rejected")
	var player:=adapter.hydrate(input.player)
	check(player!=null,"Genuine archived-source player hydrates")
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var world:=codec.restore(input.world,input.player,player,catalog)
	check(world!=null,"Genuine BF active-project world hydrates: "+codec.error)
	if world!=null:
		var saved:=codec.capture(world);var comparison:=saved.duplicate(true);comparison.source_identity=input.world.source_identity
		check(existing_equal(input.world,comparison),"Every old active hand/token, score, finance/history/roster and RNG field preserved")
		check(existing_equal(input.player,adapter.capture(player)),"Player gameplay fields preserved across explicit schema revision")
		var active:=0
		for id: StringName in world.studios:
			var owner: RefCounted=world.studios[id]
			if owner.in_studio:continue
			active+=1;var budget: Dictionary=owner.development.pass_budget_state()
			check(budget=={"version":0,"origin":input.world.source_identity,"printed":0,"spent":0},"Explicit project legacy version/origin without invented past counts")
			if owner.development.phase_index<2:check(owner.development.hand.pass_budget_available()==7,"Legacy active-project rules retained until exit")
		check(active>0,"Authentic predecessor fixture contains active projects")
		var p:=adapter.capture(player);var cold_player:=adapter.hydrate(JSON.parse_string(JSON.stringify(p)))
		var cold:=codec.restore(JSON.parse_string(JSON.stringify(saved)),p,cold_player,catalog)
		check(cold!=null and codec.capture(cold)==saved,"Migrated current snapshot round trips exactly")
	check(JSON.stringify(input)==original,"Original archived payload untouched")
	FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"source":Replay.source_identity()},"\t"));print("LEGACY_BUDGET ",checks," failures=",failures.size());quit(0 if failures.is_empty() else 1)
