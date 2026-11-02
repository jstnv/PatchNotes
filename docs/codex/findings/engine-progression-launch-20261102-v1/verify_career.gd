extends SceneTree
const Campaign=preload("res://scripts/simulation/campaign_session.gd")
const Browser=preload("res://scripts/ui/engine_market_browser.gd")
var checks:=0
var failures:=0
var trace:Array=[]
var run:RunState
var session:RefCounted
var engine:StringName
var browser:Control
var career_world:RivalWorld
var rival_ticks:=0
var feature_plays:=0
var secondary_plays:=0
var alpha_features:=0
var actual_pass_bonus:=0
var gen_two_bug_hands:=0
var gen_one_bonus_hands:=0
func check(ok:bool,label:String)->bool:
	checks+=1
	print("PASS: " if ok else "FAIL: ",label)
	if not ok:failures+=1
	return ok
func _initialize()->void:go.call_deferred()
func issue(kind:StringName,payload:Dictionary={})->Dictionary:
	var result:Dictionary=session.execute(session.command(kind,payload))
	trace.append({"kind":kind,"payload":payload,"ok":result.ok,"error":result.get("error",""),"cycle":run.get_completed_run_cycles(),"cash":run.get_cash_cents()})
	return result
func dev(kind:StringName,payload:Dictionary={})->Dictionary:
	return issue(&"development",{"request":session.development.command(kind,payload)})
func project(name:String)->bool:
	if not check(issue(&"begin_development",{"name":name,"genre":&"action","theme":&"fantasy"}).ok,"Normal project begins: "+name):return false
	for phase in 3:
		if phase>0 and not check(dev(&"enter_next_phase").ok,"Enter phase "+str(phase)):return false
		if not check(dev(&"begin").ok,"Ordinary initial deal "+str(phase)):return false
		var played:=0
		var seen_features:Dictionary={}
		var budget_bonus:=0
		for step in 65:
			var hand:RefCounted=session.development.hand
			var ids:Array=[]
			var cards:Array[CardData]=[]
			# Prefer finite Features; otherwise advance actual legal Pass candidates.
			for i in hand.candidate_ids.size():
				var card:CardData=hand._candidate_cards[i]
				if (phase<2 and card.card_type==&"feature") or (phase==2 and card.qa_operation==CardData.QA_OPERATION_SEARCH and session.development.project.get_hidden_bugs()>0):
					ids.append(hand.candidate_ids[i]);cards.append(card)
					if ids.size()==4:break
			if ids.is_empty():
				if phase<2 and played>0:
					var all_done:=true
					for card:CardData in session.catalog.get_project_features_for_phase(session.development.project,session.development.PHASES[phase]):
						if not seen_features.has(card.id):all_done=false;break
					if all_done and not (session.development.project.get_engine_id()==engine and run.ProprietaryEngines.milestone(run.get_proprietary_engine_row(engine))==2 and actual_pass_bonus==0):break
				if phase<2 and session.development.project.get_engine_id()==engine and not run.get_proprietary_engine_row(engine).pass_effectiveness.is_empty():
					for i in hand.candidate_ids.size():
						var pass_card:CardData=hand._candidate_cards[i]
						if pass_card.card_type==&"pass" and pass_card.primary_stat in [&"graphics",&"sound"]:
							ids=[hand.candidate_ids[i]];cards.assign([pass_card]);break
				if ids.is_empty():
					for i in mini(4,hand.candidate_ids.size()):ids.append(hand.candidate_ids[i]);cards.append(hand._candidate_cards[i])
			if ids.is_empty():break
			var before:Dictionary=run.get_proprietary_engine_row(engine)
			var project_state:ProjectState=session.development.project
			var cores_before:Array=[]
			for category in 4:cores_before.append(project_state.get_core_score(category))
			var remainders:Dictionary=project_state._skill_pass_remainders.duplicate()
			var pressure_before:float=project_state.get_accumulated_bug_pressure() if phase==0 else project_state.get_accumulated_alpha_bug_pressure()
			var outcome:=dev(&"play",{"candidate_ids":ids})
			if not outcome.ok:
				# A partial hand is a normal legal route when a larger combination is unavailable.
				outcome={"ok":false}
				for i in hand.candidate_ids.size():
					ids=[hand.candidate_ids[i]];cards.assign([hand._candidate_cards[i]])
					outcome=dev(&"play",{"candidate_ids":ids})
					if outcome.ok:break
			if not check(outcome.ok,"Accepted ordinary hand phase%d step%d"%[phase,step]):return false
			played+=1
			for accepted:CardData in cards:
				if accepted.card_type==&"feature":seen_features[accepted.id]=true
			if phase<2:
				var expected:=before.duplicate(true)
				var effect_row:Dictionary=before if project_state.get_engine_id()==engine else {}
				var expected_pressure:=0.0
				for card:CardData in cards:
					if card.card_type!=&"feature":continue
					var weighted:=0.0
					for contribution:Dictionary in card.core_contributions():
						weighted+=float(contribution.value)*(1.0-float(effect_row.get("bug_prevention",{}).get(contribution.stat,0))/100.0)
						budget_bonus+=int(contribution.value)*int(effect_row.get("pass_efficiency",{}).get(contribution.stat,0))
					expected_pressure+=weighted*float(card.scope)/18.0
				var pressure_after:float=project_state.get_accumulated_bug_pressure() if phase==0 else project_state.get_accumulated_alpha_bug_pressure()
				check(absf(pressure_after-pressure_before-expected_pressure)<0.00001,"Accepted Feature bug pressure applies only owned category reductions")
				check(int(session.development.pass_budget_state().get("bonus_centi",0))==budget_bonus,"Exact purchased GenI budget contribution, excluding Passes and synergy")
				if budget_bonus>0:gen_one_bonus_hands+=1
				if not effect_row.get("bug_prevention",{}).is_empty() and expected_pressure>0.0:gen_two_bug_hands+=1
				if cards.size()==1 and cards[0].card_type==&"pass" and effect_row.get("pass_effectiveness",{}).has(cards[0].primary_stat):
					var pass_card:CardData=cards[0]
					var category:int=0 if pass_card.primary_stat==&"graphics" else 1
					var numerator:int=int(remainders.get(pass_card.primary_stat,0))+pass_card.primary_value
					check(project_state.get_core_score(category)-int(cores_before[category])==pass_card.primary_value+numerator/10 and int(project_state._skill_pass_remainders.get(pass_card.primary_stat,0))==numerator%10,"Real GenII Pass effect grants exact marginal bonus and fraction")
					actual_pass_bonus+=numerator/10
				for card:CardData in cards:
					if card.card_type!=&"feature":continue
					feature_plays+=1
					if not card.secondary_stat.is_empty():secondary_plays+=1
					if phase==1:alpha_features+=1
					if session.development.project.get_engine_id()!=engine:continue
					# Independent printed-Core oracle, never calls credit or mutates live counters.
					for contribution:Dictionary in card.core_contributions():
						var branch:StringName=contribution.stat
						if branch not in run.ProprietaryEngines.BRANCHES:continue
						var level:int=expected.branch_progress.get(branch,0)
						if level>=2:continue
						var threshold:int=run.ProprietaryEngines.node(branch,level+1).threshold
						expected.challenge_progress[branch]=mini(threshold,int(expected.challenge_progress.get(branch,0))+int(contribution.value))
				if not check(run.get_proprietary_engine_row(engine)==expected,"Only accepted matching-engine printed Feature Core advances challenges"):return false
				browser._inspect(engine);browser._open_skill_tree()
				if not check(text_of(browser.skill_tree).contains("%d/"%int(expected.challenge_progress.get(&"graphics",0))) or int(expected.branch_progress.get(&"graphics",0))>=2,"UI reflects current challenge immediately"):return false
			if phase==2:
				if career_world==null and played>=3:break
				if career_world!=null and session.development.project.get_remaining_bugs()==0 and session.development.project.get_marketing_output()>=8:break
				if played>=20:break
		if not check(played>0,"Each phase actually plays cards"):return false
		var exit:=dev(&"request_exit")
		if not check(exit.ok,"Normal phase exit request"):return false
		if session.development.awaiting_confirmation and not check(dev(&"confirm_exit").ok,"Normal under-Scope/launch confirmation"):return false
	if not check(issue(&"launch").ok,"Normal Review, launch and Studio return"):return false
	print("GAME ",name," cash=",run.get_cash_cents()," cycle=",run.get_completed_run_cycles()," progress=",run.get_proprietary_engine_row(engine))
	return true
func text_of(node:Node)->String:
	var value:String=str(node.get("text")) if node is Label or node is Button else ""
	for child in node.get_children():value+="\n"+text_of(child)
	return value
func go()->void:
	await process_frame
	run=RunState.new();run.initialize_cash(0)
	if not check(run.create_studio_with_traits("Legal Progression",&"action",[]),"Fresh starting economy"):quit(1);return
	var settings:Dictionary={}
	if not OS.get_environment("PN_CONTRACT_FIXTURE").is_empty():settings=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_CONTRACT_FIXTURE")))
	if settings.get("world",false):
		career_world=preload("res://scripts/market/rival_trial.gd").create_world(run,root.get_node("CardDatabase").get_development_catalog())
		if not check(career_world!=null and career_world.studios.size()==8,"Normal certified eight-rival opening"):quit(1);return
		run.calendar_changed.connect(func():
			var tick:Dictionary=career_world.advance_committed_player_cycle(preload("res://scripts/market/rival_trial.gd").policies(career_world),preload("res://scripts/market/rival_trial.gd").ZERO_STEPS)
			check(tick.ok,"Normal player productive cycle advances every rival")
			if tick.ok:rival_ticks+=1)
	var created:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Career Engine"))
	if not check(created.get("ok",false),"Pay normal100-dollar engine creation"):quit(1);return
	engine=created.engine_id
	FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT").get_base_dir().path_join("initial-player.json"),FileAccess.WRITE).store_string(JSON.stringify(StudioCheckpoint.new().capture(run)))
	check(run.get_engine_feature_state().engines[engine].capacity==25,"Fresh25-Scope capacity")
	var snapshots:=PrimitiveSnapshotDatabase.new();snapshots.load_ledgers()
	session=Campaign.new();session.initialize(run,root.get_node("CardDatabase").get_development_catalog(),snapshots)
	browser=Browser.new();root.add_child(browser);browser.open(run,null,engine);browser._open_skill_tree()
	# Fund real acquisition with normal public-engine production, never debug cash.
	if not project("Public Funding1"):finish();return
	check(run.get_proprietary_engine_row(engine).challenge_progress.is_empty(),"Other engines never advance owned challenges")
	for funding in 2:
		if run.get_cash_cents()>=850000:break
		if not project("Public Funding"+str(funding+2)):finish();return
	for id:StringName in [&"text",&"4_color_palette",&"8_bit_sound",&"keyboard_and_mouse",&"menu_system",&"score_system",&"timer_system",&"main_theme"]:
		var quote:=run.get_feature_research_quote(id,engine)
		if not check(issue(&"admit_research",{"quote":quote}).ok,"Pay Feature admission: "+str(id)):finish();return
		quote=run.get_feature_research_quote(id,engine)
		if not check(issue(&"research",{"quote":quote}).ok,"Pay productive implementation: "+str(id)):finish();return
	if not check(issue(&"select_engine",{"engine_id":engine}).ok,"Select proprietary engine through normal command"):finish();return
	for game in 6:
		if not project("Proprietary"+str(game+1)):finish();return
		browser._inspect(engine);browser._open_skill_tree()
		for branch:StringName in run.ProprietaryEngines.BRANCHES:
			var quote:=run.get_engine_skill_quote(engine,branch)
			if quote.is_empty():continue
			var before:=run.get_cash_cents();var cycles:=run.get_completed_run_cycles()
			var level:int=run.ProprietaryEngines.generation(run.get_proprietary_engine_row(engine),branch)+1
			var button:=browser.find_child("EngineSkill_%s_%d"%[branch,level],true,false) as Button
			if not check(button!=null and not button.disabled,"Normal UI node purchase available: "+str(branch)):finish();return
			button.pressed.emit()
			trace.append({"kind":"purchase_engine_skill","quote":quote,"cash":run.get_cash_cents(),"cycle":run.get_completed_run_cycles()})
			if not check(run.get_cash_cents()==before-int(quote.cost_cents) and run.get_completed_run_cycles()==cycles,"Node fee only, no cycle or Scope fee"):finish();return
			check(not run.purchase_engine_skill(quote).get("ok",false),"Duplicate/stale node purchase rejects")
			check(not run.get_proprietary_engine_row(engine).challenge_progress.has(branch),"Successor challenge begins at zero")
		var milestone:int=run.ProprietaryEngines.milestone(run.get_proprietary_engine_row(engine))
		check(run.get_engine_feature_state().engines[engine].capacity==25+5*milestone,"Capacity matches automatic unique milestone")
		var adapter:=StudioCheckpoint.new();var saved:=adapter.capture(run);var loaded:=adapter.hydrate(saved)
		if not check(loaded!=null and adapter.capture(loaded)==saved,"Exact Studio save/load preserves challenges, purchases, cash, history and RNG"):finish();return
		if milestone==2:break
	check(run.get_engine_feature_state().engines[engine].capacity==35,"Actual gameplay completes25â†’30â†’35")
	check(feature_plays>0 and secondary_plays>0 and alpha_features>0,"Real Features include secondary Core and Alpha activations")
	check(run.get_proprietary_engine_row(engine).scope_milestones==[&"generation_1",&"generation_2"],"Both milestones granted exactly once")
	if career_world!=null:
		verify_world_boundary()
		finish();return
	if run.get_cash_cents()<400000:
		var loan:=run.get_bank_quote(300000,12)
		if not check(issue(&"bank_borrow",{"quote":loan}).ok,"Normal Bank finances post-completion effect coverage"):finish();return
	if not project("Purchased Effects"):finish();return
	check(actual_pass_bonus>0 and gen_one_bonus_hands>0 and gen_two_bug_hands>0,"Actual subsequent hands exercise all purchased effect families")
	if run.get_cash_cents()<120000:
		var loan:=run.get_bank_quote(300000,12)
		if not check(issue(&"bank_borrow",{"quote":loan}).ok,"Ordinary Bank financing for optional second-engine coverage"):finish();return
	var second:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Independent Engine"))
	if not check(second.get("ok",false),"Create independent second engine with its normal fee"):finish();return
	var other:StringName=second.engine_id
	for kind:StringName in [&"admit_research",&"research"]:
		if not check(issue(kind,{"quote":run.get_feature_research_quote(&"text",other)}).ok,"Pay second engine Text implementation"):finish();return
	check(issue(&"select_engine",{"engine_id":other}).ok,"Select independent engine")
	var completed_row:=run.get_proprietary_engine_row(engine)
	if not project("Independent Progress"):finish();return
	check(run.get_proprietary_engine_row(engine)==completed_row and int(run.get_proprietary_engine_row(other).challenge_progress.get(&"graphics",0))==3,"Second engine earns its own partial challenge only")
	var adapter:=StudioCheckpoint.new();var current:=adapter.capture(run)
	var prior:=adapter.hydrate(current)
	prior._proprietary_engines.version=2
	for id:StringName in prior._proprietary_engines.engines:prior._engine_features.engines[id].capacity-=5
	var previous_format:=adapter.capture(prior)
	check(not previous_format.is_empty(),"Constructed version2 progressed/partial state validates under its old capacities")
	var upgraded:=adapter.hydrate(previous_format)
	check(upgraded!=null and adapter.capture(upgraded)==current,"Version2 migration changes only capacities/version; all real purchases, partial progress, finance/history/RNG preserved")

	finish()
func verify_world_boundary()->void:
	var adapter:=StudioCheckpoint.new();var current:=adapter.capture(run)
	var world_codec:=preload("res://scripts/market/rival_world_checkpoint.gd").new()
	check(career_world.studios.size()==8 and career_world.cycle==run.get_completed_run_cycles() and rival_ticks==run.get_completed_run_cycles(),"Eight rivals actually advanced on every player cycle")
	var current_world:Dictionary=world_codec.capture(career_world)
	if not check(not current_world.is_empty(),"Full legal career world remains valid"):return
	var cold_player:=adapter.hydrate(current)
	var cold_world:RivalWorld=world_codec.restore(current_world,current,cold_player,session.catalog)
	check(cold_world!=null and world_codec.capture(cold_world)==current_world and adapter.capture(cold_player)==current,"Full eight-rival/player cold Continue preserves entire progression, finance, history and RNG")
	FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT").get_base_dir().path_join("final-world-pair.json"),FileAccess.WRITE).store_string(JSON.stringify({"player":current,"world":current_world}))
func finish()->void:
	var directory:=OS.get_environment("PN_CONTRACT_REPORT").get_base_dir()
	FileAccess.open(directory.path_join("career-trace.json"),FileAccess.WRITE).store_string(JSON.stringify(trace))
	FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"cash":run.get_cash_cents(),"cycle":run.get_completed_run_cycles(),"feature_plays":feature_plays,"secondary_plays":secondary_plays,"alpha_features":alpha_features,"actual_pass_bonus":actual_pass_bonus,"world_studios":career_world.studios.size() if career_world!=null else 0,"rival_ticks":rival_ticks,"gen_one_bonus_hands":gen_one_bonus_hands,"gen_two_bug_hands":gen_two_bug_hands,"engine":run.get_proprietary_engine_row(engine)}))
	browser.queue_free();await process_frame;quit(1 if failures else 0)
