## In-memory development session. Owns command freshness and phase lifecycle.
## Inputs are validated canonical domain objects; this is not a save decoder.
## Successful Beta exit ends here, before Launch/Review/Studio settlement.
extends RefCounted

const Actions := preload("res://scripts/simulation/development_actions.gd")
const HAND_SCRIPTS := [preload("res://scripts/simulation/design_hand_command.gd"),preload("res://scripts/simulation/alpha_hand_command.gd"),preload("res://scripts/simulation/beta_hand_command.gd")]
const PHASES: Array[StringName] = [&"design",&"alpha",&"beta"]
var project: ProjectState
var run: RunState
var catalog: RefCounted
var snapshots: PrimitiveSnapshotDatabase
var hand: RefCounted
var actions: RefCounted
var phase_index := 0
var sequence := 0
var awaiting_confirmation := false
var finalized := false
var _busy := false

func initialize(project_state: ProjectState,run_state: RunState,definitions: RefCounted,snapshot_definitions: PrimitiveSnapshotDatabase) -> bool:
	if project!=null or project_state==null or run_state==null or definitions==null or snapshot_definitions==null or project_state.has_design_bug_finalization() or project_state.has_alpha_finalization() or project_state.has_beta_finalization(): return false
	project=project_state
	run=run_state
	catalog=definitions
	snapshots=snapshot_definitions
	_create_phase()
	return true

func _create_phase() -> void:
	hand=HAND_SCRIPTS[phase_index].new()
	hand._project_state=project
	hand._run_state=run
	hand._deal_rng=run.random_streams.stream(StringName(str(PHASES[phase_index])+"_deal"))
	if phase_index<2:
		hand.priorities=PriorityAllocation.new().get_priority_distribution()
		hand._available_features=catalog.get_project_features_for_phase(project,PHASES[phase_index])
		hand._pass_definitions=catalog.passes()
	else:
		hand.priorities=BetaPriorityAllocation.new().get_distribution()
		hand._snapshot_database=snapshots
		hand._insight_rng=run.random_streams.stream(&"beta_insight")
		hand._beta_definitions=catalog.get_cards_by_phase(&"beta")
		for card: CardData in hand._beta_definitions+catalog.passes(): hand._definitions_by_id[card.id]=card
	actions=Actions.new()
	actions.hand=hand
	actions.phase=PHASES[phase_index]
	actions.catalog=catalog
	if phase_index<2: actions.finalization_rng=run.random_streams.stream(StringName(str(PHASES[phase_index])+"_finalize"))
	awaiting_confirmation=false
	finalized=false
	run.refresh_redraws()

func command(kind: StringName,payload: Dictionary = {}) -> Dictionary:
	return {"schema_version":1,"type":kind,"project_id":project.get_release_id(),"phase":PHASES[phase_index],"sequence":sequence,"project_cycle":project.get_current_cycle(),"run_cycle":run.get_completed_run_cycles(),"payload":payload.duplicate(true)}

func reject(reason: String) -> Dictionary:
	return {"ok":false,"error":reason,"events":[]}

func execute(request: Dictionary) -> Dictionary:
	if _busy or project==null: return reject("Session unavailable")
	for field in ["schema_version","sequence","project_cycle","run_cycle"]:
		if not request.get(field) is int: return reject("Malformed command counter")
	for field in ["type","phase","project_id"]:
		if not request.get(field) is String and not request.get(field) is StringName: return reject("Malformed command identity")
	if request.get("schema_version")!=1 or request.get("sequence")!=sequence or request.get("phase")!=PHASES[phase_index] or request.get("project_id")!=project.get_release_id() or request.get("project_cycle")!=project.get_current_cycle() or request.get("run_cycle")!=run.get_completed_run_cycles(): return reject("Stale or unsupported command")
	if not request.get("type") is String and not request.get("type") is StringName: return reject("Malformed command type")
	if not request.get("payload") is Dictionary: return reject("Malformed command payload")
	_busy=true
	var streams_before:=run.random_streams.snapshot()
	var result:=_execute(StringName(request.type),request.payload)
	if result.ok:
		sequence+=1
		result.sequence=sequence
		result.rng_before=streams_before
		result.rng_after=run.random_streams.snapshot()
	_busy=false
	return result

func _execute(kind: StringName,payload: Dictionary) -> Dictionary:
	if kind==&"enter_next_phase":
		if not finalized or phase_index>=2 or not payload.is_empty(): return reject("No next development phase")
		phase_index+=1
		_create_phase()
		return {"ok":true,"events":[{"type":"phase_entered","phase":PHASES[phase_index]}]}
	if finalized: return reject("Phase finalized")
	if awaiting_confirmation:
		if not payload.is_empty(): return reject("Unexpected confirmation payload")
		if kind==&"cancel_exit":
			awaiting_confirmation=false
			return {"ok":true,"events":[{"type":"exit_canceled"}]}
		if kind!=&"confirm_exit": return reject("Exit confirmation pending")
		return _finish()
	if kind in [&"cancel_exit",&"confirm_exit"]: return reject("No pending confirmation")
	if kind==&"priorities":
		var distribution: Variant = payload.get("distribution")
		if payload.size()!=1 or not distribution is Dictionary: return reject("Malformed priorities")
		var valid: bool = BetaPriorityAllocation.is_valid_distribution(distribution) if phase_index==2 else PriorityAllocation.is_valid_distribution(distribution)
		if not valid or distribution==hand.priorities: return reject("Invalid or unchanged priorities")
		if not hand.active:
			hand.priorities=distribution.duplicate()
			return {"ok":true,"events":[{"type":"priorities_planned"}]}
		var allocation: RefCounted = BetaPriorityAllocation.new() if phase_index==2 else PriorityAllocation.new()
		allocation.set_distribution(hand.priorities)
		var publish:=func() -> void: hand.priorities=distribution.duplicate()
		if not Actions.commit_priorities(project,run,allocation,distribution,publish): return reject("Priority change rejected")
		return {"ok":true,"events":[{"type":"priorities_committed"},{"type":"productive_cycle"}]}
	if kind==&"begin":
		if hand.active or not payload.is_empty(): return reject("Phase already begun")
		var before: int = hand._deal_rng.state
		var plan: Dictionary = actions.initial_plan()
		if not plan.valid:
			hand._deal_rng.state=before
			return reject("Initial deal rejected")
		actions.publish_initial(plan)
		hand.active=true
		return {"ok":true,"events":[{"type":"initial_deal","candidate_ids":hand.candidate_ids.duplicate()}]}
	if not hand.active: return reject("Phase not begun")
	if kind in [&"play",&"redraw"]:
		var ids: Variant = payload.get("candidate_ids")
		if not ids is Array: return reject("Missing candidate tokens")
		var slots: Array[int] = []
		var typed_ids: Array[int] = []
		for id in ids:
			if not id is int or id in typed_ids or id not in hand.candidate_ids: return reject("Invalid candidate token")
			typed_ids.append(id)
			slots.append(hand.candidate_ids.find(id))
		if kind==&"redraw":
			if payload.size()!=1: return reject("Unexpected redraw payload")
			return actions.redraw(slots)
		var choice: Variant = payload.get("employee_priorities",{})
		if not choice is Dictionary or payload.size()>(2 if payload.has("employee_priorities") else 1): return reject("Invalid employee choice")
		if phase_index==2:
			if not choice.is_empty(): return reject("No Beta employee choice")
			return hand.execute(hand.command(typed_ids))
		return hand.execute(hand.command(typed_ids,choice))
	if not payload.is_empty(): return reject("Unexpected action payload")
	if kind==&"host_playtest":
		if not actions.host_playtest(): return reject("Playtest rejected")
		return {"ok":true,"events":[{"type":"host_playtest"},{"type":"productive_cycle"}]}
	if kind==&"request_exit":
		if not actions.can_finalize(): return reject("Phase cannot finish")
		var warnings: Array = []
		if phase_index==1 and project.get_current_scope()<project.get_required_scope(): warnings.append("under_scope")
		if phase_index==2: warnings=actions.boundary()._build_launch_warnings()
		if not warnings.is_empty():
			awaiting_confirmation=true
			return {"ok":true,"events":[{"type":"exit_confirmation_requested","warnings":warnings}]}
		return _finish()
	return reject("Unknown action")

func _finish() -> Dictionary:
	var result: Dictionary = actions.finalize()
	if result.ok:
		finalized=true
		awaiting_confirmation=false
	return result

## Policies receive only plain observations and return command payloads. No
## default AI policy or balance/exit budget is implied by this interface.
func observation() -> Dictionary:
	var candidates: Array = []
	for index in range(hand.candidate_ids.size()):
		var card: CardData = hand._candidate_cards[index]
		candidates.append({"token":hand.candidate_ids[index],"definition":str(card.id),"type":str(card.card_type),"primary_stat":str(card.primary_stat),"primary_value":card.primary_value,"secondary_stat":str(card.secondary_stat),"secondary_value":card.secondary_value,"scope":card.scope,"renewable":card.renewable,"beta_category":str(card.beta_category),"beta_value":card.beta_value,"qa_operation":str(card.qa_operation)})
	var core: Dictionary = {}
	for category in ProjectState.CoreScore.values(): core[category]=project.get_core_score(category)
	var pending: Array = []
	if phase_index==1: pending=hand._pending_playtest_categories.duplicate()
	if phase_index==2: pending=hand._pending_corrective_pass_ids.duplicate()
	return {"phase":str(PHASES[phase_index]),"sequence":sequence,"active":hand.active,"finalized":finalized,"confirmation_pending":awaiting_confirmation,"candidates":candidates,"priorities":hand.priorities.duplicate(),"project_cycle":project.get_current_cycle(),"run_cycle":run.get_completed_run_cycles(),"cash_cents":run.get_cash_cents(),"redraws":run.get_available_redraws(),"genre":str(project.get_genre_id()),"core":core,"scope":project.get_current_scope(),"required_scope":project.get_required_scope(),"known_bugs":project.get_known_bugs(),"fixed_bugs":project.get_fixed_bugs(),"marketing":project.get_marketing_output(),"pending_playtest":pending}
