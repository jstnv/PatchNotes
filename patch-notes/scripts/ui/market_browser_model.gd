## Presentation-only projection of the authoritative actual-release query.
extends RefCounted

const Index := preload("res://queries/market_release_index.gd")

static func query(run: RunState, world: RivalWorld = null) -> Dictionary:
	if run == null: return {"ok":false,"reason":"No Studio is available."}
	if world != null and world.player != run:
		return {"ok":false,"reason":"Market and current Studio do not match."}
	var source := world
	if source == null:
		source = RivalWorld.new()
		source.player = run
	var result := Index.query(source)
	if not result.ok: return {"ok":false,"reason":"Market records are unavailable for this Studio.","reason_code":str(result.reason)}
	var rows: Array = result.rows
	for row: Dictionary in rows:
		row["player_owned"] = row.studio_id == str(run._bank_run_id)
		var producer: RunState = run
		if world != null and not row.player_owned: producer = world.studios[StringName(row.studio_id)].run
		row["publisher_owned"] = producer.get_release_metadata(StringName(row.release_id)).get("owner",&"studio") == &"publisher"
		var support := producer.get_support_history()
		if support.deals.has(StringName(row.release_id)):
			row.support = {"terms":support.deals[StringName(row.release_id)],"rights":support.rights[StringName(row.release_id)]}
	rows.reverse() # Index supplies stable release-cycle/owner/ID ordering.
	return {"ok":true,"rows":rows,"historical_rows":_historical_rows(world)}

## Frozen records are presentation only: never insert these into the live index.
static func _historical_rows(world: RivalWorld) -> Array:
	var rows: Array = []
	if world == null: return rows
	# The catalog is immutable during this projection. Read it once per refresh,
	# rather than reopening and parsing it for every historical record.
	var catalog := PrimitivePredevelopment.catalog()
	var seen := {}
	for owner: Variant in world.historical_archive:
		if not Index._text(owner) or not world.studios.has(StringName(owner)): continue
		var archive: Variant = world.historical_archive[owner]
		if not archive is Array: continue
		for record: Variant in archive:
			if not record is Dictionary: continue
			var valid := true
			for field in ["id","title","genre","theme"]:
				valid = valid and Index._text(record.get(field))
			if not valid or not record.get("year") is int or record.year <= 0 or record.year >= RunState.START_YEAR: continue
			if not record.get("review_tenths") is int or record.review_tenths < 0 or record.review_tenths > 100: continue
			if _catalog_entry(catalog,"genres",StringName(record.genre)).is_empty() or _catalog_entry(catalog,"themes",StringName(record.theme)).is_empty(): continue
			var key := JSON.stringify([str(owner),str(record.id)])
			if seen.has(key): continue
			seen[key] = true
			rows.append({"record_type":"historical","studio_id":str(owner),"studio_name":world.studios[StringName(owner)].run.get_studio_name(),
				"release_id":str(record.id),"release_title":str(record.title),"release_year":record.year,
				"genre":str(record.genre),"theme":str(record.theme),"review_tenths":record.review_tenths,"player_owned":false})
	rows.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if a.release_year != b.release_year: return a.release_year > b.release_year
		if a.studio_id != b.studio_id: return a.studio_id < b.studio_id
		return a.release_id < b.release_id)
	return rows

static func _catalog_entry(catalog: Dictionary, kind: String, id: StringName) -> Dictionary:
	for entry: Dictionary in catalog.get(kind,[]):
		if StringName(entry.id)==id: return entry
	return {}
