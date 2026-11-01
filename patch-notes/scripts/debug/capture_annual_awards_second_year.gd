extends SceneTree

## Debug-only legal career capture. No direct owner balance/date/progress writes.
var checks := 0
var failures: Array[String] = []
var trace: Array = []
var loans: Array = []
var releases: Array = []
var first_completed := false
var output := ""

func expect(ok: bool, message: String) -> bool:
	checks += 1
	if not ok:
		failures.append(message)
		print("FAIL: ",message)
	return ok

func _initialize() -> void:
	_test.call_deferred()

func _test() -> void:
	output = OS.get_environment("PN_AWARDS_FIXTURE_OUTPUT")
	var catalog = root.get_node("CardDatabase").get_development_catalog()
	var recipe := {"schema_version":1,"studio_id":"annual-legal-player","studio_name":"Annual two year studio","specialty":"action","traits":["college_dropout"],"seed":"4417"}
	var session = preload("res://scripts/simulation/run_factory.gd").create_fresh_session(recipe,catalog)
	if not expect(session != null,"Actual new Studio creation succeeds"):
		_finish({"recipe":recipe});return
	var world = preload("res://scripts/market/rival_trial.gd").create_world(session.run,catalog)
	if not expect(world != null and world.studios.size()==8,"Actual certified eight-rival opening succeeds"):
		_finish({"recipe":recipe});return
	var hands := {"design":3,"alpha":2,"beta":2}
	var policy = preload("res://scripts/simulation/finite_fixture_policy.gd").factory({"genre":"action","theme":"fantasy","name_prefix":"Annual career","selection":"features_first","hands":hands})
	for step in range(1800):
		if session.in_studio and not world.annual_awards.entries.is_empty() and not first_completed:
			expect(_save_fixture(session,world,output+".first-year.json"),"First actual pending ceremony pair captures")
			for page in range(9):
				if not expect(world.advance_awards_stage(),"First ceremony durable stage "+str(page+1)):break
			first_completed = world.complete_awards_presentation()
			expect(first_completed,"First ceremony final stage completes legally")
		if session.run.get_completed_run_cycles()>=96 and session.in_studio and world.annual_awards.entries.size()>=2:break
		var choice: Dictionary = policy.call(session.observation())
		var before_cycle: int = session.run.get_completed_run_cycles()
		var before_cash: int = session.run.get_cash_cents()
		var result: Dictionary = session.execute(session.command(StringName(choice.type),choice.get("payload",{})))
		trace.append({"step":step,"cycle":before_cycle,"phase":str(session.phase()),"cash_before":before_cash,"cash_after":session.run.get_cash_cents(),"choice":choice,"ok":result.get("ok",false),"error":result.get("error","")})
		if not result.get("ok",false):
			print("REJECT cycle=",before_cycle," phase=",session.phase()," cash=",before_cash," ",result)
			expect(false,"Legal stock policy command rejected at step "+str(step));break
		if session.run.get_completed_run_cycles()>world.cycle:
			var tick: Dictionary = world.advance_committed_player_cycle(preload("res://scripts/market/rival_trial.gd").policies(world),128)
			if not expect(tick.get("ok",false),"Committed player+rival world transaction "+str(world.cycle)):
				print(tick);break
		if session.in_studio and session.run.get_released_game_ids().size()>releases.size():
			var release_id: StringName = session.run.get_released_game_ids()[-1]
			var sale: Dictionary = session.run.get_released_game_sales(release_id)
			releases.append({"release_id":str(release_id),"cycle":world.cycle,"cash_cents":session.run.get_cash_cents(),"review_tenths":sale.review_tenths})
			print("STUDIO cycle=",world.cycle," releases=",releases.size()," cash=",session.run.get_cash_cents()," review=",sale.review_tenths)
	expect(session.run.get_completed_run_cycles()>=96 and session.in_studio,"Legal career reaches two years and the next Studio")
	expect(world.annual_awards.entries.size()==2 and world.annual_awards.entries[0].complete and not world.annual_awards.entries[1].complete,"1980 complete and1981 pending are preserved")
	var captured := false
	if failures.is_empty():captured=_save_fixture(session,world,output)
	expect(captured,"Final second-year pending paired fixture captures and cold-restores")
	_finish({"recipe":recipe,"hands":hands,"cycle":world.cycle,"studio":session.in_studio,"cash_cents":session.run.get_cash_cents(),"fans":session.run.get_fans(),"awards":world.annual_awards.entries.size(),"first_complete":first_completed,"fixture":output if captured else ""})

func _save_fixture(session, world: RivalWorld, path: String) -> bool:
	var catalog = root.get_node("CardDatabase").get_development_catalog()
	var adapter := StudioCheckpoint.new()
	var codec := preload("res://scripts/market/rival_world_checkpoint.gd").new()
	var player: Dictionary = adapter.capture(session.run)
	var saved: Dictionary = codec.capture(world)
	if not expect(not player.is_empty() and not saved.is_empty(),"Paired native current codecs validate: "+adapter.error+codec.error):return false
	var hydrated := adapter.hydrate(JSON.parse_string(JSON.stringify(player)))
	if not expect(hydrated != null,"Player cold hydration validates: "+adapter.error):return false
	var restored = codec.restore(JSON.parse_string(JSON.stringify(saved)),JSON.parse_string(JSON.stringify(player)),hydrated,catalog)
	if not expect(restored != null,"World/player cold Continue validates: "+codec.error):return false
	expect(restored.annual_awards==world.annual_awards,"Both ceremonies and exact saved presentation progress survive")
	expect(adapter.capture(hydrated)==player,"Cold player full checkpoint remains unchanged")
	expect(codec.capture(restored)==saved,"Cold eight-rival world full checkpoint remains unchanged")
	expect(adapter.capture(session.run)==player and codec.capture(world)==saved,"Capture/restore leaves original owner and world unchanged")
	if path.is_empty():return false
	var file := FileAccess.open(path,FileAccess.WRITE)
	if not expect(file != null,"Fixture output file opens"):return false
	file.store_string(JSON.stringify({"player":player,"world":saved}))
	file.close()
	print("FIXTURE ",path)
	return true

func _finish(summary: Dictionary) -> void:
	summary.merge({"checks":checks,"failures":failures,"loans":loans,"releases":releases,"trace":trace})
	if not output.is_empty():
		var file := FileAccess.open(output+".report.json",FileAccess.WRITE)
		if file != null:file.store_string(JSON.stringify(summary,"  "));file.close()
	print("ANNUAL_AWARDS_SECOND_YEAR checks=",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
