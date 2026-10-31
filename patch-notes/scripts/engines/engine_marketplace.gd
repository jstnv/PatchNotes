## Fixed opening listings. Creator IDs refer to the certified active rival world.
extends RefCounted

const STARTING: Array[Dictionary] = [
	{"id": &"action_engine", "name": "Action Engine", "creator_id": &"incumbent-action", "creator_specialty": &"action", "max_scope": 25, "license_cents": 750000, "royalty_basis_points": 2000, "dominant": [&"graphics", &"technology"]},
	{"id": &"puzzle_engine", "name": "Puzzle Engine", "creator_id": &"incumbent-puzzle", "creator_specialty": &"puzzle", "max_scope": 25, "license_cents": 750000, "royalty_basis_points": 2000, "dominant": [&"technology", &"design"]},
]

static func starting_listings() -> Array[Dictionary]:
	return STARTING.duplicate(true)

static func find(engine_id: StringName) -> Dictionary:
	for listing: Dictionary in STARTING:
		if listing.id == engine_id: return listing.duplicate(true)
	return {}

static func bonus_basis_points(listing: Dictionary, category: StringName) -> int:
	return 1000 if category in listing.get("dominant", []) else 0

static func production_bonus(engine_id: StringName) -> Dictionary:
	var listing := find(engine_id)
	if listing.is_empty(): return {}
	var result := {}
	for stat: StringName in [&"graphics", &"sound", &"technology", &"design"]:
		var bonus := bonus_basis_points(listing, stat)
		if bonus > 0: result[ProjectState.CoreScore[stat.to_upper()]] = bonus
	return result

static func creator_matches_world(listing: Dictionary, world: RivalWorld) -> bool:
	if world == null or listing.is_empty() or not world.studios.has(listing.get("creator_id")): return false
	var session: RefCounted = world.studios[listing.creator_id]
	return session != null and session.run != null and session.run._bank_run_id == listing.creator_id and session.run.get_studio_specialty() == listing.creator_specialty
