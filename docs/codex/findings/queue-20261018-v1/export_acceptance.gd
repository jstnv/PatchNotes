## External test driver. Runtime scenes, codecs and rules load from the shipped PCK.
extends SceneTree
var failures:=0
var checks:=0
var output:=OS.get_environment("PN_EXPORT_CASE")
var mode:=OS.get_environment("PN_EXPORT_MODE")
var publisher:=OS.get_environment("PN_EXPORT_PUBLISHER")
var dimensions:=Vector2i(int(OS.get_environment("PN_EXPORT_WIDTH")),int(OS.get_environment("PN_EXPORT_HEIGHT")))
func expect(ok:bool,label:String)->void:
	checks+=1
	if ok:print("PASS: "+label)
	else:failures+=1;push_error("FAIL: "+label)
func read_json(path:String)->Dictionary:return JSON.parse_string(FileAccess.get_file_as_string(path))
func write_json(path:String,value:Dictionary)->void:FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(value,"\t"))
func _initialize()->void:
	create_timer(110).timeout.connect(func():push_error("Export acceptance timeout");quit(2))
	_run.call_deferred()
func key_accept(button:Button)->void:
	button.grab_focus()
	for pressed in [true,false]:
		var event:=InputEventAction.new();event.action=&"ui_accept";event.pressed=pressed
		root.push_input(event,true);await process_frame
func shot(label:String)->void:
	await create_timer(0.1).timeout
	await RenderingServer.frame_post_draw
	var picture:=root.get_texture().get_image()
	expect(picture.get_size()==dimensions,"exported native capture dimensions")
	picture.save_png(output+"-"+mode+"-"+label+".png")
func finish()->void:
	write_json(output+"-"+mode+".json",{"checks":checks,"failures":failures,"publisher":publisher,"mode":mode,"executable":OS.get_executable_path(),"user_directory":OS.get_user_data_dir()})
	print("EXPORTED_CHALLENGE checks=%d failures=%d"%[checks,failures]);quit(failures)
func _run()->void:
	await process_frame
	expect(not OS.has_feature("editor"),"actual exported runtime, not editor")
	expect(not FileAccess.file_exists("res://scripts/debug/verify_starwave.gd"),"debug fixture scripts absent from production pack")
	var adapter:=StudioCheckpoint.new()
	var directory:=ProjectSettings.globalize_path("user://saves/studio")
	var storage:=StudioCheckpointStore.new(directory,adapter.validate)
	if storage.inspect().status==&"empty":
		if mode=="legacy":
			DirAccess.make_dir_recursive_absolute(directory)
			expect(DirAccess.copy_absolute(OS.get_environment("PN_EXPORT_INPUT"),directory.path_join("checkpoint.1.json"))==OK,"copy real preceding-source disk generation into private profile")
		else:
			var payload:=read_json(OS.get_environment("PN_EXPORT_INPUT"))
			expect(storage.save(payload).status==&"saved","seed validated current publisher fixture through production Store")
			storage.release_writer()
	var initial:=storage.inspect()
	expect(initial.status==&"valid","production Store recognizes Continue")
	if initial.status!=&"valid":finish();return
	var old_hash:=FileAccess.get_sha256(initial.path)
	var game:Control=load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game);await process_frame
	root.size=dimensions;root.content_scale_size=dimensions;await process_frame
	expect(game._active_phase is MainMenu,"export starts at normal Main Menu")
	var resume:Button=game._active_phase.find_child("Continue",true,false)
	expect(resume!=null and not resume.disabled,"normal Continue button enabled")
	if resume==null or resume.disabled:finish();return
	await key_accept(resume)
	expect(game._active_phase is StudioPhase and game.checkpoints.failure.is_empty(),"keyboard Continue hydrates Studio")
	if not game._active_phase is StudioPhase:finish();return
	var run:RunState=game.run_state
	var expected:Dictionary=initial.payload.duplicate(true);expected.content_revision=adapter.revision();expected.sequence="1"
	expect(adapter.capture(run)==expected,"Continue preserves exact cash/contracts/RNG/history")
	expect(FileAccess.get_sha256(initial.path)==old_hash and storage.inspect().sequence==initial.sequence,"pure Continue does not rewrite generation")
	game.get_node("%GameplayHUD").tutorial_overlay.close();game.get_node("%GameplayHUD").contextual_tip.dismiss()
	await process_frame
	if mode=="cold":
		expect(adapter.capture(run)==read_json(output+"-expected.json"),"fresh exported process restores completed bonus/Promotion/state exactly")
		await shot("continued");finish();return
	if mode=="legacy":
		for row:Dictionary in run._publisher_offers.values():
			if row.state!=null:expect(row.state.get_challenge_terms().is_empty() and row.state.get_result().get_bonus_cash_cents()==0 and row.state.get_result().get_bonus_promotion()==0,"old completed publisher receives no retroactive reward")
		for row:Dictionary in run._sidestreet_entitlements.values():
			if row.state!=null:expect(row.state.get_challenge_terms().is_empty() and row.state.get_result().get_bonus_cash_cents()==0,"old SideStreet receives no retroactive reward")
		await shot("old-continued");finish();return
	var studio:StudioPhase=game._active_phase
	studio.get_node("%Contracts").pressed.emit()
	var chosen:=""
	for i in studio._contract_chooser.item_count:
		var id:StringName=studio._contract_chooser.get_item_metadata(i)
		var quote:=run.get_publisher_contract_offer(id)
		if (publisher=="sidestreet" and id==run.get_next_sidestreet_offer().get("offer_id")) or str(quote.get("publisher_id",""))==publisher:
			studio._contract_chooser.select(i);studio._contract_chooser.item_selected.emit(i);chosen=str(id);break
	expect(not chosen.is_empty(),"eligible selected publisher offer")
	if chosen.is_empty():finish();return
	game.get_node("%GameplayHUD").contextual_tip.dismiss();await process_frame
	var detail:Label=studio._contract_detail.find_child("ContractDetailText",true,false)
	expect(detail.text.contains("Challenge:"),"exported offer displays separate challenge")
	await shot("offer")
	await key_accept(studio._contract_detail.find_child("AcceptContractButton",true,false))
	expect(game._active_phase is ContractPhase,"keyboard accepts Contract through production scene")
	if not game._active_phase is ContractPhase:finish();return
	var phase:ContractPhase=game._active_phase
	var state:ContractState=phase.get_contract_state()
	expect(not state.get_challenge_terms().is_empty(),"new acceptance freezes challenge terms")
	for hand in state.get_required_hands():
		await create_timer(0.7).timeout
		if hand==0:await shot("progress")
		for view:CardView in phase._candidate_row.get_children().slice(0,4):view.input_button.pressed.emit()
		await key_accept(phase._play_button)
		for frame in 900:
			await create_timer(0.02).timeout
			if not phase.hand_motion.busy:break
		expect(state.get_successful_hand_count()==hand+1,"one committed animated hand")
		if mode=="rollback":
			expect(not state.is_completed() and FileAccess.get_sha256(initial.path)==old_hash and storage.inspect().sequence==initial.sequence,"unsaved Contract hand/advance retains original Studio generation")
			finish();return
	var result:=state.get_result()
	expect(state.is_completed() and result!=null and phase._completion_stats.text.contains("Challenge grade"),"final result includes challenge breakdown")
	if result==null:finish();return
	var bonus:Dictionary={"grade":result.get_challenge_grade_bp(),"cash_cents":result.get_bonus_cash_cents(),"promotion":result.get_bonus_promotion(),"total_cash":result.get_payout_cents(),"total_promotion":result.get_promotion()}
	write_json(output+"-bonus.json",bonus)
	await shot("result")
	await key_accept(phase._completion_panel.find_child("DismissCompletionButton",true,false))
	await process_frame;await process_frame
	expect(game._active_phase is StudioPhase and game.checkpoints.failure.is_empty(),"result dismissal commits Studio checkpoint")
	var saved:Dictionary=game.checkpoints.store.inspect()
	expect(saved.status==&"valid" and saved.sequence>initial.sequence,"new completed generation published")
	var final:=adapter.capture(run)
	write_json(output+"-expected.json",final)
	var restored:=adapter.hydrate(saved.get("payload",{}))
	expect(restored!=null and adapter.capture(restored)==final,"production saved payload exactly matches completed run")
	await shot("studio");finish()
