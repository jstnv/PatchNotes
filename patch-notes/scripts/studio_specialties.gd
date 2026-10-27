class_name StudioSpecialties
extends RefCounted

## Historical v1/v2, root-first v3;2026-10-27 twelve-Scope new starts (v4).
## Fixed Primitive membership: future cards and Store ancestors never auto-grant.
const ROSTER_VERSION := 4
const STARTING_SCOPE := 12
const LEVELS_SWAP := [&"strategy", &"simulation", &"sports"]
const COMMON_IDS: Array[StringName] = [&"text", &"4_color_palette", &"8_bit_sound", &"keyboard_and_mouse", &"controller", &"controls"]
const ROOT_FIRST_COMMON_IDS: Array[StringName] = [&"text", &"4_color_palette", &"sound_effects", &"keyboard_and_mouse", &"controller", &"controls"]
## Fixed subsets of v3. Keep roots/parents, common six and genre identity;
## do not prune by RNG or grant future catalog additions automatically.
const SCOPE_12_EXTRAS := {
	&"action": ["sprites", "levels", "exploration", "simple_story"],
	&"adventure": ["levels", "exploration", "simple_story", "dialogue", "character_backstories"],
	&"role_playing": ["menu_system", "simple_story", "dialogue", "character_backstories", "score_system"],
	&"strategy": ["levels", "menu_system", "lives_system", "score_system"],
	&"simulation": ["scrolling", "menu_system", "lives_system", "score_system"],
	&"puzzle": ["levels", "exploration", "simple_story", "dialogue", "score_system"],
	&"sports": ["music", "levels", "lives_system", "power_ups"],
	&"racing": ["sprites", "levels", "scrolling"],
}
const ROOT_FIRST_PATCHES := {
	&"action": {"remove":["multiple_endings","general_combat"],"add":["lives_system","simple_story"]},
	&"adventure": {"remove":["8_bit_sound","local_leaderboards","multiple_endings","general_combat"],"add":["enemies","sound_effects"]},
	&"role_playing": {"remove":["8_bit_sound","local_leaderboards","multiple_endings","general_combat","secrets"],"add":["enemies","sound_effects","exploration"]},
	&"strategy": {"remove":["multiple_endings"],"add":["simple_story"]},
	&"simulation": {"remove":["local_leaderboards","multiple_endings","enemies"],"add":["lives_system","simple_story"]},
	&"puzzle": {"remove":["8_bit_sound","local_leaderboards","multiple_endings","general_combat","secrets"],"add":["enemies","sound_effects","exploration"]},
	&"sports": {"remove":["multiple_endings","enemies"],"add":["lives_system","simple_story"]},
	&"racing": {"remove":["multiple_endings","enemies"],"add":["lives_system","simple_story"]},
}
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

static func preview(specialty: StringName, roster_version: int = ROSTER_VERSION) -> Dictionary:
	var genre := PrimitivePredevelopment.find_entry("genres", specialty)
	if roster_version not in [1, 2, 3, 4] or not RULES.has(specialty) or genre.is_empty(): return {}
	var rule: Dictionary = RULES[specialty]
	var swap := roster_version >= 2 and specialty in LEVELS_SWAP
	var ids: Array[StringName] = []
	var names: Array[String] = []
	var scope := 0
	for card: Dictionary in FeatureStoreCatalog.starting_features():
		if not PRIMITIVE_IDS.has(str(card.id)): continue
		var included: bool = COMMON_IDS.has(StringName(card.id)) or rule.signature.has(str(card.id))
		for prefix in ["primary", "secondary"]:
			included = included or (rule.cores.has(card.get(prefix + "_stat", "")) and int(card.get(prefix + "_value", 0)) > 0)
		if swap and card.id in ["maps", "levels"]: included = card.id == "levels"
		if included and not ids.has(StringName(card.id)):
			ids.append(StringName(card.id))
			names.append(str(card.name))
			scope += int(card.scope)
	if roster_version >= 3:
		var patch: Dictionary = ROOT_FIRST_PATCHES[specialty]
		for id in patch.remove: ids.erase(StringName(id))
		for id in patch.add:
			if not ids.has(StringName(id)): ids.append(StringName(id))
		if roster_version == 4:
			var allowed: Array[StringName] = ROOT_FIRST_COMMON_IDS.duplicate()
			for id in SCOPE_12_EXTRAS[specialty]:
				if not ids.has(StringName(id)): return {}
				allowed.append(StringName(id))
			ids = ids.filter(func(id: StringName): return allowed.has(id))
		# Recompute only presentation totals from actual fixed membership.
		names.clear()
		scope=0
		var definitions := {}
		for card: Dictionary in FeatureStoreCatalog.starting_features(): definitions[StringName(card.id)]=card
		for id in ids:
			if not PRIMITIVE_IDS.has(str(id)) or not definitions.has(id): return {}
			names.append(str(definitions[id].name))
			scope+=int(definitions[id].scope)
	for id in ROOT_FIRST_COMMON_IDS if roster_version >= 3 else COMMON_IDS:
		if not ids.has(StringName(id)): return {}
	if roster_version < 3:
		for id in rule.signature:
			if not ids.has(StringName(id)): return {}
	if roster_version == 4 and scope != STARTING_SCOPE: return {}
	var note := "Starts with connected Primitive parent paths. Later Features are optional Store purchases or research."
	if roster_version == 4: note = "Starts with 12 printed Scope and connected Primitive parent paths."
	elif roster_version < 3: note = "Starts with Levels instead of Maps. Maps is an optional Store purchase unlocked by Levels." if swap else ""
	return {"id": specialty, "name": genre.name, "ids": ids, "names": names, "scope": scope, "count": ids.size(), "emphasis": rule.emphasis,
		"roster_version":roster_version,"note":note}
