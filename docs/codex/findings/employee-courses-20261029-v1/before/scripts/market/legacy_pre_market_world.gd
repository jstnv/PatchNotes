## Frozen pre-market validation dependency, 2026-10-18.
## Source market/rival_world_checkpoint.gd SHA256 6194aa33230bb10f177c3fe8d3ce7bab013ac8654de80a46a5e68c92050dd7c6
## Accounting and schema only; never dispatch gameplay through this copy.
## Data-only active-rival checkpoint. The player Studio payload and this world
## field are published in one CheckpointStore generation. Disk input supplies
## no classes, resource paths, constructors or executable Variant objects.
extends RefCounted

const CheckpointSchema := preload("res://scripts/market/legacy_pre_market_schema.gd")
const StudioCheckpoint := preload("res://scripts/market/legacy_pre_market_studio_validator.gd")

const Session := preload("res://scripts/simulation/campaign_session.gd")
const Development := preload("res://scripts/simulation/development_session.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const Legacy := preload("res://scripts/legacy/legacy_world.gd")
const FROZEN_SOURCE := "1e7e9c1f1c5766d209a5d0826cf07982c528b6e4b132087e08130dcb0c30cb82"
# Verified 2026-10-17 export: live rival releases, active second projects and
# exact cold Continue at cycles7/9. All normal field/catalog checks still run.
const COMPATIBLE_V1_SOURCES := ["3e0d3958740f71149b3bb5b3e9f0b15b70cc6d71c96c6c03dd1f594d56a71c8f"]
# Exact pre-victory source: unchanged sessions/finance/RNG, v1 Founder codec
# retained. Full field, catalog, ownership and journal validation still applies.
const COMPATIBLE_FOUNDER_V1_SOURCES := ["0679720d9518de5ce8eb7f94ba7cd2970d001afad945b3a0e4156e5396de7040"]
# 2026-10-18 title-to-Studio audio timing and pause menu; the source fingerprint
# includes presentation scripts. Exact prior world/Founder v2 state is verified.
const COMPATIBLE_PRESENTATION_SOURCES := [
	"f4303f0101e1971026080ec0b0acf3c817e96675fa190758d7c8651b8969a412", # Pre-Store-header UI; exact prior-world restore verified.
	"580bd1331cdc4bca578230005e3ca4f9cc91ead0b03b78be3238bdb7c9fc5150", # Explicit always-processing music transport; unchanged persisted fields.
	"38f92c219924494964e5982c6ed7976a5d2fec97de6ea1a7565fdd4d7e6bb41e", # Pre-pause-music presentation; persisted world fields unchanged.
	"236a7e6184d14ff5b8f0f14fff01e61643f208e1318385c64cebea24f21a3ac3", # Pre-tooltip Pause routing; unchanged persisted world fields.
	"f8f130c6a3e6b7d27710e11a56b445ea6c73d9dbc26ca26a8501ca2cf7ca32de",
	"200a5b089b34f95c31231bade1e3f6720b77b8ec87c9691e19b496b91098bfd6",
	"fd7e8a3bfe749b1c121b7515e150c35ea926f80f5511b2ba86d8ee5dceb8c867", # Pre-sales-HUD UI source.
	"ac944a5fafd1470251f51fafd9496b4c54542e6f51baaa963fd3c860cef5d2f5", # Pre-folder-guide UI source.
]
# Branch acquisition upgrade preserves saved sessions, ownership and admitted queues.
# Only future unowned purchases use the new gates; unknown sources still reject.
const COMPATIBLE_PRE_BRANCH_SOURCES := ["1365082d5d1d70e81749e19931215f74cc303678edbba35479db9676ce7415a3"]
# Contracts4 preserves already-completed results; new acceptances freeze trial challenges.
const COMPATIBLE_PRE_CHALLENGE_SOURCES := ["b3e0baf68815977cad07a3915045a85f53c18df341f3bf3bbe2d8bcc24c94d46"]
# Cardinal Store trees: retain actual saved ownership and admitted payments.
const COMPATIBLE_PRE_CONE_SOURCES := ["ea4268bd65ae08e2a5a344384eb82dbd1a2fd9f3ef710def8443a0ce578f910c", "81d4c3577b722bd2bbf552618ae3011cd9f8672f5ee83b3f4c0851c4aa750aed"]
# Actual pre-roster-v2 player and active rivals; hydrate never rebuilds grants.
const COMPATIBLE_PRE_ROSTER_SOURCES := ["9f321103092057b23ced7fc43ebefdffc1aa56e620b237dc734e17a451a1cbf7"]
# Exact pre-synergy-policy world. Saved hands/RNG/outcomes are preserved;
# only future rival decisions use the approved current-cohort trial selector.
const COMPATIBLE_PRE_SYNERGY_SOURCES := ["bf8d5157c91dd608456d66470d61e4927edb283401ef001c93b3a62d34b9aa6f"]
const MAX_RIVALS := 8
const PROJECT_INTS := ["_current_scope","_hidden_bugs","_known_bugs","_fixed_bugs","_marketing_output","_alpha_hidden_bugs_generated","_required_scope","_current_cycle"]
const PROJECT_FLOATS := ["_accumulated_bug_pressure","_accumulated_alpha_bug_pressure"]
const PROJECT_BOOLS := ["_has_design_bug_finalization","_was_perfect_production","_competitor_snapshot_revealed","_market_forecast_snapshot_revealed","_has_alpha_finalization","_has_beta_finalization"]
const PROJECT_IDS := ["_release_id","_competitor_snapshot_id","_market_forecast_snapshot_id","_genre_id","_theme_id"]
const PROJECT_ID_ARRAYS := ["_exhausted_beta_card_ids","_implemented_design_feature_ids","_unimplemented_design_feature_ids","_implemented_alpha_feature_ids","_unimplemented_alpha_feature_ids","_feature_supply_ids"]
const RESULT_FIELDS := ["_review_result","_awareness_result","_launch_market_context_result","_units_sold_result","_month_one_sales_revenue_result"]
const HAND_COMMON := ["priorities","candidate_ids","next_candidate_id","revision","active"]
var error := ""

static func _project_schema() -> Dictionary:
	var schema := {"_base_name":"text","_core_scores":CheckpointSchema.map_of("uint","uint"),"_genre_ratios":CheckpointSchema.array_of("uint")}
	for field: String in PROJECT_INTS: schema[field] = "uint"
	for field: String in PROJECT_FLOATS: schema[field] = "float"
	for field: String in PROJECT_BOOLS: schema[field] = "bool"
	for field: String in PROJECT_IDS: schema[field] = "id"
	for field: String in PROJECT_ID_ARRAYS: schema[field] = CheckpointSchema.array_of("id")
	return schema

static func _hand_schema(phase: int) -> Dictionary:
	var schema := {"priorities":CheckpointSchema.map_of("id" if phase==2 else "uint","uint"),"candidate_ids":CheckpointSchema.array_of("uint"),"candidate_cards":CheckpointSchema.array_of("id"),"next_candidate_id":"uint","revision":"uint","active":"bool"}
	if phase == 0:
		schema.available_features = CheckpointSchema.array_of("id")
		schema.exhausted = CheckpointSchema.map_of("id","bool")
		schema.finalization_requested = "bool"
	elif phase == 1:
		schema.available_features = CheckpointSchema.array_of("id")
		schema.exhausted = CheckpointSchema.map_of("id","bool")
		schema.pending_playtest = CheckpointSchema.array_of("uint")
	else:
		schema.injected_candidate_ids = CheckpointSchema.array_of("uint")
		schema.pending_corrective_pass_ids = CheckpointSchema.array_of("id")
		schema.launch_confirmation_pending = "bool"
	return schema

static func _development_schema(phase: int) -> Dictionary:
	return {"phase_index":"uint","sequence":"uint","awaiting_confirmation":"bool","finalized":"bool","project":_project_schema(),"hand":_hand_schema(phase)}

static func _archive_schema() -> Dictionary:
	return {"id":"id","title":"text","year":"uint","genre":"id","theme":"id","review_tenths":"uint"}

static func _release_schema() -> Dictionary:
	return {"studio_id":"id","release_id":"id","release_cycle":"uint","title":"text","genre":"id","theme":"id","review_tenths":"uint"}

func _encode(value: Variant, schema: Variant) -> Variant:
	var codec := CheckpointCodec.new()
	var result: Variant = codec.encode(value,schema)
	if not codec.error.is_empty(): error = codec.error
	return result

func _decode(value: Variant, schema: Variant) -> Variant:
	var codec := CheckpointCodec.new()
	var result: Variant = codec.decode(value,schema)
	if not codec.error.is_empty(): error = codec.error
	return result

func _project_state(project: ProjectState) -> Dictionary:
	if project == null: return {}
	for field: String in RESULT_FIELDS:
		if project.get(field) != null: error = "Rival launch result was not settled"; return {}
	var result := {}
	for field: String in PROJECT_INTS + PROJECT_FLOATS + PROJECT_BOOLS + PROJECT_IDS + PROJECT_ID_ARRAYS + ["_base_name","_core_scores","_genre_ratios"]:
		result[field] = project.get(field)
	return result

func _hand_state(hand: RefCounted, phase: int) -> Dictionary:
	var candidate_cards: Array[StringName] = []
	for card: CardData in hand._candidate_cards: candidate_cards.append(card.id)
	var result := {"candidate_cards":candidate_cards}
	for field: String in HAND_COMMON: result[field] = hand.get(field)
	if phase < 2:
		result.available_features = hand._available_features.map(func(card: CardData) -> StringName: return card.id)
		result.exhausted = hand._exhausted_card_ids if phase == 0 else hand._exhausted_feature_ids
		if phase == 0: result.finalization_requested = hand.finalization_requested
		else: result.pending_playtest = hand._pending_playtest_categories
	else:
		result.injected_candidate_ids = hand.injected_candidate_ids
		result.pending_corrective_pass_ids = hand._pending_corrective_pass_ids
		result.launch_confirmation_pending = hand.launch_confirmation_pending
	return result

func _capture_development(session: RefCounted) -> Variant:
	if session.in_studio: return null
	var dev: RefCounted = session.development
	if dev == null or dev.phase_index < 0 or dev.phase_index > 2: error = "Invalid active rival phase"; return null
	var project := _project_state(dev.project)
	if not error.is_empty(): return null
	var state := {"phase_index":dev.phase_index,"sequence":dev.sequence,"awaiting_confirmation":dev.awaiting_confirmation,"finalized":dev.finalized,"project":project,"hand":_hand_state(dev.hand,dev.phase_index)}
	return _encode(state,_development_schema(dev.phase_index))

func capture(world: RivalWorld) -> Dictionary:
	error = ""
	if world == null or world.player == null or world._busy or world.cycle != world.player.get_completed_run_cycles() or world.studios.is_empty() or world.studios.size() > MAX_RIVALS: error = "World is not at a save boundary"; return {}
	var rows: Array = []
	var ids: Array = world.studios.keys()
	ids.sort_custom(func(a: StringName,b: StringName) -> bool: return str(a) < str(b))
	var adapter := StudioCheckpoint.new()
	for id: StringName in ids:
		var session: RefCounted = world.studios[id]
		if session.run.get_completed_run_cycles() != world.cycle or session.contract != null: error = "Rival clock or Contract unavailable"; return {}
		var active_id: StringName = &"" if session.in_studio else session.project_id()
		var saved_run := adapter.capture(session.run,active_id)
		if saved_run.is_empty(): error = adapter.error; return {}
		var development: Variant = _capture_development(session)
		if not error.is_empty(): return {}
		var archive: Variant = _encode(world.historical_archive.get(id,[]),CheckpointSchema.array_of(_archive_schema()))
		if not error.is_empty(): return {}
		rows.append({"id":str(id),"run":saved_run,"sequence":str(session.sequence),"development":development,"archive":archive})
	var history: Variant = _encode(world.observation().live_releases,CheckpointSchema.array_of(_release_schema()))
	if not error.is_empty(): return {}
	var payload := {"schema_version":"1","source_identity":Replay.source_identity(),"rng_algorithm":RunRandom.ALGORITHM,"cycle":str(world.cycle),"studios":rows,"history":history}
	if not world.legacy.is_empty():
		if not Legacy.valid(world.legacy,world): error="Invalid founder world"; return {}
		payload.legacy=Legacy.encode(world.legacy)
	return payload

func _read(payload: Dictionary, player_payload: Dictionary) -> Dictionary:
	error = ""
	var source_ok: bool = payload.get("source_identity")==FROZEN_SOURCE or payload.get("source_identity") in COMPATIBLE_PRE_ROSTER_SOURCES or payload.get("source_identity") in COMPATIBLE_PRE_SYNERGY_SOURCES or payload.get("source_identity") in COMPATIBLE_PRE_CONE_SOURCES or payload.get("source_identity") in COMPATIBLE_PRE_CHALLENGE_SOURCES or payload.get("source_identity") in COMPATIBLE_PRE_BRANCH_SOURCES or payload.get("source_identity") in COMPATIBLE_PRESENTATION_SOURCES or (not payload.has("legacy") and payload.get("source_identity") in COMPATIBLE_V1_SOURCES) or (payload.get("source_identity") in COMPATIBLE_FOUNDER_V1_SOURCES and (not payload.has("legacy") or (payload.legacy is Dictionary and payload.legacy.get("version")=="1")))
	if payload.size()!=(7 if payload.has("legacy") else 6) or payload.get("schema_version")!="1" or not source_ok or payload.get("rng_algorithm")!=RunRandom.ALGORITHM or not payload.get("studios") is Array or not payload.get("history") is Array:
		error = "INCOMPATIBLE_RIVAL_WORLD_SOURCE_OR_SCHEMA"
		return {}
	var legacy := {}
	if payload.has("legacy"):
		if not payload.legacy is Dictionary: error="Malformed founder world"; return {}
		legacy=Legacy.decode(payload.legacy)
		if legacy.is_empty(): error="Malformed founder world"; return {}
	var codec := CheckpointCodec.new()
	var cycle: Variant = codec.integer(payload.get("cycle"))
	if not codec.error.is_empty() or cycle != int(player_payload.run.completed_run_cycles): error = "Rival/player calendar mismatch"; return {}
	if payload.studios.is_empty() or payload.studios.size()>MAX_RIVALS: error = "Invalid rival count"; return {}
	var seen := {}
	var all_archive_ids := {}
	var rows: Array = []
	var adapter := StudioCheckpoint.new()
	for row: Variant in payload.studios:
		if not row is Dictionary or row.size()!=5 or not row.get("id") is String or not row.get("run") is Dictionary or not row.get("sequence") is String or not row.has("development") or not row.get("archive") is Array:
			error = "Malformed rival record"; return {}
		var id := StringName(row.id)
		if id.is_empty() or seen.has(id) or row.run.get("run_id")!=row.id or row.id==player_payload.run_id: error = "Duplicate or mismatched rival ID"; return {}
		seen[id]=true
		var sequence: Variant = codec.integer(row.sequence)
		if not codec.error.is_empty() or sequence > RunState.MAX_SIGNED_INT: error = "Invalid rival sequence"; return {}
		var active := row.development != null
		var reason := adapter.validate_active_rival(row.run) if active else adapter.validate(row.run)
		if not reason.is_empty(): error = reason; return {}
		if row.run.run.completed_run_cycles != payload.cycle: error = "Rival run cycle mismatch"; return {}
		var archive: Variant = _decode(row.archive,CheckpointSchema.array_of(_archive_schema()))
		if not error.is_empty(): return {}
		if archive.is_empty() and (legacy.is_empty() or row.id not in legacy.founder.career_studio_ids): error = "Missing frozen rival archive"; return {}
		var historical_ids := {}
		for title: Dictionary in archive:
			if title.id.is_empty() or all_archive_ids.has(title.id) or title.year>=RunState.START_YEAR or title.review_tenths>100 or PrimitivePredevelopment.find_entry("genres",title.genre).is_empty() or PrimitivePredevelopment.find_entry("themes",title.theme).is_empty(): error = "Invalid rival archive"; return {}
			historical_ids[title.id] = true
			all_archive_ids[title.id] = true
		var dev := {}
		if active:
			if not row.development is Dictionary or not row.development.get("phase_index") is String: error = "Malformed active rival"; return {}
			var phase: Variant = codec.integer(row.development.phase_index)
			if not codec.error.is_empty() or phase>2: error = "Invalid rival phase"; return {}
			dev = _decode(row.development,_development_schema(phase))
			if not error.is_empty() or dev.is_empty(): return {}
			if dev.project._release_id != StringName(row.run.active_project_id) or dev.project._release_id in historical_ids or dev.finalized or dev.project._has_beta_finalization: error = "Invalid active project boundary"; return {}
			if dev.hand.candidate_ids.size()!=dev.hand.candidate_cards.size() or dev.hand.candidate_ids.size()>32: error = "Invalid rival hand"; return {}
		rows.append({"id":id,"run":row.run,"sequence":sequence,"development":dev,"archive":archive})
	var history: Variant = _decode(payload.history,CheckpointSchema.array_of(_release_schema()))
	if not error.is_empty(): return {}
	return {"cycle":cycle,"rows":rows,"history":history,"legacy":legacy}

func validate(payload: Dictionary, player_payload: Dictionary) -> String:
	_read(payload,player_payload)
	return error

func restore(payload: Dictionary, player_payload: Dictionary, player: RunState, catalog: RefCounted) -> RivalWorld:
	var decoded := _read(payload,player_payload)
	if not error.is_empty() or player == null or catalog == null: return null
	var world := RivalWorld.new()
	world.player = player
	world.cycle = decoded.cycle
	world.legacy = decoded.legacy
	var snapshots := PrimitiveSnapshotDatabase.new()
	if not snapshots.load_ledgers(): error = "Rival snapshots unavailable"; return null
	var adapter := StudioCheckpoint.new()
	for row: Dictionary in decoded.rows:
		var active: bool = not row.development.is_empty()
		var run := adapter.hydrate(row.run,active)
		if run == null: error = adapter.error; return null
		var session := Session.new()
		session.run = run
		session.catalog = catalog
		session.snapshots = snapshots
		session.sequence = row.sequence
		session.in_studio = not active
		if active:
			var state: Dictionary = row.development
			var project := ProjectState.new(state.project._required_scope)
			for field: String in state.project:
				if field in PROJECT_ID_ARRAYS or field in ["_genre_ratios","_core_scores"]: continue
				project.set(field,state.project[field])
			var core_scores: Dictionary[ProjectState.CoreScore,int] = {}
			for category: int in state.project._core_scores: core_scores[category] = state.project._core_scores[category]
			project.set("_core_scores",core_scores)
			var ratios: Array[int] = []
			ratios.assign(state.project._genre_ratios)
			project.set("_genre_ratios",ratios)
			for field: String in PROJECT_ID_ARRAYS:
				var ids: Array[StringName] = []
				ids.assign(state.project[field])
				project.set(field,ids)
			var dev := Development.new()
			dev.project = project
			dev.run = run
			dev.catalog = catalog
			dev.snapshots = snapshots
			dev.phase_index = state.phase_index
			dev._create_phase(false)
			dev.sequence = state.sequence
			dev.awaiting_confirmation = state.awaiting_confirmation
			dev.finalized = state.finalized
			var hand_state: Dictionary = state.hand
			for field: String in HAND_COMMON:
				if field != "candidate_ids": dev.hand.set(field,hand_state[field])
			var candidate_ids: Array[int] = []
			candidate_ids.assign(hand_state.candidate_ids)
			dev.hand.set("candidate_ids",candidate_ids)
			var candidate_cards: Array[CardData] = []
			for id: StringName in hand_state.candidate_cards:
				var card: CardData = catalog.get_card(id)
				if card == null: error = "Missing rival hand definition"; return null
				candidate_cards.append(card)
			dev.hand.set("_candidate_cards",candidate_cards)
			if dev.hand._candidate_cards.size()!=candidate_cards.size() or dev.hand.candidate_ids.size()!=candidate_ids.size(): error = "Rival hand restore mismatch"; return null
			if state.phase_index<2:
				var available_features: Array[CardData] = []
				for id: StringName in hand_state.available_features:
					var card: CardData = catalog.get_card(id)
					if card == null: error = "Missing rival Feature definition"; return null
					available_features.append(card)
				dev.hand.set("_available_features",available_features)
				if state.phase_index==0:
					var exhausted_cards: Dictionary[StringName,bool] = {}
					for id: StringName in hand_state.exhausted: exhausted_cards[id] = hand_state.exhausted[id]
					dev.hand.set("_exhausted_card_ids",exhausted_cards)
					dev.hand.finalization_requested = hand_state.finalization_requested
				else:
					var exhausted_features: Dictionary[StringName,bool] = {}
					for id: StringName in hand_state.exhausted: exhausted_features[id] = hand_state.exhausted[id]
					dev.hand.set("_exhausted_feature_ids",exhausted_features)
					var pending_playtest: Array[ProjectState.CoreScore] = []
					pending_playtest.assign(hand_state.pending_playtest)
					dev.hand.set("_pending_playtest_categories",pending_playtest)
			else:
				var injected_ids: Array[int] = []
				injected_ids.assign(hand_state.injected_candidate_ids)
				dev.hand.set("injected_candidate_ids",injected_ids)
				var corrective_ids: Array[StringName] = []
				corrective_ids.assign(hand_state.pending_corrective_pass_ids)
				dev.hand.set("_pending_corrective_pass_ids",corrective_ids)
				dev.hand.launch_confirmation_pending = hand_state.launch_confirmation_pending
			session.development = dev
		world.studios[row.id] = session
		world.historical_archive[row.id] = row.archive
	var actual := {}
	for entry: Dictionary in decoded.history:
		if actual.has(entry.release_id) or (not world.studios.has(entry.studio_id) and (world.legacy.is_empty() or entry.studio_id!=player._bank_run_id)): error = "Invalid world release owner"; return null
		var run: RunState = player if entry.studio_id==player._bank_run_id else world.studios[entry.studio_id].run
		var meta := run.get_release_metadata(entry.release_id)
		var sales := run.get_released_game_sales(entry.release_id)
		if meta.is_empty() or sales.is_empty() or meta.release_cycle!=entry.release_cycle or meta.release_title!=entry.title or meta.genre!=entry.genre or meta.theme!=entry.theme or sales.review_tenths!=entry.review_tenths: error = "World release provenance mismatch"; return null
		actual[entry.release_id] = entry
	for id: StringName in world.studios:
		for release_id: StringName in world.studios[id].run.get_released_game_ids():
			if not actual.has(release_id) or actual[release_id].studio_id!=id: error = "Missing world release"; return null
	world.live_releases = actual
	if not world.legacy.is_empty() and not Legacy.valid(world.legacy,world): error="Invalid restored founder world"; return null
	return world
