## Validated actual release facts, shared by inspection and the monthly market.
## Explicitly included in the mechanical source identity since market adoption.
extends RefCounted

static func _failure(reason: String, studio_id := "", release_id := "") -> Dictionary:
	return {"ok":false,"reason":reason,"studio_id":studio_id,"release_id":release_id}

static func _text(value: Variant) -> bool:
	return (value is String or value is StringName) and not str(value).strip_edges().is_empty()

static func query(world: RefCounted) -> Dictionary:
	if world == null or not world.player is RunState: return _failure("MISSING_PLAYER")
	var owners: Array = [world.player]
	var ids: Array = world.studios.keys()
	ids.sort_custom(func(a: Variant,b: Variant) -> bool: return str(a)<str(b))
	for id in ids:
		var session: Variant = world.studios[id]
		if not session is RefCounted or not session.get("run") is RunState: return _failure("MISSING_OWNER",str(id))
		if str(session.run._bank_run_id)!=str(id): return _failure("OWNER_ID_MISMATCH",str(id))
		owners.append(session.run)
	var seen := {}
	var rows: Array = []
	for run: RunState in owners:
		var studio_id := str(run._bank_run_id)
		if not _text(studio_id) or not _text(run.get_studio_name()): return _failure("MISSING_OWNER_IDENTITY",studio_id)
		if seen.has(studio_id): return _failure("DUPLICATE_OWNER",studio_id)
		seen[studio_id] = true
		var releases := {}
		for id: StringName in run.get_released_game_ids():
			var release_id := str(id)
			if not _text(id) or releases.has(id): return _failure("DUPLICATE_OR_EMPTY_RELEASE",studio_id,release_id)
			releases[id] = true
			var metadata := run.get_release_metadata(id)
			var sales := run.get_released_game_sales(id)
			for field in ["release_title","genre","theme"]:
				if not _text(metadata.get(field)): return _failure("INVALID_METADATA_"+field,studio_id,release_id)
			if not metadata.get("release_cycle") is int or metadata.release_cycle<0 or not metadata.get("release_year") is int or metadata.release_year<1980:
				return _failure("INVALID_RELEASE_DATE",studio_id,release_id)
			if not ReleasedGameSales.is_valid(sales) or str(sales.get("release_id"))!=release_id or not sales.get("review_tenths") is int or sales.review_tenths<0 or sales.review_tenths>100:
				return _failure("INVALID_SALES",studio_id,release_id)
			var cores: Variant = metadata.get("review",{}).get("cores") if metadata.get("review") is Dictionary else null
			var available: bool = cores is Array and cores.size()==4
			if available:
				for value in cores:
					if not value is int or value<0: available=false;break
			rows.append({"studio_id":studio_id,"studio_name":run.get_studio_name(),"release_id":release_id,
				"release_cycle":metadata.release_cycle,"release_year":metadata.release_year,"release_title":str(metadata.release_title),
				"genre":str(metadata.genre),"theme":str(metadata.theme),"review_tenths":sales.review_tenths,
				"cores_available":available,"cores":cores.duplicate() if available else [],
				"earned_units":sales.earned_units,"entitlement_cents":sales.entitlement_cents,"settled_cents":sales.settled_cents})
	rows.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if a.release_cycle!=b.release_cycle: return a.release_cycle<b.release_cycle
		if a.studio_id!=b.studio_id: return a.studio_id<b.studio_id
		return a.release_id<b.release_id)
	return {"ok":true,"rows":rows}
