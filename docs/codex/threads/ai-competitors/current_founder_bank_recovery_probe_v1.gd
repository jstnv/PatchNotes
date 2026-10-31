## Private one-Studio prelude experiment. All mutations go through CampaignSession.
extends SceneTree

const Factory := preload("res://scripts/simulation/run_factory.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const Synergy := preload("res://scripts/market/rival_synergy_choice.gd")
const BetaChoice := preload("res://scripts/market/rival_beta_synergy_choice.gd")
const Historical := preload("res://scripts/market/historical_standard_trial.gd")
const Market := preload("res://scripts/market/market_transaction_trial.gd")
const StudioCodec := preload("res://scripts/persistence/studio_checkpoint.gd")
const WorldCodec := preload("res://scripts/market/rival_world_checkpoint.gd")
const MAX_COMMANDS := 340
const GENRES := ["action","adventure","role_playing","strategy","simulation","puzzle","sports","racing"]
const HORIZON := 80
const FIRST_SCOPE := 30
const JANUARY_SCOPE := 35
const FULL_PRIMITIVE_SCOPE := 30
var _policy := ""
var _standard := ""
var _genre := ""
var _trial_run: RunState

func _initialize() -> void:
	_run.call_deferred()

func _argument(prefix: String) -> String:
	for item in OS.get_cmdline_user_args():
		if item.begins_with(prefix): return item.substr(prefix.length())
	return ""

func _recipe(seed: String) -> Dictionary:
	var recipe: Dictionary={"schema_version":1,"studio_id":"prelude-"+_genre+"-"+seed,"studio_name":"Prelude "+_genre.capitalize(),"specialty":_genre,"traits":["family_funding","cult_following"],"seed":seed,"rival_founder_profile":"rival-founder-active-1977-v1","prelude_capital_cents":"2500000"}
	if _argument("--finance=")=="ordinary":recipe.erase("prelude_capital_cents")
	if _argument("--profile=")=="control":recipe.rival_founder_profile="rival-current-trial-1977-control-v1"
	return recipe

func _run() -> void:
	var seed := _argument("--seed=")
	_genre = _argument("--genre=")
	var output := _argument("--output=")
	var cold_fixture := _argument("--cold-fixture=")
	var completion_fixture := _argument("--completion-fixture=")
	var post_release_cold := _argument("--post-release-cold-fixture=")
	if not post_release_cold.is_empty():
		_cold_post_release(post_release_cold,output)
		return
	if not completion_fixture.is_empty():
		_cold_completion(completion_fixture,output,_argument("--post-release=")=="1")
		return
	if not cold_fixture.is_empty():
		_cold_world(cold_fixture,output)
		return
	var tape_path := _argument("--tape=")
	var replay_path := _argument("--replay=")
	var stop_cycle_text := _argument("--stop-cycle=")
	var stop_cycle := 80 if stop_cycle_text.is_empty() else int(stop_cycle_text)
	_policy = _argument("--policy=")
	_standard = _argument("--standard=")
	if _genre not in GENRES or _policy not in ["full_pool","audio_path","store_one_gap","store_two_gaps"] or _standard not in ["none","midpoint"] or stop_cycle not in [72,80] or seed not in ["4417","4423","5501","5507","5513","5519","5601","5607","5613","5619"] or output.is_empty() or FileAccess.file_exists(output):
		push_error("Declared seed and fresh output required")
		quit(2)
		return
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var session: RefCounted = Factory.create_fresh_session(_recipe(seed),catalog)
	if session == null:
		push_error("Fresh legal Studio unavailable")
		quit(2)
		return
	_trial_run=session.run
	_trial_run._market_provider=Callable(self,"_market_for_run")
	if not replay_path.is_empty():
		var old_tape := Replay.load_tape(replay_path)
		var replay: Dictionary = Replay.replay(session,old_tape)
		_write(output,{"mode":"fresh-replay","seed":seed,"source_identity":Replay.source_identity(),"replay":replay,"final_cycle":session.run.get_completed_run_cycles(),"final_phase":str(session.phase()),"final_rng_digest":Replay.digest(session.run.random_streams.snapshot())})
		quit(0 if replay.get("ok",false) else 1)
		return
	if tape_path.is_empty() or FileAccess.file_exists(tape_path):
		push_error("Fresh tape output required")
		quit(2)
		return
	var run: RunState = session.run
	var initial := {"calendar_year":run.get_current_year(),"cash_cents":run.get_cash_cents(),"fans":run.get_fans(),"owned_features":run.get_owned_feature_ids(),"future_supply":run.get_future_project_feature_ids(),"owned_scope":_owned_scope(run),"rng_digest":Replay.digest(run.random_streams.snapshot()),"state_digest":Replay.digest(Replay.state(session))}
	var tape: Dictionary = Replay.begin(session)
	var actions: Array = []
	var project_standards: Array = []
	var issue := ""
	var stop := ""
	var january: Dictionary = {}
	for index in range(MAX_COMMANDS):
		if run.get_completed_run_cycles() == 72 and january.is_empty():
			var boundary: Dictionary = session.observation()
			january = {"cycle":72,"year":run.get_current_year(),"month":run.get_current_month(),"phase":str(boundary.phase),"project_id":str(boundary.project_id),"development":boundary.get("development",{}),"future_supply":run.get_future_project_feature_ids(),"cash_cents":run.get_cash_cents(),"fans":run.get_fans(),"release_count":run.get_released_game_ids().size(),"finance":run.get_studio_finance_snapshot(),"rng_digest":Replay.digest(run.random_streams.snapshot()),"state_digest":Replay.digest(Replay.state(session))}
		if run.get_completed_run_cycles() >= stop_cycle:
			stop = "c%d projection boundary" % stop_cycle
			break
		var view: Dictionary = session.observation()
		var choice: Dictionary = _choose(session,view)
		var kind := StringName(choice.get("type",&""))
		if kind == &"blocked" or kind.is_empty():
			issue = str(choice.get("payload",{}).get("reason","No legal policy choice"))
			break
		var before_cycle := run.get_completed_run_cycles()
		var selected_visible: Array = []
		if kind == &"development" and choice.get("payload",{}).get("request",{}).get("type",&"") == &"play":
			for token: int in choice.payload.request.payload.get("candidate_ids",[]):
				for candidate: Dictionary in view.get("development",{}).get("candidates",[]):
					if int(candidate.token) == token:
						selected_visible.append({"id":str(candidate.definition),"type":str(candidate.type),"phase":str(view.phase),"scope":int(candidate.scope)})
						break
		var request: Dictionary = session.command(kind,choice.get("payload",{}))
		var result: Dictionary = Replay.record(session,tape,request)
		var event_types: Array = []
		for event: Dictionary in result.get("events",[]): event_types.append(str(event.get("type","")))
		actions.append({"index":index,"type":str(kind),"choice":choice,"selected_visible":selected_visible,"accepted":result.get("ok",false),"error":result.get("error",""),"before_cycle":before_cycle,"after_cycle":run.get_completed_run_cycles(),"phase":str(session.phase()),"cash_cents":run.get_cash_cents(),"owned_scope":_owned_scope(run),"events":event_types})
		if result.get("ok",false) and kind==&"begin_development" and session.development!=null:
			var project: ProjectState=session.development.project
			project_standards.append({"project_id":str(project.get_release_id()),"begin_cycle":run.get_completed_run_cycles(),
				"standards":project.get_market_standards(),"source_id":project.get_market_snapshot_id(),
				"details":project.get_market_details()})
		if not result.get("ok",false):
			issue = "Rejected "+str(kind)+": "+str(result.get("error",""))
			break
	if stop.is_empty() and issue.is_empty(): issue = "340-command bound before c80"
	var releases: Array = []
	for id: StringName in run.get_released_game_ids():
		var metadata: Dictionary = run.get_release_metadata(id)
		var sales: Dictionary = run.get_released_game_sales(id)
		releases.append({"id":str(id),"cycle":int(metadata.get("release_cycle",-1)),"year":1977+int(metadata.get("release_cycle",0))/24,"metadata":metadata,"review_tenths":int(sales.get("review_tenths",-1)),"sales":sales})
	var final_view: Dictionary = session.observation()
	var development: Dictionary = final_view.get("development",{})
	var finance: Dictionary = run.get_studio_finance_snapshot()
	var preprojection := {"cycle":run.get_completed_run_cycles(),"year":run.get_current_year(),"month":run.get_current_month(),
		"cash_cents":run.get_cash_cents(),"fans":run.get_fans(),"owned_features":run.get_owned_feature_ids(),
		"owned_scope":_owned_scope(run),"rng_digest":Replay.digest(run.random_streams.snapshot()),"state_digest":Replay.digest(Replay.state(session))}
	var projection: Dictionary = _projection(session,catalog,seed,output) if stop_cycle==72 and issue.is_empty() else {}
	var source: Dictionary = Historical.source_from_run(run)
	var source_checks := {"available":not source.is_empty(),"valid":false,"early_rejected":false,"tamper_rejected":false,
		"effective_cycle":-1,"sales_neutral":false}
	if not source.is_empty():
		var effective: int=Historical.effective_cycle(source)
		var snapshot: Dictionary=Historical.snapshot(source,effective)
		var details: Dictionary=Historical.details(snapshot,StringName(_genre))
		var tampered: Dictionary=details.duplicate(true)
		tampered.standards[0]=int(tampered.standards[0])+1
		source_checks={"available":true,"valid":Market.valid(snapshot) and Market.valid_details(details,StringName(_genre)),
			"early_rejected":Historical.snapshot(source,effective-1).is_empty(),
			"tamper_rejected":not Market.valid_details(tampered,StringName(_genre)),
			"effective_cycle":effective,
			"sales_neutral":Market.sales_factor(snapshot,str(run._bank_run_id),"probe",_genre,"fantasy")==Market.neutral_factor()}
	var saved := Replay.save_tape(tape_path,tape)
	var report := {"mode":"one-specialty-1977-prelude","genre":_genre,"policy":_policy,"standard":_standard,"seed":seed,"source_identity":Replay.source_identity(),"initial":initial,"january_boundary":january,"projection":projection,"actions":actions,"project_standards":project_standards,"historical_source":source,"source_checks":source_checks,"releases":releases,"issue":issue,"stop":stop,"tape_saved":saved,"tape_steps":tape.steps.size(),"final_cycle":preprojection.cycle,"final_year":preprojection.year,"final_month":preprojection.month,"final_phase":str(final_view.phase),"final_project_id":str(final_view.project_id),"final_development":development,"final_cash_cents":preprojection.cash_cents,"final_fans":preprojection.fans,"final_owned_features":preprojection.owned_features,"final_owned_scope":preprojection.owned_scope,"research_entries":run._feature_research.duplicate(true),"finance":finance,"final_rng_digest":preprojection.rng_digest,"final_state_digest":preprojection.state_digest}
	_write(output,report)
	print("ONE_ACTION_PRELUDE seed=%s cycle=%d releases=%d scope=%d issue=%s" % [seed,run.get_completed_run_cycles(),releases.size(),_owned_scope(run),issue])
	quit(0 if issue.is_empty() and saved else 1)

func _world_state(world: RivalWorld) -> Dictionary:
	var player_payload: Dictionary=StudioCodec.new().capture(world.player)
	var world_payload: Dictionary=WorldCodec.new().capture(world)
	return {"player":player_payload,"world":world_payload} if not player_payload.is_empty() and not world_payload.is_empty() else {}

func _cold_world(fixture_path: String,output: String) -> void:
	if output.is_empty() or FileAccess.file_exists(output) or not FileAccess.file_exists(fixture_path):
		push_error("Fresh cold-world output and fixture required")
		quit(2)
		return
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(fixture_path))
	var result: Dictionary={"ok":false,"reason":"","source_identity":Replay.source_identity(),"fixture_sha256":FileAccess.get_sha256(fixture_path)}
	if not parsed is Dictionary or parsed.get("source_identity")!=Replay.source_identity():
		result.reason="Source/fixture mismatch"
	else:
		var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
		var studio_codec:=StudioCodec.new()
		var player: RunState=studio_codec.hydrate(parsed.player)
		var codec:=WorldCodec.new()
		var restored: RivalWorld=codec.restore(parsed.world,parsed.player,player,catalog) if player!=null else null
		if restored==null:
			result.reason=studio_codec.error if player==null else codec.error
		else:
			var id: StringName=restored.studios.keys()[0]
			var idle_policy:=func(_view: Dictionary) -> Dictionary: return {"type":&"blocked","payload":{"reason":"Projection idle boundary"}}
			var player_ok: bool=restored.player.complete_productive_action(Callable(),0,restored.player.get_completed_run_cycles())
			var advanced: Dictionary=restored.advance_committed_player_cycle({id:idle_policy},4) if player_ok else {"ok":false,"reason":"Cold player rejected"}
			var actual: Dictionary=_world_state(restored) if advanced.get("ok",false) else {}
			result.ok=advanced.get("ok",false) and not actual.is_empty() and actual==parsed.expected_after
			result.reason="" if result.ok else str(advanced.get("reason","Cold state differs"))
			result.actual_digest=Replay.digest(actual)
			result.expected_digest=Replay.digest(parsed.expected_after)
			result.world_cycle=restored.cycle
			result.rival_cycle=restored.studios[id].run.get_completed_run_cycles()
	_write(output,result)
	quit(0 if result.ok else 1)

func _cold_completion(fixture_path: String,output: String,post_release: bool=false) -> void:
	if output.is_empty() or FileAccess.file_exists(output) or not FileAccess.file_exists(fixture_path):
		push_error("Fresh completion output and fixture required")
		quit(2)
		return
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(fixture_path))
	var result: Dictionary={"ok":false,"reason":"","source_identity":Replay.source_identity(),"fixture_sha256":FileAccess.get_sha256(fixture_path),"steps":[],"releases":[]}
	if not parsed is Dictionary or parsed.get("source_identity")!=Replay.source_identity():
		result.reason="Source/fixture mismatch"
	else:
		_policy="full_pool"
		_standard="midpoint"
		var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
		var studio_codec:=StudioCodec.new()
		var player: RunState=studio_codec.hydrate(parsed.player)
		var codec:=WorldCodec.new()
		var world: RivalWorld=codec.restore(parsed.world,parsed.player,player,catalog) if player!=null else null
		if world==null:
			result.reason=studio_codec.error if player==null else codec.error
		else:
			var id: StringName=world.studios.keys()[0]
			var rival: RunState=world.studios[id].run
			var old_sales: Dictionary={}
			for old_id: StringName in rival.get_released_game_ids(): old_sales[old_id]=rival.get_released_game_sales(old_id).duplicate(true)
			var policy:=func(view: Dictionary)->Dictionary: return _choose(world.studios[id],view)
			for step in range(12):
				var player_ok: bool=world.player.complete_productive_action(Callable(),0,world.player.get_completed_run_cycles())
				if not player_ok:
					result.reason="Player calendar rejected"
					break
				var advanced: Dictionary=world.advance_committed_player_cycle({id:policy},4)
				result.steps.append({"step":step,"world_cycle":world.cycle,"rival_cycle":rival.get_completed_run_cycles(),"boundary":advanced})
				if not advanced.get("ok",false):
					result.reason=str(advanced.get("reason","Rival world rejected"))
					break
				if not advanced.get("new_releases",[]).is_empty():
					result.releases=advanced.new_releases.duplicate(true)
					break
			var old_equal:=true
			for old_id: StringName in old_sales:
				if rival.get_released_game_sales(old_id)!=old_sales[old_id]: old_equal=false
			result.old_sales_equal=old_equal
			result.old_live_count=world.live_releases.size()-result.releases.size()
			result.live_count=world.live_releases.size()
			result.market_fact_count=world.market_snapshot.get("facts",[]).size()
			result.world_cycle=world.cycle
			result.rival_cycle=rival.get_completed_run_cycles()
			if not result.releases.is_empty():
				var release: Dictionary=result.releases[0]
				var release_id: StringName=StringName(release.release_id)
				result.release_metadata=rival.get_release_metadata(release_id)
				result.release_sales=rival.get_released_game_sales(release_id)
				result.mapped_release_cycle=int(result.release_metadata.release_cycle)-72
				result.world_mapping_ok=int(release.release_cycle)==int(result.mapped_release_cycle)
				result.ok=old_equal and result.old_live_count==0 and result.world_mapping_ok
				if not result.ok and result.reason.is_empty(): result.reason="Historical freeze or live release calendar mismatch"
				if post_release and result.ok:
					var followup: Dictionary=_post_release(world,id,release_id,old_sales,output)
					result.post_release=followup
					result.ok=bool(followup.get("ok",false))
					if not result.ok: result.reason=str(followup.get("reason","Post-release check failed"))
			elif result.reason.is_empty(): result.reason="No release within 12 cycles"
	_write(output,result)
	quit(0 if result.ok else 1)

func _advance_two_idle(world: RivalWorld,id: StringName) -> Dictionary:
	var result: Dictionary={"ok":false,"reason":"","boundaries":[],"c7_market":{},"c8_market":{}}
	var idle_policy:=func(_view: Dictionary)->Dictionary: return {"type":&"blocked","payload":{"reason":"Post-release idle boundary"}}
	for step in range(2):
		var player_ok: bool=world.player.complete_productive_action(Callable(),0,world.player.get_completed_run_cycles())
		if not player_ok:
			result.reason="Post-release player calendar rejected"
			return result
		var boundary: Dictionary=world.advance_committed_player_cycle({id:idle_policy},4)
		result.boundaries.append(boundary)
		if not boundary.get("ok",false):
			result.reason=str(boundary.get("reason","Post-release rival calendar rejected"))
			return result
		if step==0: result.c7_market=world.market_snapshot.duplicate(true)
		else: result.c8_market=world.market_snapshot.duplicate(true)
	result.ok=true
	return result

func _post_release(world: RivalWorld,id: StringName,release_id: StringName,old_sales: Dictionary,output: String) -> Dictionary:
	var result: Dictionary={"ok":false,"reason":"","source_identity":Replay.source_identity(),"release_id":str(release_id)}
	if world.cycle!=6 or world.studios[id].run.get_completed_run_cycles()!=78:
		result.reason="Unexpected release boundary"
		return result
	var player_codec:=StudioCodec.new()
	var player_payload: Dictionary=player_codec.capture(world.player)
	var world_codec:=WorldCodec.new()
	var world_payload: Dictionary=world_codec.capture(world)
	result.player_capture_ok=not player_payload.is_empty()
	result.world_capture_ok=not world_payload.is_empty()
	result.world_capture_error=world_codec.error
	if player_payload.is_empty() or world_payload.is_empty():
		result.reason="Post-release checkpoint capture failed"
		return result
	result.world_validation=WorldCodec.new().validate(world_payload,player_payload)
	if not result.world_validation.is_empty():
		result.reason="Post-release checkpoint validation failed"
		return result
	var rival: RunState=world.studios[id].run
	var target_cycle:=rival.get_completed_run_cycles()+1
	var market: Dictionary=rival._market_provider.call(id,target_cycle) if rival._market_provider.is_valid() else {}
	var factor: Dictionary=Market.sales_factor(market,str(id),str(release_id),"action","fantasy") if Market.valid(market) else {}
	var sale: Dictionary=rival.get_released_game_sales(release_id)
	var next_sale: Dictionary=ReleasedGameSales.next_cycle(sale,target_cycle,rival.will_next_cycle_cross_month_boundary(),false,int(factor.get("factor_bp",0)),str(factor.get("snapshot_id","")),factor) if not factor.is_empty() else {}
	var sales_plan: Dictionary=rival._plan_sales_cycle(&"",market) if Market.valid(market) else {}
	var full_plan: Dictionary=rival._plan_productive_cycle(0)
	result.preflight={"run_cycle":rival.get_completed_run_cycles(),"target_cycle":target_cycle,
		"cash_cents":rival.get_cash_cents(),"market_valid":Market.valid(market),
		"market_cycle_start":int(market.get("cycle_start",-1)),"market_id":str(market.get("id","")),
		"factor_valid":Market.valid_factor(factor),"factor_bp":int(factor.get("factor_bp",0)),
		"sale_record_valid":ReleasedGameSales.is_valid(sale),"next_sale_available":not next_sale.is_empty(),
		"sales_plan_available":not sales_plan.is_empty(),"sales_plan_keys":sales_plan.keys(),
		"full_plan_available":not full_plan.is_empty(),"full_plan_keys":full_plan.keys(),
		"finance_block_reason":rival.get_financial_block_reason(),
		"player_preview_valid":Market.valid(Market.preview(world,world.cycle+1))}
	var continued: Dictionary=_advance_two_idle(world,id)
	result.continued=continued
	if not continued.get("ok",false):
		result.reason=str(continued.get("reason","Post-release continuation failed"))
		return result
	result.c7_facts=continued.c7_market.facts.duplicate(true)
	result.c8_facts=continued.c8_market.facts.duplicate(true)
	result.c7_player_sales_factor=Market.sales_factor(continued.c7_market,str(world.player._bank_run_id),"probe","action","fantasy")
	result.c8_player_sales_factor=Market.sales_factor(continued.c8_market,str(world.player._bank_run_id),"probe","action","fantasy")
	result.c7_player_targets=Market.targets(continued.c7_market,str(world.player._bank_run_id),&"action")
	result.c8_player_targets=Market.targets(continued.c8_market,str(world.player._bank_run_id),&"action")
	var old_equal:=true
	for old_id: StringName in old_sales:
		if world.studios[id].run.get_released_game_sales(old_id)!=old_sales[old_id]: old_equal=false
	result.old_sales_equal=old_equal
	result.c8_world_cycle=world.cycle
	result.c8_rival_cycle=world.studios[id].run.get_completed_run_cycles()
	var expected_after: Dictionary=_world_state(world)
	result.c8_checkpoint_ok=not expected_after.is_empty()
	var one_fact: bool=result.c8_facts.size()==1 and result.c8_facts[0].studio_id==str(id) and result.c8_facts[0].release_id==str(release_id) and result.c8_facts[0].release_cycle==6 and result.c8_facts[0].genre=="action" and result.c8_facts[0].theme=="fantasy"
	result.ok=old_equal and result.c7_facts.is_empty() and one_fact and Market.valid(continued.c8_market) and result.c8_player_sales_factor.get("factor_bp",0)==8800 and not expected_after.is_empty() and result.c8_world_cycle==8 and result.c8_rival_cycle==80
	if not result.ok:
		result.reason="Post-release Market or checkpoint mismatch"
		return result
	var fixture_path:=output.get_basename()+"-post-release-fixture.json"
	_write(fixture_path,{"source_identity":Replay.source_identity(),"player":player_payload,"world":world_payload,"expected_after":expected_after,"release_id":str(release_id)})
	result.fixture_path=fixture_path
	result.fixture_sha256=FileAccess.get_sha256(fixture_path)
	result.expected_after_digest=Replay.digest(expected_after)
	return result

func _cold_post_release(fixture_path: String,output: String) -> void:
	if output.is_empty() or FileAccess.file_exists(output) or not FileAccess.file_exists(fixture_path):
		push_error("Fresh cold post-release output and fixture required")
		quit(2)
		return
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(fixture_path))
	var result: Dictionary={"ok":false,"reason":"","source_identity":Replay.source_identity(),"fixture_sha256":FileAccess.get_sha256(fixture_path)}
	if not parsed is Dictionary or parsed.get("source_identity")!=Replay.source_identity():
		result.reason="Source/fixture mismatch"
	else:
		var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
		var studio_codec:=StudioCodec.new()
		var player: RunState=studio_codec.hydrate(parsed.player)
		var codec:=WorldCodec.new()
		var world: RivalWorld=codec.restore(parsed.world,parsed.player,player,catalog) if player!=null else null
		if world==null:
			result.reason=studio_codec.error if player==null else codec.error
		else:
			var id: StringName=world.studios.keys()[0]
			var continued: Dictionary=_advance_two_idle(world,id)
			var actual: Dictionary=_world_state(world) if continued.get("ok",false) else {}
			result.ok=continued.get("ok",false) and not actual.is_empty() and actual==parsed.expected_after
			result.reason="" if result.ok else str(continued.get("reason","Cold post-release state differs"))
			result.actual_digest=Replay.digest(actual)
			result.expected_digest=Replay.digest(parsed.expected_after)
			result.world_cycle=world.cycle
			result.rival_cycle=world.studios[id].run.get_completed_run_cycles()
			result.market=world.market_snapshot.duplicate(true)
	_write(output,result)
	quit(0 if result.ok else 1)

func _projection(session: RefCounted,catalog: RefCounted,seed: String,output: String) -> Dictionary:
	var run: RunState=session.run
	var source: Dictionary=Historical.source_from_run(run)
	var archive: Array=[]
	var ids: Dictionary={}
	for id: StringName in run.get_released_game_ids():
		var meta: Dictionary=run.get_release_metadata(id)
		var sales: Dictionary=run.get_released_game_sales(id)
		archive.append({"id":str(id),"title":str(meta.release_title),"year":int(meta.release_year),
			"genre":str(meta.genre),"theme":str(meta.theme),"review_tenths":int(sales.review_tenths),
			"cores":meta.review.cores.duplicate(),"release_cycle":int(meta.release_cycle)})
		ids[id]=true
	var codec:=StudioCodec.new()
	var native: Dictionary=codec.snapshot(run,session.project_id())
	var capture_error: String=codec.error
	var encoded: Dictionary={} if native.is_empty() else codec.encode_snapshot(native)
	if capture_error.is_empty(): capture_error=codec.error
	var restored: RunState=null if encoded.is_empty() else codec.hydrate(encoded,true)
	if capture_error.is_empty(): capture_error=codec.error
	var restore_checks: Dictionary={"hydrated":restored!=null}
	if restored!=null:
		restore_checks.cash=restored.get_cash_cents()==run.get_cash_cents()
		restore_checks.fans=restored.get_fans()==run.get_fans()
		restore_checks.owned_features=restored.get_owned_feature_ids()==run.get_owned_feature_ids()
		restore_checks.finance=restored.get_studio_finance_snapshot()==run.get_studio_finance_snapshot()
		restore_checks.rng=restored.random_streams.snapshot()==run.random_streams.snapshot()
		restore_checks.release_ids=restored.get_released_game_ids()==run.get_released_game_ids()
		restore_checks.calendar=restored.get_completed_run_cycles()==run.get_completed_run_cycles()
	var world_codec:=WorldCodec.new()
	var dev_encoded: Variant=world_codec._capture_development(session)
	var dev_error: String=world_codec.error
	var dev_native: Dictionary={} if dev_encoded==null else world_codec._decode(dev_encoded,world_codec._development_schema(session.development.phase_index))
	if dev_error.is_empty(): dev_error=world_codec.error
	var dev_equal: bool=not dev_native.is_empty() and dev_native.project==world_codec._project_state(session.development.project) and dev_native.hand==world_codec._hand_state(session.development.hand,session.development.phase_index)
	var tampered_cash_rejected:=false
	var tampered_id_rejected:=false
	if not native.is_empty():
		var cash_bad: Dictionary=native.duplicate(true)
		cash_bad.run.cash_cents=int(cash_bad.run.cash_cents)+1
		tampered_cash_rejected=codec.encode_snapshot(cash_bad).is_empty()
		var id_bad: Dictionary=native.duplicate(true)
		id_bad.active_project_id=&"wrong-project"
		tampered_id_rejected=codec.encode_snapshot(id_bad).is_empty()
	var tampered_target_rejected:=false
	if not dev_native.is_empty():
		var target_bad: Dictionary=dev_native.project._market_details.duplicate(true)
		target_bad.standards[0]=int(target_bad.standards[0])+1
		tampered_target_rejected=not Market.valid_details(target_bad,session.development.project.get_genre_id())
	var fresh_recipe:=_recipe(seed)
	fresh_recipe.studio_id="jan-player-"+seed
	fresh_recipe.erase("prelude_capital_cents")
	fresh_recipe.erase("rival_founder_profile")
	fresh_recipe.specialty="action"
	var player_session: RefCounted=Factory.create_fresh_session(fresh_recipe,catalog)
	if player_session!=null: player_session.run._calendar_start_year=1980
	var world:=RivalWorld.new()
	var world_rejected:=player_session!=null and not world.initialize(player_session.run,{run._bank_run_id:session})
	var before_sales:=0
	var after_sales:=0
	var post_cycle_ok:=false
	var fans_before:=0
	var fans_after:=0
	if restored!=null:
		for id: StringName in restored.get_released_game_ids(): before_sales+=int(restored.get_released_game_sales(id).earned_units)
		fans_before=restored.get_fans()
		post_cycle_ok=restored.complete_productive_action(Callable(),0,72)
		if post_cycle_ok:
			for id: StringName in restored.get_released_game_ids(): after_sales+=int(restored.get_released_game_sales(id).earned_units)
			fans_after=restored.get_fans()
	var capsule: Dictionary={"version":1,"prelude_cycle":72,"relative_cycle":0,"source_identity":Replay.source_identity(),
		"run":encoded,"development":dev_encoded,"archive":archive,"historical_source":source}
	var capsule_path:=output.get_basename()+"-capsule.json"
	_write(capsule_path,capsule)
	var projected: Dictionary={"admitted":false,"wrong_offset_rejected":false,"missing_archive_rejected":false,
		"physical_years_equal":false,"first_boundary":{},"second_boundary":{},"old_sales_earned_units_delta":-1,
		"old_sales_settled_cents_delta":-1,"fans_delta":-1,"old_records_equal":false,"old_live_count":-1,
		"market_facts":-1,"world_cycle":-1,"rival_cycle":-1,"player_cycle":-1,"phase":""}
	if player_session!=null:
		projected.wrong_offset_rejected=not RivalWorld.new().initialize_projected_prelude(player_session.run,run._bank_run_id,session,archive,71)
		projected.missing_archive_rejected=not RivalWorld.new().initialize_projected_prelude(player_session.run,run._bank_run_id,session,archive.slice(1),72)
		projected.admitted=world.initialize_projected_prelude(player_session.run,run._bank_run_id,session,archive,72)
		if projected.admitted:
			var c0_player: Dictionary=StudioCodec.new().capture(world.player)
			var c0_codec:=WorldCodec.new()
			var c0_world: Dictionary=c0_codec.capture(world)
			_write(output.get_basename()+"-c0-world.json",{"source_identity":Replay.source_identity(),"player":c0_player,"world":c0_world,"error":c0_codec.error})
	if projected.admitted:
		projected.physical_years_equal=player_session.run.get_current_year()==1980 and run.get_current_year()==1980
		var old_records: Dictionary={}
		var before_earned:=0
		var before_settled:=0
		var before_fans:=run.get_fans()
		for id: StringName in run.get_released_game_ids():
			var sale: Dictionary=run.get_released_game_sales(id)
			old_records[id]=sale.duplicate(true)
			before_earned+=int(sale.earned_units)
			before_settled+=int(sale.settled_cents)
		var idle_policy:=func(_view: Dictionary) -> Dictionary: return {"type":&"blocked","payload":{"reason":"Projection idle boundary"}}
		for turn in range(2):
			var player_ok: bool=player_session.run.complete_productive_action(Callable(),0,player_session.run.get_completed_run_cycles())
			var boundary: Dictionary=world.advance_committed_player_cycle({run._bank_run_id:idle_policy},4) if player_ok else {"ok":false,"reason":"Player cycle rejected"}
			if turn==0: projected.first_boundary=boundary
			else: projected.second_boundary=boundary
			if not boundary.get("ok",false): break
		var after_earned:=0
		var after_settled:=0
		var records_equal:=true
		for id: StringName in old_records:
			var sale: Dictionary=run.get_released_game_sales(id)
			after_earned+=int(sale.earned_units)
			after_settled+=int(sale.settled_cents)
			if sale!=old_records[id]: records_equal=false
		projected.old_sales_earned_units_delta=after_earned-before_earned
		projected.old_sales_settled_cents_delta=after_settled-before_settled
		projected.fans_delta=run.get_fans()-before_fans
		projected.old_records_equal=records_equal
		projected.old_live_count=world.live_releases.size()
		projected.market_facts=world.market_snapshot.facts.size()
		projected.world_cycle=world.cycle
		projected.rival_cycle=run.get_completed_run_cycles()
		projected.player_cycle=player_session.run.get_completed_run_cycles()
		projected.phase=str(session.phase())
		var player_codec:=StudioCodec.new()
		var player_saved: Dictionary=player_codec.capture(player_session.run)
		var player_restored: RunState=player_codec.hydrate(player_saved) if not player_saved.is_empty() else null
		var rival_codec:=StudioCodec.new()
		var rival_saved: Dictionary=rival_codec.capture(run,session.project_id())
		var rival_restored: RunState=rival_codec.hydrate(rival_saved,true) if not rival_saved.is_empty() else null
		var tampered_closure_id_rejected:=false
		var tampered_closure_cycle_rejected:=false
		if not rival_saved.is_empty():
			var native_rival: Dictionary=rival_codec.snapshot(run,session.project_id())
			var missing_id: Dictionary=native_rival.duplicate(true)
			missing_id.run.closed_historical_ids.erase(missing_id.run.closed_historical_ids.keys()[0])
			tampered_closure_id_rejected=StudioCodec.new().encode_snapshot(missing_id).is_empty()
			var wrong_cycle: Dictionary=native_rival.duplicate(true)
			wrong_cycle.run.historical_close_cycle=71
			tampered_closure_cycle_rejected=StudioCodec.new().encode_snapshot(wrong_cycle).is_empty()
		var projected_world_codec:=WorldCodec.new()
		var world_saved: Dictionary=projected_world_codec.capture(world)
		var world_save_error: String=projected_world_codec.error
		var world_validation: String="Not captured"
		var restored_world: RivalWorld=null
		var restored_world_error: String=""
		var world_tamper_offset_rejected:=false
		var world_tamper_archive_rejected:=false
		var world_tamper_core_rejected:=false
		var continued_equal:=false
		var cold_fixture_path: String=""
		var cold_fixture_sha256: String=""
		var full_state_equal:=false
		var continued_original: Dictionary={}
		var continued_restored: Dictionary={}
		if not world_saved.is_empty() and not player_saved.is_empty():
			world_validation=projected_world_codec.validate(world_saved,player_saved)
			if world_validation.is_empty() and player_restored!=null:
				restored_world=projected_world_codec.restore(world_saved,player_saved,player_restored,catalog)
				restored_world_error=projected_world_codec.error
			var native_world: Dictionary=projected_world_codec.snapshot(world)
			if not native_world.is_empty():
				var bad_offset: Dictionary=native_world.duplicate(true)
				bad_offset.studios[0].offset="71"
				var bad_offset_encoded: Dictionary=WorldCodec.new().encode_snapshot(bad_offset)
				world_tamper_offset_rejected=bad_offset_encoded.is_empty() or not WorldCodec.new().validate(bad_offset_encoded,player_saved).is_empty()
				var bad_archive: Dictionary=native_world.duplicate(true)
				bad_archive.studios[0].archive.remove_at(0)
				var bad_archive_encoded: Dictionary=WorldCodec.new().encode_snapshot(bad_archive)
				world_tamper_archive_rejected=bad_archive_encoded.is_empty() or not WorldCodec.new().validate(bad_archive_encoded,player_saved).is_empty()
				var bad_core: Dictionary=native_world.duplicate(true)
				bad_core.studios[0].archive[0].cores[0]=int(bad_core.studios[0].archive[0].cores[0])+1
				var bad_core_encoded: Dictionary=WorldCodec.new().encode_snapshot(bad_core)
				world_tamper_core_rejected=bad_core_encoded.is_empty() or not WorldCodec.new().validate(bad_core_encoded,player_saved).is_empty()
			if restored_world!=null:
				var original_player_ok: bool=player_session.run.complete_productive_action(Callable(),0,player_session.run.get_completed_run_cycles())
				continued_original=world.advance_committed_player_cycle({run._bank_run_id:idle_policy},4) if original_player_ok else {"ok":false,"reason":"Original player rejected"}
				var restored_player_ok: bool=restored_world.player.complete_productive_action(Callable(),0,restored_world.player.get_completed_run_cycles())
				continued_restored=restored_world.advance_committed_player_cycle({run._bank_run_id:idle_policy},4) if restored_player_ok else {"ok":false,"reason":"Restored player rejected"}
				var original_rival: RunState=world.studios[run._bank_run_id].run
				var restored_rival: RunState=restored_world.studios[run._bank_run_id].run
				continued_equal=continued_original.get("ok",false) and continued_restored.get("ok",false) and world.cycle==restored_world.cycle and original_rival.get_completed_run_cycles()==restored_rival.get_completed_run_cycles() and original_rival.get_cash_cents()==restored_rival.get_cash_cents() and original_rival.get_fans()==restored_rival.get_fans() and original_rival.random_streams.snapshot()==restored_rival.random_streams.snapshot()
				var expected_after: Dictionary=_world_state(world)
				var restored_after: Dictionary=_world_state(restored_world)
				full_state_equal=continued_equal and not expected_after.is_empty() and expected_after==restored_after
				if full_state_equal:
					cold_fixture_path=output.get_basename()+"-world-fixture.json"
					_write(cold_fixture_path,{"source_identity":Replay.source_identity(),"player":player_saved,"world":world_saved,"expected_after":expected_after})
					cold_fixture_sha256=FileAccess.get_sha256(cold_fixture_path)
		projected.checkpoint={"player_ok":not player_saved.is_empty(),"player_error":player_codec.error,
			"player_restored_year":player_restored.get_current_year() if player_restored!=null else -1,
			"rival_ok":not rival_saved.is_empty(),"rival_error":rival_codec.error,
			"rival_restored":rival_restored!=null,
			"rival_restored_year":rival_restored.get_current_year() if rival_restored!=null else -1,
			"rival_restored_fans":rival_restored.get_fans() if rival_restored!=null else -1,
			"rival_restored_cash_cents":rival_restored.get_cash_cents() if rival_restored!=null else -1,
			"rival_restored_rng_equal":rival_restored!=null and rival_restored.random_streams.snapshot()==run.random_streams.snapshot(),
			"rival_restored_closure_equal":rival_restored!=null and rival_restored._closed_historical_ids==run._closed_historical_ids and rival_restored._historical_close_cycle==72,
			"tampered_closure_id_rejected":tampered_closure_id_rejected,
			"tampered_closure_cycle_rejected":tampered_closure_cycle_rejected,
			"world_ok":not world_saved.is_empty(),"world_error":world_save_error,
			"world_validation":world_validation,"world_restored":restored_world!=null,
			"world_restore_error":restored_world_error,
			"tampered_world_offset_rejected":world_tamper_offset_rejected,
			"tampered_world_archive_rejected":world_tamper_archive_rejected,
			"tampered_world_core_rejected":world_tamper_core_rejected,
			"continued_equal":continued_equal,"full_state_equal":full_state_equal,
			"cold_fixture_path":cold_fixture_path,"cold_fixture_sha256":cold_fixture_sha256,
			"continued_original":continued_original,
			"continued_restored":continued_restored}
	return {"capsule_path":capsule_path,"capsule_sha256":FileAccess.get_sha256(capsule_path),
		"run_capture_ok":not encoded.is_empty(),"run_capture_error":capture_error,
		"development_capture_ok":dev_error.is_empty() and dev_equal,"development_error":dev_error,
		"restore_checks":restore_checks,
		"restored_equal":restored!=null and restore_checks.values().all(func(value: Variant)->bool:return value==true),
		"tampered_cash_rejected":tampered_cash_rejected,"tampered_id_rejected":tampered_id_rejected,
		"tampered_target_rejected":tampered_target_rejected,"world_c0_rejected":world_rejected,
		"archive_count":archive.size(),"archive_unique":ids.size()==archive.size(),
		"archive_all_pre1980":archive.all(func(item: Dictionary)->bool:return item.release_cycle<72 and item.year<1980),
		"active_project_id":str(session.project_id()),"phase":str(session.phase()),
		"post_cycle_ok":post_cycle_ok,"old_sales_earned_units_delta":after_sales-before_sales,
		"old_fans_delta":fans_after-fans_before,"projected":projected}

func _market_for_run(owner_id: StringName,target_cycle: int) -> Dictionary:
	if _standard=="none" or _trial_run==null or owner_id!=_trial_run._bank_run_id: return Market.neutral()
	var source: Dictionary=Historical.source_from_run(_trial_run)
	if source.is_empty() or target_cycle<Historical.effective_cycle(source): return Market.neutral()
	return Historical.snapshot(source,target_cycle)

func _write(path: String,value: Dictionary) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null:
		push_error("Cannot write report: "+path)
		quit(2)
		return
	file.store_string(JSON.stringify(value,"  "))
	file.close()

func _owned_scope(run: RunState) -> int:
	return preload("res://scripts/market/rival_prelude_policy.gd").new(_genre,_policy)._owned_scope(run)

func _choose(session: RefCounted,view: Dictionary) -> Dictionary:
	var choice: Dictionary=preload("res://scripts/market/rival_prelude_policy.gd").new(_genre,_policy).choose(session,view)
	# Declared recovery-policy delta: quote eligibility is checked even when
	# can_admit is false solely because the upfront cash is unavailable.
	if choice.get("type",&"")==&"blocked" and view.phase==&"studio" and session.run._studio_finance.bank_loans.size()<4:
		for id: StringName in [&"main_theme",&"multiple_soundtracks"]:
			if session.run.owns_feature(id):continue
			var purchase: Dictionary=session.run.get_feature_research_quote(id)
			if purchase.get("unlocked",false) and session.run.get_financial_block_reason().is_empty() and session.run.get_cash_cents()<int(purchase.get("down_cents",0))+int(purchase.get("remaining_cents",0))+100000:
				var quote: Dictionary=session.run.get_bank_quote(150000,12)
				if quote.get("accepted",false):return {"type":&"bank_borrow","payload":{"quote":quote}}
			break
	return choice
