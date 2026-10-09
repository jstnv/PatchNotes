extends "res://scripts/debug/verify_balanced_primitive_contract.gd"

func _verify() -> void:
	snapshots.load_ledgers()
	database=root.get_node("CardDatabase")
	for resolution in [Vector2i(1152,648),Vector2i(900,600),Vector2i(1307,741)]:
		root.size=resolution
		root.content_scale_size=resolution
		var game:Control=load("res://scenes/gameplay.tscn").instantiate()
		game.project_state=ProjectState.new(30)
		# This test replaces the run below; keep disk coordination out of the fixture.
		game.run_state=RunState.new()
		root.add_child(game)
		await process_frame
		var previous:Control=game.get("_active_phase")
		game.get_node("%PhaseRoot").remove_child(previous)
		previous.queue_free()
		var project:=release(751)
		var run:=new_run(550000)
		game.project_state=project
		game.run_state=run
		var studio:=load("res://scenes/phases/studio_phase.tscn").instantiate() as StudioPhase
		studio.setup(project,run,snapshots)
		game.get_node("%PhaseRoot").add_child(studio)
		game.set("_active_phase",studio)
		game.get_node("%GameplayHUD").setup(project,run)
		game.get_node("%GameplayHUD").set_phase(studio)
		await create_timer(0.4).timeout
		var before:=run_snapshot(run,project)
		for visit in range(2):
			studio.get_node("%Contracts").pressed.emit()
			await create_timer(0.4).timeout
			var panel:Control=studio.get("_contract_detail")
			var back:Button=panel.find_child("CloseContractDetailButton",true,false)
			var accept:Button=panel.find_child("AcceptContractButton",true,false)
			print("DETAIL GEOMETRY ",resolution," studio=",studio.get_global_rect()," panel=",panel.get_global_rect()," back=",back.get_global_rect()," accept=",accept.get_global_rect())
			_check_button(back,studio,"Contract Back")
			_check_button(accept,studio,"Contract Accept")
			if visit==0:await _capture_menu("contract-detail",resolution)
			_click_button(back)
			await create_timer(0.3).timeout
			expect(not panel.visible and studio.get_node("%Dashboard").visible,"Contract Back restores Studio")
			expect(run_snapshot(run,project)==before and run.get_active_contract()==null,"Contract browsing and Back preserve cash, time, redraws, sales and offer")
		await _verify_studio_menus(game,studio,run,project)
		studio.contract_requested.connect(game._on_contract_requested)
		studio.get_node("%Contracts").pressed.emit()
		await create_timer(0.3).timeout
		_click_button(studio.get("_contract_detail").find_child("AcceptContractButton",true,false))
		var contract:ContractPhase=game.get("_active_phase")
		expect(contract is ContractPhase,"Visible Accept enters Contract gameplay")
		contract.open_priority_overlay()
		await create_timer(0.3).timeout
		var cancel:=_button_text(contract.get("_priority_modal"),"Cancel")
		_check_button(cancel,game,"Contract priorities Cancel")
		var accepted:=run_snapshot(run,project)
		_click_button(cancel)
		expect(not contract.get("_priority_modal").visible and accepted==run_snapshot(run,project),"Contract priorities Cancel is passive")
		for hand in range(2):
			_select_first(contract,4)
			expect(contract.call("_play_selected_hand"),"Contract hand remains playable")
		await create_timer(0.3).timeout
		var dismiss:Button=contract.get("_completion_panel").find_child("DismissCompletionButton",true,false)
		_check_button(dismiss,game,"Contract completion Return")
		_click_button(dismiss)
		await create_timer(0.3).timeout
		studio=game.get("_active_phase")
		before=run_snapshot(run,project)
		expect(run.is_sidestreet_offer_available(),"Completed Ironclad exposes legitimate SideStreet fixture offer")
		studio.get_node("%Contracts").pressed.emit()
		await create_timer(0.3).timeout
		var side:Control=studio.get("_contract_detail")
		(side.find_child("ContractDetailText",true,false) as Label).text += "\n" + "Long released-game title and description. ".repeat(80)
		await create_timer(0.3).timeout
		var side_back:Button=side.find_child("CloseContractDetailButton",true,false)
		_check_button(side_back,studio,"Long SideStreet detail Back")
		_check_button(side.find_child("AcceptContractButton",true,false),studio,"Long SideStreet detail Accept")
		await _capture_menu("sidestreet-detail",resolution)
		_click_button(side_back)
		expect(run_snapshot(run,project)==before and studio.get_node("%Dashboard").visible,"SideStreet Back preserves pending offer and authoritative state")
		game.queue_free()
		await process_frame
		await _verify_main_setup(resolution)
	print("Menu navigation verification: %d failures"%failures)
	quit(failures)

func _check_button(button:Button,workspace:Control,label:String) -> void:
	print("BUTTON GEOMETRY ",label,"=",button.get_global_rect()," workspace=",workspace.get_global_rect())
	expect(button!=null and button.is_visible_in_tree() and not button.disabled and workspace.get_global_rect().encloses(button.get_global_rect()) and Rect2(Vector2.ZERO,Vector2(root.size)).encloses(button.get_global_rect()),label+" is visible and inside the playable workspace")

func _button_text(node:Node,text:String) -> Button:
	if node is Button and node.text==text:return node
	for child:Node in node.get_children():
		var result:=_button_text(child,text)
		if result!=null:return result
	return null

func _verify_studio_menus(game:Control,studio:StudioPhase,run:RunState,project:ProjectState) -> void:
	var before:=run_snapshot(run,project)
	studio.get_node("%FeatureStoreButton").pressed.emit()
	await create_timer(0.35).timeout
	var back:=_button_text(studio.get("_feature_store"),"Close Store")
	_check_button(back,studio,"Store Close")
	await _capture_menu("store",root.size)
	_click_button(back)
	studio.get_node("%PublisherList").pressed.emit()
	await create_timer(0.35).timeout
	back=studio.get("_publisher_browser").find_child("ClosePublisherBrowser",true,false)
	_check_button(back,studio,"Publishers Back")
	_click_button(back)
	studio.call("_show_predevelopment")
	await create_timer(0.35).timeout
	back=studio.get("_predevelopment").back_button
	_check_button(back,studio,"Predevelopment Back")
	await _capture_menu("predevelopment",root.size)
	_click_button(back)
	studio.open_summary()
	await create_timer(0.35).timeout
	_check_button(studio.get_node("%CloseSummaryButton"),studio,"Summary Back")
	await _capture_menu("summary",root.size)
	studio.get_node("%DetailedReviewButton").pressed.emit()
	await create_timer(0.35).timeout
	back=studio.get("_review_view").get_node("%ContinueButton")
	_check_button(back,studio,"Detailed Review Back")
	_click_button(back)
	studio.get_node("%MonthlySalesButton").pressed.emit()
	await create_timer(0.35).timeout
	back=studio.get("_monthly_report").find_child("BackButton",true,false)
	_check_button(back,studio,"Monthly Sales Back")
	_click_button(back)
	_click_button(studio.get_node("%CloseSummaryButton"))
	var hud:GameplayHUD=game.get_node("%GameplayHUD")
	hud.show_tutorial()
	await create_timer(0.35).timeout
	_check_button(hud.tutorial_overlay.skip_button,game,"Tutorial Close")
	_click_button(hud.tutorial_overlay.skip_button)
	expect(studio.get_node("%Dashboard").visible and before==run_snapshot(run,project),"All Studio menu Back/Close buttons preserve authoritative state")

func _verify_main_setup(resolution:Vector2i) -> void:
	var menu:=MainMenu.new()
	root.add_child(menu)
	menu.find_child("StartGame",true,false).pressed.emit()
	await create_timer(0.3).timeout
	var back:Button=menu.find_child("Back",true,false)
	_check_button(back,menu,"Studio setup Back")
	_click_button(back)
	expect(not menu.get("_setup").visible,"Setup Back restores Main Menu")
	await _capture_menu("main-menu",resolution)
	menu.queue_free()
	await process_frame

func _capture_menu(label:String,resolution:Vector2i) -> void:
	if "--capture" not in OS.get_cmdline_user_args():return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://design-logs/menu-navigation-v1/%s-%dx%d.png"%[label,resolution.x,resolution.y])

func _click_button(button:Button) -> void:
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new()
		event.position=button.get_global_rect().get_center()
		event.global_position=event.position
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=pressed
		root.push_input(event,true)
