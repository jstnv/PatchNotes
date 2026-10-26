extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Fixture := preload("res://scripts/simulation/finite_fixture_policy.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const IDS := [&"turn_based_combat",&"character_classes",&"character_development",&"branching_dialogue"]
const PARENTS := [[&"general_combat"],[&"general_combat",&"save_files"],[&"character_backstories",&"save_files"],[&"dialogue",&"branching_nodes"]]
var checks := 0
var failures := 0
var catalog: RefCounted
var evidence: Array = []
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error("Alpha pack: "+label)
func recipe(index: int) -> Dictionary:
	return {"schema_version":1,"studio_id":"alpha-pack-"+str(index),"studio_name":"Alpha pack fixture","specialty":"action" if index<2 else "adventure","traits":[],"seed":str(4417+index)}
func fresh(index: int) -> RefCounted:
	var session: RefCounted=Factory.create_fresh_session(recipe(index),catalog)
	check(session.run.finalize_starter_selection(),"confirm initial specialty supply")
	# Explicit funded mechanics fixture, not a new-game affordability/balance run.
	check(session.run.add_cash_cents(5000000,&"other_income",&"alpha_pack_test_funding"),"recorded fixture funding")
	return session
func execute(session: RefCounted,tape: Dictionary,kind: StringName,payload: Dictionary={}) -> Dictionary:
	var result:=Replay.record(session,tape,session.command(kind,payload))
	check(result.ok,"legal command "+str(kind)+": "+str(result.get("error","")))
	return result
func acquire(session: RefCounted,tape: Dictionary,id: StringName) -> void:
	if session.run.owns_feature(id): return
	var quote: Dictionary=session.run.get_feature_store_offer(id)
	for parent: StringName in quote.get("purchase_parents",[]): acquire(session,tape,parent)
	# Root ancestors are explicit too; never auto-purchased by gameplay.
	var path: Dictionary=session.run.get_feature_acquisition_quote(id)
	for step: Dictionary in path.get("steps",[]):
		var next:=StringName(step.id)
		if session.run.owns_feature(next): continue
		execute(session,tape,&"admit_research",{"quote":session.run.get_feature_research_quote(next)})
		execute(session,tape,&"research",{"quote":session.run.get_feature_research_quote(next)})
func _initialize() -> void:
	await process_frame
	create_timer(150).timeout.connect(func(): push_error("Alpha pack verifier timed out");quit(2))
	catalog=root.get_node("CardDatabase").get_development_catalog()
	var output:=OS.get_environment("PN_CARD_FRAME_OUTPUT")
	var adapter:=StudioCheckpoint.new()
	if OS.get_environment("PN_ALPHA_PACK_COLD")=="1":
		var data: Array=JSON.parse_string(FileAccess.get_file_as_string(output))
		for index in IDS.size():
			for key in ["queued","completed"]:
				var payload: Dictionary=data[index][key]
				var restored:=adapter.hydrate(payload)
				check(restored!=null,"cold "+key+" "+str(IDS[index])+": "+adapter.error)
				if restored!=null: check(adapter.capture(restored)==payload,"cold exact fields/cents/RNG")
			var result:=Replay.replay(fresh(index),Replay.load_tape(output+"."+str(index)+".tape.json"))
			check(result.ok,"fresh exact action replay "+str(IDS[index])+": "+str(result.get("error","")))
		print("ALPHA_PACK_COLD checks=%d failures=%d"%[checks,failures]);quit(failures);return
	check(FeatureStoreCatalog.entries().size()==15 and FeatureStoreCatalog.starting_features().size()==27,"exactly four later nodes; Primitive ledger untouched")
	for index in IDS.size():
		var id: StringName=IDS[index]
		var card: CardData=catalog.cards[id]
		check(card.phase==&"alpha" and not card.renewable and card.scope==2 and card.department==(&"gameplay" if index<2 else &"story"),"finite Alpha identity/department "+str(id))
		check(card.primary_stat==(&"design" if index in [0,2] else &"technology") and card.primary_value==(5 if index in [0,2] else 2) and card.secondary_value==(0 if index in [0,2] else 3),"ordered printed contributions "+str(id))
		check(WeightedCandidateMath.calculate_printed_score_weight(card,{0:10,1:20,2:30,3:40},{&"graphics":0,&"sound":1,&"technology":2,&"design":3})==(200.0 if index in [0,2] else 180.0),"weight uses both ordered printed contributions")
		check(not StudioSpecialties.preview(&"action").ids.has(id) and not StudioSpecialties.preview(&"adventure").ids.has(id),"no specialty auto-grant")
		var run:=RunState.new();run.initialize_cash_cents(3000000)
		for parent: StringName in PARENTS[index]: run._owned_features.erase(parent)
		for parent: StringName in PARENTS[index]:
			var before:=Replay.digest(Replay.freeze(run))
			check(not run.admit_feature_research(run.get_feature_research_quote(id)) and Replay.digest(Replay.freeze(run))==before,"each missing parent rejects without state/RNG "+str(parent))
			run._feature_research.append({"feature_id":parent,"actions":1,"payments":[]})
			check(not run.get_feature_store_offer(id).unlocked,"queued parent is not owned")
			run._feature_research.clear();run._owned_features[parent]=true
		var same:=ProjectState.new(30)
		for parent: StringName in PARENTS[index]:
			var parent_card: CardData=catalog.cards[parent]
			check(run.record_resolved_feature(same,parent,parent_card.phase),"same-project distinct parent credit")
		for credit in 6:
			var parent: StringName=PARENTS[index][credit%PARENTS[index].size()]
			run.record_resolved_feature(ProjectState.new(30),parent,catalog.cards[parent].phase)
		var q:=run.get_feature_research_quote(id)
		check(q.down_cents==85000 and q.due_cents==42500,"one shared fifty-percent cap, exact split "+str(id))
		run._cash_cents=84999
		var poor:=Replay.digest(Replay.freeze(run))
		check(not run.admit_feature_research(run.get_feature_research_quote(id)) and Replay.digest(Replay.freeze(run))==poor,"one-cent-short atomic admission")
		var session:=fresh(index)
		var tape:=Replay.begin(session)
		for parent: StringName in PARENTS[index]: acquire(session,tape,parent)
		var old_supply: Array=session.run.get_owned_feature_ids()
		q=session.run.get_feature_research_quote(id)
		check(q.can_admit and q.down_cents==85000 and q.due_cents==85000,"owned parent admission exact undiscounted cents")
		var cycle: int=session.run.get_completed_run_cycles()
		execute(session,tape,&"admit_research",{"quote":q})
		check(not session.run.owns_feature(id) and session.run.get_completed_run_cycles()==cycle,"deposit grants no ownership/cycle")
		var queued:=adapter.capture(session.run)
		check(not queued.is_empty(),"queued save validates: "+adapter.error)
		var frozen_project:=ProjectState.new(30)
		frozen_project._feature_supply_ids.assign(old_supply)
		execute(session,tape,&"research",{"quote":session.run.get_feature_research_quote(id)})
		check(session.run.owns_feature(id) and session.run.get_completed_run_cycles()==cycle+1 and not frozen_project.get_feature_supply_ids().has(id),"one Research cycle, future-project supply only")
		var completed:=adapter.capture(session.run)
		check(not completed.is_empty(),"completed save validates: "+adapter.error)
		var policy:=Fixture.factory({"genre":recipe(index).specialty,"theme":"fantasy","name_prefix":"Pack","selection":"features_first","hands":{"design":2,"alpha":12,"beta":2}})
		var played:=false
		var production: Dictionary={}
		for step in range(100):
			var view: Dictionary=session.observation()
			var choice: Dictionary=policy.call(view)
			var expected_scores: Dictionary={0:0,1:0,2:0,3:0}
			var expected_scope:=0
			var expected_pressure:=0.0
			var selected_stats: Array=[]
			if view.phase==&"alpha" and view.development.active and not view.development.finalized and not view.development.confirmation_pending:
				var cards: Array=view.development.candidates.duplicate()
				cards.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
					if (a.definition==id)!=(b.definition==id): return a.definition==id
					return int(a.token)<int(b.token))
				var tokens: Array[int]=[]
				for slot in range(mini(4,cards.size())): tokens.append(int(cards[slot].token))
				for slot in range(mini(4,cards.size())):
					var selected: CardData=catalog.cards[StringName(cards[slot].definition)]
					selected_stats.append(selected.primary_stat)
					expected_scope+=selected.scope
					var printed:=0
					for contribution: Dictionary in selected.core_contributions():
						var category: int=[&"graphics",&"sound",&"technology",&"design"].find(contribution.stat)
						expected_scores[category]+=int(contribution.value);printed+=int(contribution.value)
					if selected.card_type==&"feature": expected_pressure+=float(printed*selected.scope)/18.0
				choice={"type":&"development","payload":{"request":session.development.command(&"play",{"candidate_ids":tokens})}}
			var result:=execute(session,tape,StringName(choice.type),choice.get("payload",{}))
			if not result.ok: break
			for event: Dictionary in result.get("events",[]):
				if event.get("type")=="feature_exhausted" and event.id==id: played=true
				if event.get("type")=="production": production=event
			if not selected_stats.is_empty():
				check(production.scope==expected_scope and is_equal_approx(production.alpha_bug_pressure,expected_pressure),"committed Scope and Bug Pressure match printed hand")
				var uniform: bool=selected_stats.all(func(stat: StringName) -> bool: return stat==selected_stats[0])
				var sum:=0
				for score: int in expected_scores.values(): sum+=score
				var balanced: bool=sum>0 and expected_scores.values().all(func(score: int) -> bool: return absf(float(score)-float(sum)/4.0)<=float(sum)/4.0*0.15)
				if uniform:
					for category in 4: check(int(production.scores.get(category,0))==roundi(expected_scores[category]*1.5),"specialization uses primary identity and preserves secondary production")
				elif not balanced:
					for category in 4: check(int(production.scores.get(category,0))==expected_scores[category],"committed Core equals printed hand")
			if played:
				check(session.development.hand._exhausted_feature_ids.has(id) and not session.development.hand._available_features.has(card),"real dealt finite card commits and exhausts "+str(id))
				var printed_card: Array[CardData]=[card]
				check(session.run.primitive_feature_hand_cost_cents(printed_card)==0,"approved zero Alpha play fee")
				check(session.development.project.get_feature_supply_ids().has(id),"new project freezes completed ownership")
				break
		check(played,"actual legal Alpha draw/commit observed "+str(id))
		check(Replay.save_tape(output+"."+str(index)+".tape.json",tape),"exact replay saved")
		evidence.append({"id":id,"queued":queued,"completed":completed,"played":played,"production":Replay.freeze(production),"commands":tape.steps.size()})
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(evidence))
	print("ALPHA_PACK checks=%d failures=%d"%[checks,failures]);quit(failures)
