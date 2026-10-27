## Fresh-process Main Menu Continue of byte-copied real disk generations.
extends SceneTree
const WorldCodec := preload("res://scripts/market/rival_world_checkpoint.gd")
var checks: Array = []
class PrivateStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer != null:return true
		var server:=TCPServer.new()
		if server.listen(47734,"127.0.0.1")!=OK:return false
		_writer=server
		return true
func replace_store(node: Node) -> void:
	if node is CheckpointCoordinator:node.store=PrivateStore.new("user://saves/studio",node._validate_payload)
func check(ok: bool,label: String) -> void:
	checks.append({"pass":ok,"check":label});print("PASS: " if ok else "FAIL: ",label)
func _initialize() -> void: execute.call_deferred()
func execute() -> void:
	var args:=OS.get_cmdline_user_args()
	node_added.connect(replace_store)
	var game: Control=load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	await process_frame
	var width:=int(args[1])
	root.size=Vector2i(width,width*9/16);root.content_scale_size=root.size
	root.gui_embed_subwindows=true
	var menu: MainMenu=game._active_phase as MainMenu
	check(menu!=null,"fresh process opens actual Main Menu")
	var inspected: Dictionary=game.checkpoints.store.inspect()
	check(inspected.status==&"valid","original byte-copied disk generation validates")
	if inspected.status!=&"valid":finish(args[0],game);return
	var original:=FileAccess.get_file_as_bytes(inspected.path)
	var candidate: Dictionary=game.checkpoints._market_compatible_payload(inspected.payload)
	var player:=candidate.duplicate(true);player.erase("rival_world")
	var run: RunState=game.checkpoints.adapter.hydrate(player)
	check(run!=null,"expected player hydrates through named migration")
	if run==null:finish(args[0],game);return
	var expected: Dictionary=game.checkpoints.adapter.capture(run)
	var expected_world: Dictionary={}
	if candidate.has("rival_world"):
		var codec:=WorldCodec.new()
		var world:=codec.restore(candidate.rival_world,player,run,game.checkpoints.rival_catalog)
		check(world!=null,"expected populated world hydrates through named source pair")
		if world==null:finish(args[0],game);return
		expected_world=codec.capture(world)
	menu.continue_requested.emit()
	while game._loading_checkpoint:await process_frame
	check(game._active_phase is StudioPhase and game.project_state==null and game.active_contract_state==null,"Main Menu Continue ends at Studio only")
	var actual: Dictionary=game.checkpoints.adapter.capture(game.run_state)
	var notice_acknowledgment: Array=run.take_pending_publisher_notifications()
	if not notice_acknowledgment.is_empty():
		# Existing Studio entry displays and consumes pending publisher notices.
		# Do not ignore a field: require the exact expected notice text, then
		# compare every other typed field and RNG after that one known UI action.
		var names: Array[String]=[]
		for id: StringName in notice_acknowledgment:names.append(PublisherCatalog.name_for(id))
		var panel: PanelContainer=game._active_phase._publisher_notice
		check(not notice_acknowledgment.is_empty() and panel!=null and panel.visible and panel.find_child("PublisherUnlockMessage",true,false).text=="Publisher unlocked: %s" % ", ".join(names),"only expected pending publisher notices are displayed and acknowledged")
	var hud: GameplayHUD=game.get_node("%GameplayHUD")
	var guidance_key: StringName=&"studio_first_store" if run.needs_starter_selection() else &"studio_between_games"
	var guidance_title: String="Explore your starting pool" if run.needs_starter_selection() else "Choose your next step"
	if not run._seen_tutorial_topics.has(guidance_key) and game.run_state._seen_tutorial_topics.get(guidance_key,false):
		check(hud._current_tip_key==String(guidance_key) and hud.contextual_tip.title_label.text==guidance_title,"exact ordinary Studio guidance is shown and marked visited")
		run.visit_guidance_tip(guidance_key)
	expected=game.checkpoints.adapter.capture(run)
	if actual!=expected:FileAccess.open(args[0]+".divergence.json",FileAccess.WRITE).store_string(JSON.stringify({"actual":actual,"expected":expected},"\t"))
	check(actual==expected,"every gameplay field, receipt, standing and RNG survives exact cold Continue after the explicit notice acknowledgment")
	check((game.rival_world==null and expected_world.is_empty()) or (game.rival_world!=null and WorldCodec.new().capture(game.rival_world)==expected_world),"populated Founder ownership, active rivals, market and RNG survive exact cold Continue")
	check(FileAccess.get_file_as_bytes(inspected.path)==original and game.checkpoints.store.inspect().payload==inspected.payload,"Continue leaves original generation bytes and rewards unchanged")
	game._active_phase.open_summary()
	await process_frame
	var selected: StringName=game._active_phase._selected_release_id
	if game.run_state._commission_deals.has(selected):
		var deal: Dictionary=game.run_state._commission_deals[selected]
		var text: String=game._active_phase.get_node("%ReviewLabel").text
		check(CashFormatter.format_exact_cents(deal.result.fee_paid_cents) in text and "publisher-owned" in text and "Studio sales income: $0" in text,"native result shows exact zero/partial/full fee and publisher rights")
		check(game.run_state.get_post_launch_campaign_offer(selected).is_empty(),"restored publisher title cannot buy a Studio campaign")
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_size()==Vector2(width,width*9/16),"actual cold viewport matches requested supported size")
	check(root.get_texture().get_image().save_png(args[0]+".png")==OK,"native cold result capture")
	finish(args[0],game)
func finish(path: String,game: Control) -> void:
	var failures:=checks.filter(func(row: Dictionary) -> bool:return not row["pass"]).size()
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	game.free()
	await process_frame
	quit(0 if failures==0 else 1)
