## Controlled accounting/UI fixtures, not an unfunded balance campaign.
extends "res://scripts/debug/verify_studio_finance_integration.gd"
const Replay:=preload("res://scripts/simulation/development_replay.gd")
const CashMotion:=preload("res://scripts/ui/cash_feedback.gd")
var count:=0
var problems: Array=[]
func check(ok: bool,label: String) -> void:
	count+=1
	if not ok:problems.append(label);push_error(label)
func _initialize() -> void:
	Engine.max_fps=60
	await process_frame
	snapshots.load_ledgers()
	await contracts()
	await money()
	await loan_refresh()
	await menus()
	await warning()
	var output:=""
	for item: String in OS.get_cmdline_user_args():
		if item.begins_with("--output="):output=item.trim_prefix("--output=")
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"checks":count,"failures":problems,"source":Replay.source_identity()},"\t"))
	print("STUDIO_CASH_BEHAVIORS "+JSON.stringify({"checks":count,"failures":problems}))
	quit(0 if problems.is_empty() else 1)
func contracts() -> void:
	var run:=named();check(run.register_release(_released_project(0)),"Accounting release unlocks contract")
	var state:=run.accept_primitive_contract();check(state!=null,"Accept real contract state")
	if state==null:return
	check(run.spend_cash_cents(run.get_cash_cents()),"Spend fixture funds legitimately")
	check(run.complete_productive_action() and run.complete_productive_action(),"Ordinary bills create exact arrears")
	check(run.get_cash_cents()==0 and run.get_studio_finance_report().total_overdue_cents>0,"Contract starts broke/overdue")
	check(not run.complete_productive_action(),"Unrelated calendar production remains blocked")
	check(not run.complete_productive_action(Callable(),0,-1,&"",&"contract_hand",&"forged"),"Wrong contract provenance rejects")
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var session: RefCounted=load("res://scripts/simulation/contract_session.gd").new(state,run,catalog)
	check(session.execute(session.command(&"begin")).ok,"Contract deals normally")
	for hand in range(2):
		var selected: Array[CardData]=[];var tokens: Array=[]
		for i in range(4):selected.append(session.cards[i]);tokens.append(session.candidate_ids[i])
		var plan: Dictionary=state.plan_hand(selected);check(run.can_complete_contract_hand(state,plan),"Broke contract preflight "+str(hand))
		var before_cycle:=run.get_completed_run_cycles();var before_redraw:=run.get_available_redraws()
		var rng:=run.random_streams.snapshot();var bad:=tokens.duplicate();bad[1]=bad[0]
		check(not session.execute(session.command(&"play",{"candidate_ids":bad})).ok and run.random_streams.snapshot()==rng,"Rejected duplicate hand preserves RNG")
		var outcome: Dictionary=session.execute(session.command(&"play",{"candidate_ids":tokens}))
		check(outcome.ok and run.get_completed_run_cycles()==before_cycle+1,"Real free hand commits exactly one cycle "+str(hand))
		check(run.get_available_redraws()==mini(4,before_redraw+1),"Normal redraw restoration retained")
		check(run.get_studio_finance_report().available,"Journal remains valid after hand")
	check(state.is_completed() and run.get_completed_contract_count()==1,"Broke contract finishes and pays once")
	var report:=run.get_studio_finance_report();check(report.rows.reduce(func(total,row):return total+row.rent_due_cents,0)==100000,"Both ordinary rent bills remain due")
	reconcile(run)
	var adapter:=StudioCheckpoint.new();var saved:=adapter.capture(run);print("CONTRACT_CAPTURE "+adapter.error+" empty="+str(saved.is_empty()));var restored:=adapter.hydrate(saved);print("CONTRACT_RESTORE "+adapter.error)
	check(restored!=null and StudioCheckpoint.new().capture(restored)==saved,"Contract receipt/debt exact codec reconstruction")
	# Partial payout still cannot clear a larger old bill; it may finish anyway.
	var ledger:=StudioFinanceLedger.create(0)
	for cycle in [1,2]:ledger=StudioFinanceLedger.plan(ledger,cycle,0,0,&"calendar",0,0,true).ledger
	var partial:=StudioFinanceLedger.plan(ledger,3,0,12345,&"contract_receipt",0,0,true,&"contract-test")
	check(not partial.is_empty() and partial.cash_cents==0 and partial.ledger.obligations[0].unpaid_cents==37655,"Partial payout services bills without forgiving remainder")
	StudioFinanceLedger._validated_journals.clear();StudioFinanceLedger._validated_journal_bytes=0
	check(StudioFinanceLedger.report(partial.ledger,3,0).available,"Cold journal replay accepts contract-specific receipt")
func money() -> void:
	var host:=Control.new();host.size=root.size;root.add_child(host)
	var button:=Button.new();host.add_child(button);button.position=Vector2(800,500);button.size=Vector2(220,48)
	var motion:=CashMotion.new();host.add_child(motion);motion.configure(button);motion.set_process(false);motion.reset(10000)
	var original:=button.text;motion.observe(12500);motion.observe(10900)
	check(motion._label.text=="+$9.00" and button.text==original,"Simultaneous inflow/outflow batches to net; number waits")
	check(is_equal_approx(CashMotion.pose(0),112.0) and CashMotion.pose(CashMotion.RISE*0.65)<CashMotion.pose(CashMotion.RISE),"Popup emerges with overshoot and settles below peak")
	motion._process(CashMotion.RISE+CashMotion.HOLD+CashMotion.FALL-0.01)
	check(button.text==original,"No premature HUD deposit")
	motion._process(0.02);check(motion.presented_cents==10900 and button.text.contains("109.00"),"Value updates exactly on button contact")
	motion.observe(-50000);motion._process(2.0)
	check(button.text=="Cash: -$500.00","Overdue bankroll displays signed amount")
	await create_timer(0.9).timeout;motion._process(0)
	check(motion.warning_mix>0.99,"Broke background reaches gradual red tint")
	motion._process(0.5);check(not button.has_theme_color_override("font_color"),"Persistent debt warning leaves normal font color")
	motion.observe(15000);motion._process(2);motion._process(0.5);await create_timer(0.9).timeout
	check(motion.warning_mix<0.01 and button.text.contains("150.00"),"Recovery clears warning and updates balance")
	motion.observe(18000);motion.observe(19000);motion._process(2)
	check(motion.presented_cents==19000,"Further changes in flight are retained")
	motion.reset(19000,true);check(button.text=="Cash: ∞" and not motion.flying,"Debug infinity does not produce phantom transactions")
	check(CashMotion.balance(0,100)==-100 and CashMotion.difference(-9223372036854775807,9223372036854775807)=="+$184467440737095516.14","Signed display and full-range delta do not overflow")
	host.free()
func loan_refresh() -> void:
	var run:=named();var project:=ProjectState.new(30)
	var phase: DesignPhase=load("res://scenes/phases/design_phase.tscn").instantiate();phase.setup(project,run);root.add_child(phase)
	await process_frame;check(phase.begin_design(),"Real Design pool begins")
	await create_timer(0.65).timeout
	var views: Array=phase.get_node("%HandContainer").card_views()
	if views.size()<4:check(false,"Design has four visible candidates");phase.free();return
	for i in range(4):phase._on_card_pressed(views[i])
	check(phase._selected_card_views.size()==4,"Select four actual cards")
	check(run.spend_cash_cents(run.get_cash_cents()) and run.complete_productive_action() and run.complete_productive_action(),"UI accounting fixture enters arrears")
	await process_frame;await process_frame
	check(phase.play_card_button.disabled,"Selection correctly blocks while in arrears")
	var selected:=phase._selected_card_views.duplicate();var rng:=run.random_streams.snapshot()
	var quote:=run.get_bank_quote(150000,12);check(quote.get("accepted",false) and run.accept_bank_loan(quote),"Accept actual Bank loan")
	await process_frame;await process_frame
	check(not phase.play_card_button.disabled and phase._selected_card_views==selected,"Loan refreshes Implement without reselecting")
	check(run.random_streams.snapshot()==rng,"Loan/affordability refresh never redraws")
	phase.free()
func menus() -> void:
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var session: RefCounted=load("res://scripts/simulation/run_factory.gd").create_fresh_session({"schema_version":1,"studio_id":"hub-menu","studio_name":"Hub Menu","specialty":"action","traits":[],"seed":"4417"},catalog)
	var certificate: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://certified/rival-opening-5607-v1.json"))
	var world: RivalWorld=load("res://scripts/market/rival_world_checkpoint.gd").new().restore(certificate.fixture.world,StudioCheckpoint.new().capture(session.run),session.run,catalog)
	check(world!=null,"Exact prior eight-owner save is accepted with all ordinary validation")
	var game: Control=load("res://scenes/gameplay.tscn").instantiate();game.run_state=session.run;game.rival_world=world;root.add_child(game)
	await process_frame;await process_frame
	game._on_tutorial_choice(true,false);await process_frame
	var hud_for_tips: GameplayHUD=game.get_node("%GameplayHUD");hud_for_tips.contextual_tip.dismiss();hud_for_tips.tutorial_overlay.close()
	check(game.guided_tutorial==null,"Tutorial invitation legally declined before menu interaction")
	var studio: StudioPhase=game._active_phase
	var before: Array=[session.run.get_cash_cents(),session.run.get_completed_run_cycles(),session.run.random_streams.snapshot(),session.run.get_studio_finance_snapshot()]
	for size in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=size;root.content_scale_size=size;await process_frame;await process_frame
		check(not studio.get_node("Dashboard/Layout/StudioIdentity").visible,"Studio details leave dashboard")
		for key in [&"market",&"management",&"production"]:
			studio._open_menu(key,null);await process_frame
			check(studio._menu_panels[key].visible and not studio.get_node("%Dashboard").visible,"Only requested folder visible "+str(key))
			await process_frame;check(studio._menu_panels[key].has_meta("slide_bound"),"Folder participates in shared entrance animation "+str(key))
			await capture("hub-"+str(key)+"-"+str(size.x))
			studio._close_menu(key)
			await click(studio._menu_buttons[key]);check(studio._menu_panels[key].is_visible_in_tree(),"Pointer enters actual folder "+str(key))
			await click(studio._menu_panels[key].find_child("Back",true,false));check(studio.get_node("%Dashboard").is_visible_in_tree(),"Pointer Back returns dashboard "+str(key))
		check(studio.get_node("%StartNextGame").text=="Produce New Game" and studio.get_node("%StartNextGame").get_index()==0,"Produce New Game always first")
		studio._open_menu(&"market",null);studio._open_market();studio._market_browser.close()
		check(studio._menu_panels[&"market"].visible and studio._market_button.has_focus(),"Daily Chart Back restores Market Info/focus")
		studio._open_rival_info();check(studio._rival_info.entries.size()==8,"Rival Info includes all eight owners");await capture("rival-info-"+str(size.x))
		check(studio.get_live_rival_rows().all(func(row):return row.games.is_empty()),"Historical releases are never counted as live games")
		studio._rival_info.close();studio._close_menu(&"market")
		studio._open_management();studio._open_studio_info();await capture("studio-info-"+str(size.x));studio._close_menu(&"info")
		check(studio._management_panel.visible and studio.get_node("%StudioInfoButton").has_focus(),"Studio Info Back returns to Management")
		studio._open_bank();var hud: GameplayHUD=game.get_node("%GameplayHUD")
		check(hud.studio_finances.visible and hud.studio_finances.page==&"bank","Management opens Bank directly")
		hud.studio_finances.back();check(not hud.studio_finances.visible and studio._management_panel.visible,"Bank Back returns to Management")
		studio._close_management();studio.close_summary(true)
		check(studio.get_node("%Dashboard").visible and not studio._management_panel.visible,"Launch Continue returns to Studio dashboard")
		await capture("hub-dashboard-"+str(size.x))
	check(before==[session.run.get_cash_cents(),session.run.get_completed_run_cycles(),session.run.random_streams.snapshot(),session.run.get_studio_finance_snapshot()],"All menu browsing preserves cash/finance/calendar/RNG")
	game.free();await process_frame

func capture(label: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await create_timer(0.3).timeout;await RenderingServer.frame_post_draw
	var output:=OS.get_cmdline_user_args()[0].trim_prefix("--output=").get_base_dir()
	root.get_texture().get_image().save_png(output+"/"+label+".png")

func _released_project(units: int) -> ProjectState:
	var project := ProjectState.new(30)
	assert(project.configure_predevelopment("Accounting Fixture",&"action",&"fantasy",[] as Array[StringName]))
	project.initialize_snapshots(&"fast_follower", &"stable_market")
	project.finalize_design_bugs(false, 0, [&"text"], [])
	project.finalize_alpha(0, [], [])
	project.finalize_beta()
	project.commit_review_result(ReviewResult.new(PrimitiveReviewCalculator.get_baseline_profile(), {}, 0.0, 0.0, 0.0, 7.0, 1.0, 0, 0.0, 1.0, 50, 0.0, 7.0, 7.0))
	project.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(project))
	project.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(project, snapshots))
	project.set("_units_sold_result", UnitsSoldResult.new(&"primitive_units_sold_v1", &"month_1", 500, 70, 70, 100, 200, 300, 10000, 10000, units, 1, float(units), units))
	project.commit_month_one_sales_revenue_result(PrimitiveMonthOneSalesRevenueCalculator.calculate(project))
	return project



func click(button: Button) -> void:
	var event:=InputEventMouseButton.new();event.position=button.get_global_rect().get_center();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true
	Input.parse_input_event(event);await process_frame
	event=event.duplicate();event.pressed=false;Input.parse_input_event(event);await process_frame
	await create_timer(0.32).timeout
func warning() -> void:
	var beta: BetaPhase=load("res://scenes/phases/beta_phase.tscn").instantiate();root.add_child(beta)
	var dialog: ConfirmationDialog=beta.get_node("%LaunchWarningDialog")
	dialog.dialog_text="Project Scope is incomplete: 12 / 30.\nScope shortfall: 18.\nThese conditions may reduce the game's launch performance.\nLaunch anyway?"
	dialog.popup_centered(Vector2i(720,300));await create_timer(0.3).timeout
	check(dialog.get_node("QuitCopy/Header/Heading").text=="Launch Warning" and dialog.get_ok_button().text=="Launch Anyway","Launch Warning retains text/action inside shared menu surface")
	check(dialog.size.y<400,"Shared warning shrinks after autowrap without excessive blank space")
	await capture("launch-warning")
	dialog.hide();beta.free()
