## New incumbent grants are independent of player specialty roster versions.
## Fixed membership; catalog additions never silently expand these pools.
extends RefCounted

const PROFILE := "incumbent-active-27-v1"
const SCOPE := 27
const POOLS := {
	&"action": ["text", "sprites", "4_color_palette", "8_bit_sound", "keyboard_and_mouse", "controller", "scrolling", "menu_system", "controls", "enemies", "levels", "maps", "exploration", "lives_system", "simple_story", "inventory_system", "timer_system", "score_system", "dialogue"],
	&"adventure": ["text", "4_color_palette", "keyboard_and_mouse", "controller", "score_system", "lives_system", "simple_story", "dialogue", "character_backstories", "controls", "levels", "maps", "exploration", "secrets", "enemies", "8_bit_sound", "inventory_system", "timer_system", "sprites", "scrolling"],
}

static func apply_to_new_rival(run: RunState) -> bool:
	if run == null or run.get_completed_run_cycles() != 0 or not run.get_released_game_ids().is_empty() or not run._feature_research.is_empty() or not run._familiarity.is_empty(): return false
	var specialty := run.get_studio_specialty()
	if not POOLS.has(specialty): return false
	var graph := FeatureStoreCatalog.graph(run._feature_definitions,run._feature_offers)
	if graph.has("error"): return false
	var owned := {}
	var scope := 0
	for raw_id: String in POOLS[specialty]:
		var id := StringName(raw_id)
		if owned.has(id) or not FeatureStoreCatalog.is_active(id) or not run._feature_definitions.has(id): return false
		var entry: Dictionary = run._feature_definitions[id]
		if entry.phase not in ["design","alpha"]: return false
		owned[id] = true
		scope += int(entry.scope)
	if scope != SCOPE: return false
	for id: StringName in owned:
		for parent: StringName in graph.parents[id]:
			if not owned.has(parent): return false
	run._owned_features = owned
	return true

static func supports_synergy_feature(id: StringName) -> bool:
	# Legacy saves retain their original Primitive eligibility. The two new
	# fixed foundation grants must not switch the incumbent selector off.
	return str(id) in StudioSpecialties.PRIMITIVE_IDS or id in [&"inventory_system",&"timer_system"]
