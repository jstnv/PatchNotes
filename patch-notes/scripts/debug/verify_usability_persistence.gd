extends SceneTree
const Factory:=preload("res://scripts/simulation/run_factory.gd")
const WorldCodec:=preload("res://scripts/market/rival_world_checkpoint.gd")
var failures:=0
var checks:=0
func _initialize() -> void:_run.call_deferred()
func check(ok:bool,message:String) -> void:
	checks+=1;print("PASS: " if ok else "FAIL: ",message)
	if not ok:failures+=1
func _run() -> void:
	var out:=OS.get_environment("PN_CARD_FRAME_OUTPUT").get_base_dir()
	var input:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg.begins_with("--input="):input=arg.trim_prefix("--input=")
	var adapter:=StudioCheckpoint.new()
	var catalog:RefCounted=root.get_node("CardDatabase").get_development_catalog()
	if not input.is_empty():
		var saved:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(input))
		var run:=adapter.hydrate(saved)
		check(run!=null,"Fresh OS process restores current Trait9/Bank2 save: "+adapter.error)
		if run!=null:check(adapter.capture(run)==saved,"Every saved field and RNG matches in fresh process")
	else:
		var session:RefCounted=Factory.create_fresh_session({"schema_version":1,"studio_id":"usability-cold","studio_name":"Usability Cold","specialty":"action","traits":["family_funding","publisher_connections","resourceful","studio_buzz","graduate","expensive_lease","unknown_name"],"seed":"20261024"},catalog)
		check(session!=null,"Uncapped Trait9 Studio creates through authoritative factory")
		if session!=null:
			var run:RunState=session.run
			check(run.spend_cash_cents(run.get_cash_cents()),"Controlled financial stress fixture spends available cash")
			check(run.complete_productive_action() and run.complete_productive_action(),"Original-due rent becomes overdue")
			var quote:=run.get_bank_quote(9223372036854775807,12)
			check(quote.get("accepted",false) and run.accept_bank_loan(quote),"Native recovery quote commits")
			var saved:=adapter.capture(run)
			check(not saved.is_empty(),"Trait9 and Bank2 strict checkpoint encodes: "+adapter.error)
			if not saved.is_empty():
				var restored:=adapter.hydrate(saved)
				check(restored!=null,"Current checkpoint hydrates: "+adapter.error)
				if restored!=null:check(adapter.capture(restored)==saved,"Current entire saved state/RNG matches")
				FileAccess.open(out.path_join("current-save.json"),FileAccess.WRITE).store_string(JSON.stringify(saved))
	# Retained real P4 compiled-world and earned EXE generation, never relabeled.
	var prior_root:=OS.get_environment("PN_USABILITY_PREVIOUS_ROOT")
	if prior_root.is_empty():
		print("Usability persistence: %d checks, %d failures; external predecessor fixtures not requested"%[checks,failures]);quit(failures);return
	for suffix:String in [".fixture.json",".operator-fixture.json"]:
		var path:=prior_root+"/p4-compiled-world-v1/world-result.json"+suffix
		var fixture:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
		check(adapter.validate(fixture.player).is_empty(),"Actual P4 predecessor validates: "+adapter.error)
		var player:=adapter.hydrate(fixture.player)
		check(player!=null,"Actual P4 player hydrates")
		if player==null:continue
		var captured:=adapter.capture(player);captured.content_revision=fixture.player.content_revision;captured.sequence=fixture.player.sequence
		check(captured==fixture.player,"Every actual prior player field/RNG preserved")
		var codec:=WorldCodec.new()
		var world:=codec.restore(fixture.world,fixture.player,player,catalog)
		check(world!=null,"Actual populated/active P4 world restores: "+codec.error)
		if world!=null:
			var current:=codec.capture(world);current.source_identity=fixture.world.source_identity
			for i in current.studios.size():current.studios[i].run.content_revision=fixture.world.studios[i].run.content_revision
			check(current==fixture.world,"Every prior world/ownership/active hand/RNG preserved")
		var forged:Dictionary=fixture.world.duplicate(true);forged.source_identity="unknown-usability-source"
		check(codec.restore(forged,fixture.player,player,catalog)==null,"Unknown source rejects")
		forged=fixture.world.duplicate(true)
		var forged_player:Dictionary=fixture.player.duplicate(true);forged_player.content_revision=adapter.revision()
		for row:Dictionary in forged.studios:row.run.content_revision=adapter.revision()
		check(codec.restore(forged,forged_player,player,catalog)==null,"Joint false current revision on old source rejects")
	var codec:=CheckpointCodec.new()
	var actual:=codec.open_envelope(FileAccess.get_file_as_string(prior_root+"/actual-p4-1152/actual-later-sales.generation.json"))
	var actual_run:=adapter.hydrate(actual)
	check(actual_run!=null,"Actual P4 release EXE earned generation restores: "+adapter.error)
	if actual_run!=null:
		var saved:=adapter.capture(actual_run);saved.sequence=actual.sequence;saved.content_revision=actual.content_revision
		check(saved==actual,"Actual EXE generation preserves every field/RNG")
	FileAccess.open(out.path_join("persistence-result.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"source":preload("res://scripts/simulation/development_replay.gd").source_identity()}))
	print("Usability persistence: %d checks, %d failures"%[checks,failures]);quit(failures)
