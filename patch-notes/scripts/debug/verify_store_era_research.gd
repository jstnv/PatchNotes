extends SceneTree
const Fixture := preload("res://scripts/debug/store_era_test_fixtures.gd")
const Fence := preload("res://scripts/simulation/transaction_projection.gd")
var failures:=0
var checks:=0
func _initialize() -> void: _run.call_deferred()
func expect(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;print("FAIL: ",label)
func acquire(run: RunState,id: StringName) -> bool:
	var graph:=FeatureStoreCatalog.graph(run._feature_definitions,run._feature_offers)
	var order:Array=FeatureStoreCatalog.ordered_ancestors([id],graph.parents).order
	for target: StringName in order:
		if run.owns_feature(target):continue
		var quote:=run.get_feature_research_quote(target)
		if not quote.can_admit or not run.admit_feature_research(quote):expect(false,"Admit funded prerequisite "+str(target));return false
		if not run.research_feature(run.get_feature_research_quote(target)):expect(false,"Complete funded prerequisite "+str(target));return false
	return true
func advance(run: RunState,cycle: int) -> void:
	while run.get_completed_run_cycles()<cycle:
		if not run.complete_productive_action():expect(false,"Funded checked date advance");return
func _run() -> void:
	var run:=RunState.new();run.initialize_cash_cents(0)
	run.create_studio_with_traits("Era Research",&"action",[]);run.finalize_starter_selection()
	expect(run.add_cash(1000000),"Explicitly funded mechanics fixture, not a solvency claim")
	for id in [&"save_files",&"levels",&"exploration",&"power_ups",&"character_backstories",&"controls",&"character_development"]:
		if not acquire(run,id):quit(1);return
	var adapter:=StudioCheckpoint.new()
	var original:=PrimitivePredevelopment.prepare_project("Frozen before unlock",&"action",&"fantasy",run)
	var supply:=original.get_feature_supply_ids().duplicate()
	# Actual atomic release publication, with explicit frozen Scope fixture.
	expect(run.register_release(Fixture.release(30)),"Qualifying committed release earns an early receipt")
	expect(not run.get_store_era_status(1984).eligible and not run.get_store_era_status(1984).receipt_id.is_empty(),"Receipt is banked, never advances year")
	var dates:Dictionary={&"player_level_editor":72,&"ability_gated_exploration":144,&"switchable_protagonists":168,&"character_skill_checks":192}
	for id: StringName in dates:
		advance(run,int(dates[id])-1)
		var before:=Fence.authority(run)
		var quote:=run.get_feature_research_quote(id)
		expect(not quote.can_admit and not run.admit_feature_research(quote) and before==Fence.authority(run),"Exact preceding year boundary rejects atomically: "+str(id))
		advance(run,int(dates[id]))
		quote=run.get_feature_research_quote(id)
		expect(quote.can_admit and quote.base_cents==170000 and quote.down_cents==85000 and quote.due_cents==85000 and quote.actions==1,"First legal year has exact850/850 one-action Research: "+str(id))
		before=Fence.authority(run)
		expect(run.admit_feature_research(quote) and not run.owns_feature(id),"Admission grants no ownership")
		expect(not run.admit_feature_research(quote),"Duplicate admission cannot charge twice")
		var saved:=adapter.capture(run);var restored:=adapter.hydrate(saved)
		expect(restored!=null and adapter.capture(restored)==saved,"Paid queue/receipt/RNG survive Continue")
		quote=run.get_feature_research_quote(id)
		expect(run.research_feature(quote) and run.owns_feature(id),"One paid Research grants finite child")
		expect(not run.research_feature(quote),"Duplicate completion cannot advance or charge")
		expect(original.get_feature_supply_ids()==supply and id not in supply,"Already begun project supply stays frozen")
		var next:=PrimitivePredevelopment.prepare_project("New supply",&"action",&"fantasy",run)
		expect(id in next.get_feature_supply_ids(),"Only next project's supply gains child")
		var card:CardData=root.get_node("CardDatabase").get_card(id)
		var hand:Array[CardData]=[card]
		expect(run.primitive_feature_hand_cost_cents(hand)==0 and not card.renewable,"Approved finite Feature play fee stays zero")
	expect(not adapter.capture(run).is_empty(),"Final integrated finance/release/Research checkpoint validates: "+adapter.error)
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT")+".checkpoint.json",FileAccess.WRITE).store_string(JSON.stringify(adapter.capture(run)))
	var expected_unknown:=0
	for owned:StringName in run.get_owned_feature_ids():
		if run._feature_offers.has(owned) and not run._feature_offers[owned].has("play_cost_cents"):expected_unknown+=1
	expect(run.get_feature_spending_advice().unpriced_count==expected_unknown,"Approved zero-fee children do not inflate unknown-cost advice")
	var display:=FeatureStore.new();root.add_child(display);display.setup(run)
	expect(display._summarize_owned_features().unpriced_count==expected_unknown,"Owned-pool tooltip counts only genuinely TBD Store play costs")
	display.free()
	var resource:=RunState.new();resource.initialize_cash_cents(0)
	resource.create_studio_with_traits("Resourceful era",&"action",[&"resourceful"]);resource.finalize_starter_selection()
	resource.add_cash(1000000) # Explicit accounting fixture only.
	advance(resource,72)
	expect(resource.admit_feature_research(resource.get_feature_research_quote(&"save_files")),"Parent can be paid and queued")
	expect(not resource.get_feature_research_quote(&"player_level_editor").can_admit and not resource.owns_feature(&"save_files"),"Queued/paid parent is not owned, child remains locked")
	expect(resource.research_feature(resource.get_feature_research_quote(&"save_files")),"Parent completion unlocks ownership gate")
	var credited:=Fixture.release(30)
	expect(resource.record_resolved_feature(credited,&"save_files",&"design") and resource.record_resolved_feature(credited,&"levels",&"alpha"),"Both actual parent-project credit paths count once")
	expect(resource.register_release(credited),"Credit provenance freezes with one committed release")
	var quote:=resource.get_feature_research_quote(&"player_level_editor")
	expect(quote.discount_percent==20 and quote.down_cents==85000 and quote.nominal_cents==85000 and quote.saving_cents==10000 and quote.due_cents==58000,"Two-parent familiarity and current Resourceful adjust unpaid installment only")
	var baseline:=adapter.capture(resource)
	expect(not baseline.is_empty(),"Parent credits and earlier Resourceful claim validate: "+adapter.error)
	var poor:=adapter.hydrate(baseline)
	if poor!=null:
		expect(poor.spend_cash_cents(poor.get_cash_cents()-84999),"One-cent-short fixture records actual spending")
		var before:=Fence.authority(poor)
		expect(not poor.get_feature_research_quote(&"player_level_editor").can_admit and not poor.admit_feature_research(poor.get_feature_research_quote(&"player_level_editor")) and before==Fence.authority(poor),"Insufficient admission rejects atomically without using future sales")
	expect(resource.admit_feature_research(quote),"Discounted child admission still pays exact base half")
	quote=resource.get_feature_research_quote(&"player_level_editor")
	expect(resource.research_feature(quote) and resource.resourceful_saving(85000)==0,"Committed adjusted payment consumes Resourceful once per release window")
	expect(not adapter.capture(resource).is_empty(),"Discount, cents, claim and ownership remain strict-save valid: "+adapter.error)
	print("STORE_ERA_RESEARCH checks=%d failures=%d"%[checks,failures]);quit(failures)
