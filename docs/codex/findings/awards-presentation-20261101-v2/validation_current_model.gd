extends SceneTree
class CountingValidator extends "res://scripts/persistence/checkpoint_write_validator.gd":
	var calls := 0
	var timings: Array = []
	func _validate_uncached(payload: Dictionary) -> String:
		calls+=1
		var start:=Time.get_ticks_msec()
		var result:=super._validate_uncached(payload)
		timings.append(Time.get_ticks_msec()-start)
		return result
var failures := 0
var checks := 0
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize() -> void:
	await process_frame
	var pair: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_AWARDS_UI_FIXTURE")))
	var adapter:=StudioCheckpoint.new()
	var live_catalog=root.get_node("CardDatabase").get_development_catalog()
	var run:=adapter.hydrate(pair.player)
	var codec=load("res://scripts/market/rival_world_checkpoint.gd").new()
	var world=codec.restore(pair.world,pair.player,run,live_catalog)
	check(run!=null and world!=null,"Genuine predecessor migrates under the current approved Engine model")
	if world==null:quit(1);return
	var payload: Dictionary=adapter.capture(run)
	payload["rival_world"]=codec.capture(world)
	var validator:=CountingValidator.new()
	validator.rival_catalog=root.get_node("CardDatabase").get_development_catalog()
	validator._publishing_source_identity=load("res://scripts/simulation/development_replay.gd").source_identity()
	check(payload.rival_world.source_identity==validator._publishing_source_identity,"Current typed payload uses its actual executing source")
	check(validator._validate_payload(payload).is_empty(),"Initial world is fully validated")
	check(validator.calls==1,"Unknown world performs full validation")
	var next:=payload.duplicate(true)
	next.sequence="2"
	next.rival_world.annual_awards.entries[0].stage="1"
	check(validator._validate_payload(next).is_empty(),"Legal saved presentation advance validates")
	check(validator.calls==1,"Presentation-only advance reuses exact gameplay proof")
	var bad:=next.duplicate(true)
	bad.rival_world.annual_awards.entries[0].stage="10"
	check(not validator._validate_payload(bad).is_empty(),"Out-of-range presentation stage rejects")
	bad=next.duplicate(true);bad.rival_world.annual_awards.entries[0].complete=true
	check(not validator._validate_payload(bad).is_empty(),"Completion below final stage rejects")
	bad=next.duplicate(true);bad.rival_world.annual_awards.entries[0].stage=1
	check(not validator._validate_payload(bad).is_empty(),"Noncanonical stage type rejects")
	bad=next.duplicate(true);bad.run.cash_cents=str(int(bad.run.cash_cents)+1)
	var before:=validator.calls
	check(not validator._validate_payload(bad).is_empty() and validator.calls==before+1,"Cash mutation cannot inherit presentation proof")
	bad=next.duplicate(true);bad.rival_world.annual_awards.entries[0].result.awards[0].nominees[0].score="999999"
	before=validator.calls
	check(not validator._validate_payload(bad).is_empty() and validator.calls==before+1,"Frozen ranking mutation cannot inherit presentation proof")
	var final:=next.duplicate(true);final.rival_world.annual_awards.entries[0].stage="9";final.rival_world.annual_awards.entries[0].complete=true
	before=validator.calls
	check(validator._validate_payload(final).is_empty() and validator.calls==before,"Valid completion preserves exact immutable world proof")
	for path in [["rng",0,"value","state"],["rival_world","studios",0,"run","rng",0,"value","state"],["rival_world","studios",0,"offset"],["rival_world","studios",0,"policy","search_done"],["rival_world","annual_awards","entries",0,"owners",0,"offset"],["rival_world","annual_awards","entries",0,"result","rewards",0,"fans"],["rival_world","source_identity"],["content_revision"]]:
		bad=next.duplicate(true)
		var parent: Variant=bad
		for key in path.slice(0,-1):parent=parent[key]
		var key: Variant=path[-1]
		var value: Variant=parent[key]
		parent[key]=not value if value is bool else str(int(value)+1) if str(value).is_valid_int() else str(value)+"-changed"
		before=validator.calls
		var cached_reason:=validator._validate_payload(bad)
		check(validator.calls==before+1,"Changed protected state cannot inherit a progress proof: "+str(path))
		check(cached_reason==validator._validate_uncached(bad),"Fallback agrees with full validation: "+str(path))
	var card: CardData=validator.rival_catalog.cards.values()[0]
	var old_scope:=card.scope
	card.scope+=1
	var fresh:=CountingValidator.new()
	fresh.rival_catalog=live_catalog
	fresh._publishing_source_identity=validator._publishing_source_identity
	fresh._validate_payload(next)
	check(fresh.calls==1,"Changed catalog in a fresh worker cannot inherit a previous worker proof")
	card.scope=old_scope
	var binding:=CheckpointCoordinator.new();root.add_child(binding)
	binding.attach(run)
	check(binding.attach_rivals(world,live_catalog),"Writer binds its own detached catalog")
	var detached: RefCounted=binding._write_catalog
	var detached_card: CardData=detached.cards[card.id]
	check(detached_card!=card and detached_card.scope==old_scope,"Writer definition is a distinct value copy")
	card.scope+=1
	check(detached_card.scope==old_scope,"Live catalog mutation cannot leak into an existing writer")
	check(binding.attach_rivals(world,live_catalog),"Later attachment produces a new writer catalog")
	check(binding._write_catalog!=detached and binding._write_catalog.cards[card.id].scope==card.scope and detached_card.scope==old_scope,"Rebind replaces the catalog and preserves the in-flight reference")
	card.scope=old_scope
	binding.free()
	print("AWARDS_VALIDATION_CURRENT_MODEL checks=%d failures=%d full_calls=%d full_ms=%s"%[checks,failures,validator.calls,str(validator.timings)])
	quit(1 if failures else 0)
