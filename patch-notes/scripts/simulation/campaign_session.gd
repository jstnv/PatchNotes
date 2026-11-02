## Scene-free multi-project session. Player Continue remains Studio-only and is
## preserved by the explicit checkpoint adapter. Definitions are trusted.
extends RefCounted

const Development := preload("res://scripts/simulation/development_session.gd")
const BeginProject := preload("res://scripts/simulation/begin_project.gd")
const Launch := preload("res://scripts/simulation/launch_settlement.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const Contract := preload("res://scripts/simulation/contract_session.gd")
const StudioActions := preload("res://scripts/simulation/studio_actions.gd")
var run: RunState
var catalog: RefCounted
var snapshots: PrimitiveSnapshotDatabase
var development: RefCounted
var contract: RefCounted
var sequence := 0
var in_studio := true
var _busy := false
var _commission_request: Dictionary = {}
var _support_request: Dictionary = {}

func initialize(run_state: RunState, definitions: RefCounted, snapshot_definitions: PrimitiveSnapshotDatabase) -> bool:
	if run != null or run_state == null or definitions == null or snapshot_definitions == null or not run_state.is_cash_initialized() or run_state._bank_run_id.is_empty() or run_state.get_studio_name().is_empty() or run_state.get_active_contract() != null: return false
	run = run_state
	catalog = definitions
	snapshots = snapshot_definitions
	# Initial Studio entry, once. Reconstructing a session must use a later explicit
	# restore adapter; this initializer does not load player saves.
	run.refresh_redraws()
	return true

func phase() -> StringName:
	if contract != null and not in_studio: return &"contract"
	return &"studio" if in_studio else Development.PHASES[development.phase_index]

func project_id() -> StringName:
	return &"" if in_studio or contract != null or development == null else development.project.get_release_id()

func command(kind: StringName, payload: Dictionary = {}) -> Dictionary:
	return {"schema_version":1,"run_id":run._bank_run_id,"project_id":project_id(),"phase":phase(),"sequence":sequence,"run_cycle":run.get_completed_run_cycles(),"type":kind,"payload":payload.duplicate(true)}

func reject(message: String) -> Dictionary:
	return {"ok":false,"error":message,"events":[]}

func execute(request: Dictionary) -> Dictionary:
	if _busy or run == null or sequence >= RunState.MAX_SIGNED_INT: return reject("Session unavailable")
	for field in ["schema_version","sequence","run_cycle"]:
		if not request.get(field) is int: return reject("Malformed counter")
	for field in ["run_id","project_id","phase","type"]:
		if not request.get(field) is String and not request.get(field) is StringName: return reject("Malformed identity")
	if not request.get("payload") is Dictionary: return reject("Malformed payload")
	if request.schema_version != 1 or request.sequence != sequence or request.run_cycle != run.get_completed_run_cycles() or request.run_id != run._bank_run_id or request.project_id != project_id() or request.phase != phase(): return reject("Stale or unsupported command")
	_busy = true
	var before := run.random_streams.snapshot()
	var result := _execute(StringName(request.type),request.payload)
	if result.ok:
		if StringName(request.type) != &"quote_commission": _commission_request = {}
		if StringName(request.type) != &"quote_support": _support_request = {}
		sequence += 1
		result.sequence = sequence
		result.rng_before = before
		result.rng_after = run.random_streams.snapshot()
		for ordinal in range(result.events.size()):
			result.events[ordinal].event_id = "%s:%d:%d" % [run._bank_run_id,sequence,ordinal]
	_busy = false
	return result

func _execute(kind: StringName,payload: Dictionary) -> Dictionary:
	# Explicit counterpart of the existing automatic rival calendar settlement.
	# It advances real sales/bills only; never a player's clock or project work.
	if kind==&"rival_wait":
		if run._rival_founder_profile!="rival-founder-active-1977-v2" or not payload.is_empty():return reject("Rival calendar unavailable")
		if not run.complete_productive_action(Callable(),0,run.get_completed_run_cycles(),&"",&"rival_wait",run._bank_run_id):return reject("Rival calendar settlement rejected")
		return {"ok":true,"events":[{"type":"rival_calendar_advanced","run_cycle":run.get_completed_run_cycles()}]}
	# Bank/education actions are available through Finances in every live phase.
	if kind in StudioActions.MONEY_ACTIONS: return StudioActions.execute(run,kind,payload,in_studio)
	if contract != null and not in_studio:
		if kind == &"contract":
			if payload.size() != 1 or not payload.get("request") is Dictionary: return reject("Missing Contract command")
			return contract.execute(payload.request)
		if kind != &"dismiss_contract" or not payload.is_empty() or not contract._state.is_completed(): return reject("Contract remains active")
		var offer: StringName = contract._state.get_offer_id()
		contract = null
		in_studio = true
		run.refresh_redraws()
		return {"ok":true,"events":[{"type":"studio_entered","offer_id":offer}]}
	if not in_studio:
		if kind == &"development":
			if payload.size() != 1 or not payload.get("request") is Dictionary: return reject("Missing development command")
			return development.execute(payload.request)
		if kind != &"launch" or not payload.is_empty() or development.phase_index != 2 or not development.finalized: return reject("Not at the launch boundary")
		var result := Launch.new(development.project,run,snapshots).settle()
		if not result.ok: return result
		in_studio = true
		run.refresh_redraws()
		result.events.append({"type":"studio_entered","release_id":development.project.get_release_id()})
		return result
	if kind in [&"activate_employees",&"hire",&"course",&"search_contracts",&"accept_contract"]:
		var result := StudioActions.execute(run,kind,payload,true)
		if result.ok and kind == &"accept_contract":
			contract = Contract.new(result.state,run,catalog)
			result.erase("state")
			in_studio = false
		return result
	if kind in [&"quote_commission",&"quote_support"]:
		if payload.size() != 3: return reject("Malformed quote request")
		for key: String in ["name","genre","theme"]:
			if not payload.get(key) is String and not payload.get(key) is StringName: return reject("Malformed quote choice")
		var quote := run.get_support_quote(str(payload.name),StringName(payload.genre),StringName(payload.theme)) if kind == &"quote_support" else run.get_commission_quote(str(payload.name),StringName(payload.genre),StringName(payload.theme))
		if quote.is_empty(): return reject("Commission unavailable")
		var choice := {"name":str(payload.name),"genre":str(payload.genre),"theme":str(payload.theme)}
		if kind == &"quote_support": _support_request = choice
		else: _commission_request = choice
		return {"ok":true,"events":[{"type":"support_quoted" if kind == &"quote_support" else "commission_quoted","quote":quote}]}
	if kind == &"begin_development":
		for field in ["name","genre","theme"]:
			if not payload.get(field) is String and not payload.get(field) is StringName: return reject("Missing project choice")
		var priorities: Variant = payload.get("priorities",{})
		if not priorities is Dictionary or (not priorities.is_empty() and not PriorityAllocation.is_valid_new_distribution(priorities, run)) or not payload.get("commission_quote",{}) is Dictionary or not payload.get("support_quote",{}) is Dictionary or payload.size() != 3 + int(payload.has("priorities")) + int(payload.has("commission_quote")) + int(payload.has("support_quote")): return reject("Invalid priorities or project payload")
		var result := BeginProject.execute(run,snapshots,str(payload.name),StringName(payload.genre),StringName(payload.theme),Callable(),[],payload.get("commission_quote",{}),payload.get("support_quote",{}))
		if not result.ok: return reject(result.error)
		development = Development.new()
		development.initialize(result.project,run,catalog,snapshots)
		if not priorities.is_empty(): development.hand.priorities = priorities.duplicate()
		in_studio = false
		return {"ok":true,"events":result.events}
	if kind == &"acknowledge_publishers" and payload.is_empty():
		return {"ok":true,"events":[{"type":"publishers_acknowledged","publishers":run.take_pending_publisher_notifications()}]}
	if kind == &"starter_purchase":
		if payload.size() != 1 or (not payload.get("feature_id") is String and not payload.get("feature_id") is StringName): return reject("Missing starter Feature")
		if not run.purchase_starter_feature(StringName(payload.feature_id)): return reject("Starter purchase rejected")
		return {"ok":true,"events":[{"type":"starter_feature_purchased","feature_id":StringName(payload.feature_id)}]}
	if kind==&"select_engine":
		if payload.size()!=1 or (not payload.get("engine_id") is String and not payload.get("engine_id") is StringName) or not run.select_engine(StringName(payload.engine_id)):return reject("Engine selection rejected")
		return {"ok":true,"events":[{"type":"engine_selected","engine_id":run.get_selected_engine_id()}]}
	if kind in [&"admit_research",&"research"]:
		if payload.size() != 1 or not payload.get("quote") is Dictionary: return reject("Missing research quote")
		var ok := run.admit_feature_research(payload.quote) if kind == &"admit_research" else run.research_feature(payload.quote)
		if not ok: return reject("Research rejected")
		var events: Array = [{"type":"research_admitted" if kind == &"admit_research" else "research_completed","feature_id":payload.quote.feature_id}]
		if kind == &"research": events.append({"type":"productive_cycle"})
		return {"ok":true,"events":events}
	if kind == &"campaign":
		if payload.size() != 1 or (not payload.get("release_id") is String and not payload.get("release_id") is StringName): return reject("Missing campaign release")
		if not run.purchase_post_launch_campaign(StringName(payload.release_id),run.get_completed_run_cycles()): return reject("Campaign rejected")
		return {"ok":true,"events":[{"type":"campaign_purchased","release_id":StringName(payload.release_id)},{"type":"productive_cycle"}]}
	return reject("Unsupported Studio command")

func observation() -> Dictionary:
	var commission_quote := {}
	var support_quote := {}
	if in_studio and not _support_request.is_empty(): support_quote = run.get_support_quote(_support_request.name,StringName(_support_request.genre),StringName(_support_request.theme))
	if in_studio and not _commission_request.is_empty(): commission_quote = run.get_commission_quote(_commission_request.name,StringName(_commission_request.genre),StringName(_commission_request.theme))
	var releases: Array = []
	for id in run.get_released_game_ids():
		releases.append({"id":id,"metadata":run.get_release_metadata(id),"sales":run.get_released_game_sales(id),"campaign":run.get_post_launch_campaign_offer(id)})
	var quotes: Array = []
	if in_studio:
		var ids: Array = run._feature_definitions.keys()
		ids.sort_custom(func(a: StringName,b: StringName) -> bool: return str(a) < str(b))
		for id in ids:
			var quote := run.get_feature_research_quote(id)
			if not quote.is_empty(): quotes.append(quote)
	return {"run_id":run._bank_run_id,"project_id":project_id(),"phase":phase(),"sequence":sequence,"run_cycle":run.get_completed_run_cycles(),"cash_cents":run.get_cash_cents(),"fans":run.get_fans(),"engine_available_features":FeatureStoreCatalog.future_supply(run.get_owned_feature_ids(),run._feature_offers),"engine_features":run.get_engine_feature_state(),"selected_engine_id":run.get_selected_engine_id(),"owned_features":run.get_owned_feature_ids(),"research_queue":run.get_feature_research_queue(),"research_quotes":quotes,"releases":releases,"studio_actions":StudioActions.observation(run),"publisher_relationships":run.get_publisher_relationships(),"commission_quote":commission_quote,"support_quote":support_quote,"support_history":run.get_support_history(),"commission_deals":run.get_commission_deals(),"contract":{} if contract == null else contract.observation(),"development":{} if in_studio or contract != null else development.observation()}

func quote_bank(principal_cents: Variant,months: Variant) -> Dictionary:
	return run.get_bank_quote(principal_cents,months) if run != null else {}

## Explicit termination budget and release target; no built-in gameplay policy.
## Policies return {type,payload}; all actions still use the legal command path.
func drive(policy: Callable,max_steps: int,target_release_count: int) -> Dictionary:
	if not policy.is_valid() or max_steps < 1 or target_release_count < 1: return {"ok":false,"error":"Policy, step budget and release target required"}
	var tape := Replay.begin(self)
	for step in range(max_steps):
		if in_studio and run.get_released_game_ids().size() >= target_release_count: return {"ok":true,"tape":tape}
		var choice: Variant = policy.call(observation())
		if not choice is Dictionary or (not choice.get("type") is String and not choice.get("type") is StringName) or not choice.get("payload",{}) is Dictionary: return {"ok":false,"error":"Malformed policy decision","step":step,"tape":tape}
		var result := Replay.record(self,tape,command(StringName(choice.type),choice.get("payload",{})))
		if not result.ok: return {"ok":false,"error":"Policy action rejected","step":step,"tape":tape}
	var completed := in_studio and run.get_released_game_ids().size() >= target_release_count
	return {"ok":completed,"error":"" if completed else "Policy step bound reached","tape":tape}

func replay_state() -> Dictionary:
	return _replay_state_with_context({})

func _replay_state_with_context(objects: Dictionary) -> Dictionary:
	var definitions: Array = []
	for card: CardData in catalog.cards.values():
		var fields: Dictionary = {}
		for property in card.get_property_list():
			if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE: fields[property.name] = Replay._freeze(card.get(property.name),objects)
		definitions.append(fields)
	# Completed presentation objects are not Studio authority. Continue has always
	# discarded them; canonical Studio replay state must do the same.
	# The committed-candidate scratch only bridges the synchronous player/world
	# transaction. The saved world.market owns its durable snapshot. Do not let
	# scratch discarded by Continue change a campaign's authoritative digest.
	var run_state: Dictionary = Replay._freeze(run,objects)
	run_state.erase("_market_committed_candidate")
	objects[run] = run_state.duplicate(true) # Nested hand/Contract Run references use the same projection.
	return {"kind":"campaign_v2","commission_request":_commission_request.duplicate(true),"support_request":_support_request.duplicate(true),"run":run_state,"sequence":sequence,"studio":in_studio,"development":{} if development == null or in_studio or contract != null else Replay._state(development,objects),"contract":{} if contract == null or in_studio else Replay._freeze(contract,objects),"definitions":definitions,"snapshots":Replay._freeze(snapshots,objects)}

## Simulation checkpoint envelope. The inner payload is exactly the existing
## Studio codec, not an active-project save format. Sequence is a command count,
## deliberately separate from the player save generation number.
func export_checkpoint() -> Dictionary:
	if _busy or run == null or not in_studio or contract != null: return {}
	var adapter := StudioCheckpoint.new()
	var payload := adapter.capture(run)
	if payload.is_empty(): return {}
	var envelope := {"schema_version":"1","kind":"campaign_studio","source_identity":Replay.source_identity(),"engine_version":Engine.get_version_info().string,"rng_algorithm":RunRandom.ALGORITHM,"accepted_sequence":str(sequence),"studio_payload":payload,"commission_request":_commission_request.duplicate(true)}
	envelope.integrity = Replay.digest(envelope)
	# Added before re-hashing; old named current envelopes may omit empty support.
	envelope.support_request = _support_request.duplicate(true)
	envelope.integrity = Replay.digest(_without_integrity(envelope))
	return envelope

func restore_checkpoint(envelope: Dictionary,definitions: RefCounted,snapshot_definitions: PrimitiveSnapshotDatabase) -> bool:
	if _busy or run != null or definitions == null or snapshot_definitions == null: return false
	if not envelope.get("schema_version") is String or envelope.schema_version != "1" or envelope.get("kind") != "campaign_studio" or envelope.get("source_identity") != Replay.source_identity() or envelope.get("engine_version") != Engine.get_version_info().string or envelope.get("rng_algorithm") != RunRandom.ALGORITHM or not envelope.get("studio_payload") is Dictionary or not envelope.get("integrity") is String: return false
	var contents := envelope.duplicate(true)
	contents.erase("integrity")
	if Replay.digest(contents) != envelope.integrity: return false
	var codec := CheckpointCodec.new()
	var restored_sequence: Variant = codec.integer(envelope.get("accepted_sequence"))
	if not codec.error.is_empty(): return false
	var restored := StudioCheckpoint.new().hydrate(envelope.studio_payload)
	if restored == null: return false
	var pending: Variant = envelope.get("commission_request",{})
	if not pending is Dictionary or (not pending.is_empty() and pending.size() != 3): return false
	if not pending.is_empty():
		for key: String in ["name","genre","theme"]:
			if not pending.get(key) is String: return false
		if restored.get_commission_quote(pending.name,StringName(pending.genre),StringName(pending.theme)).is_empty(): return false
	var support_pending: Variant = envelope.get("support_request",{})
	if not support_pending is Dictionary or (not support_pending.is_empty() and support_pending.size() != 3): return false
	if not support_pending.is_empty():
		for key: String in ["name","genre","theme"]:
			if not support_pending.get(key) is String: return false
		if restored.get_support_quote(support_pending.name,StringName(support_pending.genre),StringName(support_pending.theme)).is_empty(): return false
	# Publish metadata only after every part of the envelope has passed.
	_commission_request = pending.duplicate(true)
	_support_request = support_pending.duplicate(true)
	run = restored
	catalog = definitions
	snapshots = snapshot_definitions
	sequence = restored_sequence
	in_studio = true
	# No initialize(), refresh, seed override, release registration or reward.
	return true

static func _without_integrity(value: Dictionary) -> Dictionary:
	var result := value.duplicate(true)
	result.erase("integrity")
	return result

func save_checkpoint(path: String) -> bool:
	var envelope := export_checkpoint()
	if envelope.is_empty(): return false
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(envelope,"\t"))
	return file.get_error() == OK
