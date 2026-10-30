## Thread-owned diagnostic for a frozen private simulator project.
## Legal founding/world progression only; no injected cash, titles, scores or time.
## Run through run_world.py against an isolated simulator bundle, never canonical.
extends SceneTree

const Factory := preload("res://scripts/simulation/run_factory.gd")
const Trial := preload("res://scripts/market/rival_trial.gd")
const Market := preload("res://scripts/market/market_transaction_trial.gd")
const Codec := preload("res://scripts/market/rival_world_checkpoint.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const Synergy := preload("res://scripts/market/rival_synergy_choice.gd")
const BetaChoice := preload("res://scripts/market/rival_beta_synergy_choice.gd")
const COMMAND_LIMIT := 180
const ORDINARY_RELEASES := 6
const ORDINARY_CYCLES := 48
const STRONG_RELEASES := 2
const STRONG_CYCLES := 36

var checks := 0
var failures := 0
var errors: Array = []
var timings: Array = []
var observations: Array = []
var release_reports: Array = []
var rival_choices: Array = []
var rival_progress: Array = []
var rival_releases: Array = []
var project_records: Dictionary = {}
var snapshots: Dictionary = {}
var coverage := {"genre_only":0,"theme_only":0,"pair":0,"disjoint":0,"own_other_title":0,
	"completed_pressured_player":0,"strong_player_release":0,"strong_player_to_rival":0,
	"age_month_reuse":0,"expired_facts":0,"rejected_atomic":0}
var recipe: Dictionary
var route := ""
var output := ""
var player: RefCounted
var world: RivalWorld
var catalog: RefCounted
var codec := Codec.new()
var last_checkpoint: Dictionary = {}
var failure_reason := ""
var starting_source := ""
var study_seed := ""
var candidate_mode := false
var initial_state_digest := ""
var initial_rng: Dictionary = {}
var arm := ""
var first_boundary_digest := ""
var first_boundary_rng: Dictionary = {}
var store_records: Array = []
var rival_release_details: Array = []

func _arg(prefix: String, fallback: String = "") -> String:
	for item in OS.get_cmdline_user_args():
		if item.begins_with(prefix): return item.substr(prefix.length())
	return fallback

func expect(ok: bool, label: String) -> void:
	checks += 1
	if ok: return
	failures += 1
	errors.append(label)
	push_error("MARKET_AWARE_STUDY " + label)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	output = _arg("--output=")
	route = _arg("--route=")
	study_seed = _arg("--seed=")
	candidate_mode = _arg("--candidate=", "0") == "1"
	arm = _arg("--arm=")
	starting_source = Replay.source_identity()
	if output.is_empty() or route != "action-war" or study_seed not in ["4417","4418"] or arm not in ["A","B","C"]:
		push_error("Explicit predeclared route, seed and fresh output required")
		quit(2)
		return
	if starting_source != _arg("--source=") or FileAccess.file_exists(output) or FileAccess.file_exists(output+".tape.json"):
		push_error("Source identity mismatch or output already exists")
		quit(2)
		return
	catalog = root.get_node("CardDatabase").get_development_catalog()
	var mode := _arg("--mode=", "record")
	if mode == "replay":
		_replay(_arg("--input="))
		return
	if mode == "restore":
		_restore(_arg("--input="))
		return
	# Preserve exact previously legal recipe identities. Their run IDs also seed
	# the incumbent cohort, so a new label would not be an equal starting world.
	recipe = {"schema_version":1,"studio_id":"market-acceptance-strong" if route=="strong" else "market-exposure-"+route+"-"+study_seed,
		"studio_name":"Market strong" if route=="strong" else "Exposure "+route+" "+study_seed,
		"specialty":"puzzle" if route=="puzzle-war" else "action",
		"traits":["family_funding","graduate"] if route == "strong" else ["cult_following"],"seed":study_seed}
	if not _start(): _finish({}); return
	var tape := {"source_identity":Replay.source_identity(),"engine_version":Engine.get_version_info().string,
		"recipe":recipe.duplicate(true),"route":route,"seed":study_seed,"candidate_mode":candidate_mode,"arm":arm,
		"initial":initial_state_digest,"initial_rng":initial_rng.duplicate(true),"steps":[]}
	var target_releases := STRONG_RELEASES if route == "strong" else ORDINARY_RELEASES
	var cycle_limit := STRONG_CYCLES if route == "strong" else ORDINARY_CYCLES
	for index in range(COMMAND_LIMIT):
		if player.in_studio and player.run.get_released_game_ids().size() >= target_releases: break
		if world.cycle >= cycle_limit: failure_reason="Predeclared cycle bound reached"; break
		var decision := _choose(player.observation())
		if decision.is_empty(): failure_reason="No legal policy choice"; break
		var request: Dictionary = player.command(StringName(decision.type),decision.get("payload",{}))
		# Stale protocol input is rejected at each real productive boundary.
		# This is a negative-control command, never counted as gameplay progression.
		if decision.type == &"begin_development" or (decision.type == &"development" and decision.payload.request.type == &"play"):
			var stale := request.duplicate(true)
			stale.run_cycle += 1
			var before := _state_digest()
			var rejected: Dictionary = player.execute(stale)
			expect(not rejected.ok and _state_digest()==before,"stale command leaves entire player/world/RNG unchanged")
			coverage.rejected_atomic += 1
		var step := _step(request)
		# Match Replay.record: freeze CardData/resources before object-disabled
		# Variant encoding. Commands retain their original typed payloads.
		var recorded := step.duplicate(true)
		recorded.result = Replay.freeze(step.result)
		recorded.advance = Replay.freeze(step.advance)
		tape.steps.append(recorded)
		if not step.result.get("ok",false):
			failure_reason=str(step.result.get("error","Legal policy action rejected"))
			break
		if failures: break
		await process_frame
	var completed: bool = player.in_studio and player.run.get_released_game_ids().size() >= target_releases
	expect(completed,"predeclared complete legal player releases")
	if route != "strong":
		if route.begins_with("action"):
			expect(coverage.completed_pressured_player>0,"completed player Review uses raised targets")
		var expected_bucket := "genre_only" if route=="action-war" else "disjoint"
		expect(coverage[expected_bucket]>0,"live player sales reaches "+expected_bucket)
		expect(coverage.own_other_title>0,"actual own other title enters sales crowding")
		expect(coverage.age_month_reuse>0,"second earning half reuses frozen factor")
		expect(coverage.expired_facts>0,"old actual releases expire after twelve cycles")
	else:
		expect(coverage.strong_player_release>0 and coverage.strong_player_to_rival>0,"legal strong player release affects a rival's next frozen targets")
	tape.final = _state_digest()
	tape.completed = completed
	expect(Replay.save_tape(output+".tape.json",tape),"exact interleaved world tape saved")
	_finish({"completed":completed,"commands":tape.steps.size(),"final":tape.final,
		"strong_status":"REACHED" if coverage.strong_player_to_rival>0 else "NOT REACHED" if route=="strong" else "NOT REQUESTED"})

func _start() -> bool:
	player = Factory.create_fresh_session(recipe,catalog)
	expect(player!=null,"legal founding recipe")
	if player==null: return false
	world = Trial.create_world(player.run,catalog)
	expect(world!=null,"ordinary activated two-incumbent world")
	if world==null: return false
	snapshots[world.market_snapshot.id]=world.market_snapshot.duplicate(true)
	initial_state_digest = _state_digest()
	initial_rng = _rng_snapshot()
	return true

func _choose(view: Dictionary) -> Dictionary:
	var genre := "puzzle" if route.begins_with("puzzle") else "action"
	var theme := "fantasy" if route.ends_with("fantasy") else "war"
	if view.phase == &"studio":
		return {"type":&"begin_development","payload":{"name":"Market route %d"%(view.releases.size()+1),"genre":genre,"theme":theme}}
	var current: Dictionary = view.development
	if current.finalized: return {"type":&"launch"} if current.phase=="beta" else Trial._development(view,&"enter_next_phase")
	if current.confirmation_pending: return Trial._development(view,&"confirm_exit")
	if not current.active:
		if route=="strong" and current.phase=="beta":
			var desired := {&"qa":50,&"marketing":20,&"insider":30}
			if current.priorities!=desired: return Trial._development(view,&"priorities",{"distribution":desired})
		return Trial._development(view,&"begin")
	var hands := 2
	if route=="strong" and view.releases.is_empty(): hands=int({"design":5,"alpha":11,"beta":3}[current.phase])
	if current.hand_revision >= hands+1 and current.can_exit: return Trial._development(view,&"request_exit")
	var cards: Array = current.candidates.duplicate(true)
	cards.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if (a.type=="feature")!=(b.type=="feature"): return a.type=="feature"
		return int(a.token)<int(b.token))
	if cards.size()<4: return {}
	var tokens: Array[int] = []
	if route=="strong" and current.phase in ["design","alpha"]:
		# A bounded public-view test policy; never reads hidden Bugs or future RNG.
		# Every choice still resolves through the ordinary hand command and finance.
		var best := -INF
		for a in range(cards.size()-3):
			for b in range(a+1,cards.size()-2):
				for c in range(b+1,cards.size()-1):
					for d in range(c+1,cards.size()):
						var candidate := Synergy._assess(current,[cards[a],cards[b],cards[c],cards[d]])
						if candidate.is_empty() or candidate.cost_cents>current.cash_cents: continue
						var value: float = candidate.proxy + mini(int(candidate.scope),maxi(0,current.required_scope-current.scope))*0.03
						if value>best: best=value;tokens.assign(candidate.tokens)
	else:
		for card: Dictionary in cards.slice(0,4): tokens.append(int(card.token))
		if route=="strong" and current.phase=="beta": tokens=BetaChoice.pick(current,cards.slice(0,4),StringName(view.run_id),true)
	if tokens.size()!=4: return {}
	return Trial._development(view,&"play",{"candidate_ids":tokens})

func _traced_policies() -> Dictionary:
	var wrapped := {}
	var originals: Dictionary = Trial.store_probe_policies(world,arm)
	for id: StringName in originals:
		wrapped[id] = _traced_policy(id, originals[id])
	return wrapped

func _traced_policy(id: StringName, original: Callable) -> Callable:
	return func(view: Dictionary) -> Dictionary:
		if id == &"incumbent-wayfinder-works" and view.releases.size() >= 1 and first_boundary_digest.is_empty():
			first_boundary_digest = _state_digest()
			first_boundary_rng = _rng_snapshot()
		var before := Time.get_ticks_usec()
		var chosen: Dictionary = original.call(view)
		var policy_us := Time.get_ticks_usec() - before
		var session: RefCounted = world.studios[id]
		var development: Dictionary = view.get("development", {})
		var frozen: Array = []
		var project_id := ""
		if not session.in_studio and session.development != null and session.development.project != null:
			var project: ProjectState = session.development.project
			frozen = project.get_market_standards()
			project_id = str(project.get_release_id())
		var observed: Array = development.get("review_standards", [])
		if candidate_mode and not frozen.is_empty():
			expect(observed == frozen, "candidate observation exposes its own immutable four-Core targets")
		var request: Dictionary = chosen.get("payload", {}).get("request", {})
		var selected: Array = request.get("payload", {}).get("candidate_ids", [])
		var row := {"studio_id":str(id), "cycle":world.cycle, "project_id":project_id,
			"phase":str(view.get("phase", "")), "sequence":view.get("sequence", -1),
			"hand_revision":development.get("hand_revision", -1),
			"cash_cents":development.get("cash_cents", view.get("cash_cents", -1)), "known_bugs":development.get("known_bugs", -1),
			"core":development.get("core", {}).duplicate(true), "scope":development.get("scope", -1),
			"frozen_standards":frozen.duplicate(), "observed_standards":observed.duplicate(),
			"candidates":development.get("candidates", []).duplicate(true),
			"action":str(chosen.get("type", "")), "request":str(request.get("type", "")),
			"selected_tokens":selected.duplicate(), "policy_wall_us":policy_us}
		rival_choices.append(row)
		if id == &"incumbent-wayfinder-works" and view.releases.size() >= 1 and view.phase == &"studio":
			var offer: Dictionary = {}
			for quote: Dictionary in view.research_quotes:
				if quote.feature_id == &"16_bit_music": offer = quote.duplicate(true); break
			store_records.append({"cycle":world.cycle,"cash_cents":view.cash_cents,
				"owned_features":view.owned_features.duplicate(true),"quote":offer,
				"outstanding":session.run.get_outstanding_expenses(),
				"finance":session.run.get_studio_finance_report(),
				"action":chosen.duplicate(true)})
			if chosen.is_empty():
				var deferred: bool = not offer.is_empty() and offer.queued and not offer.can_research and int(view.run_cycle) > world.cycle
				expect(deferred,"Wayfinder first Studio Store policy blocked outside post-cycle research deferment")
		return chosen

func _choice_signatures(start_index: int) -> Array:
	var result: Array = []
	for index in range(start_index, rival_choices.size()):
		var row: Dictionary = rival_choices[index].duplicate(true)
		row.erase("policy_wall_us")
		result.append(row)
	return result

func _capture_rival_progress() -> void:
	var ids: Array = world.studios.keys()
	ids.sort_custom(func(a: StringName,b: StringName) -> bool: return str(a) < str(b))
	for id: StringName in ids:
		var session: RefCounted = world.studios[id]
		var row := {"studio_id":str(id), "cycle":world.cycle, "phase":str(session.phase()),
			"cash_cents":session.run.get_cash_cents(), "fans":session.run.get_fans(),
			"outstanding":session.run.get_outstanding_expenses(),
			"release_count":session.run.get_released_game_ids().size()}
		if not session.in_studio and session.development != null and session.development.project != null:
			var project: ProjectState = session.development.project
			row["project_id"] = str(project.get_release_id())
			row["standards"] = project.get_market_standards()
			var cores: Array = []
			for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
				cores.append(project.get_core_score(category))
			row["cores"] = cores
			row["scope"] = project.get_current_scope()
			row["known_bugs"] = project.get_known_bugs()
			row["remaining_bugs"] = project.get_remaining_bugs()
		rival_progress.append(row)

func _owners() -> Dictionary:
	var result := {str(player.run._bank_run_id):player.run}
	for id: StringName in world.studios: result[str(id)]=world.studios[id].run
	return result

func _ledger_snapshot() -> Dictionary:
	var result := {}
	for id: String in _owners():
		var run: RunState=_owners()[id]
		var sales := {}
		for release_id: StringName in run.get_released_game_ids(): sales[str(release_id)]=run.get_released_game_sales(release_id)
		result[id]={"sales":sales,"fans":run._fanbase.duplicate(true),"cash":run.get_cash_cents()}
	return result

func _state_digest() -> String:
	var rivals := {}
	for id: StringName in world.studios: rivals[str(id)]=Replay.state(world.studios[id])
	return Replay.digest({"player":Replay.state(player),"rivals":rivals,"world":world.observation(),"market":world.market_snapshot})

func _rng_snapshot() -> Dictionary:
	var rivals := {}
	for id: StringName in world.studios: rivals[str(id)] = world.studios[id].run.random_streams.snapshot()
	return {"player":player.run.random_streams.snapshot(),"rivals":rivals}

func _step(request: Dictionary) -> Dictionary:
	var old_cycle: int=world.cycle
	var first_choice := rival_choices.size()
	var previous := _ledger_snapshot()
	var before_releases: int=player.run.get_released_game_ids().size()
	var clock := Time.get_ticks_usec()
	var result: Dictionary=player.execute(request)
	var action_us := Time.get_ticks_usec()-clock
	var advance: Dictionary={}
	var world_us := 0
	if result.ok and player.run.get_completed_run_cycles()==old_cycle+1:
		clock=Time.get_ticks_usec()
		advance=world.advance_committed_player_cycle(_traced_policies(),Trial.ZERO_STEPS)
		world_us=Time.get_ticks_usec()-clock
		expect(advance.get("ok",false),"rivals advance exactly once after legal player command: "+str(advance.get("reason","")))
		expect(world.cycle==player.run.get_completed_run_cycles(),"player/world calendar agreement")
		if not advance.get("ok",false): failure_reason=str(advance.get("reason",""))
		snapshots[world.market_snapshot.id]=world.market_snapshot.duplicate(true)
		_audit_month(previous)
		_audit_projects()
		_audit_expiry()
		_capture_rival_progress()
		for released: Dictionary in advance.get("new_releases", []):
			var owner: StringName = StringName(released.get("studio_id", ""))
			var event: Dictionary = released.duplicate(true)
			event["world_cycle"] = world.cycle
			if world.studios.has(owner):
				event["cash_cents"] = world.studios[owner].run.get_cash_cents()
				var rival_session: RefCounted = world.studios[owner]
				if rival_session.development != null and rival_session.development.project != null:
					var project: ProjectState = rival_session.development.project
					var cores: Array = []
					for category: ProjectState.CoreScore in ProjectState.CoreScore.values(): cores.append(project.get_core_score(category))
					rival_release_details.append({"studio_id":str(owner),"release_id":str(released.release_id),
						"cycle":world.cycle,"cores":cores,"scope":project.get_current_scope(),
						"known_bugs":project.get_known_bugs(),"remaining_bugs":project.get_remaining_bugs(),
						"review_tenths":released.review_tenths,"owned_features":rival_session.run.get_owned_feature_ids()})
			event["fans"] = world.studios[owner].run.get_fans()
			rival_releases.append(event)
	elif result.ok:
		expect(player.run.get_completed_run_cycles()==old_cycle,"free command preserves world calendar")
	if result.ok and player.run.get_released_game_ids().size()>before_releases:
		_audit_player_release()
		_checkpoint()
	clock=Time.get_ticks_usec()
	var state := _state_digest()
	var hash_us := Time.get_ticks_usec()-clock
	timings.append({"sequence":player.sequence,"cycle":world.cycle,"type":str(request.type),
		"action_wall_us":action_us,"world_wall_us":world_us,"hash_wall_us":hash_us,
		"static_memory_bytes":OS.get_static_memory_usage(),"peak_static_memory_bytes":OS.get_static_memory_peak_usage()})
	print("MARKET_ACCEPTANCE_STEP route=%s step=%d cycle=%d action_us=%d world_us=%d hash_us=%d cash=%d fans=%d"%[route,player.sequence,world.cycle,action_us,world_us,hash_us,player.run.get_cash_cents(),player.run.get_fans()])
	return {"command":request.duplicate(true),"result":result.duplicate(true),"advance":advance.duplicate(true),
		"choice_signatures":_choice_signatures(first_choice),"state":state}

func _buckets(snapshot: Dictionary, owner: String, release_id: String, genre: String, theme: String) -> Dictionary:
	var counts := {"genre_only":0,"theme_only":0,"pair":0,"own_other_title":0}
	for fact: Dictionary in snapshot.facts:
		if fact.studio_id==owner and fact.release_id==release_id: continue
		var same_genre: bool=fact.genre==genre
		var same_theme: bool=fact.theme==theme
		if same_genre and same_theme: counts.pair+=1
		elif same_genre: counts.genre_only+=1
		elif same_theme: counts.theme_only+=1
		if fact.studio_id==owner and (same_genre or same_theme): counts.own_other_title+=1
	counts.factor_bp=maxi(7000,10000-600*counts.genre_only-300*counts.theme_only-1200*counts.pair)
	return counts

func _audit_month(previous: Dictionary) -> void:
	for owner: String in _owners():
		var run: RunState=_owners()[owner]
		var before: Dictionary=previous[owner]
		for release_id: String in before.sales:
			var old: Dictionary=before.sales[release_id]
			var now:=run.get_released_game_sales(StringName(release_id))
			expect(now.total_earned_cycles==old.total_earned_cycles+1,"one earning tick per existing title")
			var age: int=int(now.total_earned_cycles+1)/2
			var factor: Dictionary=now.market_factors[age]
			var meta:=run.get_release_metadata(StringName(release_id))
			if now.total_earned_cycles%2==1:
				var counted:=_buckets(world.market_snapshot,owner,release_id,str(meta.genre),str(meta.theme))
				for key: String in ["genre_only","theme_only","pair","factor_bp"]: expect(factor[key]==counted[key],"saved exclusive "+key+" matches actual release facts")
				expect(factor.snapshot_id==world.market_snapshot.id and factor.cycle_start==world.market_snapshot.cycle_start and not factor.historical,"new factor stores committed snapshot provenance")
				if owner==str(player.run._bank_run_id):
					for key: String in ["genre_only","theme_only","pair"]:
						if counted[key]>0: coverage[key]+=1
					if counted.genre_only+counted.theme_only+counted.pair==0 and not world.market_snapshot.facts.is_empty(): coverage.disjoint+=1
					if counted.own_other_title>0: coverage.own_other_title+=1
			else:
				expect(factor==old.market_factors[age],"second half preserves exact prior factor metadata")
				coverage.age_month_reuse+=1
			for prior_age: int in old.market_factors: expect(now.market_factors[prior_age]==old.market_factors[prior_age],"past factor never rewritten")
			var expected_units := 0
			if now.total_earned_cycles<=2:
				var base_units: int=int(now.total_units)*int(now.total_earned_cycles)/2
				expected_units=base_units*int(factor.factor_bp)/10000
			else:
				var earned_now: int=int(now.monthly_units)/2 if now.total_earned_cycles%2==1 else int(now.monthly_units)-int(now.monthly_units)/2
				expected_units=int(old.earned_units)+earned_now
				if now.total_earned_cycles%2==1:
					var raw_month: int=500*int(now.review_tenths)*int(now.active_awareness_scaled)*int(now.market_bp)/(70*200*10000*10000)
					expect(now.monthly_units==raw_month*int(factor.factor_bp)/10000,"later age month exact independently calculated market units")
			var expected_cents: int=expected_units*999*70/100
			expect(now.earned_units==expected_units and now.entitlement_cents==expected_cents,"independent cumulative integer units and cents")
			expect(now.settled_cents==(expected_cents if world.cycle%2==0 else old.settled_cents),"calendar cash settlement timing exact")
			observations.append({"cycle":world.cycle,"owner":owner,"release":release_id,"age_month":age,"factor":factor.duplicate(true),"earned_units":now.earned_units,"entitlement_cents":now.entitlement_cents,"settled_cents":now.settled_cents,"fans":run.get_fans(),"cash_cents":run.get_cash_cents()})
		if world.cycle%2==1:
			expect(run.get_fans()==int(before.fans.fans),"first half leaves settled Fan count unchanged")
		else:
			var month: Dictionary=run._fanbase.months[-1]
			expect(month.starting==int(before.fans.fans) and month.ending==month.starting+month.gained-month.lost and month.ending==run.get_fans(),"exact monthly Fan reconciliation")
			_audit_fan_targets(run,before)

func _audit_fan_targets(run: RunState, before: Dictionary) -> void:
	# Independent integer targets for the existing ACTIVE/TRIAL Fan rules.
	# Audit only titles present before this cycle; an actual rival launch can
	# register after this same boundary and must not acquire retroactive Fans.
	var ids: Array=before.sales.keys()
	ids.sort()
	var gains := 0
	var losses := 0
	var starting: int=before.fans.fans
	for release_id: String in ids:
		var prior: Dictionary=before.fans.releases[StringName(release_id)]
		var current: Dictionary=run._fanbase.releases[StringName(release_id)]
		var sales:=run.get_released_game_sales(StringName(release_id))
		var buyers: int=maxi(0,int(sales.earned_units)-int(prior.launch_fans))
		var quality: int=mini(30,maxi(0,int(prior.review_tenths)-50))
		var gain_target: int=buyers*8*quality/2000
		var exposed: int=mini(int(prior.launch_fans),int(current.neutral.earned_units))
		var loss_target: int=exposed*15*maxi(0,50-int(prior.review_tenths))/1000
		var loss: int=mini(starting-losses,loss_target-int(prior.loss_exposure_accounted))
		gains+=gain_target-int(prior.gained)
		losses+=loss
		expect(current.gained==gain_target and current.accounted_units==sales.earned_units,"independent market-adjusted cumulative Fan gain")
		expect(current.loss_exposure_accounted==loss_target and current.lost==int(prior.lost)+loss,"independent neutral-exposure Fan loss with shared cap")
		for age: int in current.neutral.market_factors:
			expect(current.neutral.market_factors[age].factor_bp==10000,"neutral Fan exposure is not reduced by crowding")
	var month: Dictionary=run._fanbase.months[-1]
	expect(month.gained==gains and month.lost==losses and run.get_fans()==starting+gains-losses,"independent exact aggregate Fans after market sales")

func _audit_projects() -> void:
	var sessions: Dictionary={str(player.run._bank_run_id):player}
	for id: StringName in world.studios: sessions[str(id)]=world.studios[id]
	for owner: String in sessions:
		var session: RefCounted=sessions[owner]
		if session.in_studio or session.development==null: continue
		var project: ProjectState=session.development.project
		var id:=str(project.get_release_id())
		var details: Dictionary=project.get_market_details()
		var standards:=project.get_market_standards()
		if project_records.has(id):
			expect(project_records[id].details==details and project_records[id].standards==standards,"active project never changes frozen market basis")
			continue
		var source: Dictionary=snapshots.get(project.get_market_snapshot_id(),{})
		expect(not source.is_empty(),"project target names a previously committed snapshot")
		if source.is_empty(): continue
		var expected: Dictionary=Market.targets(source,owner,project.get_genre_id())
		expect(standards==expected.standards,"new project uses saved current market standards")
		project_records[id]={"owner":owner,"cycle":world.cycle,"genre":str(project.get_genre_id()),"standards":standards.duplicate(),"details":details.duplicate(true),"source":source.duplicate(true)}
		if owner!=str(player.run._bank_run_id):
			for fact: Dictionary in source.facts:
				if fact.studio_id!=str(player.run._bank_run_id) or fact.genre!=str(project.get_genre_id()) or fact.review_tenths<70 or not fact.cores_available: continue
				var base: Array=PrimitiveReviewCalculator.GENRE_TARGETS[project.get_genre_id()]
				for category in range(4):
					var lift: int=mini(8,maxi(0,int(fact.cores[category])-int(base[category]))/2)
					if lift>int(expected.density_lift) and standards[category]==base[category]+lift:
						coverage.strong_player_to_rival+=1

func _audit_expiry() -> void:
	for source: Dictionary in snapshots.values():
		for old: Dictionary in source.facts:
			if world.market_snapshot.cycle_start-int(old.release_cycle)<=12: continue
			var found := false
			for fact: Dictionary in world.market_snapshot.facts:
				if old.studio_id==fact.studio_id and old.release_id==fact.release_id: found=true
			expect(not found,"actual release expires at thirteen cycles")
			coverage.expired_facts+=1

func _audit_player_release() -> void:
	var project: ProjectState=player.development.project
	var id:=project.get_release_id()
	var standards:=project.get_market_standards()
	var base: Array=PrimitiveReviewCalculator.GENRE_TARGETS[project.get_genre_id()]
	var review:=project.get_review_result()
	for category in range(4): expect(review.get_standard(category)==standards[category],"completed Review uses project frozen target")
	if standards!=base: coverage.completed_pressured_player+=1
	var record: Dictionary=player.run.get_released_game_sales(id)
	if record.review_tenths>=70: coverage.strong_player_release+=1
	release_reports.append({"id":str(id),"cycle":world.cycle,"metadata":player.run.get_release_metadata(id),"standards":standards,"market_details":project.get_market_details(),"sales":record,"fans":player.run.get_fans(),"cash_cents":player.run.get_cash_cents()})

func _checkpoint() -> void:
	expect(player.in_studio, "checkpoint only after completed player release at Studio boundary")
	if not player.in_studio: return
	var clock:=Time.get_ticks_usec()
	var player_saved:=StudioCheckpoint.new().capture(player.run)
	var world_saved:=codec.capture(world)
	expect(not player_saved.is_empty() and not world_saved.is_empty(),"actual completed Studio pair captures: "+codec.error)
	var elapsed:=Time.get_ticks_usec()-clock
	last_checkpoint={"player":player_saved,"world":world_saved,"digest":Replay.digest(world_saved),
		"source_identity":Replay.source_identity(),"engine_version":Engine.get_version_info().string,
		"candidate_mode":candidate_mode,"route":route,"seed":study_seed,
		"release_count":player.run.get_released_game_ids().size(),"world_cycle":world.cycle,
		"player_rng":Replay.freeze(player.run.random_streams.snapshot()),
		"world_observation":Replay.freeze(world.observation())}
	timings.append({"cycle":world.cycle,"checkpoint_wall_us":elapsed,"checkpoint_bytes":JSON.stringify(last_checkpoint).to_utf8_buffer().size(),"static_memory_bytes":OS.get_static_memory_usage()})

func _restore(input: String) -> void:
	var payload: Variant = JSON.parse_string(FileAccess.get_file_as_string(input)) if FileAccess.file_exists(input) else null
	expect(payload is Dictionary and not payload.is_empty(), "source-matched Studio checkpoint exists")
	if failures: _finish({"mode":"restore"}); return
	expect(payload.get("source_identity")==starting_source and payload.get("engine_version")==Engine.get_version_info().string
		and payload.get("candidate_mode")==candidate_mode and payload.get("route")==route
		and str(payload.get("seed", ""))==study_seed,"no cross-source, cross-engine or cross-arm checkpoint load")
	if failures: _finish({"mode":"restore"}); return
	var saved_player: Dictionary=payload.get("player",{})
	var saved_world: Dictionary=payload.get("world",{})
	expect(not saved_player.is_empty() and not saved_world.is_empty(),"paired player and world checkpoint payload")
	if failures: _finish({"mode":"restore"}); return
	var player_codec:=StudioCheckpoint.new()
	var hydrated: RunState=player_codec.hydrate(saved_player)
	expect(hydrated!=null,"Studio-only player Continue: "+player_codec.error)
	if failures: _finish({"mode":"restore"}); return
	world=codec.restore(saved_world,saved_player,hydrated,catalog)
	expect(world!=null,"paired rival world Continue: "+codec.error)
	if failures: _finish({"mode":"restore"}); return
	var recaptured_player: Dictionary=player_codec.capture(hydrated)
	var recaptured_world: Dictionary=codec.capture(world)
	expect(Replay.freeze(recaptured_player)==Replay.freeze(saved_player)
		and Replay.freeze(recaptured_world)==Replay.freeze(saved_world),
		"Studio Continue preserves complete paired checkpoint payload")
	expect(world.cycle==int(payload.get("world_cycle",-1))
		and Replay.freeze(world.observation())==payload.get("world_observation",{}),
		"Studio Continue preserves world cycle and visible market")
	expect(Replay.freeze(hydrated.random_streams.snapshot())==payload.get("player_rng",{})
		and world.player==hydrated and hydrated.get_released_game_ids().size()==int(payload.get("release_count",-1)),
		"Studio Continue preserves player RNG, release history and world ownership")
	_finish({"mode":"restore","completed":failures==0,"restored_world_cycle":world.cycle,
		"restored_release_count":hydrated.get_released_game_ids().size(),
		"saved_world_digest":payload.get("digest", ""),"recaptured_world_digest":Replay.digest(recaptured_world)})

func _replay(input: String) -> void:
	var tape:=Replay.load_tape(input)
	expect(not tape.is_empty() and tape.get("source_identity")==Replay.source_identity()
		and tape.get("engine_version")==Engine.get_version_info().string
		and tape.get("candidate_mode")==candidate_mode and tape.get("arm")==arm,"fresh replay exact gameplay source, engine and arm")
	if tape.is_empty() or failures: _finish({"mode":"replay"});return
	recipe=tape.recipe
	route=tape.route
	study_seed=str(tape.get("seed", ""))
	if not _start(): _finish({"mode":"replay"});return
	expect(_state_digest()==tape.initial and _rng_snapshot()==tape.initial_rng,
		"fresh player and both rivals have identical initial state/RNG")
	for index in range(tape.steps.size()):
		var expected: Dictionary=tape.steps[index]
		var actual:=_step(expected.command)
		if Replay.freeze(actual.result)!=expected.result or Replay.freeze(actual.advance)!=expected.advance or actual.choice_signatures!=expected.choice_signatures or actual.state!=expected.state:
			observations.append({"replay_divergence_step":index,"expected":Replay.freeze(expected),"actual":Replay.freeze(actual)})
		expect(Replay.freeze(actual.result)==expected.result and Replay.freeze(actual.advance)==expected.advance
			and actual.choice_signatures==expected.choice_signatures and actual.state==expected.state,
			"exact player/rival choice, result and state replay step "+str(index))
		if failures: break
	expect(_state_digest()==tape.final,"fresh interleaved world final state/RNG exact")
	_finish({"mode":"replay","commands":tape.steps.size(),"final":_state_digest()})

func _finish(extra: Dictionary) -> void:
	var ending_source := Replay.source_identity()
	var report := {"route":route,"seed":study_seed,"candidate_mode":candidate_mode,"arm":arm,"recipe":recipe,
		"source_identity":ending_source,"starting_source_identity":starting_source,"source_drift":starting_source!=ending_source,
		"initial_state_digest":initial_state_digest,"initial_rng":initial_rng,
		"first_boundary_digest":first_boundary_digest,"first_boundary_rng":first_boundary_rng,
		"store_records":store_records,"rival_release_details":rival_release_details,
		"checks":checks,"failures":failures,"errors":errors,"failure_reason":failure_reason,
		"coverage":coverage,"timings":timings,"observations":observations,"releases":release_reports,"projects":project_records,
		"rival_choices":rival_choices,"rival_progress":rival_progress,"rival_releases":rival_releases,
		"rival_publications":[] if world==null else world.observation().live_releases,
		"harness_sha256":FileAccess.get_sha256(get_script().resource_path),"synthetic_gameplay_state":false,"cpu_note":"Wall timings only; measure actual process CPU in external runner."}
	report.merge(extra,true)
	if not last_checkpoint.is_empty():
		var saved:=FileAccess.open(output+".checkpoint.json",FileAccess.WRITE)
		if saved!=null: saved.store_string(JSON.stringify(last_checkpoint,"\t"));saved.close()
	var file:=FileAccess.open(output,FileAccess.WRITE)
	if file==null: push_error("Cannot save acceptance report");quit(2);return
	file.store_string(JSON.stringify(report,"\t"));file.close()
	print("MARKET_AWARE_STUDY route=%s seed=%s checks=%d failures=%d coverage=%s"%[route,study_seed,checks,failures,JSON.stringify(coverage)])
	quit(0 if failures==0 else 1)
