## Prospective market upgrade. Validate the original source/schema/accounting
## before adding neutral historical factors. Only the in-memory copy changes;
## CheckpointStore publishes it at the next ordinary committed Studio action.
extends RefCounted

const OldStudio := preload("res://scripts/market/legacy_pre_market_studio_validator.gd")
const OldWorld := preload("res://scripts/market/legacy_pre_market_world.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const Market := preload("res://scripts/market/market_transaction_trial.gd")
const OldSource := "1e7e9c1f1c5766d209a5d0826cf07982c528b6e4b132087e08130dcb0c30cb82"
const OldPlayerRevision := "a6547dc9b3e4d316c024267b1fe40406adfce6efa0e5692127b9b155a7fe7cfd"
# Named sources already accepted by the pre-market codec, paired with their
# original content revision. These are not arbitrary source substitutions.
const SOURCE_REVISIONS := {
	OldSource: OldPlayerRevision,
	"bf8d5157c91dd608456d66470d61e4927edb283401ef001c93b3a62d34b9aa6f": OldPlayerRevision,
	"9f321103092057b23ced7fc43ebefdffc1aa56e620b237dc734e17a451a1cbf7": "2533834fd893a109e4f794984360f77d3ebe20545cc4402ca4ac681c263f2d08",
	"ea4268bd65ae08e2a5a344384eb82dbd1a2fd9f3ef710def8443a0ce578f910c": "20acdff15d364fb81cc305c04a7f05f23d7ee183ffc1345da4183f3e127821f3",
	"81d4c3577b722bd2bbf552618ae3011cd9f8672f5ee83b3f4c0851c4aa750aed": "8194d8d5849f214bf9929f604c0809ebd499b9f40063e43c7c5613aba38f8af4",
	"b3e0baf68815977cad07a3915045a85f53c18df341f3bf3bbe2d8bcc24c94d46": "6d71877d168cd74230b48d66b0b9f43c5c291ebbeebe11fd3cf3e5af132d2d37",
	"1365082d5d1d70e81749e19931215f74cc303678edbba35479db9676ce7415a3": "dd095178754c57e1f7eba29959c26e5cb023e81b3074b238b6af7655019f455e",
	"f4303f0101e1971026080ec0b0acf3c817e96675fa190758d7c8651b8969a412": "20acdff15d364fb81cc305c04a7f05f23d7ee183ffc1345da4183f3e127821f3",
	"580bd1331cdc4bca578230005e3ca4f9cc91ead0b03b78be3238bdb7c9fc5150": "20acdff15d364fb81cc305c04a7f05f23d7ee183ffc1345da4183f3e127821f3",
	"38f92c219924494964e5982c6ed7976a5d2fec97de6ea1a7565fdd4d7e6bb41e": "8194d8d5849f214bf9929f604c0809ebd499b9f40063e43c7c5613aba38f8af4",
	"236a7e6184d14ff5b8f0f14fff01e61643f208e1318385c64cebea24f21a3ac3": "8194d8d5849f214bf9929f604c0809ebd499b9f40063e43c7c5613aba38f8af4",
	"f8f130c6a3e6b7d27710e11a56b445ea6c73d9dbc26ca26a8501ca2cf7ca32de": "dd095178754c57e1f7eba29959c26e5cb023e81b3074b238b6af7655019f455e",
	"200a5b089b34f95c31231bade1e3f6720b77b8ec87c9691e19b496b91098bfd6": "dd095178754c57e1f7eba29959c26e5cb023e81b3074b238b6af7655019f455e",
	"fd7e8a3bfe749b1c121b7515e150c35ea926f80f5511b2ba86d8ee5dceb8c867": "dd095178754c57e1f7eba29959c26e5cb023e81b3074b238b6af7655019f455e",
	"ac944a5fafd1470251f51fafd9496b4c54542e6f51baaa963fd3c860cef5d2f5": "dd095178754c57e1f7eba29959c26e5cb023e81b3074b238b6af7655019f455e",
	"0679720d9518de5ce8eb7f94ba7cd2970d001afad945b3a0e4156e5396de7040": "e5fa9d0bf6ac3f0722f2b310e0a14c0de07a8c4b4deccce9b703894406eae1ea",
	"3e0d3958740f71149b3bb5b3e9f0b15b70cc6d71c96c6c03dd1f594d56a71c8f": "e5fa9d0bf6ac3f0722f2b310e0a14c0de07a8c4b4deccce9b703894406eae1ea",
}

var error := ""
static var _old_revisions: Array = []

static func known_source(source_id: String) -> bool:
	return SOURCE_REVISIONS.has(source_id)

static func is_old_revision(revision_id: String) -> bool:
	# Player-only Store generations have content provenance, not a runtime-source
	# field. The frozen validator still checks the complete exact old schema.
	if _old_revisions.is_empty():
		var old := OldStudio.new()
		_old_revisions = old._catalog_revisions(OldStudio.RULES) + old._catalog_revisions(OldStudio.PRE_ROSTER_RULES) + old._catalog_revisions(OldStudio.PRE_GAMEPLAY_TREE_RULES) + old._catalog_revisions(OldStudio.PRE_CONE_RULES) + old._catalog_revisions(OldStudio.PRE_CHALLENGE_RULES) + old._catalog_revisions(OldStudio.PRE_BRANCH_RULES) + old._catalog_revisions(OldStudio.PRE_CULT20_RULES) + old._legacy_revisions(OldStudio.PRE_CULT_RULES) + old._legacy_revisions(OldStudio.PRE_EDUCATION_RULES)
	return revision_id in _old_revisions

func _old_native(payload: Dictionary, active: bool) -> Dictionary:
	if payload.get("source_build") != OldStudio.BUILD or not is_old_revision(str(payload.get("content_revision", ""))):
		error = "Unknown pre-market Studio revision/build"
		return {}
	var adapter := OldStudio.new()
	var reason: String = adapter.validate_active_rival(payload) if active else adapter.validate(payload)
	if not reason.is_empty():
		error = "Invalid original pre-market Studio: " + reason
		return {}
	var native: Dictionary = adapter._decode_payload(payload, active)
	if native.is_empty(): error = adapter.error
	return native

static func _neutral_factor(source_id: String) -> Dictionary:
	return {"factor_bp":10000, "snapshot_id":source_id, "cycle_start":0,
		"genre_only":0, "theme_only":0, "pair":0, "historical":true}

func _add_factors(sale: Dictionary, source_id: String, historical: bool = true) -> bool:
	if sale.has("market_factors"):
		error = "Mixed old/new sales shape"
		return false
	var factors := {}
	var cycles: int = sale.total_earned_cycles
	for age in range(1, cycles / 2 + cycles % 2 + 1):
		factors[age] = _neutral_factor(source_id)
		factors[age].historical = historical
	sale.market_factors = factors
	return true

func _upgrade_run(payload: Dictionary, active: bool, source_id: String) -> Dictionary:
	var native := _old_native(payload, active)
	if native.is_empty(): return {}
	for id: StringName in native.run.released_games:
		if not _add_factors(native.run.released_games[id], source_id): return {}
	for id: StringName in native.run.fanbase.releases:
		if not _add_factors(native.run.fanbase.releases[id].neutral, "market-0-neutral", false): return {}
	native.run.publisher_relationships = RunState.RelationshipLedger.create(native.run.bank_run_id)
	native.run.sidestreet_briefs = {}
	native.run.commission_deals = {}
	StudioCheckpoint._empty_support(native)
	native.run.contract_search=RunState.ContractSearch.from_legacy(native.run)
	native.content_revision = StudioCheckpoint.new().revision()
	var codec := CheckpointCodec.new()
	var encoded: Variant = codec.encode(native, CheckpointSchema.root(true, active))
	if not codec.error.is_empty() or not encoded is Dictionary:
		error = "Upgraded Studio encoding: " + codec.error
		return {}
	var adapter := StudioCheckpoint.new()
	var reason: String = adapter.validate_active_rival(encoded) if active else adapter.validate(encoded)
	if not reason.is_empty():
		error = "Upgraded Studio validation: " + reason
		return {}
	return encoded

func upgrade_store_player(payload: Dictionary, active: bool = false) -> Dictionary:
	error = ""
	if payload.has("rival_world"):
		error = "World must migrate with its player"
		return {}
	if not is_old_revision(str(payload.get("content_revision", ""))): return payload.duplicate(true)
	return _upgrade_run(payload, active, "pre-market-neutral:content:" + str(payload.content_revision))

func upgrade_player_only(envelope: Dictionary) -> Dictionary:
	error = ""
	var source_id := str(envelope.get("source_identity", ""))
	if envelope.size() != 8 or not known_source(source_id) or envelope.get("kind") != "campaign_studio" or envelope.get("schema_version") != "1" or envelope.get("engine_version") != Engine.get_version_info().string or envelope.get("rng_algorithm") != RunRandom.ALGORITHM or not envelope.get("studio_payload") is Dictionary or not envelope.get("integrity") is String:
		error = "Unknown or mixed pre-market simulator envelope"
		return {}
	var contents := envelope.duplicate(true)
	contents.erase("integrity")
	if Replay.digest(contents) != envelope.integrity or envelope.studio_payload.get("content_revision") != SOURCE_REVISIONS[source_id]:
		error = "Old envelope integrity or source/content pair mismatch"
		return {}
	var sequence: Variant = CheckpointCodec.new().integer(envelope.get("accepted_sequence"))
	if not sequence is int or sequence < 0:
		error = "Invalid old player sequence"
		return {}
	var player := _upgrade_run(envelope.studio_payload, false, "pre-market-neutral:" + source_id)
	return {"player":player, "source_identity":source_id} if not player.is_empty() else {}

func _historical_project(project: Dictionary, source_id: String) -> bool:
	if project.has("_market_standards") or project.has("_market_snapshot_id") or project.has("_market_details"):
		error = "Mixed old/new project shape"
		return false
	var base: Array = PrimitiveReviewCalculator.GENRE_TARGETS.get(StringName(str(project.get("_genre_id", ""))), [])
	if base.size() != 4:
		error = "Unknown historical project Genre"
		return false
	var encoded: Array = base.map(func(value: Variant) -> String: return str(value))
	project._market_standards = encoded.duplicate()
	project._market_snapshot_id = source_id
	project._market_details = {"snapshot_id":source_id, "cycle_start":"0", "standards":encoded.duplicate(),
		"base":encoded.duplicate(), "recent_count":"0", "density_lift":"0", "benchmark_lifts":["0","0","0","0"], "historical":true}
	return true

func upgrade_pair(old_player: Dictionary, old_world: Dictionary, catalog: RefCounted = null) -> Dictionary:
	error = ""
	var source_id := str(old_world.get("source_identity", ""))
	if not known_source(source_id) or old_world.has("market") or old_player.has("rival_world") or not old_world.get("studios") is Array:
		error = "Unknown or mixed pre-market world source/shape"
		return {}
	if catalog == null:
		error = "Card catalog required for original world validation"
		return {}
	var revision_id: String = SOURCE_REVISIONS[source_id]
	if old_player.get("content_revision") != revision_id:
		error = "Old player/world source/content mismatch"
		return {}
	if _old_native(old_player, false).is_empty(): return {}
	for row: Variant in old_world.studios:
		if not row is Dictionary or not row.get("run") is Dictionary or row.run.get("content_revision") != revision_id:
			error = "Mixed old rival source/content revision"
			return {}
		if _old_native(row.run, row.get("development") != null).is_empty(): return {}
	# Restore the original whole world against the frozen schema before adding
	# fields. This checks active hands, catalog, release ownership and Founder.
	var old_adapter := OldStudio.new()
	var old_run := old_adapter.hydrate(old_player)
	if old_run == null:
		error = old_adapter.error
		return {}
	var old_codec := OldWorld.new()
	var restored: RivalWorld = old_codec.restore(old_world, old_player, old_run, catalog)
	if restored == null:
		error = "Original pre-market world: " + old_codec.error
		return {}
	var factor_source := "pre-market-neutral:" + source_id
	var player := _upgrade_run(old_player, false, factor_source)
	if player.is_empty(): return {}
	var world := old_world.duplicate(true)
	for row: Dictionary in world.studios:
		var active: bool = row.development != null
		var upgraded := _upgrade_run(row.run, active, factor_source)
		if upgraded.is_empty(): return {}
		row.run = upgraded
		if active and not _historical_project(row.development.project, factor_source): return {}
	var cycle: int = restored.cycle
	var start: int = cycle - cycle % 2
	var codec: RefCounted = load("res://scripts/market/rival_world_checkpoint.gd").new()
	var facts: Variant = codec._expected_market_facts({"cycle_start":start}, player, world.studios)
	if not facts is Array:
		error = "Invalid original release facts"
		return {}
	var market := {"version":Market.VERSION, "cycle_start":start,
		"id":"market-0-neutral" if start == 0 else Market.identifier(start, facts), "facts":facts}
	if not Market.valid(market):
		error = "Invalid migrated market month"
		return {}
	var encoder := CheckpointCodec.new()
	world.market = encoder.encode(market, codec._market_schema())
	if not encoder.error.is_empty():
		error = encoder.error
		return {}
	var active_projects := {}
	for row: Dictionary in old_world.studios:
		if row.development != null:
			active_projects[StringName(row.id)] = StringName(row.run.active_project_id)
	world.market_origin = encoder.encode({"source_id":source_id,"content_revision":revision_id,
		"cycle":cycle,"active_projects":active_projects},codec._origin_schema())
	if not encoder.error.is_empty():
		error = encoder.error
		return {}
	# Runtime provenance changes only on this validated in-memory version.
	world.source_identity = Replay.source_identity()
	var current_player := StudioCheckpoint.new().hydrate(player)
	if current_player == null:
		error = "Upgraded player could not hydrate"
		return {}
	if codec.restore(world, player, current_player, catalog) == null:
		error = "Upgraded world: " + str(codec.error) + " [source=" + str(world.source_identity) + ", current=" + Replay.source_identity() + "]"
		return {}
	return {"player":player, "world":world, "market":market, "source_identity":source_id}
