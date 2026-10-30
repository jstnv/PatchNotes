extends SceneTree

const Codec := preload("res://scripts/market/rival_world_checkpoint.gd")
const Trial := preload("res://scripts/market/rival_trial.gd")
var checks := 0
var failures := 0

func expect(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(label)

func before_era_player(current: Dictionary, prior: Dictionary) -> Dictionary:
	var result := current.duplicate(true)
	var adapter := StudioCheckpoint.new()
	var decoded := adapter._decode_payload(current,current.checkpoint_kind=="rival_active")
	expect(not decoded.is_empty() and current.content_revision == adapter.revision(), "Current strict schema validates before historical comparison")
	if decoded.is_empty(): return {}
	expect(decoded.run.store_era_receipts == RunState.StoreEra.from_releases(decoded.run.release_metadata) and not prior.run.has("store_era_receipts"), "Only justified era receipts are new in this exact predecessor")
	result.run.erase("store_era_receipts")
	result.content_revision = prior.content_revision
	return result

func before_era_world(current: Dictionary, prior: Dictionary) -> Dictionary:
	var result := current.duplicate(true)
	result.erase("source_identity")
	expect(result.studios.size()==prior.studios.size(), "Same historical rival roster")
	for index in mini(result.studios.size(),prior.studios.size()):
		result.studios[index].run=before_era_player(result.studios[index].run,prior.studios[index].run)
	return result

func without_source(world: Dictionary) -> Dictionary:
	var result := world.duplicate(true)
	result.erase("source_identity")
	return result

func _initialize() -> void:
	# Frozen pre-hold next-action oracle; normal Insider default stays disabled.
	ProjectSettings.set_setting("gameplay/beta/insider_enabled",true)
	await process_frame
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var fixture := OS.get_environment("PN_LATENCY_PRIOR_SAVES")
	if fixture.is_empty(): fixture = "res://../tools/fixtures/latency_restore_pre_store_era_v1.json"
	var fixtures: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(fixture))
	for label: String in ["actions-before-v3","compiled-v003","long-v003","long-final"]:
		var data: Dictionary=fixtures[label]
		expect(data.get("ok",false),label+": successful genuine producer")
		var adapter:=StudioCheckpoint.new()
		var player:=adapter.hydrate(data.player)
		expect(player!=null,label+": full player validation/hydration")
		if player==null: continue
		var codec:=Codec.new()
		var world:=codec.restore(data.world,data.player,player,catalog)
		expect(world!=null,label+": full world validation/hydration: "+codec.error)
		if world==null: continue
		expect(before_era_player(adapter.capture(player),data.player)==data.player,label+": every player field and RNG is exact")
		expect(before_era_world(codec.capture(world),data.world)==without_source(data.world),label+": every rival/market field and RNG is exact")
		if data.has("next_player"):
			expect(player.complete_productive_action(),"Compiled save's next legal cycle commits")
			expect(world.advance_committed_player_cycle(Trial.policies(world),Trial.ZERO_STEPS).ok,"Compiled save's next rival decisions commit")
			expect(before_era_player(adapter.capture(player),data.next_player)==data.next_player,"Next player outcomes equal the actual old compiled runtime")
			var actual_next := codec.capture(world)
			var second_player := adapter.hydrate(data.player)
			var second_world: RefCounted=Codec.new().restore(data.world,data.player,second_player,catalog)
			expect(second_player!=null and second_world!=null,"Independent old-world continuation restores")
			if second_world!=null:
				second_player.complete_productive_action()
				second_world.advance_committed_player_cycle(Trial.policies(second_world),Trial.ZERO_STEPS)
				expect(codec.capture(second_world)==actual_next,"Complete current next-world outcomes and RNG repeat exactly")
			if label=="long-v003":
				# The approved prospective 1.25 Balanced reward makes this frozen
				# eight-point Pass hand10→3/3/2/2 instead of the old2/2/2/2.
				# Guard the exact old/new boundary, then project only those two points
				# from a detached comparison copy; raw current equality is above.
				var current_scores: Array=actual_next.studios[1].development.project._core_scores
				var prior_scores: Array=data.next_world.studios[1].development.project._core_scores
				expect(actual_next.cycle=="97" and actual_next.studios[1].id=="incumbent-wayfinder-works" and current_scores.map(func(row):return row.value)==["26","15","19","20"] and prior_scores.map(func(row):return row.value)==["25","14","19","20"],"Only the documented eight→ten Balanced total differs from this historical next-action oracle")
				actual_next=actual_next.duplicate(true)
				for index in [0,1]:actual_next.studios[1].development.project._core_scores[index].value=str(int(current_scores[index].value)-1)
			expect(before_era_world(actual_next,data.next_world)==without_source(data.next_world),"Historical next-world fields/RNG match after explicit prospective Balanced reward projection")
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
