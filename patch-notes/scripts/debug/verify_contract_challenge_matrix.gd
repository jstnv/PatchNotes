extends "res://scripts/debug/verify_starwave.gd"
const HANDS := {
	"side_full":[["graphics_pass","sound_pass","technology_pass","design_pass"],["graphics_pass","sound_pass","technology_pass","design_pass"]],
	"side_partial":[["split_screen","sprites","8_bit_sound","scrolling"],["menu_system","levels","text","graphics_pass"]],
	"side_miss":[["split_screen","sprites","8_bit_sound","scrolling"],["menu_system","levels","maps","general_combat"]],
	"crown_full":[["graphics_pass","sound_pass","technology_pass","design_pass"],["graphics_pass","sound_pass","technology_pass","design_pass"]],
	"crown_partial":[["graphics_pass","sound_pass","technology_pass","design_pass"],["graphics_pass","graphics_pass","sound_pass","technology_pass"]],
	"crown_miss":[["graphics_pass","sound_pass","technology_pass","design_pass"],["graphics_pass","graphics_pass","graphics_pass","graphics_pass"]],
	"neon_full":[["graphics_pass","sound_pass","technology_pass","design_pass"],["graphics_pass","sound_pass","technology_pass","design_pass"]],
	"star_full":[["controls","power_ups","levels","keyboard_and_mouse"],["graphics_pass","graphics_pass","sound_pass","sound_pass"],["sound_pass","technology_pass","design_pass","design_pass"]],
	"star_partial":[["graphics_pass","sound_pass","technology_pass","design_pass"],["graphics_pass","sound_pass","technology_pass","design_pass"],["graphics_pass","sound_pass","technology_pass","design_pass"]],
	"star_miss":[["graphics_pass","graphics_pass","graphics_pass","graphics_pass"],["graphics_pass","graphics_pass","graphics_pass","graphics_pass"],["graphics_pass","graphics_pass","graphics_pass","graphics_pass"]],
}
func _run() -> void:
	var evidence:=[]
	for key:String in HANDS:
		var run:=starwave_fixture() if key.begins_with("star") or key.begins_with("side") else trial_run()
		if key=="side_miss":
			# The authored historical miss uses General Combat, which root-first
			# founding no longer grants. Acquire its real parent path before the
			# new paid Search freezes this offer's eligible owned pool.
			for id: StringName in [&"enemies",&"general_combat"]:
				if run.owns_feature(id):continue
				var quote:=run.get_feature_research_quote(id)
				expect(quote.can_admit and run.admit_feature_research(quote),"Research missing authored prerequisite "+str(id))
				expect(run.research_feature(run.get_feature_research_quote(id)),"Complete authored prerequisite "+str(id))
		if key.begins_with("side"):expect(run.search_contracts(run.get_contract_search_quote(&"sidestreet",&"cash")),"Paid Search finds "+key)
		var state:ContractState
		if key.begins_with("side"):state=run.accept_sidestreet_offer(run.get_next_sidestreet_offer().offer_id)
		else:
			var publisher:=PublisherCatalog.CROWN_QUILL if key.begins_with("crown") else PublisherCatalog.NEON_CIRCUIT if key.begins_with("neon") else PublisherCatalog.STARWAVE
			state=run.accept_publisher_contract(offer_for(run,publisher))
		expect(state!=null,"accepted " + key)
		if state==null:continue
		for ids:Array in HANDS[key]:
			var cards:Array[CardData]=[]
			for id:String in ids:cards.append(root.get_node("CardDatabase").get_card(StringName(id)))
			var plan:=state.plan_hand(cards)
			expect(not plan.is_empty(),"legal owned/unexhausted authored cards " + key)
			if plan.is_empty():break
			expect(commit_native_hand(run,state,cards,plan.remainder_cents),"productive hand commits " + key)
		expect(state.is_completed(),"completed " + key)
		if not state.is_completed():continue
		var result:=state.get_result()
		var grade:=result.get_challenge_grade_bp()
		expect(grade==10000 if key.ends_with("full") else grade==0 if key.ends_with("miss") else grade>0 and grade<10000,"reachable grade " + key)
		var base:=state.calculate_for_state(state.get_scope(),result._core_half_units)
		expect(result.get_payout_cents()==int(base.payout_cents)+result.get_bonus_cash_cents(),"base preserved plus bonus " + key)
		var paid:=0
		for action:Dictionary in run._studio_finance.actions:
			if action.source_id==state.get_offer_id() and action.kind==&"publisher_receipt":paid+=int(action.direct_delta)
		expect(paid==result.get_payout_cents(),"exact total once-only publisher journal " + key)
		var before:=snapshot(run,state)
		expect(not commit_native_hand(run,state,passes(),0) and snapshot(run,state)==before,"duplicate final hand atomic rejection " + key)
		var banked:=run.get_pending_promotion_awards()
		expect(not run.register_release(ProjectState.new(30)) and run.get_pending_promotion_awards()==banked,"failed launch preserves keyed bonus " + key)
		roundtrip(run,"challenged " + key)
		var release:=finished(run,"Challenge next launch",0)
		expect(run.register_release(release) and run.get_pending_promotion()==0,"next successful launch consumes once " + key)
		evidence.append({"case":key,"hands":HANDS[key],"scope":state.get_scope(),"cores":result._core_half_units,"grade_bp":grade,"bonus_cash_cents":result.get_bonus_cash_cents(),"bonus_promotion":result.get_bonus_promotion()})
	# Exhaustive per-definition lower bound proves current Neon partial/miss
	# unreachable: addition preserves it and Specialization can only increase Core.
	for entry:Dictionary in FeatureStoreCatalog.starting_features():
		expect(2*(int(entry.primary_value)+int(entry.secondary_value))>=4*int(entry.scope),"Neon authored-pool lower bound " + str(entry.id))
	var output:=OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if not output.is_empty():FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"cases":evidence,"neon_partial_miss":"Unreachable with current authored pool; minimum Core/Scope is2, required1.5"},"\t"))
	print("CHALLENGE_MATRIX failures=%d"%failures);quit(failures)
