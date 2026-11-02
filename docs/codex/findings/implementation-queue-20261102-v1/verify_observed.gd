extends "res://../docs/codex/findings/implementation-queue-20261102-v1/verify_pointer.gd"
const WorldCodec:=preload("res://scripts/market/rival_world_checkpoint.gd")
func go() -> void:
	await process_frame
	var pair:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_CONTRACT_FIXTURE")))
	var adapter:=StudioCheckpoint.new();var run:=adapter.hydrate(pair.player)
	check(run!=null,"Observed player hydrates")
	if run==null:print("HYDRATE_ERROR ",adapter.error);quit(1);return
	var codec:=WorldCodec.new();var world:=codec.restore(pair.world,pair.player,run,root.get_node("CardDatabase").get_development_catalog())
	check(world!=null,"Observed world restores: "+codec.error)
	if world==null:quit(1);return
	# Match Gameplay._connect_rival_calendar; the Store alone does not own AI ticks.
	run.calendar_changed.connect(func():
		var tick:Dictionary=world.advance_committed_player_cycle(preload("res://scripts/market/rival_trial.gd").policies(world),preload("res://scripts/market/rival_trial.gd").ZERO_STEPS)
		check(tick.ok,"Observed action advances the real rival calendar: "+str(tick.get("reason",""))))
	var pending:=run.get_feature_research_queue()
	print("OBSERVED_QUEUE ",pending)
	check(not pending.is_empty(),"Observed save has pending implementation")
	if pending.is_empty():quit(1);return
	var head:Dictionary=pending[0];var engine:StringName=head.engine_id;var id:StringName=head.feature_id
	var quote:=run.get_feature_research_quote(id,engine)
	print("OBSERVED_QUOTE ",quote," mutable=",run.can_mutate_checkpoint()," block=",run.get_financial_block_reason())
	var market:Dictionary=preload("res://scripts/market/market_transaction_trial.gd").neutral()
	if run._market_provider.is_valid():market=run._market_provider.call(run._bank_run_id,run.get_completed_run_cycles()+1)
	print("PLAN_DIAG flags=",[run._productive_cycle_in_progress,run._feature_purchase_in_progress,run._pending_contract_completion,run._available_redraws]," market_valid=",preload("res://scripts/market/market_transaction_trial.gd").valid(market))
	var sales:Dictionary=run._plan_sales_cycle(&"",market)
	print("PLAN_DIAG sales_empty=",sales.is_empty()," entitlements=",run.get_engine_entitlements()," releases=",run._released_games.keys())
	if not sales.is_empty():print("PLAN_DIAG finance_empty=",StudioFinanceLedger.plan(run._studio_finance,run.get_completed_run_cycles()+1,run.get_cash_cents(),-int(quote.due_cents),&"other_expense",sales.earned,sales.payable,true,&"").is_empty())
	for release:StringName in run._released_games:
		var meta:Dictionary=run._release_metadata[release]
		var factor:Dictionary=preload("res://scripts/market/market_transaction_trial.gd").sales_factor(market,str(run._bank_run_id),str(release),str(meta.genre),str(meta.theme))
		print("RELEASE_DIAG id=",release," engine=",run._release_engine_ids.get(release)," factor=",factor)
		if not factor.is_empty():print("RELEASE_DIAG next_empty=",ReleasedGameSales.next_cycle(run._released_games[release],run.get_completed_run_cycles()+1,run.will_next_cycle_cross_month_boundary(),false,int(factor.factor_bp),str(factor.snapshot_id),factor).is_empty())
		var raw:Dictionary=run._released_games[release]
		print("RAW_VALID ",ReleasedGameSales.is_valid(raw)," raw=",raw," factor_valid=",preload("res://scripts/market/market_transaction_trial.gd").valid_factor(factor))
		var prospective:Dictionary=raw.duplicate(true)
		prospective.total_earned_cycles+=1;prospective.earned_cycles=1;prospective.market_factors[1]=factor.duplicate(true);prospective.last_processed_run_cycle=run.get_completed_run_cycles()+1
		print("PROSPECTIVE_VALID ",ReleasedGameSales.is_valid(prospective)," recalc=",ReleasedGameSales._recalculate(prospective)," clock=",preload("res://scripts/calendar/calendar_clock.gd").position(prospective.total_earned_cycles,prospective.calendar))
	root.size=Vector2i(1280,720);root.content_scale_size=Vector2i(1152,648)
	var host:=Control.new();root.add_child(host);host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var store:=FeatureStore.new();store.theme=load("res://resources/ui/workspace_theme.tres");host.add_child(store);store.setup(run);store.open_store(engine)
	await settle()
	store._research_button.pressed.connect(func():print("OBSERVED_BUTTON_PRESSED"))
	check(store._research_list.is_visible_in_tree() and store._research_list.item_count==pending.size(),"Observed pending queue is visible and complete")
	var before_browse:=adapter.capture(run)
	await click(store._research_list)
	check(store._research_list.get_popup().visible,"Pointer opens implementation queue")
	if store._research_list.get_popup().visible:
		print("QUEUE_FOCUS ",store._research_list.get_popup().get_focused_item())
		var focused:=store._research_list.get_popup().get_focused_item()
		var codes:Array=[]
		for index in (2 if focused<0 else (1 if focused==0 else 0)):codes.append(KEY_DOWN)
		codes.append(KEY_ENTER)
		for code in codes:
			for down in [true,false]:
				var key:=InputEventKey.new();key.keycode=code;key.pressed=down;Input.parse_input_event(key);await process_frame
		await create_timer(0.75).timeout
		check(store._selected==pending[1].feature_id,"Queue selection inspects its Feature")
	check(adapter.capture(run)==before_browse,"Inspecting a queued Feature preserves the entire player state")
	check(not store._research_button.disabled,"Observed head is actionable")
	var cash:=run.get_cash_cents();var cycle:=run.get_completed_run_cycles()
	await click(store._research_button)
	print("OBSERVED_AFTER cash=",run.get_cash_cents()," cycle=",run.get_completed_run_cycles()," queue=",run.get_feature_research_queue())
	check(run.owns_feature(id,engine) and run.get_completed_run_cycles()==cycle+1,"Observed click completes exactly one productive action")
	check(run.get_cash_cents()==cash-int(quote.due_cents),"Observed click pays quoted amount once")
	check(not run.owns_feature(pending[1].feature_id,engine) and run.get_feature_research_queue().size()==1,"Inspecting the later row does not bypass FIFO")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("PN_CONTRACT_REPORT").get_base_dir().path_join("observed-queue.png"))
	var remaining:StringName=pending[1].feature_id
	var next_quote:=run.get_feature_research_quote(remaining,engine)
	check(next_quote.can_research and not store._research_button.disabled,"Next queue head becomes actionable immediately")
	var cash_before:=run.get_cash_cents()
	await click(store._research_button)
	check(run.owns_feature(remaining,engine) and run.get_completed_run_cycles()==cycle+2,"Second queue entry completes through the productive month boundary")
	check(run.get_cash_cents()==cash_before-int(next_quote.due_cents)-int(run._studio_finance.monthly_rent_cents),"Second action pays only its remaining fee plus one normal monthly rent")
	check(run.get_feature_research_queue().is_empty() and store._research_list.disabled and store._research_button.disabled,"Empty queue disables both controls")
	var after:=adapter.capture(run)
	await click(store._research_button)
	check(adapter.capture(run)==after,"Repeated completion cannot charge twice or advance time")
	var saved_world:=WorldCodec.new().capture(world)
	check(not saved_world.is_empty(),"Completed observed world remains a valid save boundary")
	if not saved_world.is_empty():
		var restored:=adapter.hydrate(after)
		var cold_world:=WorldCodec.new().restore(saved_world,after,restored,root.get_node("CardDatabase").get_development_catalog())
		check(cold_world!=null and adapter.capture(restored)==after and WorldCodec.new().capture(cold_world)==saved_world,"Cold world/player round trip preserves all finance, queue, library and RNG state")
	FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}))
	host.queue_free();await process_frame;quit(failures)
