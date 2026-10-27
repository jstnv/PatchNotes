extends SceneTree
var checks:=0
var failures:=0
var clock:=0.0
var output:=""
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+label)
func _initialize() -> void:
	_run.call_deferred()

func jump(motion: HandPresentation, seconds: float) -> void:
	clock=seconds
	motion.advance_music(clock)

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output=arg.trim_prefix("--out=")
	check(ResourceLoader.exists("res://scripts/ui/card_score_floats.gd"),"Music-sampled floating scores exist")
	var motion:=HandPresentation.new()
	check(motion.has_method("_deposit_scores"),"HUD deposit is separate from card score events")
	motion.free()
	if failures: quit(failures); return
	for dimensions in [Vector2i(1152,648),Vector2i(1280,720),Vector2i(832,320)]:
		root.size=dimensions;root.content_scale_size=dimensions
		for kind in ["normal","specialization","balanced"]: await exercise(kind,false)
	for kind in ["normal","specialization","balanced"]: await exercise(kind,true)
	await contract_units()
	await capped_qa()
	await punch()
	await process_frame
	await create_timer(0.2).timeout
	print("SCORE_FLOATS checks=%d failures=%d"%[checks,failures])
	quit(failures)

func shot(label: String) -> void:
	if output.is_empty() or DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))

func exercise(kind: String, slow: bool) -> void:
	var fan:=Control.new();var motion:=HandPresentation.new()
	root.add_child(fan);root.add_child(motion)
	motion.set_process(false);clock=0.0;motion.clock_source=func():return clock
	var cards: Array=[]
	for index in range(4):
		var card:=CardData.new()
		card.id=StringName("float_fixture_"+str(index));card.card_name="Score "+str(index+1)
		card.primary_stat=HandPresentation.CORE[0 if kind=="specialization" else index]
		card.primary_value=3 if index==2 and kind!="specialization" else 2
		var view: CardView=load("res://scenes/cards/card_view.tscn").instantiate()
		view.set_card(card);fan.add_child(view);cards.append(view)
	var state: Dictionary={"_cycle":0,&"graphics":10,&"sound":20,&"technology":30,&"design":40}
	var before:=state.duplicate()
	var calls: Array=[0]
	var deposits: Array=[]
	var action:=func():
		calls[0]+=1;state._cycle+=1
		if kind=="specialization":state[&"graphics"]+=12;motion.note_specialization(Callable())
		elif kind=="balanced":
			for index in range(4):state[HandPresentation.CORE[index]]+=3 if index<3 else 2
			motion.note_specialization(Callable(),true)
		else:
			for index in range(4):state[HandPresentation.CORE[index]]+=3 if index==2 else 2
	var update:=func(values: Dictionary,deltas: Dictionary):
		if not deltas.is_empty():deposits.append({"values":values.duplicate(),"hidden":motion._score_flow.tokens.all(func(t):return not t.window.visible)})
	check(motion.play("play",fan,cards,action,func():return state.duplicate(),update,Callable()),kind+" accepted")
	var first: float=motion._first_beat*HandPresentation.BEAT_SECONDS
	var step:=HandPresentation.BEAT_SECONDS
	if slow:
		while motion._music_driven and clock<20:jump(motion,clock+0.31)
		check(deposits.size()==1 and motion.display_values==state,kind+" low FPS deposits exactly once")
		for event in motion.trace:
			if event.beat_index>=0:check(event.lateness_seconds>=-0.0001 and event.lateness_seconds<=0.3101,"Every low-FPS event stays within one frame")
	else:
		jump(motion,first+0.6*step)
		check(deposits.is_empty() and motion.display_values==before,"Card score floats without leaking committed HUD totals")
		var flow: Control=motion._score_flow
		check(flow.tokens[0].window.visible and flow.tokens[0].value.horizontal_alignment==HORIZONTAL_ALIGNMENT_CENTER,"Score rises centered above its card")
		var pose: Vector2=flow.tokens[0].value.position
		jump(motion,clock)
		check(flow.tokens[0].value.position==pose,"Stationary music holds the exact text pose")
		motion._rejoin_music_grid(2)
		jump(motion,clock+2*step)
		check(flow.tokens[0].value.position==pose,"Resume rejoin preserves text age and pose")
		first=motion._first_beat*step
		if kind!="normal":
			var popup:=first+4*step
			jump(motion,popup+0.75*step)
			if kind=="specialization":
				check(flow.tokens.all(func(t):return t.mult.visible and t.mult.text=="×1.5"),"All specialization multipliers appear together")
				for token in flow.tokens:
					var midpoint: float=(token.value.position.x+token.value.size.x/2+token.mult.position.x+token.mult.size.x/2)/2
					check(absf(midpoint-token.window.size.x/2)<1.1,"Original and multiplier have symmetric centers")
				await shot(kind+"-pair-"+str(root.size.x))
				jump(motion,popup+1.5*step)
				for token in flow.tokens:
					var gap: float=token.mult.position.x-token.value.position.x
					check(absf(gap-token.window.size.x/4)<1.1,"Both texts move inward during the merge")
				jump(motion,popup+2.05*step)
				check(flow.tokens.all(func(t):return t.value.text=="+3" and not t.mult.visible),"Specialization merges to exact resolved per-card values")
			else:
				check(flow.hub.window.visible and flow.hub.value.text=="+9" and flow.hub.mult.text=="×1.25","Balanced collects total and splits sum/multiplier")
				await shot(kind+"-pair-"+str(root.size.x))
				jump(motion,popup+2.05*step)
				check(flow.hub.value.text=="+11","Balanced merge uses floored boosted total")
				jump(motion,popup+3.05*step)
				check(flow.tokens.map(func(t):return t.value.text)==["+3","+3","+3","+2"],"Balanced splits exact whole-category values to four cards")
				await shot(kind+"-split-"+str(root.size.x))
			for token in flow.tokens:
				check(token.value.get_global_rect().position.y>=0 and token.value.get_global_rect().end.y<=token.window.get_global_rect().end.y,"Settled floating scores fit above the card inside a short stage")
		var deposit: float=motion._deposit_beat*step
		jump(motion,deposit-0.001)
		check(deposits.is_empty() and motion.display_values==before,"HUD remains held throughout merge and falling values")
		jump(motion,deposit+0.0001)
		check(deposits.size()==1 and deposits[0].hidden and motion.display_values==state,"Hidden numbers deposit the exact committed snapshot once")
		var names: Array=motion.trace.map(func(e):return e.event)
		check(names.find("numbers_hidden")<names.find("hud_deposit") and names.find("hud_deposit")<names.find("exit_slide"),"Numbers hide before HUD update before card slide")
		motion._deposit_scores()
		check(deposits.size()==1,"Duplicate deposit callback is harmless")
	check(calls[0]==1 and state._cycle==1,"Presentation never resolves the hand twice")
	motion.cancel()
	check(motion._score_flow==null and motion._card_bursts.is_empty(),"Cancel clears floats and particles")
	motion.free();fan.free();await process_frame

func punch() -> void:
	var hud:=ProductionScoreboard.new();root.add_child(hud);await process_frame
	var project:=ProjectState.new(30)
	var before:=HandPresentation.project_snapshot(project,null)
	project.add_core_scores_and_scope({},1,0.75)
	hud.render(project,&"design",before)
	check(hud.stats[6].text=="Bug Pressure\n0.00","Committed Bug Pressure stays held alongside floating scores")
	hud.render(project,&"design",HandPresentation.project_snapshot(project,null))
	check(hud.stats[6].text=="Bug Pressure\n0.75","Deposited Bug Pressure shows the exact confirmed value")
	hud.punch({&"graphics":3})
	check(hud._punches.size()==1,"Scoreboard starts one bounded punch per changed counter")
	# Sample the exact peak: a native frame can skip a short wall-clock peak.
	hud._punches[1].pause()
	hud._punches[1].custom_step(0.075)
	check(hud.stats[1].scale.x>1.0,"Changed number pops visibly")
	hud.punch({&"graphics":1});check(hud._punches.size()==1,"Rapid update replaces the previous punch")
	await create_timer(0.6).timeout
	check(hud.stats[1].scale.is_equal_approx(Vector2.ONE) and is_zero_approx(hud.stats[1].rotation) and hud._punches.is_empty(),"HUD animation settles exactly")
	hud.reset_punches();hud.free()

func contract_units() -> void:
	var motion:=HandPresentation.new();var fan:=Control.new()
	root.add_child(fan);root.add_child(motion);motion.set_process(false)
	clock=0;motion.clock_source=func():return clock
	var view: CardView=load("res://scenes/cards/card_view.tscn").instantiate()
	view.set_card(root.get_node("CardDatabase").get_card(&"graphics_pass"));fan.add_child(view)
	var state: Dictionary={"_cycle":0,"_score_divisor":2,&"graphics":0}
	var action:=func():state._cycle=1;state[&"graphics"]=6;motion.note_specialization(Callable())
	check(motion.play("play",fan,[view],action,func():return state.duplicate(),Callable(),Callable()),"Contract half-unit fixture starts")
	jump(motion,(motion._first_beat+0.6)*HandPresentation.BEAT_SECONDS)
	check(motion._score_flow.tokens[0].value.text=="+2","Contract base score displays points, not storage half-units")
	jump(motion,(motion._first_beat+1+2.05)*HandPresentation.BEAT_SECONDS)
	check(motion._score_flow.tokens[0].value.text=="+3","Contract specialization displays exact converted points")
	motion.cancel();motion.free();fan.free();await process_frame

func capped_qa() -> void:
	var motion:=HandPresentation.new();var fan:=Control.new()
	root.add_child(fan);root.add_child(motion);motion.set_process(false)
	clock=0;motion.clock_source=func():return clock
	var cards: Array=[]
	for index in range(4):
		var view: CardView=load("res://scenes/cards/card_view.tscn").instantiate()
		view.set_card(root.get_node("CardDatabase").get_card(&"debug"));fan.add_child(view);cards.append(view)
	var state: Dictionary={"_cycle":0,&"fixed":0,&"discovered":1}
	var action:=func():state._cycle=1;state[&"fixed"]=1;motion.note_specialization(Callable())
	check(motion.play("play",fan,cards,action,func():return state.duplicate(),Callable(),Callable()),"Capped QA fixture starts")
	jump(motion,(motion._first_beat+4+2.05)*HandPresentation.BEAT_SECONDS)
	check(motion._score_flow.tokens.reduce(func(sum,t):return sum+int(t.final),0)==1,"Capped QA floats conserve the exact resolved Bug count")
	check(motion._score_flow.tokens.all(func(t):return t.value.text in ["+0","+1"]),"Capped QA never invents multiplied Bugs")
	motion.cancel();motion.free();fan.free();await process_frame
