extends SceneTree
const Factory=preload("res://scripts/simulation/run_factory.gd")
const Begin=preload("res://scripts/simulation/begin_project.gd")
const Replay=preload("res://scripts/simulation/development_replay.gd")
var checks:=0
var failures: Array=[]
var captures: Array=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func ids(hand: RefCounted) -> Array[int]:
	var count: int=hand.candidate_ids.size()
	for a in range(count):
		for b in range(a+1,count):
			for c in range(b+1,count):
				for d in range(c+1,count):
					var cards: Array[CardData]=[hand._candidate_cards[a],hand._candidate_cards[b],hand._candidate_cards[c],hand._candidate_cards[d]]
					if hand.can_play_pass_budget(cards):return [hand.candidate_ids[a],hand.candidate_ids[b],hand.candidate_ids[c],hand.candidate_ids[d]]
	return []
func parity(scene: Node,dev: RefCounted,phase: int,label: String) -> void:
	var state: RefCounted=scene.call("_capture_design_command" if phase==0 else "_capture_alpha_command")
	check(Replay.freeze(state)==Replay.freeze(dev.hand),"Full live/headless Project/Run/hand/tokens/counters/RNG "+label)
	check(state.pass_budget_available()>=0 and state._candidate_cards.size()<=7,"Budget/reservation bounds "+label)
func _initialize() -> void:
	await process_frame
	var output:=OS.get_cmdline_user_args()[0].trim_prefix("--output=")
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	for width: int in [1152,1280]:
		root.size=Vector2i(width,width*9/16)
		for genre: String in ["action","puzzle","simulation"]:
			var recipe: Dictionary={"schema_version":1,"studio_id":"native-budget-"+genre,"studio_name":"Native Budget","specialty":genre,"traits":[],"seed":"4417"}
			var live: RefCounted=Factory.create_fresh_session(recipe,catalog);var head: RefCounted=Factory.create_fresh_session(recipe,catalog)
			var prepared:=Begin.execute(live.run,live.snapshots,"Native Budget",StringName(genre),&"fantasy")
			check(prepared.ok and head.execute(head.command(&"begin_development",{"name":"Native Budget","genre":genre,"theme":"fantasy"})).ok,"Identical legal new project "+genre)
			if not prepared.ok:continue
			for phase: int in [0,1]:
				var scene: Control=load("res://scenes/phases/"+("design" if phase==0 else "alpha")+"_phase.tscn").instantiate()
				scene.setup(prepared.project,live.run);root.add_child(scene);scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				await process_frame
				check(scene.call("begin_design" if phase==0 else "begin_alpha"),"Native phase starts with real small pool")
				check(head.development.execute(head.development.command(&"start")).ok,"Headless phase starts")
				scene.get_workspace().hand_motion.cancel();parity(scene,head.development,phase,genre+str(phase)+" start")
				if genre=="action":
					await RenderingServer.frame_post_draw
					var path:=output.get_base_dir().path_join("budget-%d-%d.png"%[width,phase]);root.get_texture().get_image().save_png(path);captures.append(path)
				for hand_index in range(12):
					var selected:=ids(head.development.hand)
					if selected.is_empty():break
					scene.get_workspace().hand_motion.cancel()
					var command: RefCounted=scene.call("_capture_design_command" if phase==0 else "_capture_alpha_command")
					var views: Array=scene.get_node("%HandContainer").card_views()
					for token: int in selected:scene.call("_on_card_pressed",views[command.candidate_ids.find(token)])
					scene.call("_on_play_card_pressed" if phase==0 else "_on_play_alpha_hand_pressed")
					check(head.development.execute(head.development.command(&"play",{"candidate_ids":selected})).ok,"Same legal production hand accepted")
					parity(scene,head.development,phase,genre+str(phase)+" hand"+str(hand_index))
					await process_frame
				var actions: RefCounted=scene.call("_capture_development_actions")
				check(actions.can_finalize(),"Native short/exhausted pool has legal phase exit")
				check(actions.finalize().ok,"Native phase finalizes")
				var finished: Dictionary=head.development.execute(head.development.command(&"request_exit"))
				if head.development.awaiting_confirmation:finished=head.development.execute(head.development.command(&"confirm_exit"))
				check(finished.ok and head.development.finalized,"Headless phase finalizes")
				check(Replay.freeze(prepared.project)==Replay.freeze(head.development.project) and live.run.random_streams.snapshot()==head.run.random_streams.snapshot(),"Finalized score/history/RNG exact")
				scene.free()
				if phase==0:check(head.development.execute(head.development.command(&"enter_next_phase")).ok,"Independent Alpha budget starts")
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"source":Replay.source_identity(),"captures":captures},"\t"));print("NATIVE_BUDGET ",checks," failures=",failures.size());quit(0 if failures.is_empty() else 1)
