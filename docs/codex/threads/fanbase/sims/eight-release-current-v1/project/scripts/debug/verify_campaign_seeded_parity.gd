## Predeclared native/headless two-release routes. Uses the original maintained
## adapter and its exact three projection exclusions; no controlled game RNG.
extends "res://scripts/debug/verify_campaign_live_parity.gd"

const ROUTES := [
	{"seed":"1104","specialty":"puzzle","genres":["puzzle","adventure"],"selection":"front"},
	{"seed":"4417","specialty":"strategy","genres":["strategy","role_playing"],"selection":"reverse"},
	{"seed":"90210","specialty":"sports","genres":["racing","sports"],"selection":"features_first"},
]
const COMMAND_BOUND := 100
var route_reports: Array = []
var coverage := {"genres":{},"specialties":{},"selections":{},"planned_priorities":{"design":0,"alpha":0,"beta":0},"redraws":{"design":0,"alpha":0,"beta":0},"host_playtests":{"alpha":0,"beta":0}}

func compare(label: String) -> void:
	# Existing helpers may make one final comparison after a native action fails.
	# Retain its first evidence, then caller checks failures before another action.
	if failures: return
	super.compare(label)
	if tape.steps.size() > COMMAND_BOUND: expect(false,"Predeclared per-route command bound")

func _initial_priorities(route_index: int,project_index: int,phase_index: int) -> void:
	clear_signals()
	var distribution: Dictionary
	if phase_index == 2:
		distribution = {&"qa":50,&"marketing":30,&"insider":20} if (route_index+project_index)%2 == 0 else {&"qa":20,&"marketing":50,&"insider":30}
	else:
		distribution = {0:20,1:20,2:20,3:20}
		distribution[(route_index+project_index+phase_index)%4] = 40
	expect(game._active_phase.set_priority_distribution(distribution),"Native explicit initial priorities")
	if failures: return
	dev(&"priorities",{"distribution":distribution})
	compare("Planned priorities "+str(session.phase()))
	coverage.planned_priorities[str(session.phase())] += 1

func _redraw(route_index: int,phase_index: int) -> void:
	clear_signals()
	var slots: Array = [6] if (route_index+phase_index)%2 == 0 else [2,5]
	var ids: Array[int] = []
	for slot: int in slots: ids.append(session.development.hand.candidate_ids[slot])
	native_select(slots)
	expect(game._active_phase.redraw_selected_cards(),"Native seeded redraw")
	if failures: return
	dev(&"redraw",{"candidate_ids":ids})
	compare("Seeded redraw "+str(session.phase()))
	coverage.redraws[str(session.phase())] += 1

func _selection(mode: String) -> Array:
	# Only the visible current pool is consulted; no hidden future RNG or scores.
	var slots: Array = range(session.development.hand.candidate_ids.size())
	if mode == "reverse": slots.reverse()
	elif mode == "features_first":
		var cards: Array = session.development.hand._candidate_cards
		slots.sort_custom(func(a: int,b: int) -> bool:
			var first: CardData = cards[a]
			var second: CardData = cards[b]
			if (first.card_type == &"feature") != (second.card_type == &"feature"): return first.card_type == &"feature"
			return a < b)
	return slots.slice(0,4)

func _host_playtest() -> void:
	clear_signals()
	expect(game._active_phase.host_playtest(),"Native seeded "+str(session.phase())+" Host Playtest")
	if failures: return
	dev(&"host_playtest")
	compare("Seeded Host Playtest "+str(session.phase()))
	coverage.host_playtests[str(session.phase())] += 1

func _project(route: Dictionary,route_index: int,project_index: int) -> void:
	var genre := StringName(route.genres[project_index])
	coverage.genres[str(genre)] = true
	begin_project("Seeded %s %d" % [route.seed,project_index+1],genre)
	if failures: return
	for phase_index in range(3):
		_initial_priorities(route_index,project_index,phase_index)
		if failures: return
		begin_phase()
		if failures: return
		_redraw(route_index,phase_index)
		if failures: return
		play_slots(_selection(route.selection),"Selected "+route.selection+" "+str(session.phase()))
		if failures: return
		# One free Alpha playtest in project one and one paid Beta playtest in
		# project two. Their next refill is observed before ordinary phase exit.
		if (project_index == 0 and phase_index == 1) or (project_index == 1 and phase_index == 2):
			_host_playtest()
			if failures: return
		play_slots(_selection("features_first"),"Selected features_first "+str(session.phase()))
		if failures: return
		exit_phase()
		await process_frame
		if failures: return

func _write(path: String,value: Dictionary) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	expect(file != null,"Seeded parity evidence destination writable")
	if file != null: file.store_string(JSON.stringify(value,"\t"))

func _retain_route(recipe: Dictionary,route: Dictionary,start: int) -> void:
	var base := OS.get_environment("PN_CARD_FRAME_OUTPUT")+"."+route_id
	expect(Replay.save_tape(base+".tape.json",tape),"Retain exact seeded command tape")
	var states := {"native":snapshot(true),"headless":snapshot(false)}
	_write(base+".states.json",states)
	_write(base+".trace.json",{"route":route,"recipe":recipe,"traces":traces.slice(start),"failures":failures,"command_bound":COMMAND_BOUND})
	var replayed: Dictionary = {"ok":false,"error":"Route stopped before replay verification"}
	if not failures:
		var fresh: RefCounted = Bootstrap.create_fresh_session(recipe,root.get_node("CardDatabase"))
		expect(fresh != null,"Fresh seeded replay session initializes")
		if fresh != null:
			replayed = Replay.replay(fresh,tape)
			expect(replayed.ok and replayed.get("final_state") == Replay.digest(Replay.state(session)),"Full seeded route exactly replays")
	_write(base+".replay.json",replayed)
	route_reports.append({"id":route_id,"recipe":recipe,"route":route,"boundaries":traces.size()-start,"commands":tape.steps.size(),"releases":session.run.get_released_game_ids().size(),"final_state":Replay.digest(Replay.state(session)),"strict_replay_ok":replayed.ok,"ok":failures == 0})

func _initialize() -> void:
	await process_frame
	var output := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if output.is_empty():
		push_error("PN_CARD_FRAME_OUTPUT required for isolated seeded parity evidence")
		quit(2)
		return
	for route_index in range(ROUTES.size()):
		var route: Dictionary = ROUTES[route_index]
		route_id = "seeded_"+route.seed+"_"+route.specialty
		segment = 0
		coverage.specialties[route.specialty] = true
		coverage.selections[route.selection] = true
		var recipe := {"schema_version":1,"studio_id":route_id,"studio_name":"Seeded live parity","specialty":route.specialty,"traits":[],"seed":route.seed}
		var trace_start := traces.size()
		var coordinator := start_route(recipe)
		if not failures: await _project(route,route_index,0)
		# The same ordinary Ironclad route funds the second project. Its real
		# advance, paid hands, completion and rent are compared by the adapter.
		if not failures: contract()
		if not failures: await _project(route,route_index,1)
		if not failures:
			expect(session.run.get_released_game_ids().size() == 2 and session.in_studio,"Two legal releases reach Studio for "+route_id)
			expect(coordinator.flush(),"Native seeded Studio checkpoint flushes")
		_retain_route(recipe,route,trace_start)
		game.free()
		await process_frame
		if failures: break
	if not failures:
		expect(route_reports.size() == ROUTES.size(),"Every predeclared seed completed without replacement")
		for phase in ["design","alpha","beta"]:
			expect(coverage.redraws[phase] == ROUTES.size()*2 and coverage.planned_priorities[phase] == ROUTES.size()*2,"All projects cover redraw and priority planning in "+phase)
		expect(coverage.host_playtests.alpha == ROUTES.size() and coverage.host_playtests.beta == ROUTES.size(),"Declared Alpha and Beta Host Playtests completed")
	_write(output,{"ok":failures == 0,"failures":failures,"comparisons":comparisons,"routes":route_reports,"coverage":coverage,"traces":traces,"limits":"Bounded native scene methods versus shared headless commands; original HUD/coordinator exclusions; no visual/audio acceptance or AI policy claim"})
	print("Seeded campaign parity: %d failures, %d boundaries, %d routes" % [failures,comparisons,route_reports.size()])
	quit(1 if failures else 0)
