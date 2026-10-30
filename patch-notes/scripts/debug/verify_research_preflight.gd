extends SceneTree
const Before:=preload("res://scripts/debug/fixtures/store_before_research_latency.gd")
const View:=preload("res://scripts/simulation/transaction_projection.gd")
var checks:=0
var failures:=0
class Counted extends RunState:
	var preflights:=0
	func _plan_productive_cycle(delta: int,campaign: StringName=&"",kind: StringName=&"",source: StringName=&"")->Dictionary:
		preflights+=1
		return super._plan_productive_cycle(delta,campaign,kind,source)
func expect(ok: bool,label: String)->void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+label)
func _initialize()->void:
	await process_frame
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../tools/fixtures/background_checkpoint_v003_c96.json"))
	var base:=StudioCheckpoint.new().hydrate(fixture.player)
	var current:=Counted.new();View.copy_fields(base,current)
	var original:=Before.new();View.copy_fields(base,original)
	for candidate in [current,original]:expect(candidate.admit_feature_research(candidate.get_feature_research_quote(&"secrets")),"Ordinary admission creates a head")
	var quote:=current.get_feature_research_quote(&"secrets")
	current.preflights=0
	expect(current.research_feature(quote) and original.research_feature(original.get_feature_research_quote(&"secrets")),"Both real Research transactions succeed")
	expect(current.preflights==1,"One Research commit performs one full productive preflight")
	var codec:=StudioCheckpoint.new()
	expect(var_to_bytes(codec.capture(current))==var_to_bytes(codec.capture(original)),"Entire persisted outcome and RNG match the frozen original")
	for id: StringName in [&"character_backstories",&"dialogue"]:expect(current.admit_feature_research(current.get_feature_research_quote(id)),"Queue fixture admits legally")
	var forged:=current.get_feature_research_quote(&"dialogue");forged.can_research=true
	var before:=codec.capture(current)
	expect(not current.research_feature(forged) and codec.capture(current)==before,"Forged can_research cannot skip the queue head")
	expect(current.spend_cash_cents(current.get_cash_cents(),&"other_expense",&"private-drain"),"Legal isolated expense creates an unaffordable head")
	forged=current.get_feature_research_quote(&"character_backstories");forged.can_research=true
	before=codec.capture(current)
	expect(not current.research_feature(forged) and codec.capture(current)==before,"Forged can_research cannot bypass cash/sales/bill preflight")
	var report: Dictionary={"ok":failures==0,"checks":checks,"failures":failures}
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(report));print(JSON.stringify(report));quit(1 if failures else 0)
