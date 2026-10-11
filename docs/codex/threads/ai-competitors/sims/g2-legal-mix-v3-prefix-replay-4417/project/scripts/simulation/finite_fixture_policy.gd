## Explicit finite TEST policy, not approved competitor AI or balance advice.
## Chooses from public observations, never future RNG or mutable Run references.
## Configuration supplies all phase hand counts, Genre, Theme and card ordering.
extends RefCounted

const POLICY_ID := "finite-development-fixture"
const POLICY_VERSION := "1"
var _config: Dictionary
var _hands: Dictionary = {}

static func factory(config: Dictionary) -> Callable:
	if not valid_config(config): return Callable()
	var policy: RefCounted = load("res://scripts/simulation/finite_fixture_policy.gd").new()
	policy._config = config.duplicate(true)
	# Object-method Callables do not own their target. The closure deliberately
	# retains this RefCounted policy for exactly as long as the batch owns it.
	return func(view: Dictionary) -> Dictionary: return policy.choose(view)

static func valid_config(config: Dictionary) -> bool:
	for field in ["genre","theme","name_prefix"]:
		if not config.get(field) is String or config[field].strip_edges().is_empty(): return false
	if config.get("selection") not in ["visible_order","features_first"] or not config.get("hands") is Dictionary: return false
	if config.hands.size() != 3: return false
	for phase in ["design","alpha","beta"]:
		var value: Variant = config.hands.get(phase)
		if not (value is int or value is float) or not is_finite(float(value)) or value < 1 or value > 1000000 or value != int(value): return false
	return true

func choose(view: Dictionary) -> Dictionary:
	if view.phase == &"studio":
		return {"type":&"begin_development","payload":{"name":"%s %d" % [_config.name_prefix,view.releases.size()+1],"genre":_config.genre,"theme":_config.theme}}
	if view.phase == &"contract": return {"type":&"unsupported_fixture_contract"}
	var current: Dictionary = view.development
	if current.finalized:
		return {"type":&"launch"} if current.phase == "beta" else _development(view,&"enter_next_phase")
	if current.confirmation_pending: return _development(view,&"confirm_exit")
	if not current.active: return _development(view,&"begin")
	var key := "%s:%s" % [view.project_id,current.phase]
	if int(_hands.get(key,0)) >= int(_config.hands[current.phase]): return _development(view,&"request_exit")
	var cards: Array = current.candidates.duplicate(true)
	if _config.selection == "features_first":
		cards.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
			if (a.type == "feature") != (b.type == "feature"): return a.type == "feature"
			return int(a.token) < int(b.token))
	var tokens: Array[int] = []
	for index in range(mini(4,cards.size())): tokens.append(int(cards[index].token))
	_hands[key] = int(_hands.get(key,0))+1
	return _development(view,&"play",{"candidate_ids":tokens})

static func _development(view: Dictionary,kind: StringName,payload: Dictionary = {}) -> Dictionary:
	var current: Dictionary = view.development
	return {"type":&"development","payload":{"request":{"schema_version":1,"type":kind,"project_id":view.project_id,"phase":current.phase,"sequence":current.sequence,"project_cycle":current.project_cycle,"run_cycle":current.run_cycle,"payload":payload}}}
