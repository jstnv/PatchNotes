extends SceneTree
const Session:=preload("res://scripts/simulation/campaign_session.gd")
const Replay:=preload("res://scripts/simulation/development_replay.gd")
const C:=preload("res://scripts/employees/employee_career_rules.gd")
var failures:=0
var hands: Dictionary={}
var aligned:=0
var exercise_alignment:=false
var eight_in_one_project:=false
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
	var count: int=h._candidate_cards.size()
	for a in range(maxi(0,count-3)):
		for b in range(a+1,count-2):
			for c in range(b+1,count-1):
				for d in range(c+1,count):result.append([a,b,c,d])
	return result
func is_minimum_group(session: RefCounted,slots: Array) -> bool:
	var h: RefCounted=session.development.hand
	var beta: bool=session.phase()==&"beta"
	var stat: StringName=h._candidate_cards[slots[0]].beta_category if beta else h._candidate_cards[slots[0]].primary_stat
	var keys: Array=[&"graphics",&"sound",&"technology",&"design"]
	var key: Variant=stat
	if not beta:key=keys.find(stat)
	if (beta and stat not in [&"qa",&"marketing"]) or (not beta and stat not in keys):return false
	for slot: int in slots:
		var card: CardData=h._candidate_cards[slot]
		if (card.beta_category if beta else card.primary_stat)!=stat:return false
	var categories: Array=[&"qa",&"marketing",&"insider"] if beta else [0,1,2,3]
	var lowest:=101
	for category: Variant in categories:lowest=mini(lowest,int(h.priorities.get(category,101)))
	return h.priorities.get(key,-1)==lowest
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
		var priorities: Dictionary=BetaPriorityAllocation.editable_distribution({&"qa":35,&"marketing":30,&"insider":35},run) if phase==&"beta" else PriorityAllocation.normalize({0:25,1:25,2:25,3:25},[0,1,2,3],limits)
		return command(session,&"priorities",{"distribution":priorities}) if h.priorities!=priorities else command(session,&"begin")
	var key:=str(session.project_id())+":"+str(phase)
	var count: int=hands.get(key,0)
	if h._candidate_cards.is_empty():return command(session,&"request_exit")
	if h._candidate_cards.size()<4:
		var available: Array=[]
		for id in h.candidate_ids:available.append(id)
		hands[key]=count+1
		return command(session,&"play",{"candidate_ids":available})
	var manager:=employee(run,&"project_manager");var production:=employee(run,&"production")
	var manager_project: Dictionary=manager.career.projects.get(session.project_id(),{})
	var active_manager:=C.current_course(manager)
	var need_manager: bool=not active_manager.is_empty() and (C.manager_one_hands(manager)<8 if active_manager==&"manager_1" else manager_project.get("specializations",[]).size()<2)
	var course:=C.current_course(production)
	var need_match: bool=phase in [&"design",&"alpha"] and ((course==&"production_planning" and phase==&"design") or (course==&"pass_alignment" and production.career.projects.get(session.project_id(),{}).get(phase,[]).is_empty()))
	if exercise_alignment and aligned==0 and phase in [&"design",&"alpha"] and C.alignment_available(run._employees):
		for slot in h._candidate_cards.size():
			var offers: Array=dev.actions.alignment_options([slot] as Array[int])
			if not offers.is_empty():aligned+=1;return command(session,&"align_pass",{"quote":offers[0].quote})
	if count>0 and (not need_match and not need_manager or count>=40):return command(session,&"request_exit")
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
	if false and best_value<900 and (need_manager or need_match) and phase!=&"beta":
		var target: StringName=&"design"
		var feature_slot:=-1
		if need_match:
			for slot in h._candidate_cards.size():
				if h._candidate_cards[slot].card_type==&"feature":feature_slot=slot;target=h._candidate_cards[slot].primary_stat;break
		var rare: Array[int]=[]
		for slot in h._candidate_cards.size():
			if h._candidate_cards[slot].primary_stat==target:rare.append(slot)
		if rare.size()>0 or feature_slot>=0:
			if run.get_available_redraws()>0:
				for slot in h._candidate_cards.size():
					if slot in rare or slot==feature_slot or (phase==&"alpha" and h.candidate_ids[slot] in h.injected_candidate_ids):continue
					for offer: Dictionary in dev.actions.alignment_options([slot] as Array[int]):
						if offer.primary==target:aligned+=1;return command(session,&"align_pass",{"quote":offer.quote})
					if dev.actions.valid_redraw([slot] as Array[int],[] as Array[float]):return command(session,&"redraw",{"candidate_ids":[h.candidate_ids[slot]]})
			var keep: Array[int]=rare.slice(0,3)
			if feature_slot>=0 and feature_slot not in keep:
				if keep.size()==3:keep.pop_back()
				keep.append(feature_slot)
			var discard: Array=[]
			for slot in h._candidate_cards.size():
				if slot not in keep and discard.size()<4:discard.append(slot)
			best=discard
	var tokens: Array[int]=[]
	for slot: int in best:tokens.append(h.candidate_ids[slot])
	hands[key]=count+1
	return command(session,&"play",{"candidate_ids":tokens})
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	ProjectSettings.set_setting("gameplay/beta/insider_enabled",true)
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var snapshots:=PrimitiveSnapshotDatabase.new();snapshots.load_ledgers()
	var output:=OS.get_environment("PN_CARD_FRAME_OUTPUT")
	var _tiers:=1;var replay_path:="";var resume_path:=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tiers="):_tiers=int(arg.trim_prefix("--tiers="))
		if arg.begins_with("--replay="):replay_path=arg.trim_prefix("--replay=")
		if arg.begins_with("--resume="):resume_path=arg.trim_prefix("--resume=")
		if arg=="--exercise-alignment":exercise_alignment=true
	var session:=Session.new();var adapter:=StudioCheckpoint.new()
	if not replay_path.is_empty():
		var replay_initial: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(replay_path+".initial.json"))
		var restored:=adapter.hydrate(replay_initial)
		check(restored!=null and session.initialize(restored,catalog,snapshots),"Fresh process restores exact campaign start")
		var result:=Replay.replay(session,Replay.load_tape(replay_path+".tape.json"))
		check(result.ok,"Independent exact replay "+str(result.get("error",""))+" step "+str(result.get("step",-1)))
		print("CAREER_REPLAY ",JSON.stringify({"failures":failures,"steps":result.get("steps",[]).size()}));quit(failures);return
	var run: RunState
	if resume_path.is_empty():
		run=preload("res://scripts/debug/employee_test_actions.gd").fresh_two_releases(catalog)
		check(run.add_cash_cents(300000000,&"other_income",&"career_functional_fixture"),"Explicit $3m functional fixture; not solvency evidence")
		for id: StringName in [&"8_bit_sound",&"main_theme"]:
			if not run.owns_feature(id):check(run.admit_feature_research(run.get_feature_research_quote(id)) and run.research_feature(run.get_feature_research_quote(id)),"Acquire genuine Alpha training Feature "+str(id))
	else:
		run=adapter.hydrate(JSON.parse_string(FileAccess.get_file_as_string(resume_path)))
		check(run!=null,"Fresh process resumes previous tier's exact Studio "+adapter.error)
		if run==null:quit(failures);return
	check(session.initialize(run,catalog,snapshots),"Initialize actual career campaign")
	var initial:=adapter.capture(run);check(not initial.is_empty(),"Validated initial Studio")
	FileAccess.open(output+".initial.json",FileAccess.WRITE).store_string(JSON.stringify(initial))
	var tape:=Replay.begin(session);var low:=run.get_cash_cents();var completed:=false;var last_releases:=run.get_released_game_ids().size()
	for step in 4000:
		var _production:=employee(run,&"production")
		if C.level(run._employees)>=1 and not session.in_studio and not eight_in_one_project:
			var current_manager:=employee(run,&"project_manager")
			var _earned: Dictionary=current_manager.career.projects.get(session.project_id(),{})
			eight_in_one_project=C.manager_one_hands(current_manager)==8
			check(eight_in_one_project,"Eight qualifying hands complete before the current release")
			var payroll: Array=run.get_studio_finance_snapshot().employees
			var person: Array=payroll.filter(func(e):return e.employee_id==current_manager.employee_id)
			check(not person.is_empty() and StudioFinanceLedger.payroll_wage(person[0],StudioFinanceLedger.MAX_INT)==110000,"Completion schedules exactly one prospective raise")
		if session.in_studio and eight_in_one_project:completed=true;break
		var request:=choose(session)
		var result:=Replay.record(session,tape,request)
		low=mini(low,run.get_cash_cents())
		if not result.ok:check(false,"Campaign legal action "+str(request)+" result "+str(result));break
		if session.in_studio and run.get_released_game_ids().size()>last_releases:
			last_releases=run.get_released_game_ids().size()
			check(not adapter.capture(run).is_empty(),"Release checkpoint and career/payroll provenance "+str(last_releases)+" "+adapter.error)
			print("CAREER_PROGRESS ",JSON.stringify({"step":step,"releases":last_releases,"tier":C.level(run._employees),"cycle":run.get_completed_run_cycles(),"cash":run.get_cash_cents()}))
			Replay.save_tape(output+".tape.json",tape)
			FileAccess.open(output+".latest.json",FileAccess.WRITE).store_string(JSON.stringify(adapter.capture(run)))
	check(completed,"Actual committed hands/releases complete requested courses")
	var final:=adapter.capture(run) if session.in_studio else {}
	if not final.is_empty():FileAccess.open(output+".final.json",FileAccess.WRITE).store_string(JSON.stringify(final))
	check(Replay.save_tape(output+".tape.json",tape),"Source-pinned complete action tape retained")
	var report:={"failures":failures,"completed":completed,"steps":tape.steps.size(),"tier":C.level(run._employees),"releases":run.get_released_game_ids().size(),"cycles":run.get_completed_run_cycles(),"alignment_uses":aligned,"cash_low_cents":low,"cash_cents":run.get_cash_cents(),"functional_funding_cents":300000000 if resume_path.is_empty() else 0,"source":Replay.source_identity()}
	var actual_insider_hands: Array=run._employees.events.filter(func(e):return e.type==&"career_hand" and e.phase==&"beta" and int(e.priorities.get(&"insider",0))>0)
	check(not actual_insider_hands.is_empty(),"Actual campaign committed Beta hands with Insider active")
	check(EmployeeRoster.valid(run._employees),"Active-Insider campaign journal validates")
	var manager:=employee(run,&"project_manager");var credited:Dictionary={}
	for project:Dictionary in manager.career.projects.values():
		for action:Variant in project.get("specializations",[]):credited[action]=true
	var proven:=0
	for event:Dictionary in run._employees.events:
		if event.type!=&"career_hand":continue
		var identity:=StringName("%s:%s:%d"%[event.project_id,event.phase,event.project_cycle])
		if not credited.has(identity):continue
		var beta:bool=event.phase==&"beta";var stat:StringName=event.cards[0].beta if beta else event.cards[0].primary
		var keys:Array=[&"graphics",&"sound",&"technology",&"design"]
		var key:Variant=stat
		if not beta:key=keys.find(stat)
		var categories:Array=([&"qa",&"marketing",&"insider"] if int(event.priorities.get(&"insider",0))>0 else [&"qa",&"marketing"]) if beta else [0,1,2,3]
		var minimum:=101
		for category:Variant in categories:minimum=mini(minimum,int(event.priorities.get(category,101)))
		var valid_hand:bool=event.cards.size()==4 and event.cards.all(func(card):return (card.beta if beta else card.primary)==stat) and event.priorities.get(key,-1)==minimum
		check(valid_hand,"Recorded credited hand actually matches a lowest active priority")
		proven+=int(valid_hand)
	check(proven==8 and credited.size()==8,"Exactly eight committed hands independently satisfy the challenge")
	report.failures=failures;report.insider_hands=actual_insider_hands.size()
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report));print("CAREER_CAMPAIGN ",JSON.stringify(report));quit(failures)
