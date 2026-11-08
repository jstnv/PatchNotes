extends SceneTree
## Actual development/launch/checkpoint mechanics with explicitly synthetic
## accounting funds. Never evidence of recurring wage affordability.
const Factory=preload("res://scripts/simulation/run_factory.gd")
const Session=preload("res://scripts/simulation/campaign_session.gd")
const Policy=preload("res://scripts/simulation/finite_fixture_policy.gd")
const Replay=preload("res://scripts/simulation/development_replay.gd")
var failures:=0
var checks:=0
var session: RefCounted
var tape: Dictionary
var output: String=OS.get_environment("PN_CARD_FRAME_OUTPUT")
var observed: Array[Dictionary]=[]
var publisher_events: Array[StringName]=[]
func expect(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func act(kind: StringName,payload: Dictionary={}) -> bool:
	var result:=Replay.record(session,tape,session.command(kind,payload))
	expect(result.ok,"Actual career command %s: %s"%[kind,result.get("error","")])
	return result.ok
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	var run=preload("res://scripts/debug/employee_test_actions.gd").fresh_two_releases(catalog)
	var controller=preload("res://scripts/tutorial/focused_guidance_controller.gd").new()
	root.add_child(controller)
	controller._run=run;controller._queue_studio=str(run._bank_run_id);controller.automatic_enabled=false
	var notices=preload("res://scripts/ui/challenge_progress_notices.gd").new()
	root.add_child(notices)
	notices.notice_requested.connect(func(value: Dictionary):
		observed.append(value.duplicate(true));controller._queue_progress(value))
	notices.bind_run(run)
	run.publishers_changed.connect(func():
		for id: StringName in run.get_pending_publisher_notifications():
			if id not in publisher_events:publisher_events.append(id))
	expect(run.add_cash_cents(5000000,&"other_income",&"synthetic_accounting_fixture"),"Explicit accounting fixture, not earned-sale affordability")
	var created:Dictionary=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Natural engine"))
	expect(created.get("ok",false),"Create the test engine through the real Studio action")
	if not created.get("ok",false):quit(1);return
	expect(run.select_engine(created.engine_id),"Select the real engine for the following projects")
	var snapshots:=PrimitiveSnapshotDatabase.new();snapshots.load_ledgers()
	session=Session.new();expect(session.initialize(run,catalog,snapshots),"Career starts at genuine two-release Studio")
	var initial: Dictionary=session.export_checkpoint()
	tape=Replay.begin(session)
	if not act(&"hire",{"quote":run.get_employee_hire_quote(&"qa")}):quit(1);return
	for course in [&"mixed",&"pure"]:
		if not act(&"course",{"quote":run.get_qa_course_quote(course)}):quit(1);return
	var choose:=Policy.factory({"genre":"action","theme":"fantasy","name_prefix":"QA career","selection":"features_first","hands":{"design":3,"alpha":3,"beta":8}})
	var boundaries:=[]
	var prior:=2
	for step in range(260):
		if session.in_studio and run.get_released_game_ids().size()>=6:break
		var view: Dictionary=session.observation()
		var choice: Dictionary=choose.call(view)
		if not session.in_studio and session.development.phase_index==2:
			var dev: Dictionary=view.development
			if not dev.active and not dev.finalized and not dev.confirmation_pending and dev.priorities!={&"qa":50,&"marketing":50,&"insider":0}:
				choice={"type":&"development","payload":{"request":session.development.command(&"priorities",{"distribution":{&"qa":50,&"marketing":50,&"insider":0}})}}
			elif choice.type==&"development" and choice.payload.request.type==&"play":
				var cards: Array=dev.candidates.duplicate(true)
				# Prefer QA cards using only visible facts. A mixed hand can earn its
				# benefit only when real Hidden and Known Bugs were processed.
				cards.sort_custom(func(a,b):return a.beta_category=="qa" if (a.beta_category=="qa")!=(b.beta_category=="qa") else a.token<b.token)
				choice.payload.request.payload.candidate_ids=cards.slice(0,4).map(func(c):return int(c.token))
		if not act(choice.type,choice.get("payload",{})):quit(1);return
		if session.in_studio and run.get_released_game_ids().size()>prior:
			prior=run.get_released_game_ids().size()
			var saved: Dictionary=session.export_checkpoint()
			expect(not saved.is_empty(),"Actual QA progress/raises survive complete released project")
			var cold:=Session.new()
			expect(cold.restore_checkpoint(saved,catalog,snapshots) and Replay.state(cold)==Replay.state(session),"Every Studio boundary restores all progress, finance and RNG")
			boundaries.append(saved)
	expect(run.get_released_game_ids().size()==6 and boundaries.size()==4,"Four complete post-course projects without card/deal injection")
	var qa: Dictionary=run.get_employees().employees.values()[0]
	print("QA training state (not an engine requirement): ",qa.trained)
	expect(observed.any(func(item: Dictionary):return str(item.title).contains("Natural engine")),"Genuine played engine Feature emits challenge notification")
	expect(controller.notices.count()==observed.size() and run.get_studio_notice_state().pending.size()==observed.size(),"All genuine engine progress reaches the checkpointed queue")
	print("NATURAL_NOTICE_COUNT=",observed.size()," PUBLISHER_EVENTS=",publisher_events)
	controller.queue_free()
	notices.queue_free()
	# Duplicate one real Beta action using a different invented project-cycle.
	var real_roster: Dictionary=run.get_employees()
	var forged:=EmployeeRoster.create(real_roster.owner)
	var inserted:=false
	for event: Dictionary in real_roster.events:
		if forged.is_empty():break
		forged=EmployeeRoster._apply(forged,event)
		if event.type==&"qa_beta" and not inserted:
			var extra:=event.duplicate(true);extra.project_cycle+=1000000;extra.search=0;extra.debug=0;extra.discovered=0;extra.fixed=0
			forged=EmployeeRoster._apply(forged,extra);inserted=true
	run._employees=forged
	expect(inserted and (forged.is_empty() or StudioCheckpoint.new().capture(run).is_empty()),"One real Beta hand cannot prove two QA progress events")
	run._employees=real_roster
	var repeated:=Session.new();expect(repeated.restore_checkpoint(initial,catalog,snapshots),"Replay restores original accounting fixture")
	var replayed:=Replay.replay(repeated,tape)
	expect(replayed.ok and Replay.state(repeated)==Replay.state(session),"Whole post-course career tape replays exactly")
	if not output.is_empty():
		Replay.save_tape(output+".tape.json",tape)
		FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"pass":failures==0,"checks":checks,"source":Replay.source_identity(),"synthetic_funds_cents":5000000,"affordability_evidence":false,"qa":Replay.freeze(qa),"initial":initial,"checkpoint":session.export_checkpoint(),"boundaries":boundaries,"replay":replayed},"\t"))
	print("QA_CAREER checks=%d failures=%d commands=%d"%[checks,failures,tape.steps.size()]);quit(failures)
