extends SceneTree
const Session:=preload("res://scripts/simulation/campaign_session.gd")
const Replay:=preload("res://scripts/simulation/development_replay.gd")
const C:=preload("res://scripts/employees/employee_career_rules.gd")
var failures:=0
var hands: Dictionary={}
var aligned:=0
func check(ok: bool,label: String) -> void:
	print("PASS: " if ok else "FAIL: ",label)
	if not ok:failures+=1
func employee(run: RunState,role: StringName) -> Dictionary:
	for e: Dictionary in run._employees.employees.values():
		if e.type==role:return e
	return {}
func command(session: RefCounted,kind: StringName,payload: Dictionary={}) -> Dictionary:
	return session.command(&"development",{"request":session.development.command(kind,payload)})
func combinations(h: RefCounted) -> Array:
	var result: Array=[]
	for a in 4:
		for b in range(a+1,5):
			for c in range(b+1,6):
				for d in range(c+1,7):result.append([a,b,c,d])
	return result
func is_minimum_group(session: RefCounted,slots: Array) -> bool:
	var h: RefCounted=session.development.hand
	var beta: bool=session.phase()==&"beta"
	var stat: StringName=h._candidate_cards[slots[0]].beta_category if beta else h._candidate_cards[slots[0]].primary_stat
	var keys: Array=[&"graphics",&"sound",&"technology",&"design"]
	var key: Variant=stat if beta else keys.find(stat)
	if (beta and stat not in [&"qa",&"marketing"]) or (not beta and stat not in keys):return false
	for slot: int in slots:
		var card: CardData=h._candidate_cards[slot]
		if (card.beta_category if beta else card.primary_stat)!=stat:return false
	return h.priorities.get(key,-1)==(BetaPriorityAllocation.bounds(session.run).x if beta else PriorityAllocation.bounds(session.run).x)
func choose(session: RefCounted) -> Dictionary:
	var run: RunState=session.run
	if session.in_studio:
		for role: StringName in [&"production",&"project_manager"]:
			var e:=employee(run,role)
			if e.is_empty():return session.command(&"hire",{"quote":run.get_employee_hire_quote(role)})
			var next:=C.next_course(e)
			if not next.is_empty():return session.command(&"course",{"quote":run.get_employee_course_quote(e.employee_id,next)})
		return session.command(&"begin_development",{"name":"Career game %d"%(run.get_released_game_ids().size()+1),"genre":"action","theme":"fantasy"})
	var dev: RefCounted=session.development;var h: RefCounted=dev.hand;var phase: StringName=session.phase()
	if dev.finalized:return session.command(&"launch") if phase==&"beta" else command(session,&"enter_next_phase")
	if dev.awaiting_confirmation:return command(session,&"confirm_exit")
	if not h.active:
		var limits:=PriorityAllocation.bounds(run)
		var priorities: Dictionary=BetaPriorityAllocation.editable_distribution({&"qa":BetaPriorityAllocation.bounds(run).x,&"marketing":BetaPriorityAllocation.bounds(run).y,&"insider":0},run) if phase==&"beta" else PriorityAllocation.normalize({0:40,1:30,2:30-limits.x,3:limits.x},[0,1,2,3],limits)
		return command(session,&"priorities",{"distribution":priorities}) if h.priorities!=priorities else command(session,&"begin")
	var key:=str(session.project_id())+":"+str(phase)
	var count: int=hands.get(key,0)
	var manager:=employee(run,&"project_manager");var production:=employee(run,&"production")
	var manager_project: Dictionary=manager.career.projects.get(session.project_id(),{})
	var need_manager:=not C.current_course(manager).is_empty() and manager_project.get("specializations",[]).size()<2
	var course:=C.current_course(production)
	var need_match: bool=phase in [&"design",&"alpha"] and ((course==&"production_planning" and phase==&"design") or (course==&"pass_alignment" and production.career.projects.get(session.project_id(),{}).get(phase,[]).is_empty()))
	if count>0 and (not need_match and (not need_manager or phase==&"beta" and count>=2) or count>=120):return command(session,&"request_exit")
	var best: Array=[];var best_value:=-100000
	for slots: Array in combinations(h):
		var cards: Array=[]
		for slot: int in slots:cards.append(h._candidate_cards[slot])
		var matching: bool=phase!=&"beta" and EmployeeRoster.matches(EmployeeRoster.card_facts(cards))
		var minimum:=is_minimum_group(session,slots)
		var score:=int(matching and need_match)*1000+int(minimum and need_manager)*900
		if phase==&"beta":score+=cards.filter(func(card):return card.beta_category==&"marketing").size()*5
		else:score+=cards.filter(func(card):return card.card_type==&"feature").size()
		if score>best_value:best_value=score;best=slots
	if best_value<900 and (need_manager or need_match) and phase!=&"beta":
		var target: StringName=&"design"
		var feature_slot:=-1
		if need_match:
			for slot in 7:
				if h._candidate_cards[slot].card_type==&"feature":feature_slot=slot;target=h._candidate_cards[slot].primary_stat;break
		var rare: Array[int]=[]
		for slot in 7:
			if h._candidate_cards[slot].primary_stat==target:rare.append(slot)
		if rare.size()>0 or feature_slot>=0:
			if run.get_available_redraws()>0:
				for slot in 7:
					if slot in rare or slot==feature_slot or (phase==&"alpha" and h.candidate_ids[slot] in h.injected_candidate_ids):continue
					for offer: Dictionary in dev.actions.alignment_options([slot] as Array[int]):
						if offer.primary==target:aligned+=1;return command(session,&"align_pass",{"quote":offer.quote})
					if dev.actions.valid_redraw([slot] as Array[int],[]):return command(session,&"redraw",{"candidate_ids":[h.candidate_ids[slot]]})
			var keep: Array[int]=rare.slice(0,3)
			if feature_slot>=0 and feature_slot not in keep:
				if keep.size()==3:keep.pop_back()
				keep.append(feature_slot)
			var discard: Array=[]
			for slot in 7:
				if slot not in keep and discard.size()<4:discard.append(slot)
			best=discard
	var tokens: Array[int]=[]
	for slot: int in best:tokens.append(h.candidate_ids[slot])
	hands[key]=count+1
	return command(session,&"play",{"candidate_ids":tokens})
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var snapshots:=PrimitiveSnapshotDatabase.new();snapshots.load_ledgers()
	var output:=OS.get_environment("PN_CARD_FRAME_OUTPUT")
	var tiers:=1;var replay_path:=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tiers="):tiers=int(arg.trim_prefix("--tiers="))
		if arg.begins_with("--replay="):replay_path=arg.trim_prefix("--replay=")
	var session:=Session.new();var adapter:=StudioCheckpoint.new()
	if not replay_path.is_empty():
		var initial: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(replay_path+".initial.json"))
		var restored:=adapter.hydrate(initial)
		check(restored!=null and session.initialize(restored,catalog,snapshots),"Fresh process restores exact campaign start")
		var result:=Replay.replay(session,Replay.load_tape(replay_path+".tape.json"))
		check(result.ok,"Independent exact replay "+str(result.get("error",""))+" step "+str(result.get("step",-1)))
		print("CAREER_REPLAY ",JSON.stringify({"failures":failures,"steps":result.get("steps",[]).size()}));quit(failures);return
	var run: RunState=preload("res://scripts/debug/employee_test_actions.gd").fresh_two_releases(catalog)
	check(run.add_cash_cents(300000000,&"other_income",&"career_functional_fixture"),"Explicit $3m functional fixture; not solvency evidence")
	for id: StringName in [&"8_bit_sound",&"main_theme"]:
		if not run.owns_feature(id):check(run.admit_feature_research(run.get_feature_research_quote(id)) and run.research_feature(run.get_feature_research_quote(id)),"Acquire genuine Alpha training Feature "+str(id))
	check(session.initialize(run,catalog,snapshots),"Initialize actual career campaign")
	var initial:=adapter.capture(run);check(not initial.is_empty(),"Validated initial Studio")
	FileAccess.open(output+".initial.json",FileAccess.WRITE).store_string(JSON.stringify(initial))
	var tape:=Replay.begin(session);var low:=run.get_cash_cents();var completed:=false;var last_releases:=2
	for step in 4000:
		var production:=employee(run,&"production")
		if session.in_studio and C.level(run._employees)>=tiers and not production.is_empty() and C.completed(production)==2:completed=true;break
		var request:=choose(session)
		var result:=Replay.record(session,tape,request)
		low=mini(low,run.get_cash_cents())
		if not result.ok:check(false,"Campaign legal action "+str(request)+" result "+str(result));break
		if session.in_studio and run.get_released_game_ids().size()>last_releases:
			last_releases=run.get_released_game_ids().size()
			check(not adapter.capture(run).is_empty(),"Release checkpoint and career/payroll provenance "+str(last_releases)+" "+adapter.error)
			print("CAREER_PROGRESS ",JSON.stringify({"step":step,"releases":last_releases,"tier":C.level(run._employees),"cycle":run.get_completed_run_cycles(),"cash":run.get_cash_cents()}))
	check(completed,"Actual committed hands/releases complete requested courses")
	var final:=adapter.capture(run) if session.in_studio else {}
	if not final.is_empty():FileAccess.open(output+".final.json",FileAccess.WRITE).store_string(JSON.stringify(final))
	check(Replay.save_tape(output+".tape.json",tape),"Source-pinned complete action tape retained")
	var report:={"failures":failures,"completed":completed,"steps":tape.steps.size(),"tier":C.level(run._employees),"releases":run.get_released_game_ids().size(),"cycles":run.get_completed_run_cycles(),"alignment_uses":aligned,"cash_low_cents":low,"cash_cents":run.get_cash_cents(),"functional_funding_cents":300000000,"source":Replay.source_identity()}
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report));print("CAREER_CAMPAIGN ",JSON.stringify(report));quit(failures)
