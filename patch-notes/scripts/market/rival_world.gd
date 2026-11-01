## Shared-calendar rival foundation. A caller supplies actual CampaignSessions and
## bounded policies; this class never grants resources or rolls a final Review.
## Each rival's RunState remains the owner of hands, finance, sales and Fans.
class_name RivalWorld
extends RefCounted
const DecisionPolicy := preload("res://scripts/simulation/decision_policy.gd")
const Clock := preload("res://scripts/calendar/calendar_clock.gd")
var player: RunState
var cycle := -1
var studios: Dictionary = {}
var live_releases: Dictionary = {}
var market_snapshot: Dictionary = {"version":2,"cycle_start":0,"id":"market-0-neutral","facts":[]}
var market_origin: Dictionary = {} # Only named pre-market migrations populate this.
var historical_archive: Dictionary = {}
var calendar_offsets: Dictionary = {} # Private typed prelude projection; normal worlds use zero.
var policy_states: Dictionary = {}
var legacy: Dictionary = {}
var annual_awards: Dictionary = {}
var _busy := false
## Scheduler only; policy/state/order remain the same. Tools may force serial.
var parallel_careers:=true
var _scheduler_failed:=false

func license_engine(engine_id: StringName) -> Dictionary:
	if _busy or _scheduler_failed or player == null: return {"ok":false,"error":"Marketplace is unavailable"}
	var listing: Dictionary = preload("res://scripts/engines/engine_marketplace.gd").current_listing(engine_id)
	if listing.is_empty() or not preload("res://scripts/engines/engine_marketplace.gd").creator_matches_world(listing,self): return {"ok":false,"error":"Engine owner is unavailable"}
	var creator: RunState = studios[listing.creator_id].run
	if not player.can_mutate_checkpoint() or not creator.can_mutate_checkpoint(): return {"ok":false,"error":"Studio checkpoint is unavailable"}
	var quote: Dictionary = preload("res://scripts/engines/engine_entitlements.gd").plan_license(player.get_engine_entitlements(),engine_id,player.get_cash_cents(),listing.creator_id,creator.get_cash_cents(),player._registered_engine_ids())
	if quote.is_empty(): return {"ok":false,"error":"Engine license is unavailable or unaffordable"}
	if not player._first_studio_economy or not creator._first_studio_economy: return {"ok":false,"error":"Studio finance is unavailable"}
	var buyer_plan: Dictionary = StudioFinanceLedger.plan(player._studio_finance,player.get_completed_run_cycles(),player.get_cash_cents(),quote.buyer_delta_cents,&"other_expense",0,0,false,quote.receipt_id)
	var creator_plan: Dictionary = StudioFinanceLedger.plan(creator._studio_finance,creator.get_completed_run_cycles(),creator.get_cash_cents(),quote.creator_delta_cents,&"other_income",0,0,false,quote.receipt_id)
	if buyer_plan.is_empty() or creator_plan.is_empty(): return {"ok":false,"error":"Engine license could not be settled"}
	var feature_state: Dictionary=player.get_engine_feature_state()
	var library: Array[StringName]=[];library.assign(listing.library)
	if not player.EngineFeatures.add_record(feature_state,engine_id,str(listing.name),&"rival_licensed",int(listing.max_scope),library,preload("res://scripts/engines/engine_marketplace.gd").RIVAL_ORIGIN):return {"ok":false,"error":"Engine library unavailable"}
	player._engine_features=feature_state
	player._cash_cents = buyer_plan.cash_cents
	player._studio_finance = buyer_plan.ledger
	player._engine_entitlements = quote.next_state
	creator._cash_cents = creator_plan.cash_cents
	creator._studio_finance = creator_plan.ledger
	player.cash_changed.emit();player.finance_changed.emit()
	creator.cash_changed.emit();creator.finance_changed.emit()
	return {"ok":true,"engine_id":engine_id,"creator_id":listing.creator_id,"amount_cents":listing.license_cents}

func settle_engine_royalties() -> Dictionary:
	if player == null: return {"ok":false,"error":"World is unavailable"}
	var totals := {}
	var claims := {}
	var licensed_engine_ids: Array = player.get_engine_entitlements().get("licensed_ids",[])
	for release_id: StringName in player._release_engine_ids:
		var engine_id: StringName = player._release_engine_ids[release_id]
		if engine_id not in licensed_engine_ids or player._commission_deals.has(release_id): continue
		var listing: Dictionary = preload("res://scripts/engines/engine_marketplace.gd").terms_for_record(engine_id,player._engine_features.get("engines",{}).get(engine_id,{}))
		if listing.is_empty() or not studios.has(listing.creator_id) or not player._released_games.has(release_id): return {"ok":false,"error":"Royalty owner or release is unavailable"}
		var creator: RunState = studios[listing.creator_id].run
		var settled: int = player._support_rights[release_id].studio_settled_cents if player._support_rights.has(release_id) else player._released_games[release_id].settled_cents
		if settled < 0: return {"ok":false,"error":"Royalty sales are invalid"}
		var due: int = preload("res://scripts/engines/engine_royalty.gd").cumulative(settled,int(listing.royalty_basis_points))
		var paid: int = int(creator._engine_royalty_receipts.get(release_id,0))
		if paid > due: return {"ok":false,"error":"Royalty receipt exceeds sales"}
		var delta := due - paid
		if delta == 0: continue
		if delta > RunState.MAX_SIGNED_INT - int(totals.get(listing.creator_id,0)): return {"ok":false,"error":"Royalty overflow"}
		totals[listing.creator_id] = int(totals.get(listing.creator_id,0)) + delta
		claims[release_id] = {"creator_id":listing.creator_id,"cumulative_cents":due}
	var plans := {}
	for creator_id: StringName in totals:
		var creator: RunState = studios[creator_id].run
		var receipt_id := StringName("engine-royalties:%s:%d:%d" % [creator_id,player.get_completed_run_cycles(),creator._studio_finance.actions.size()])
		var plan: Dictionary = StudioFinanceLedger.plan(creator._studio_finance,creator.get_completed_run_cycles(),creator.get_cash_cents(),totals[creator_id],&"other_income",0,0,false,receipt_id)
		if plan.is_empty(): return {"ok":false,"error":"Royalty finance rejected"}
		plans[creator_id] = plan
	for creator_id: StringName in plans:
		var creator: RunState = studios[creator_id].run
		creator._cash_cents = plans[creator_id].cash_cents
		creator._studio_finance = plans[creator_id].ledger
		creator.cash_changed.emit();creator.finance_changed.emit()
	for release_id: StringName in claims:
		var claim: Dictionary = claims[release_id]
		studios[claim.creator_id].run._engine_royalty_receipts[release_id] = claim.cumulative_cents
	return {"ok":true,"transfers":totals,"claims":claims}
func initialize(player_run: RunState, sessions: Dictionary) -> bool:
	if player != null or player_run == null or player_run.get_studio_name().is_empty() or sessions.is_empty(): return false
	var start_cycle := player_run.get_completed_run_cycles()
	var accepted: Dictionary = {}
	for raw_id: Variant in sessions:
		if not raw_id is String and not raw_id is StringName: return false
		var id := StringName(raw_id)
		var session: Variant = sessions[raw_id]
		if id.is_empty() or accepted.has(id) or id == player_run._bank_run_id or not session is RefCounted or not session.has_method("execute") or not session.has_method("observation") or session.run == null or session.run == player_run or session.run._bank_run_id != id or session.run.get_completed_run_cycles() != start_cycle or session.run.get_active_contract() != null or not session.run.get_released_game_ids().is_empty(): return false
		for other: Variant in accepted.values():
			if other == session or other.run == session.run: return false
		accepted[id] = session
	player = player_run
	studios = accepted
	cycle = start_cycle
	bind_market_providers()
	return true
## Private one-Action trial. Original c72 Studio state is retained; only its
## world clock is mapped to player c0. Persistence adoption is a separate gate.
func initialize_projected_prelude(player_run: RunState,id: StringName,session: RefCounted,archive: Array,offset: int) -> bool:
	return initialize_projected_cohort(player_run,{id:session},{id:archive},offset)

## Validate every owner before committing any closure or provider binding.
func initialize_projected_cohort(player_run: RunState,sessions: Dictionary,archives: Dictionary,offset: int=72) -> bool:
	if player!=null or player_run==null or player_run.get_completed_run_cycles()!=0 or player_run.get_current_year()!=1980 or sessions.is_empty() or sessions.size()>8 or sessions.size()!=archives.size() or offset!=72:return false
	var closures: Dictionary={}
	var seen_releases: Dictionary={}
	for id: StringName in sessions:
		var session: RefCounted=sessions[id]
		if not archives.has(id) or id.is_empty() or id==player_run._bank_run_id or session==null or session.run==null or session.run._bank_run_id!=id or session.run.get_completed_run_cycles()!=offset or session.run.get_current_year()!=1980 or session.run.get_active_contract()!=null or session.in_studio:return false
		var ids: Array[StringName]=session.run.get_released_game_ids()
		var archive: Array=archives[id]
		if ids.is_empty() or archive.size()!=ids.size():return false
		var matched: Dictionary={}
		for row: Variant in archive:
			if not row is Dictionary:return false
			var release_id:=StringName(row.get("id",""))
			if release_id not in ids or matched.has(release_id) or seen_releases.has(release_id):return false
			var meta: Dictionary=session.run.get_release_metadata(release_id)
			var sales: Dictionary=session.run.get_released_game_sales(release_id)
			if meta.is_empty() or sales.is_empty() or int(meta.release_year)>=1980 or int(meta.release_cycle)>=offset:return false
			if int(row.get("year",-1))!=meta.release_year or int(row.get("release_cycle",-1))!=meta.release_cycle or str(row.get("title",""))!=str(meta.release_title) or str(row.get("genre",""))!=str(meta.genre) or str(row.get("theme",""))!=str(meta.theme) or int(row.get("review_tenths",-1))!=sales.review_tenths or row.get("cores",[])!=meta.review.cores:return false
			matched[release_id]=true;seen_releases[release_id]=true
		if matched.has(session.project_id()):return false
		closures[id]=matched
	player=player_run;studios=sessions.duplicate();cycle=0
	for id: StringName in sessions:
		calendar_offsets[id]=offset
		historical_archive[id]=archives[id].duplicate(true)
		studios[id].run._closed_historical_ids=closures[id].duplicate(true)
		studios[id].run._historical_close_cycle=offset
		# The certified prelude keeps its historical clock. Convert only after
		# closure, so its raw72 offset and all historical stamps stay intact.
		if not player_run.get_calendar_profile().is_empty() and not studios[id].run.adopt_calendar():return false
	if not calendars_aligned():return false
	bind_market_providers()
	return true

func bind_market_providers() -> void:
	if player != null: preload("res://scripts/awards/annual_awards_ledger.gd").initialize(self)
	if player!=null: player._market_provider=Callable(self,"market_for_run")
	for id: StringName in studios:
		studios[id].run._market_provider=Callable(self,"market_for_run")
## Offsets remain raw owner-action differences. Converted profiles rebase the
## calendar anchor by that same offset; no owner history or project is rescaled.
func calendars_aligned() -> bool:
	if player==null or not Clock.valid(player.get_calendar_profile()):return false
	var player_calendar: Dictionary=player.get_calendar_profile()
	for id: StringName in studios:
		var owner_calendar: Dictionary=studios[id].run.get_calendar_profile()
		var offset: int=int(calendar_offsets.get(id,0))
		if not Clock.valid(owner_calendar):return false
		if player_calendar.is_empty():
			if not owner_calendar.is_empty():return false
		elif owner_calendar.is_empty() or int(owner_calendar.legacy_until)<offset or int(owner_calendar.legacy_until)-offset!=int(player_calendar.legacy_until):return false
	return true
func market_for_run(owner_id: StringName, target_cycle: int) -> Dictionary:
	if player==null or not calendars_aligned(): return {}
	if owner_id==player._bank_run_id:
		if target_cycle!=cycle+1: return {}
		return preload("res://scripts/market/market_transaction_trial.gd").preview(self,target_cycle)
	return market_snapshot.duplicate(true) if studios.has(owner_id) and target_cycle==cycle+1+int(calendar_offsets.get(owner_id,0)) else {}
## Call only after one successful player productive action. The player already
## settled its own cycle. A rival action uses the same RunState transaction;
## an idle rival still earns/settles/owes one calendar cycle through RunState.
## max_zero_steps is an explicit work bound, not a balance or CPU default.
func advance_committed_player_cycle(policies: Dictionary, max_zero_steps: int) -> Dictionary:
	if _scheduler_failed or _busy or player == null or max_zero_steps < 1 or cycle < 0 or player.get_completed_run_cycles() != cycle + 1 or not calendars_aligned(): return {"ok":false,"reason":"Player cycle boundary unavailable"}
	if not preload("res://scripts/market/market_transaction_trial.gd").commit_after_player(self,player._market_committed_candidate): return {"ok":false,"reason":"Player market preflight unavailable"}
	for id: StringName in studios:
		if not policies.get(id) is Callable or not policies[id].is_valid() or studios[id].run.get_completed_run_cycles() != cycle+int(calendar_offsets.get(id,0)): return {"ok":false,"reason":"Rival policy or calendar unavailable","studio_id":id}
	_busy = true
	var next_cycle := cycle + 1
	var reports: Array = []
	var published: Array = []
	var ids: Array = studios.keys()
	ids.sort_custom(func(a: StringName,b: StringName) -> bool: return str(a) < str(b))
	var parallel:=_parallel_safe(ids,policies)
	var jobs: Array[Thread]=[]
	var inline: Dictionary={}
	if parallel:
		for id: StringName in ids:
			var thread:=Thread.new()
			var error:=thread.start(_advance_studio.bind(id,policies[id],next_cycle+int(calendar_offsets.get(id,0)),max_zero_steps,true))
			jobs.append(thread)
			if error!=OK:inline[id]=_advance_studio(id,policies[id],next_cycle+int(calendar_offsets.get(id,0)),max_zero_steps,true)
	# Join every started owner before inspecting errors or publishing any facts.
	var joined: Dictionary={}
	if parallel:
		for i in range(ids.size()):joined[ids[i]]=jobs[i].wait_to_finish() if jobs[i].is_started() else inline[ids[i]]
	if parallel:
		var release_ids: Dictionary={}
		for id: StringName in ids:
			if not joined.get(id) is Dictionary:
				_busy=false;_scheduler_failed=true
				return {"ok":false,"reason":"Independent owner returned no result","completed_studios":joined,"cycle":cycle,"requires_checkpoint_recovery":true}
			var report: Dictionary=joined[id]
			if not report.get("ok",false):
				_busy=false;_scheduler_failed=true
				return {"ok":false,"reason":report.get("reason","Independent owner failed"),"studio_id":id,"completed_studios":joined,"cycle":cycle,"requires_checkpoint_recovery":true}
			for release: Dictionary in report.releases:
				if live_releases.has(release.release_id) or release_ids.has(release.release_id):
					_busy=false;_scheduler_failed=true
					return {"ok":false,"reason":"Duplicate collected release ID","completed_studios":joined,"cycle":cycle,"requires_checkpoint_recovery":true}
				release_ids[release.release_id]=true
	for id: StringName in ids:
		var report: Dictionary=joined[id] if parallel else _advance_studio(id,policies[id],next_cycle+int(calendar_offsets.get(id,0)),max_zero_steps)
		reports.append(report)
		if not report.ok:
			_busy = false
			return {"ok":false,"reason":report.reason,"studio_id":id,"completed_studios":reports,"cycle":cycle}
		if parallel:
			for release: Dictionary in report.releases:live_releases[release.release_id]=release
		published.append_array(report.releases)
	var royalties: Dictionary = settle_engine_royalties()
	if not royalties.get("ok",false):
		_busy = false;_scheduler_failed = true
		return {"ok":false,"reason":royalties.get("error","Royalty settlement failed"),"completed_studios":reports,"cycle":cycle,"requires_checkpoint_recovery":true}
	for report: Dictionary in reports:
		if royalties.transfers.has(report.studio_id): report.cash_cents = studios[report.studio_id].run.get_cash_cents()
	cycle = next_cycle
	_busy = false
	var annual: Dictionary = preload("res://scripts/awards/annual_awards_ledger.gd").settle(self)
	if not annual.ok:
		_scheduler_failed = true
		return {"ok":false,"reason":annual.error,"cycle":cycle,"requires_checkpoint_recovery":true}
	return {"ok":true,"cycle":cycle,"studios":reports,"new_releases":published}

func get_annual_awards() -> Dictionary:
	return annual_awards.duplicate(true)

func pending_awards_index() -> int:
	return preload("res://scripts/awards/annual_awards_ledger.gd").pending(annual_awards)

func advance_awards_stage(skip_to_results: bool = false) -> bool:
	var index := pending_awards_index()
	if _busy or _scheduler_failed or index < 0: return false
	var entry: Dictionary = annual_awards.entries[index]
	if entry.stage >= 9: return false
	if skip_to_results:
		if preload("res://scripts/awards/annual_awards_ledger.gd").first_presentation(annual_awards,index): return false
		entry.stage = 9
	else: entry.stage += 1
	return true

func complete_awards_presentation() -> bool:
	var index := pending_awards_index()
	if _busy or _scheduler_failed or index < 0 or annual_awards.entries[index].stage != 9: return false
	annual_awards.entries[index].complete = true
	return true
func _advance_studio(id: StringName, policy: Callable, target: int, limit: int, collect_only: bool=false) -> Dictionary:
	var session: RefCounted = studios[id]
	var run: RunState = session.run
	var before_releases: Array[StringName] = run.get_released_game_ids()
	var accepted: Array = []
	var zero_steps := 0
	var blocked := ""
	var productive := false
	# Launch is held until after the calendar settlement below. A newly
	# registered title therefore cannot earn sales on its creation boundary.
	while not productive:
		var chosen := _choice(policy, session)
		if chosen.is_empty(): blocked = "No legal policy choice"; break
		if chosen.type == &"blocked": blocked = str(chosen.payload.reason); break
		if chosen.type == &"launch": break
		if not _productive_choice(chosen,session) and zero_steps >= limit:
			blocked = "Zero-cycle work bound reached"
			break
		var prior := run.get_completed_run_cycles()
		var result: Dictionary = session.execute(session.command(chosen.type,chosen.payload))
		if not result.ok: blocked = str(result.get("error","Rejected rival choice")); break
		if policy.get_object().has_method("observe_result"):policy.get_object().observe_result(chosen,result)
		accepted.append({"type":chosen.type,"events":result.events.duplicate(true)})
		if run.get_completed_run_cycles() == prior + 1:
			productive = true
			break
		if run.get_completed_run_cycles() != prior: return {"ok":false,"reason":"Rival action crossed multiple cycles"}
		zero_steps += 1
	if not productive:
		if run._rival_founder_profile=="rival-founder-active-1977-v2":
			var waiting: Dictionary=session.execute(session.command(&"rival_wait"))
			if not waiting.ok:return {"ok":false,"reason":"Rival idle calendar rejected"}
			accepted.append({"type":&"rival_wait","events":waiting.events.duplicate(true)})
		elif not run.complete_productive_action(Callable(),0,target-1): return {"ok":false,"reason":"Rival idle calendar rejected"}
	if run.get_completed_run_cycles() != target: return {"ok":false,"reason":"Rival calendar diverged"}
	# Free completion, phase transitions, redraws and launch can follow the
	# productive boundary. Stop before a second productive action.
	while zero_steps < limit:
		# Only natural Beta completion/launch needs this same-tick window.
		# Other new-policy choices probe next-cycle affordability; defer them
		# until all owners settle and that authoritative Market exists.
		if run._rival_founder_profile=="rival-founder-active-1977-v2":
			if session.in_studio or session.phase()!=&"beta":break
			var decision: Object=policy.get_object()
			if decision.has_method("allows_post_boundary"):
				if not decision.allows_post_boundary():break
			elif session.in_studio or session.phase()!=&"beta" or not session.development.finalized:break
		var chosen := _choice(policy,session)
		if chosen.is_empty() or _productive_choice(chosen,session): break
		if chosen.type == &"blocked":
			blocked = str(chosen.payload.reason)
			break
		var result: Dictionary = session.execute(session.command(chosen.type,chosen.payload))
		if not result.ok:
			blocked = str(result.get("error","Rejected rival choice"))
			break
		if policy.get_object().has_method("observe_result"):policy.get_object().observe_result(chosen,result)
		accepted.append({"type":chosen.type,"events":result.events.duplicate(true)})
		if run.get_completed_run_cycles() != target: return {"ok":false,"reason":"Free rival action advanced the calendar"}
		zero_steps += 1
	var releases: Array = []
	for release_id: StringName in run.get_released_game_ids():
		if release_id in before_releases: continue
		if live_releases.has(release_id): return {"ok":false,"reason":"Duplicate world release ID"}
		var metadata := run.get_release_metadata(release_id)
		var sales := run.get_released_game_sales(release_id)
		if metadata.is_empty() or sales.is_empty(): return {"ok":false,"reason":"Incomplete world release"}
		var mapped_cycle: int=int(metadata.release_cycle)-int(calendar_offsets.get(id,0))
		if mapped_cycle!=cycle+1: return {"ok":false,"reason":"Live release calendar diverged"}
		var record := {"studio_id":id,"release_id":release_id,"release_cycle":mapped_cycle,"title":str(metadata.release_title),"genre":StringName(metadata.genre),"theme":StringName(metadata.theme),"review_tenths":int(sales.review_tenths)}
		if not collect_only:live_releases[release_id] = record
		releases.append(record.duplicate(true))
	return {"ok":true,"studio_id":id,"productive":productive,"blocked_reason":blocked,"zero_steps":zero_steps,"actions":accepted,"cash_cents":run.get_cash_cents(),"fans":run.get_fans(),"releases":releases}
func _choice(policy: Callable, session: RefCounted) -> Dictionary:
	var owner := policy.get_object()
	var view: Dictionary = owner.observation(session) if owner is DecisionPolicy else session.observation()
	var raw: Variant = policy.call(view)
	if not raw is Dictionary or (not raw.get("type") is String and not raw.get("type") is StringName) or not raw.get("payload",{}) is Dictionary: return {}
	var kind := StringName(raw.type)
	if kind == &"blocked":
		var reason: Variant = raw.payload.get("reason","")
		return {"type":kind,"payload":{"reason":reason}} if reason is String and not reason.is_empty() else {}
	if kind not in [&"begin_development",&"development",&"launch",&"admit_research",&"research",&"starter_purchase",&"bank_borrow",&"acknowledge_publishers",&"rival_wait",&"stage_engine_features",&"commit_engine_configuration",&"select_engine"]: return {}
	return {"type":kind,"payload":raw.get("payload",{}).duplicate(true)}
func _productive_choice(choice: Dictionary, session: RefCounted) -> bool:
	match choice.type:
		&"begin_development",&"research",&"rival_wait",&"commit_engine_configuration": return true
		&"development":
			var request: Variant = choice.payload.get("request",{})
			if not request is Dictionary: return true
			var kind := StringName(request.get("type",&""))
			return kind in [&"play",&"host_playtest"] or (kind == &"priorities" and session.development != null and session.development.hand.active)
	return false
func observation() -> Dictionary:
	var rows: Array = []
	var ids: Array = studios.keys()
	ids.sort_custom(func(a: StringName,b: StringName) -> bool: return str(a) < str(b))
	for id: StringName in ids:
		var session: RefCounted = studios[id]
		rows.append({"studio_id":id,"name":session.run.get_studio_name(),"specialty":session.run.get_studio_specialty(),"phase":session.phase(),"cycle":session.run.get_completed_run_cycles(),"cash_cents":session.run.get_cash_cents(),"fans":session.run.get_fans(),"release_count":session.run.get_released_game_ids().size()})
	var history: Array = live_releases.values().map(func(row: Variant) -> Variant: return row.duplicate(true))
	history.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if a.release_cycle != b.release_cycle: return a.release_cycle < b.release_cycle
		if a.studio_id != b.studio_id: return str(a.studio_id) < str(b.studio_id)
		return str(a.release_id) < str(b.release_id))
	return {"cycle":cycle,"studios":rows,"live_releases":history,"historical_archive":historical_archive.duplicate(true)}

## Only the fixed detached Career policy can run independently. No arbitrary
## closures, legacy rules, scene listeners or checkpoint callbacks cross threads.
## Every owner observes the same already-frozen month; publication stays sorted.
func _parallel_safe(ids: Array,policies: Dictionary) -> bool:
	if not parallel_careers or ids.size()!=8 or get_script().resource_path!="res://scripts/market/rival_world.gd" or not calendars_aligned():return false
	for id: StringName in ids:
		var run: RunState=studios[id].run
		if studios[id].get_script()!=preload("res://scripts/simulation/campaign_session.gd") or studios[id].catalog.get_script()!=preload("res://scripts/simulation/development_catalog.gd") or run._market_provider!=Callable(self,"market_for_run") or policies[id].get_method()!=&"choose":return false
		if run._rival_founder_profile!="rival-founder-active-1977-v2" or run.get_script()!=preload("res://scripts/run_state.gd") or calendar_offsets.get(id)!=72:return false
		var decision: Object=policies[id].get_object()
		if decision==null or decision.get_script()!=preload("res://scripts/market/rival_career_decision.gd") or decision.session!=studios[id] or decision.policy==null or decision.policy.get_script()!=preload("res://scripts/market/rival_career_policy.gd"):return false
		if run.checkpoint_before_mutation.is_valid() or run.studio_departure_guard.is_valid():return false
		for signal_info: Dictionary in run.get_signal_list():
			if not run.get_signal_connection_list(signal_info.name).is_empty():return false
	return true
