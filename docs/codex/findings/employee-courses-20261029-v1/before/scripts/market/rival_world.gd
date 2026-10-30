## Shared-calendar rival foundation. A caller supplies actual CampaignSessions and
## bounded policies; this class never grants resources or rolls a final Review.
## Each rival's RunState remains the owner of hands, finance, sales and Fans.
class_name RivalWorld
extends RefCounted

const DecisionPolicy := preload("res://scripts/simulation/decision_policy.gd")

var player: RunState
var cycle := -1
var studios: Dictionary = {}
var live_releases: Dictionary = {}
var market_snapshot: Dictionary = {"version":2,"cycle_start":0,"id":"market-0-neutral","facts":[]}
var market_origin: Dictionary = {} # Only named pre-market migrations populate this.
var historical_archive: Dictionary = {}
var legacy: Dictionary = {}
var _busy := false

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

func bind_market_providers() -> void:
	if player!=null: player._market_provider=Callable(self,"market_for_run")
	for id: StringName in studios:
		studios[id].run._market_provider=Callable(self,"market_for_run")

func market_for_run(owner_id: StringName, target_cycle: int) -> Dictionary:
	if player==null or target_cycle!=cycle+1: return {}
	if owner_id==player._bank_run_id:
		return preload("res://scripts/market/market_transaction_trial.gd").preview(self,target_cycle)
	return market_snapshot.duplicate(true) if studios.has(owner_id) else {}

## Call only after one successful player productive action. The player already
## settled its own cycle. A rival action uses the same RunState transaction;
## an idle rival still earns/settles/owes one calendar cycle through RunState.
## max_zero_steps is an explicit work bound, not a balance or CPU default.
func advance_committed_player_cycle(policies: Dictionary, max_zero_steps: int) -> Dictionary:
	if _busy or player == null or max_zero_steps < 1 or cycle < 0 or player.get_completed_run_cycles() != cycle + 1: return {"ok":false,"reason":"Player cycle boundary unavailable"}
	if not preload("res://scripts/market/market_transaction_trial.gd").commit_after_player(self,player._market_committed_candidate): return {"ok":false,"reason":"Player market preflight unavailable"}
	for id: StringName in studios:
		if not policies.get(id) is Callable or not policies[id].is_valid() or studios[id].run.get_completed_run_cycles() != cycle: return {"ok":false,"reason":"Rival policy or calendar unavailable","studio_id":id}
	_busy = true
	var next_cycle := cycle + 1
	var reports: Array = []
	var published: Array = []
	var ids: Array = studios.keys()
	ids.sort_custom(func(a: StringName,b: StringName) -> bool: return str(a) < str(b))
	for id: StringName in ids:
		var report := _advance_studio(id, policies[id], next_cycle, max_zero_steps)
		reports.append(report)
		if not report.ok:
			_busy = false
			return {"ok":false,"reason":report.reason,"studio_id":id,"completed_studios":reports,"cycle":cycle}
		published.append_array(report.releases)
	cycle = next_cycle
	_busy = false
	return {"ok":true,"cycle":cycle,"studios":reports,"new_releases":published}

func _advance_studio(id: StringName, policy: Callable, target: int, limit: int) -> Dictionary:
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
		accepted.append({"type":chosen.type,"events":result.events.duplicate(true)})
		if run.get_completed_run_cycles() == prior + 1:
			productive = true
			break
		if run.get_completed_run_cycles() != prior: return {"ok":false,"reason":"Rival action crossed multiple cycles"}
		zero_steps += 1
	if not productive:
		if not run.complete_productive_action(Callable(),0,target-1): return {"ok":false,"reason":"Rival idle calendar rejected"}
	if run.get_completed_run_cycles() != target: return {"ok":false,"reason":"Rival calendar diverged"}
	# Free completion, phase transitions, redraws and launch can follow the
	# productive boundary. Stop before a second productive action.
	while zero_steps < limit:
		var chosen := _choice(policy,session)
		if chosen.is_empty() or _productive_choice(chosen,session): break
		if chosen.type == &"blocked":
			blocked = str(chosen.payload.reason)
			break
		var result: Dictionary = session.execute(session.command(chosen.type,chosen.payload))
		if not result.ok:
			blocked = str(result.get("error","Rejected rival choice"))
			break
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
		var record := {"studio_id":id,"release_id":release_id,"release_cycle":int(metadata.release_cycle),"title":str(metadata.release_title),"genre":StringName(metadata.genre),"theme":StringName(metadata.theme),"review_tenths":int(sales.review_tenths)}
		live_releases[release_id] = record
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
	if kind not in [&"begin_development",&"development",&"launch",&"admit_research",&"research",&"starter_purchase",&"acknowledge_publishers"]: return {}
	return {"type":kind,"payload":raw.get("payload",{}).duplicate(true)}

func _productive_choice(choice: Dictionary, session: RefCounted) -> bool:
	match choice.type:
		&"begin_development",&"research": return true
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
