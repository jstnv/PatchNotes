extends SceneTree
const Helper := preload("res://scripts/debug/employee_test_actions.gd")
const Session := preload("res://scripts/simulation/campaign_session.gd")
const Policy := preload("res://scripts/simulation/finite_fixture_policy.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	print("PASS: " if ok else "FAIL: ",label)
	if not ok: failures += 1
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var records := {}
	for trial: bool in [false,true]:
		var run := Helper.fresh_two_releases(catalog,trial)
		check(run.hire_production_specialist(run.get_production_hire_quote()),"Genuine preceding hire")
		check(run.add_cash_cents(10000000,&"other_income",&"course_migration_fixture"),"Explicit synthetic migration-mechanics funding")
		var adapter:=StudioCheckpoint.new()
		var key:="trial" if trial else "legacy"
		records[key+"_untrained"]=adapter.capture(run)
		var snapshots:=PrimitiveSnapshotDatabase.new();snapshots.load_ledgers()
		var session:=Session.new();check(session.initialize(run,catalog,snapshots),"Resume Studio diagnostic session")
		var choose:=Policy.factory({"genre":"action","theme":"fantasy","name_prefix":"Course predecessor","selection":"features_first","hands":{"design":5,"alpha":3,"beta":2}})
		for step in 100:
			if session.in_studio and run.get_released_game_ids().size()==3:break
			var choice: Dictionary=choose.call(session.observation())
			if choice.type=="play" and session.phase() in [&"design",&"alpha"]:
				var cards: Array=[]
				for token: int in choice.payload.candidate_ids:cards.append(session.development.hand._candidate_cards[session.development.hand.candidate_ids.find(token)])
				if EmployeeRoster.matches(EmployeeRoster.card_facts(cards)) and EmployeeRoster.available(run.get_employees(),session.project_id()):
					var plan:={0:40,1:20,2:20,3:20}
					if plan!=session.development.hand.priorities:choice.payload.employee_priorities=plan
			var result: Dictionary=session.execute(session.command(choice.type,choice.get("payload",{})))
			check(result.ok,"Legal predecessor command "+str(choice.type))
			if not result.ok:break
		var employee: Dictionary=run.get_employees().employees.values()[0]
		check(employee.trained and run.get_released_game_ids().size()==3,"Committed old training and successful release")
		records[key+"_trained"]=adapter.capture(run)
		check(not records[key+"_trained"].is_empty() and adapter.validate(records[key+"_trained"]).is_empty(),"Old trained checkpoint validates "+adapter.error)
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify({"source":preload("res://scripts/simulation/development_replay.gd").source_identity(),"records":records}))
	quit(failures)
