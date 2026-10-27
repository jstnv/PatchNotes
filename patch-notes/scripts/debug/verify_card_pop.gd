extends SceneTree
var checks:=0
var failures:=0
var fake_time:=0.0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+label)
func _initialize() -> void:go.call_deferred()
func go() -> void:
	check(ResourceLoader.exists("res://scripts/ui/card_play_burst.gd"),"Music-sampled card spark effect exists")
	var motion:=HandPresentation.new();root.add_child(motion)
	check(motion.has_method("_activation_bounce"),"Scoring cards have a charge and scale-pop bounce")
	if not motion.has_method("_activation_bounce"):motion.free();finish();return
	motion.free()
	await exercise(false)
	await exercise(true)
	finish()
func exercise(bonus: bool) -> void:
	var motion:=HandPresentation.new();var fan:=Control.new()
	root.add_child(fan);root.add_child(motion)
	motion.set_process(false)
	fake_time=0.0;motion.clock_source=func():return fake_time
	var selected: Array=[]
	for n in range(4):
		var view: CardView=load("res://scenes/cards/card_view.tscn").instantiate()
		view.set_card(root.get_node("CardDatabase").get_card(&"graphics_pass"));fan.add_child(view);selected.append(view)
	var state: Dictionary={"_cycle":0,&"graphics":0}
	var calls: Array=[0]
	var action:=func():
		calls[0]+=1;state._cycle+=1;state[&"graphics"]=12 if bonus else 8
		if bonus:motion.note_specialization(Callable())
	check(motion.play("play",fan,selected,action,func():return state.duplicate(),Callable(),Callable()),"Accepted presentation starts")
	var start: float=motion._first_beat*HandPresentation.BEAT_SECONDS
	fake_time=start+0.001;motion.advance_music(fake_time)
	var ghost: CardView=motion._hand[0]
	var base: float=minf(0.68,(motion.size.x-70.0)/(4*258.0))
	fake_time=start+0.06;motion.advance_music(fake_time)
	check(ghost.scale.x<base,"Quick anticipation compresses card before score")
	fake_time=start+HandPresentation.BEAT_SECONDS/2.0+0.00001;motion.advance_music(fake_time)
	check(ghost.scale.x>base*1.1,"Score peak makes card visibly larger")
	check(motion._card_bursts.size()==1,"One outward spark burst at the scoring peak")
	var burst: Node2D=motion._card_bursts[0].node
	check(burst.get("particle_count")==12,"Particle count is small and bounded")
	var held_scale:=ghost.scale
	var held_age: float=burst.age
	for n in range(5):motion.advance_music(fake_time)
	check(ghost.scale==held_scale and burst.age==held_age,"Stationary music freezes pop and particles")
	var burst_start: float=motion._card_bursts[0].started
	motion._rejoin_music_grid(2)
	fake_time+=2*HandPresentation.BEAT_SECONDS;motion.advance_music(fake_time)
	check(is_equal_approx(motion._card_bursts[0].started,burst_start+2*HandPresentation.BEAT_SECONDS) and is_equal_approx(burst.age,held_age),"Pause resume shifts particle schedule with card music grid")
	fake_time=motion._first_beat*HandPresentation.BEAT_SECONDS+HandPresentation.BEAT_SECONDS+0.00001;motion.advance_music(fake_time)
	check(ghost.scale.is_equal_approx(Vector2.ONE*base),"Card settles to its resting scale on original grounded event")
	fake_time=motion._first_beat*HandPresentation.BEAT_SECONDS+HandPresentation.BEAT_SECONDS/2.0+0.30001;motion.advance_music(fake_time)
	check(motion._card_bursts.is_empty(),"Expired sparks are released on the shared clock")
	while motion._music_driven and fake_time<20:
		fake_time+=0.31;motion.advance_music(fake_time)
	check(calls[0]==1 and state._cycle==1 and state[&"graphics"]==(12 if bonus else 8),"Visual effects never repeat gameplay")
	check(motion.trace.filter(func(e):return e.event=="score").size()==4,"Four base scores, unchanged")
	check(motion.trace.filter(func(e):return e.event=="bonus").size()==(4 if bonus else 0),"Specialization re-triggers remain exactly once")
	motion.cancel()
	check(motion._card_bursts.is_empty(),"Cancel releases every particle effect")
	motion.free();fan.free();await process_frame
func finish() -> void:
	await process_frame
	await process_frame
	await create_timer(0.2).timeout # Let stopped audio voices release their WAV references.
	print("CARD_POP checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
