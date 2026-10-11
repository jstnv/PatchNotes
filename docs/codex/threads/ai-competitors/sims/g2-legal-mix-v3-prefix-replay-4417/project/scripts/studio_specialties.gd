class_name StudioSpecialties
extends RefCounted

## Authority §63: fixed Primitive membership; future cards never auto-grant.
const COMMON_IDS: Array[StringName] = [&"text", &"4_color_palette", &"8_bit_sound", &"keyboard_and_mouse", &"controller", &"controls"]
const PRIMITIVE_IDS := ["text", "sprites", "4_color_palette", "8_bit_sound", "8_bit_music", "keyboard_and_mouse", "controller", "scrolling", "menu_system", "local_leaderboards", "split_screen", "score_system", "lives_system", "simple_story", "dialogue", "character_backstories", "multiple_endings", "controls", "enemies", "power_ups", "general_combat", "levels", "maps", "exploration", "secrets", "sound_effects", "music"]
const RULES := {
	&"action": {"cores": ["graphics", "technology"], "signature": ["general_combat"], "emphasis": "Graphics + Tech (30% each)"},
	&"adventure": {"cores": ["design"], "signature": ["exploration", "maps"], "emphasis": "Design (40%)"},
	&"role_playing": {"cores": ["design"], "signature": ["menu_system", "maps"], "emphasis": "Design (35%) · secondary Tech (30%)"},
	&"strategy": {"cores": ["technology"], "signature": ["score_system", "lives_system", "general_combat"], "emphasis": "Tech (40%) · secondary Design (35%)"},
	&"simulation": {"cores": ["technology"], "signature": ["local_leaderboards", "score_system"], "emphasis": "Tech (45%)"},
	&"puzzle": {"cores": ["design"], "signature": ["menu_system", "scrolling"], "emphasis": "Design (45%)"},
	&"sports": {"cores": ["technology"], "signature": ["music"], "emphasis": "Tech (30%) · secondary Sound (25%)"},
	&"racing": {"cores": ["technology"], "signature": ["sprites", "levels"], "emphasis": "Tech (35%) · secondary Graphics (30%)"},
}

static func preview(specialty: StringName) -> Dictionary:
	var genre := PrimitivePredevelopment.find_entry("genres", specialty)
	if not RULES.has(specialty) or genre.is_empty(): return {}
	var rule: Dictionary = RULES[specialty]
	var ids: Array[StringName] = []
	var names: Array[String] = []
	var scope := 0
	for card: Dictionary in FeatureStoreCatalog.starting_features():
		if not PRIMITIVE_IDS.has(str(card.id)): continue
		var included: bool = COMMON_IDS.has(StringName(card.id)) or rule.signature.has(str(card.id))
		for prefix in ["primary", "secondary"]:
			included = included or (rule.cores.has(card.get(prefix + "_stat", "")) and int(card.get(prefix + "_value", 0)) > 0)
		if included and not ids.has(StringName(card.id)):
			ids.append(StringName(card.id))
			names.append(str(card.name))
			scope += int(card.scope)
	for id in COMMON_IDS:
		if not ids.has(StringName(id)): return {}
	for id in rule.signature:
		if not ids.has(StringName(id)): return {}
	return {"id": specialty, "name": genre.name, "ids": ids, "names": names, "scope": scope, "count": ids.size(), "emphasis": rule.emphasis}
