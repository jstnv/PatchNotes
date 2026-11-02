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
	var payload: Dictionary=pair.player.duplicate(true)
	payload.rival_world=pair.world.duplicate(true)
	var validator:=CountingValidator.new()
	validator.rival_catalog=root.get_node("CardDatabase").get_development_catalog()
	validator._publishing_source_identity=load("res://scripts/simulation/development_replay.gd").source_identity()
	# Only presentation/cache code differs from this known, genuine fixture.
	payload.rival_world.source_identity=validator._publishing_source_identity
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
	before=validator.calls
	validator._validate_payload(next)
	check(validator.calls==before+1,"Catalog mutation cannot inherit a progress proof")
	card.scope=old_scope
	print("AWARDS_VALIDATION checks=%d failures=%d full_calls=%d full_ms=%s"%[checks,failures,validator.calls,str(validator.timings)])
	quit(1 if failures else 0)
