## Fixed opening listings. Creator IDs refer to the certified active rival world.
extends RefCounted

const STARTING: Array[Dictionary] = [
	{"id": &"puzzle_engine", "name": "Puzzle Engine", "creator_id": &"incumbent-puzzle", "creator_specialty": &"puzzle", "max_scope": 27, "license_cents": 250000, "royalty_basis_points": 1500, "dominant": [&"technology", &"design"], "library": [&"text",&"4_color_palette",&"8_bit_sound",&"keyboard_and_mouse",&"controller",&"controls",&"levels",&"exploration",&"simple_story",&"dialogue",&"main_theme",&"multiple_soundtracks",&"timer_system",&"categorized_scores",&"score_system",&"lives_system",&"scrolling",&"maps",&"high_scores"]},
	{"id": &"adventure_engine", "name": "Adventure Engine", "creator_id": &"incumbent-adventure", "creator_specialty": &"adventure", "max_scope": 27, "license_cents": 250000, "royalty_basis_points": 1500, "dominant": [&"graphics", &"design"], "library": [&"4_color_palette",&"8_bit_sound",&"categorized_scores",&"controller",&"controls",&"dialogue",&"enemies",&"exploration",&"high_scores",&"keyboard_and_mouse",&"levels",&"lives_system",&"main_theme",&"multiple_soundtracks",&"score_system",&"simple_story",&"sprites",&"text",&"timer_system"]},
]
const RIVAL_ORIGIN := "rival-library-manifest-2026-10-31-v1"
const LEGACY_ACTION := {"id": &"action_engine", "name": "Action Engine", "creator_id": &"incumbent-action", "creator_specialty": &"action", "max_scope": 25, "license_cents": 250000, "royalty_basis_points": 2000, "dominant": [&"graphics", &"technology"]}

static func starting_listings() -> Array[Dictionary]:
	return STARTING.duplicate(true)

static func find(engine_id: StringName) -> Dictionary:
	if engine_id == preload("res://scripts/engines/public_action_engine.gd").ID:
		return preload("res://scripts/engines/public_action_engine.gd").definition()
	if engine_id == &"action_engine": return LEGACY_ACTION.duplicate(true)
	for listing: Dictionary in STARTING:
		if listing.id == engine_id: return listing.duplicate(true)
	return {}

static func current_listing(engine_id: StringName) -> Dictionary:
	for listing: Dictionary in STARTING:
		if listing.id == engine_id:return listing.duplicate(true)
	return {}

static func terms_for_record(engine_id: StringName,record: Dictionary) -> Dictionary:
	var listing:=find(engine_id)
	if listing.is_empty():return {}
	if record.get("origin")=="legacy-access-v1" and engine_id in [&"action_engine",&"puzzle_engine"]:
		listing.max_scope=25
		listing.royalty_basis_points=2000
	return listing

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
