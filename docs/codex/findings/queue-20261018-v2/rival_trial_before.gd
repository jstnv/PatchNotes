## Activated new-game trial cohort and finite first-pass policy. Content and
## hand counts are provisional; the legal command path resolves every result.
extends RefCounted

const Factory := preload("res://scripts/simulation/run_factory.gd")
const ZERO_STEPS := 12
const HANDS_PER_PHASE := 2

static func create_world(player: RunState, catalog: RefCounted) -> RivalWorld:
	if player == null or catalog == null or player.get_completed_run_cycles()!=0 or player.get_studio_name().is_empty(): return null
	var definitions := [
		{"id":&"incumbent-arcade-foundry","name":"Arcade Foundry","specialty":&"action","extras":[&"music",&"dialogue",&"secrets"],"archive":[
			{"id":&"arcade-history-1977","title":"Circuit Clash","year":1977,"genre":&"action","theme":&"science_fiction","review_tenths":72},
			{"id":&"arcade-history-1979","title":"Skyline Siege","year":1979,"genre":&"action","theme":&"war","review_tenths":78}]},
		{"id":&"incumbent-wayfinder-works","name":"Wayfinder Works","specialty":&"adventure","extras":[&"sprites",&"8_bit_music",&"music"],"archive":[
			{"id":&"wayfinder-history-1976","title":"The Lantern Road","year":1976,"genre":&"adventure","theme":&"fantasy","review_tenths":71},
			{"id":&"wayfinder-history-1979","title":"Atlas of Ash","year":1979,"genre":&"adventure","theme":&"mystery","review_tenths":76}]}
	]
	var sessions := {}
	var archive := {}
	for item: Dictionary in definitions:
		var seed_text := (str(player._bank_run_id)+":"+str(item.id)).sha256_text().substr(0,12)
		var recipe := {"schema_version":1,"studio_id":str(item.id),"studio_name":item.name,"specialty":str(item.specialty),"traits":["family_funding","cult_following"],"seed":str(seed_text.hex_to_int())}
		var session: RefCounted = Factory.create_fresh_session(recipe,catalog)
		if session == null: return null
		for id: StringName in item.extras:
			if not session.run._feature_definitions.has(id) or session.run._feature_offers.has(id): return null
			session.run._owned_features[id] = true
		if not session.run._feature_research.is_empty() or not session.run._familiarity.is_empty(): return null
		sessions[item.id] = session
		archive[item.id] = item.archive
	var world := RivalWorld.new()
	if not world.initialize(player,sessions): return null
	world.historical_archive = archive
	return world

static func policies(world: RivalWorld) -> Dictionary:
	var result := {}
	for id: StringName in world.studios:
		var genre: String = String(world.studios[id].run.get_studio_specialty())
		var label: String = world.studios[id].run.get_studio_name()
		result[id] = func(view: Dictionary) -> Dictionary: return choose(view,genre,label)
	return result

static func choose(view: Dictionary, genre: String, label: String) -> Dictionary:
	if view.phase == &"studio":
		return {"type":&"begin_development","payload":{"name":"%s %d" % [label,view.releases.size()+1],"genre":genre,"theme":"fantasy"}}
	if view.phase == &"contract": return {}
	var current: Dictionary = view.development
	if current.finalized: return {"type":&"launch"} if current.phase == "beta" else _development(view,&"enter_next_phase")
	if current.confirmation_pending: return _development(view,&"confirm_exit")
	if not current.active: return _development(view,&"begin")
	# This trial never redraws, so revision 1 is the initial deal and each later
	# revision is one real productive hand. No policy counter needs restoration.
	if current.get("hand_revision",0) >= HANDS_PER_PHASE+1 and current.get("can_exit",false): return _development(view,&"request_exit")
	var cards: Array = current.candidates.duplicate(true)
	cards.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if (a.type == "feature") != (b.type == "feature"): return a.type == "feature"
		return int(a.token) < int(b.token))
	if cards.size()<4: return {}
	var tokens: Array[int] = []
	for index in range(4): tokens.append(int(cards[index].token))
	return _development(view,&"play",{"candidate_ids":tokens})

static func _development(view: Dictionary,kind: StringName,payload: Dictionary = {}) -> Dictionary:
	var current: Dictionary = view.development
	return {"type":&"development","payload":{"request":{"schema_version":1,"type":kind,"project_id":view.project_id,"phase":current.phase,"sequence":current.sequence,"project_cycle":current.project_cycle,"run_cycle":current.run_cycle,"payload":payload}}}
