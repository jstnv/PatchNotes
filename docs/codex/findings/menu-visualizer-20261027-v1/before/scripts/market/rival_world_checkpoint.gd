## Data-only active-rival checkpoint. The player Studio payload and this world
## field are published in one CheckpointStore generation. Disk input supplies
## no classes, resource paths, constructors or executable Variant objects.
extends RefCounted

const Session := preload("res://scripts/simulation/campaign_session.gd")
## Twelve-Scope grants apply to new Studios only; retain old ownership and RNG.
const STARTER_SCOPE_PREDECESSORS := ["3eb0f864ee07afc000f7ac087b5b1b7c2396d93e89056b53a84900b9e4954560"]
## Exact pre-optimization editor and shipped v0.03 sources. Rules, persisted
## fields and RNG are unchanged; every ordinary field check still applies.
const LATENCY_PREDECESSOR_SOURCES := ["a866e98020c0018f943ce8b98bbbd564b83d4ecd356bc6a4fd5cf66b0c483fa7", "617a97c83aabe2bba6613a8b4e5bddca7f1b9c4a974b8efb06e3595ad7334c94", "ce24d2a07703a664edd86574b2c678666f9307c5160710a62ce55603c7a74692", "a458650917031ee5dddd23c8a5b7c79986254f731f03a0113ddab4377aab0435"]
## Exact preceding Search editor/compiled presentation; saved fields unchanged.
const SEARCH_PRESENTATION_SOURCES := ["efc6ef13b947a784ad4db20d7220920498b3e43c28923c9965baafcf61016580","c1be4bc1ac2c8818d69b00e6e523e475382b0b6047e6e99a42891d7b8960304b","3eecb919ab1e100c930dfd792abeaca8066fe1f9977ed2e7785188f78e8b1fd2"]
## Exact editor sources before gradual pause audio/menu; saved fields unchanged.
const PAUSE_TRANSITION_SOURCES := [
	"3a8f41da6754dcf17269623586337daf39e1523263cbdb1aefcf0e8a9dba3ccc",
	"abbfa387743973cc6c727912041bee407ebeebe4fa370fd26751a1d9d87eace7",
]
## Temporary Insider hold/cap expansion is prospective; retain old world/RNG.
const INSIDER_HOLD_PREDECESSORS := ["f479c5b654d756972e5cb822756328ae3fae7eff2fdf66eb4e7badf967d20311"]
## Employee navigation only; retain the exact preceding saved world and RNG.
const EMPLOYEE_MENU_PREDECESSORS := ["71f86b840b0af8d425f8166caf169b853229e6c6ff3f4f32db22ecd7712ad019"]
## Exact pre-card-pop presentation; retained gameplay, world and RNG fields.
const CARD_POP_PREDECESSORS := ["a4d9fc318694ef143ea9d59147ae8c5e33a823d31d05a68b35d74203025b51c5"]
## Balanced 1.25 reward is prospective: retain historical scores and RNG.
const BALANCED_BOOST_PREDECESSORS := ["1c28c28f1f82b53cfb76f246f66562d476ffeb23d1ca152cd455108a693c5b4e"]
## Positive one-point Balanced allowance is prospective; saved state stays exact.
const BALANCED_SMALL_HAND_PREDECESSORS := ["9d30a157bfbcdec10be0de7120979ca282c137b23d327bb5b4e24fe2842c6cac"]
## Floating score presentation only; exact preceding player/world/RNG retained.
const SCORE_FLOAT_PREDECESSORS := ["8593779f9afa7deab4ca218fab64118864efe5d763ff088485f8d6ad43be7ab8", "02e62ac6d53d7b50c642ffb2a6e70fd64afcf01eec07dee4c919d4394773c3cc", "c3e80e9a7118d84803ef047dbf11e641030b3c6ebfcaeabc12dc6344f12d4c78", "797d2689941140d51cb8637fd2d03efa1f2011a6794a3803b65af68ac6213d4c", "6b46939ffd7efda8229858ecdbf9790cb9b12444180e7eea0db729ae22f82635", "f9854f69fe47880510e5c933b80aefbbc7f6469226328321f8ff55e33bdbe3b4", "4bc1caa6263cc6a965101c5231288465b97d4c1b76c2890d4e507441c58be0e0"]
## New grants change prospectively; existing world ownership/RNG is retained.
const EMPLOYEE_PRE_SEARCH_SOURCES := ["5dd56b5b84e8e72065c4394ca301f89694461a8a32b62486565fb1f9c49400bd","9216e53b16f5381247b2d4f6a7bfcfd168523cfc6ef5e9d0e11107280367bb31"]
const ROOT_FIRST_PREDECESSOR_SOURCES := [
	"874feab75c9d0221fc22dce1ac844a812f8a610bd58c12e203f9080c9c370392", # Pre-v3 editor.
	"57da40e29af0d492f12109030c79b549e64814faaeefba0528ce195dfc0baeac", # Actual Studio Fix EXE.
]
const USABILITY_PREDECESSOR_SOURCES := [
	"22f504d07fd73970dda3d8746e0cf23ca741afc1436acd5ff3f1630787933036",
	"6fffe610efd5a29e99f6b6359091f470f56f182814179328c91f6c8ffb5b92cc",
]
# Prerequisite link presentation only. Actual preceding editor/PCK worlds retain
# every field/RNG; admit only these identities with the current content revision.
const USABILITY_PRESENTATION_SOURCES := [
	"8216dc125219a21db6dd1b8971b6a6740c95e80ca472b4fc9bcb0d680d015d5f", # Before staged new-save invitation and neutral starter guidance.
	"3607c90b10a02bc26723b3e060618cda73f5755477f46fb32891f045c7a5a26e", # Actual Menu Slides EXE; saved gameplay unchanged.
	"224bb3f908474499968aace094e06d4e80e2ce9e48ac9fb2c26c2b2e297d21ef", # Before Container-aware title navigation motion.
	"aca924c0fd065ecf213fab534004e7f8afc32f7484a2be0db8fccfbe15b30c95", # Actual Menu Spacing EXE; persisted fields unchanged.
	"900512cd4167008a122720e252e6d2a1afd5215e0186b3f196279e4f7c9aeb87", # Before layout-safe automatic menu entrances.
	"91681dc365c033cede4a383c90299b2193f4c79886f8023ade9de30b1bc45e9c", # Actual Root First EXE; saved fields unchanged.
	"783a29291ac592ebc055867155cb640c481893c7ef900ebc36fe9adab56678ab", # Before refreshing Studio actions after the already committed first release.
	"0b0443b989c38ddd34b943846617d8bebdab3ee0cbe4e7b2dd6885f456202488", # Exact preceding Paper Icon EXE; unchanged stored gameplay fields.
	"900d63cc8e8ce4f2928ec127c3cb9d87e1ca6b5ec3ba18555ac49294fc7c2c1c", # Before the shared folder Theme and retained setup navigation.
	"6800a07e9c01c2aa0476d8251afdfc3f0f3c61ad5989ff2c99bcd813d1c2ae65", # Before offering the optional tutorial on every save opening.
	"b8785b47ebb32a94fbf1dbbf682b015be4171259a8ce9631a2df9fc93f7a6205", # Before shared tutorial/live scoreboard layout.
	"8c8ef44726aae9dbd4a7967f8a750702a0ab5887f582b7880d65a77cb0f74944", # Before optional standalone tutorial.
	"57d64e0f6a00e04918e78445f0d46caf212a900c367d4b14d794d0a9c85e0d83", # Actual v0.02 embedded Windows build.
	"1a65c871916b3b42eef25df2684c5f2e7ef1087565563864c55f41158c39019b", # Before temporarily disabling the Studio Employees button.
	"6b39be120a228132e8cd78b6c00194fc95f734430ee485901d3479d20b61d315",
	"123a714caaa52bc8b9bf150620d7bbbf178263078a397e9d91373e6fff0b67c9",
]
const Development := preload("res://scripts/simulation/development_session.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const Legacy := preload("res://scripts/legacy/legacy_world.gd")
const Market := preload("res://scripts/market/market_transaction_trial.gd")
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
# Reverb-only pause presentation: exact preceding editor/compiled market1
# builds, with unchanged persisted rules. All current field checks still run.
const COMPATIBLE_MARKET_PRESENTATION_SOURCES := [
	"6a54626db35988186fd6a1fd7f47af9191dfb4421dc798720a0725032a75f8c1", # Audited Market/Finance build before first-refusal Esc routing; saved rules unchanged.
	"e024ceb5e6aa2d9f94cacd203e121b52ce6e70c70107a12da592176e7661e94e", # Shared-header predecessor; exact old-world fields verified for Market browser.
	"37cde6dfe643cc6c13f399eac460b2621e12ca92049feaef103e999c9cadcf6d", # First Market build; only stale-tip dismissal changed; legal campaign restore checked.
	"5783246fcb2ecd6612eccf8e06cde72490db3ebb2944b8592e0943bfdaf94536",
	"d259a6545d3802f5a2493f96547d9e10ad26984f4342270724232a3764fbec72",
]
# Exact P1 preceding canonical source, tested with an unmodified whole-world
# payload. Paired content revisions are checked before ordinary validation.
const RELATIONSHIP_PREDECESSOR_SOURCE := "652f14adf47d7b305e40503e6f624ce1acfe8813fe72d31e249e8572930de14f"
# Audited pre-P1 release PCK identities differ from editor source fingerprints.
# Actual disk generations, never relabeled envelopes, exercise these migrations.
const RELATIONSHIP_PREDECESSOR_EXPORTS := [
	"30aceef1a405ac3c3b3db2cd03b35bae45d3d8959d0aacd23a0aacf5a0267453",
]
# Verified P1 editor generations and the actual audited P1 export. These pair
# only with the frozen P1 content revision; arbitrary source relabeling rejects.
const COMMISSION_PREDECESSOR_SOURCES := [
	"f790d724cb86a93efe8e6da471ba8adfb33b69fa0c217736ad81e15339404a0d",
	"026fcaf5c59c1a01cceeeea7262a8711705269488bb911afd27ca53214b47e3a",
	"568ed2c259d020443008d625c8279b23a49807e6bdfce486468222297b582631",
]
# Card entrance/tooltip presentation only: exact P2/P3 editor and audited PCK
# predecessors pair with current rules. Full world validation remains mandatory.
const COMPATIBLE_COMMISSION_PRESENTATION_SOURCES := [
	"a6766632c3c57c6abf5df0b4c981390c7f0dece678c6665d843bb84de8076cbe",
	"1be636f8f92822d4d693179a1bf9b5ed693a92ee2269133674d73ed22bacd113",
]
const SUPPORT_PREDECESSOR_SOURCES := [
	"d4065bc10fd797b32405c507044bc2349b339c2d2a5b2a5c414817d17bc398d9",
	"db23e0912d985cc67ddcc404447e5d3161589c2ff140fa1a315b0af62e7ed54e",
]
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
	var schema := {"_base_name":"text","_core_scores":CheckpointSchema.map_of("uint","uint"),"_genre_ratios":CheckpointSchema.array_of("uint"),"_market_standards":CheckpointSchema.array_of("uint"),"_market_snapshot_id":"text","_market_details":CheckpointSchema.market_details()}
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

static func _market_schema() -> Dictionary:
	return {"version":"uint","cycle_start":"uint","id":"text","facts":CheckpointSchema.array_of({
		"studio_id":"text","release_id":"text","release_cycle":"uint","genre":"text","theme":"text",
		"review_tenths":"uint","cores_available":"bool","cores":CheckpointSchema.array_of("uint")})}

static func _origin_schema() -> Dictionary:
	return {"source_id":"text","content_revision":"text","cycle":"uint","active_projects":CheckpointSchema.map_of("id","id")}

func _expected_market_facts(market: Dictionary, player_payload: Dictionary, studio_rows: Array) -> Variant:
	var sources: Array=[{"id":str(player_payload.get("run_id","")),"run":player_payload.get("run",{})}]
	for studio: Variant in studio_rows:
		if not studio is Dictionary or not studio.get("run") is Dictionary: return null
		sources.append({"id":str(studio.get("id","")),"run":studio.run.get("run",{})})
	var facts: Array=[]
	for source: Dictionary in sources:
		var run: Variant=source.run
		if source.id.is_empty() or not run is Dictionary or not run.get("release_metadata") is Array or not run.get("released_games") is Array: return null
		var sales_by_id: Dictionary={}
		for sale: Variant in run.released_games:
			if not sale is Dictionary or not sale.get("key") is String or not sale.get("value") is Dictionary or sales_by_id.has(sale.key): return null
			sales_by_id[sale.key]=sale.value
		for entry: Variant in run.release_metadata:
			if not entry is Dictionary or not entry.get("key") is String or not entry.get("value") is Dictionary or not sales_by_id.has(entry.key): return null
			var meta: Dictionary=entry.value
			var codec:=CheckpointCodec.new()
			var release_cycle: Variant=codec.integer(meta.get("release_cycle"))
			if not codec.error.is_empty(): return null
			if release_cycle>=market.cycle_start or market.cycle_start-release_cycle>Market.WINDOW_CYCLES: continue
			var review_tenths: Variant=codec.integer(sales_by_id[entry.key].get("review_tenths"))
			if not codec.error.is_empty() or not meta.get("review") is Dictionary: return null
			var core_values: Array=[]
			var raw_cores: Variant=meta.review.get("cores")
			var available: bool=raw_cores is Array and raw_cores.size()==4
			if available:
				for raw: Variant in raw_cores:
					var parsed: Variant=codec.integer(raw)
					if not codec.error.is_empty(): return null
					core_values.append(parsed)
			facts.append({"studio_id":source.id,"release_id":entry.key,"release_cycle":release_cycle,
				"genre":str(meta.get("genre","")),"theme":str(meta.get("theme","")),
				"review_tenths":review_tenths,"cores_available":available,"cores":core_values})
	facts.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		if a.studio_id!=b.studio_id: return a.studio_id<b.studio_id
		return a.release_id<b.release_id)
	return facts

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
	for field: String in PROJECT_INTS + PROJECT_FLOATS + PROJECT_BOOLS + PROJECT_IDS + PROJECT_ID_ARRAYS + ["_base_name","_core_scores","_genre_ratios","_market_standards","_market_snapshot_id","_market_details"]:
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

func snapshot(world: RivalWorld) -> Dictionary:
	error = ""
	if world == null or world.player == null or world._busy or world.cycle != world.player.get_completed_run_cycles() or world.studios.is_empty() or world.studios.size() > MAX_RIVALS: error = "World is not at a save boundary"; return {}
	if not Market.valid(world.market_snapshot) or world.market_snapshot.cycle_start!=world.cycle-world.cycle%2: error = "Invalid committed market month"; return {}
	var rows: Array = []
	var ids: Array = world.studios.keys()
	ids.sort_custom(func(a: StringName,b: StringName) -> bool: return str(a) < str(b))
	var adapter := StudioCheckpoint.new()
	for id: StringName in ids:
		var session: RefCounted = world.studios[id]
		if session.run.get_completed_run_cycles() != world.cycle or session.contract != null: error = "Rival clock or Contract unavailable"; return {}
		var active_id: StringName = &"" if session.in_studio else session.project_id()
		var saved_run := adapter.snapshot(session.run,active_id)
		if saved_run.is_empty(): error = adapter.error; return {}
		var development: Variant = _capture_development(session)
		if not error.is_empty(): return {}
		var archive: Variant = world.historical_archive.get(id,[])
		if not error.is_empty(): return {}
		rows.append({"id":str(id),"run":saved_run,"sequence":str(session.sequence),"development":development,"archive":archive})
	var history: Variant = world.observation().live_releases
	if not error.is_empty(): return {}
	var encoded_market: Variant = world.market_snapshot
	if not error.is_empty(): return {}
	var payload := {"schema_version":"1","rng_algorithm":RunRandom.ALGORITHM,"cycle":str(world.cycle),"studios":rows,"history":history,"market":encoded_market}
	if not world.market_origin.is_empty():
		payload.market_origin=world.market_origin
		if not error.is_empty(): return {}
	if not world.legacy.is_empty():
		if not Legacy.valid(world.legacy,world): error="Invalid founder world"; return {}
		payload.legacy=Legacy.encode(world.legacy)
	return payload.duplicate(true)

func encode_snapshot(native: Dictionary) -> Dictionary:
	error = ""
	var payload := native.duplicate(true)
	var adapter := StudioCheckpoint.new()
	for row: Dictionary in payload.studios:
		row.run=adapter.encode_snapshot(row.run)
		if row.run.is_empty(): error=adapter.error; return {}
		row.archive=_encode(row.archive,CheckpointSchema.array_of(_archive_schema()))
		if not error.is_empty(): return {}
	payload.history=_encode(payload.history,CheckpointSchema.array_of(_release_schema()))
	if not error.is_empty(): return {}
	payload.market=_encode(payload.market,_market_schema())
	if not error.is_empty(): return {}
	if payload.has("market_origin"):
		payload.market_origin=_encode(payload.market_origin,_origin_schema())
		if not error.is_empty(): return {}
	payload["source_identity"]=Replay.source_identity()
	return payload

func capture(world: RivalWorld) -> Dictionary:
	var native := snapshot(world)
	return {} if native.is_empty() else encode_snapshot(native)

func _read(payload: Dictionary, player_payload: Dictionary, captured_source_identity: String = "") -> Dictionary:
	error = ""
	var predecessor_source: Variant = payload.get("source_identity")
	var relationship_predecessor: bool = predecessor_source == RELATIONSHIP_PREDECESSOR_SOURCE or predecessor_source in RELATIONSHIP_PREDECESSOR_EXPORTS or predecessor_source in COMPATIBLE_MARKET_PRESENTATION_SOURCES
	var commission_predecessor: bool = predecessor_source in COMMISSION_PREDECESSOR_SOURCES
	var support_predecessor: bool = predecessor_source in SUPPORT_PREDECESSOR_SOURCES or predecessor_source in COMPATIBLE_COMMISSION_PRESENTATION_SOURCES
	var usability_predecessor: bool = predecessor_source in USABILITY_PREDECESSOR_SOURCES
	var current_source := Replay.source_identity() if captured_source_identity.is_empty() else captured_source_identity
	var source_ok: bool = predecessor_source==current_source or predecessor_source in STARTER_SCOPE_PREDECESSORS or predecessor_source in SCORE_FLOAT_PREDECESSORS or predecessor_source in BALANCED_SMALL_HAND_PREDECESSORS or predecessor_source in BALANCED_BOOST_PREDECESSORS or predecessor_source in CARD_POP_PREDECESSORS or predecessor_source in EMPLOYEE_MENU_PREDECESSORS or predecessor_source in INSIDER_HOLD_PREDECESSORS or predecessor_source in PAUSE_TRANSITION_SOURCES or predecessor_source in LATENCY_PREDECESSOR_SOURCES or predecessor_source in SEARCH_PRESENTATION_SOURCES or predecessor_source in EMPLOYEE_PRE_SEARCH_SOURCES or predecessor_source in ROOT_FIRST_PREDECESSOR_SOURCES or predecessor_source in USABILITY_PRESENTATION_SOURCES or usability_predecessor or support_predecessor or relationship_predecessor or commission_predecessor
	var paired_revision: String = StudioCheckpoint.RelationshipPrevious.new().revision() if relationship_predecessor else StudioCheckpoint.new().revision()
	if predecessor_source!=current_source and predecessor_source in ROOT_FIRST_PREDECESSOR_SOURCES+USABILITY_PRESENTATION_SOURCES:
		paired_revision=StudioCheckpoint.new()._rules_revision(StudioCheckpoint.PRE_EMPLOYEE_RULES)
	if predecessor_source in EMPLOYEE_PRE_SEARCH_SOURCES:paired_revision=StudioCheckpoint.new()._rules_revision(StudioCheckpoint.PRE_SEARCH_RULES)
	if commission_predecessor: paired_revision = StudioCheckpoint.CommissionPrevious.new().revision()
	if support_predecessor: paired_revision = StudioCheckpoint.SupportPrevious.new().revision()
	if usability_predecessor: paired_revision = StudioCheckpoint.UsabilityPrevious.new().revision()
	if source_ok:
		if player_payload.get("content_revision") != paired_revision or not payload.get("studios") is Array:
			error = "Mismatched relationship source/content pair"; return {}
		for row: Variant in payload.studios:
			if not row is Dictionary or not row.get("run") is Dictionary or row.run.get("content_revision") != paired_revision:
				error = "Mismatched relationship Studio source/content pair"; return {}
	if payload.size()!=7+int(payload.has("legacy"))+int(payload.has("market_origin")) or payload.get("schema_version")!="1" or not source_ok or payload.get("rng_algorithm")!=RunRandom.ALGORITHM or not payload.get("studios") is Array or not payload.get("history") is Array or not payload.get("market") is Dictionary:
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
	var origin := {}
	if payload.has("market_origin"):
		var decoded_origin: Variant=_decode(payload.market_origin,_origin_schema())
		if not error.is_empty() or not decoded_origin is Dictionary: error="Malformed market migration origin"; return {}
		origin=decoded_origin
		var migration: RefCounted=load("res://scripts/market/market_save_migration_trial.gd").new()
		if not migration.known_source(origin.source_id) or migration.SOURCE_REVISIONS[origin.source_id]!=origin.content_revision or origin.cycle>cycle: error="Unknown market migration origin"; return {}
	var market: Variant = _decode(payload.market,_market_schema())
	if not error.is_empty() or not Market.valid(market): error = "Invalid market snapshot"; return {}
	if market.cycle_start!=cycle-cycle%2: error = "Rival market calendar mismatch"; return {}
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
			if not Market.valid_details(dev.project._market_details,dev.project._genre_id) or dev.project._market_details.standards!=dev.project._market_standards or dev.project._market_details.snapshot_id!=dev.project._market_snapshot_id: error="Invalid frozen rival market target"; return {}
			if dev.project._release_id != StringName(row.run.active_project_id) or dev.project._release_id in historical_ids or dev.finalized or dev.project._has_beta_finalization: error = "Invalid active project boundary"; return {}
			var active_native := adapter._decode_payload(row.run,true)
			if active_native.run.support_deals.has(dev.project._release_id):
				var terms: Dictionary = active_native.run.support_deals[dev.project._release_id]
				if terms.base_name != dev.project._base_name or terms.genre != dev.project._genre_id or terms.theme != dev.project._theme_id or terms.required_scope != dev.project._required_scope: error="Support/project mismatch"; return {}
			if active_native.run.commission_deals.has(dev.project._release_id):
				var terms: Dictionary = active_native.run.commission_deals[dev.project._release_id].terms
				if terms.base_name != dev.project._base_name or terms.genre != dev.project._genre_id or terms.theme != dev.project._theme_id or terms.required_scope != dev.project._required_scope: error="Commission/project mismatch"; return {}
			if dev.hand.candidate_ids.size()!=dev.hand.candidate_cards.size() or dev.hand.candidate_ids.size()>32: error = "Invalid rival hand"; return {}
		rows.append({"id":id,"run":row.run,"sequence":sequence,"development":dev,"archive":archive})
	var history: Variant = _decode(payload.history,CheckpointSchema.array_of(_release_schema()))
	if not error.is_empty(): return {}
	var expected_facts: Variant=_expected_market_facts(market,player_payload,payload.studios)
	if expected_facts==null or expected_facts!=market.facts: error="Market owner provenance mismatch"; return {}
	if not _validate_frozen_market(player_payload,payload.studios,rows,cycle,origin): return {}
	return {"cycle":cycle,"rows":rows,"history":history,"legacy":legacy,"market":market,"market_origin":origin}

## All actual releases remain in owner ledgers, so past monthly inputs can be
## reconstructed without saving duplicate snapshots in every sales row.
func _validate_frozen_market(player_payload: Dictionary, encoded_rows: Array, decoded_rows: Array, cycle: int, origin: Dictionary) -> bool:
	var snapshots := {0:Market.neutral()}
	var owners: Array=[{"id":player_payload.run_id,"run":player_payload,"development":{}}]
	owners.append_array(decoded_rows)
	for owner: Dictionary in owners:
		var adapter:=StudioCheckpoint.new()
		var native: Dictionary=adapter._decode_payload(owner.run,not owner.development.is_empty())
		if native.is_empty(): error=adapter.error; return false
		var pending: Array=[]
		for id: StringName in native.run.released_games:
			var meta: Dictionary=native.run.release_metadata[id]
			for age: int in native.run.released_games[id].market_factors:
				var factor: Dictionary=native.run.released_games[id].market_factors[age]
				pending.append({"details":factor,"release":str(id),"genre":meta.genre,"theme":meta.theme,"earning_cycle":meta.release_cycle+(age-1)*2+1})
			if meta.review.has("market"): pending.append({"details":meta.review.market,"genre":meta.genre,"project_id":id})
		if not owner.development.is_empty(): pending.append({"details":owner.development.project._market_details,"genre":owner.development.project._genre_id,"project_id":owner.development.project._release_id})
		for item: Dictionary in pending:
			var d: Dictionary=item.details
			if d.historical:
				if origin.is_empty() or d.snapshot_id!="pre-market-neutral:"+origin.source_id: error="Unproven historical market exemption"; return false
				if item.has("earning_cycle"):
					if item.earning_cycle>origin.cycle: error="Historical exemption after migration"; return false
				elif origin.active_projects.get(StringName(owner.id),&"")!=item.project_id: error="Unproven historical project"; return false
				continue
			if item.has("earning_cycle") and d.cycle_start!=item.earning_cycle-item.earning_cycle%2: error="Market factor month mismatch"; return false
			if d.cycle_start>cycle-cycle%2: error="Future frozen market source"; return false
			if not snapshots.has(d.cycle_start):
				var facts: Variant=_expected_market_facts(d,player_payload,encoded_rows)
				if not facts is Array: error="Missing historical market facts"; return false
				snapshots[d.cycle_start]={"version":Market.VERSION,"cycle_start":d.cycle_start,"facts":facts,"id":Market.identifier(d.cycle_start,facts)}
			var snapshot: Dictionary=snapshots[d.cycle_start]
			var expected: Dictionary=Market.sales_factor(snapshot,str(owner.id),item.release,str(item.genre),str(item.theme)) if item.has("release") else Market.targets(snapshot,str(owner.id),item.genre)
			if expected!=d: error="Frozen market history/provenance mismatch"; return false
	return true

func validate(payload: Dictionary, player_payload: Dictionary) -> String:
	var decoded := _read(payload,player_payload)
	if not error.is_empty(): return error
	var adapter := StudioCheckpoint.new()
	var player := adapter.hydrate(player_payload)
	if player == null: error = adapter.error; return error
	var world := RivalWorld.new()
	world.player = player
	world.cycle = decoded.cycle
	world.legacy = decoded.legacy
	for row: Dictionary in decoded.rows:
		var run := adapter.hydrate(row.run,not row.development.is_empty())
		if run == null: error = adapter.error; return error
		var session := Session.new()
		session.run = run
		world.studios[row.id] = session
	_check_history_and_legacy(world,decoded.history)
	return error

func _check_history_and_legacy(world: RivalWorld, history: Array) -> bool:
	var actual := {}
	for entry: Dictionary in history:
		if actual.has(entry.release_id) or (not world.studios.has(entry.studio_id) and (world.legacy.is_empty() or entry.studio_id!=world.player._bank_run_id)): error = "Invalid world release owner"; return false
		var run: RunState = world.player if entry.studio_id==world.player._bank_run_id else world.studios[entry.studio_id].run
		var meta := run.get_release_metadata(entry.release_id)
		var sales := run.get_released_game_sales(entry.release_id)
		if meta.is_empty() or sales.is_empty() or meta.release_cycle!=entry.release_cycle or meta.release_title!=entry.title or meta.genre!=entry.genre or meta.theme!=entry.theme or sales.review_tenths!=entry.review_tenths: error = "World release provenance mismatch"; return false
		actual[entry.release_id] = entry
	for id: StringName in world.studios:
		for release_id: StringName in world.studios[id].run.get_released_game_ids():
			if not actual.has(release_id) or actual[release_id].studio_id!=id: error = "Missing world release"; return false
	world.live_releases = actual
	if not world.legacy.is_empty() and not Legacy.valid(world.legacy,world): error = "Invalid restored founder world"; return false
	return true

func restore(payload: Dictionary, player_payload: Dictionary, player: RunState, catalog: RefCounted, captured_source_identity: String = "") -> RivalWorld:
	# Optional identity is a code-owned synchronous capture/write scope, never
	# an expected-source field taken from an untrusted checkpoint.
	var decoded := _read(payload,player_payload,captured_source_identity)
	if not error.is_empty() or player == null or catalog == null: return null
	var world := RivalWorld.new()
	world.player = player
	world.cycle = decoded.cycle
	world.market_snapshot = decoded.market
	world.market_origin = decoded.market_origin
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
				if field in PROJECT_ID_ARRAYS or field in ["_genre_ratios","_core_scores","_market_standards"]: continue
				project.set(field,state.project[field])
			var core_scores: Dictionary[ProjectState.CoreScore,int] = {}
			for category: int in state.project._core_scores: core_scores[category] = state.project._core_scores[category]
			project.set("_core_scores",core_scores)
			var ratios: Array[int] = []
			ratios.assign(state.project._genre_ratios)
			project.set("_genre_ratios",ratios)
			var market_standards: Array[int]=[]
			market_standards.assign(state.project._market_standards)
			project.set("_market_standards",market_standards)
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
	if not _check_history_and_legacy(world,decoded.history): return null
	world.bind_market_providers()
	return world
