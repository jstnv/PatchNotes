extends SceneTree

const Codec := preload("res://scripts/market/rival_world_checkpoint.gd")
const Trial := preload("res://scripts/market/rival_trial.gd")
var checks := 0
var failures := 0

func expect(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(label)

func without_source(world: Dictionary) -> Dictionary:
	var result:=world.duplicate(true)
	result.erase("source_identity")
	return result

func _initialize() -> void:
	await process_frame
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	for label: String in ["actions-before-v3","compiled-v003","long-v003","long-final"]:
		var path: String="res://../docs/codex/findings/campaign-latency-20261025-v1/"+label+".result.json"
		var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
		expect(data.get("ok",false),label+": successful genuine producer")
		var adapter:=StudioCheckpoint.new()
		var player:=adapter.hydrate(data.player)
		expect(player!=null,label+": full player validation/hydration")
		if player==null: continue
		var codec:=Codec.new()
		var world:=codec.restore(data.world,data.player,player,catalog)
		expect(world!=null,label+": full world validation/hydration: "+codec.error)
		if world==null: continue
		expect(adapter.capture(player)==data.player,label+": every player field and RNG is exact")
		expect(without_source(codec.capture(world))==without_source(data.world),label+": every rival/market field and RNG is exact")
		if data.has("next_player"):
			expect(player.complete_productive_action(),"Compiled save's next legal cycle commits")
			expect(world.advance_committed_player_cycle(Trial.policies(world),Trial.ZERO_STEPS).ok,"Compiled save's next rival decisions commit")
			expect(adapter.capture(player)==data.next_player,"Next player outcomes equal the actual old compiled runtime")
			expect(without_source(codec.capture(world))==without_source(data.next_world),"Next rival decisions, outcomes and RNG equal the old compiled runtime")
		var altered: Dictionary=data.world.duplicate(true)
		altered.source_identity="0".repeat(64)
		expect(Codec.new().restore(altered,data.player,adapter.hydrate(data.player),catalog)==null,label+": unknown executable sources still reject")
		altered=data.world.duplicate(true)
		altered.studios[0].run.run.studio_finance.cash_cents="999999"
		expect(Codec.new().restore(altered,data.player,adapter.hydrate(data.player),catalog)==null,label+": tampered rival finance still rejects")
	var report: Dictionary={"ok":failures==0,"checks":checks,"failures":failures}
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(report))
	print(JSON.stringify(report))
	quit(failures)
