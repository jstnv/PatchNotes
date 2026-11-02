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
	var codec:=StudioCheckpoint.new()
	var base:=codec.hydrate(fixture.player)
	expect(base!=null,"Genuine historical fixture hydrates: "+codec.error)
	if base==null:quit(1);return
	# Pay for a current empty engine; never reinterpret old ownership as free
	# current supply. Both planners receive the same completed setup state.
	var created:=base.create_proprietary_engine(base.get_proprietary_engine_creation_quote("Preflight Engine"))
	expect(created.get("ok",false),"Paid current engine is created")
	if not created.get("ok",false):quit(1);return
	var engine_id: StringName=created.engine_id
	expect(base.select_engine(engine_id),"Current editable engine is selected")
	expect(base.valid_engine_state(),"Historical bindings and paid engine remain coherent")
	var current:=Counted.new();View.copy_fields(base,current)
	var original:=Before.new();View.copy_fields(base,original)
	for candidate in [current,original]:expect(candidate.admit_feature_research(candidate.get_feature_research_quote(&"text",engine_id)),"Ordinary admission creates a head")
	var quote:=current.get_feature_research_quote(&"text",engine_id)
	current.preflights=0
	expect(current.research_feature(quote) and original.research_feature(original.get_feature_research_quote(&"text",engine_id)),"Both real Research transactions succeed")
	expect(current.preflights==1,"One Research commit performs one full productive preflight")
	var current_payload:=codec.capture(current)
	expect(not current_payload.is_empty(),"Current planner outcome validates: "+codec.error)
	var original_payload:=codec.capture(original)
	expect(not original_payload.is_empty(),"Frozen planner outcome validates: "+codec.error)
	expect(not current_payload.is_empty() and not original_payload.is_empty() and var_to_bytes(current_payload)==var_to_bytes(original_payload),"Entire persisted outcome and RNG match the frozen original")
	for id: StringName in [&"4_color_palette",&"8_bit_sound"]:expect(current.admit_feature_research(current.get_feature_research_quote(id,engine_id)),"Queue fixture admits legally")
	var forged:=current.get_feature_research_quote(&"8_bit_sound",engine_id);forged.can_research=true
	var before:=codec.capture(current)
	expect(not current.research_feature(forged) and codec.capture(current)==before,"Forged can_research cannot skip the queue head")
	expect(current.spend_cash_cents(current.get_cash_cents(),&"other_expense",&"private-drain"),"Legal isolated expense creates an unaffordable head")
	forged=current.get_feature_research_quote(&"4_color_palette",engine_id);forged.can_research=true
	before=codec.capture(current)
	expect(not current.research_feature(forged) and codec.capture(current)==before,"Forged can_research cannot bypass cash/sales/bill preflight")
	var report: Dictionary={"ok":failures==0,"checks":checks,"failures":failures}
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(report));print(JSON.stringify(report));quit(1 if failures else 0)
