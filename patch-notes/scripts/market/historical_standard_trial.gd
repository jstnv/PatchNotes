## Private Action opening spike. This is not canonical market authority.
## A source is derived from the first committed legal release, not an authored score.
extends RefCounted

const PREFIX := "historical-core-v2:"

static func source_from_run(run: RunState) -> Dictionary:
	var ids := run.get_released_game_ids()
	if ids.is_empty(): return {}
	var id: StringName = ids[0]
	var metadata: Dictionary = run.get_release_metadata(id)
	var sales: Dictionary = run.get_released_game_sales(id)
	var review: Dictionary = metadata.get("review",{})
	var source := {
		"studio_id":str(run._bank_run_id),
		"release_id":str(id),
		"release_cycle":int(metadata.get("release_cycle",-1)),
		"review_tenths":int(sales.get("review_tenths",-1)),
		"genre":str(metadata.get("genre","")),
		"cores":review.get("cores",[]).duplicate()
	}
	return source if valid_source(source) else {}

static func valid_source(source: Variant) -> bool:
	if not source is Dictionary or source.size()!=6: return false
	for field: String in ["studio_id","release_id","genre"]:
		if not source.get(field) is String or source[field].is_empty(): return false
	if not source.get("release_cycle") is int or source.release_cycle<0: return false
	if not source.get("review_tenths") is int or source.review_tenths<0 or source.review_tenths>100: return false
	if not source.get("cores") is Array or source.cores.size()!=4: return false
	if not PrimitiveReviewCalculator.GENRE_TARGETS.has(StringName(source.genre)): return false
	for core: Variant in source.cores:
		if not core is int or core<0 or core>ProjectState.MAX_SIGNED_INT: return false
	return true

static func effective_cycle(source: Dictionary) -> int:
	return (int(source.release_cycle)/2+1)*2

static func identifier(source: Dictionary) -> String:
	return PREFIX+var_to_bytes(source).hex_encode() if valid_source(source) else ""

static func decoded_source(id: String) -> Dictionary:
	if not id.begins_with(PREFIX): return {}
	var encoded := id.trim_prefix(PREFIX)
	if encoded.is_empty() or encoded.length()%2!=0 or not encoded.is_valid_hex_number(false): return {}
	var parsed: Variant = bytes_to_var(encoded.hex_decode())
	if not valid_source(parsed) or identifier(parsed)!=id: return {}
	return parsed

static func targets_for(source: Dictionary) -> Array:
	# Actual first-release Core is the dated benchmark. No midpoint/floor boost.
	if not valid_source(source): return []
	return source.cores.duplicate()

static func snapshot(source: Dictionary,target_cycle: int) -> Dictionary:
	if not valid_source(source) or target_cycle<effective_cycle(source): return {}
	var cycle_start: int=target_cycle-target_cycle%2
	return {"version":3,"cycle_start":cycle_start,"id":identifier(source),"facts":[],"source":source.duplicate(true)}

static func valid_snapshot(value: Variant) -> bool:
	if not value is Dictionary or value.size()!=5 or value.get("version")!=3 or not value.get("cycle_start") is int or not value.get("id") is String or not value.get("facts") is Array or not value.get("source") is Dictionary: return false
	if value.cycle_start<0 or value.cycle_start%2!=0 or not value.facts.is_empty() or not valid_source(value.source): return false
	return value.cycle_start>=effective_cycle(value.source) and value.id==identifier(value.source)

static func details(snapshot_value: Dictionary,genre: StringName) -> Dictionary:
	if not valid_snapshot(snapshot_value) or str(genre)!=snapshot_value.source.genre: return {}
	var base: Array=PrimitiveReviewCalculator.GENRE_TARGETS[genre]
	return {"snapshot_id":snapshot_value.id,"cycle_start":snapshot_value.cycle_start,
		"standards":targets_for(snapshot_value.source),"base":base.duplicate(),
		"recent_count":0,"density_lift":0,"benchmark_lifts":[0,0,0,0],"historical":true}

static func valid_details(value: Variant,genre: StringName) -> bool:
	if not value is Dictionary or value.size()!=8 or value.get("historical")!=true or not value.get("snapshot_id") is String or not value.get("cycle_start") is int: return false
	var source:=decoded_source(value.snapshot_id)
	if source.is_empty() or source.genre!=str(genre): return false
	return value.cycle_start>=effective_cycle(source) and value.cycle_start%2==0 and value==details(snapshot(source,value.cycle_start),genre)
