## Phase2A approved October31 manifest. Independent of Studio ownership/research.
extends RefCounted
const ID := &"public_action"
const ORIGIN := "public-action-manifest-v1"
const LIBRARY: Array[StringName] = [
	&"text", &"4_color_palette", &"8_bit_sound", &"keyboard_and_mouse",
	&"controller", &"controls", &"sprites", &"levels", &"simple_story",
	&"lives_system", &"enemies", &"general_combat", &"scrolling",
	&"menu_system", &"main_theme", &"animated_sprites", &"inventory_system",
]
static func definition() -> Dictionary:
	return {"id":ID,"name":"Public Action Engine","type":&"public",
		"creator_id":&"external-public-engine-provider","creator_specialty":&"action",
		"max_scope":27,"license_cents":0,"royalty_basis_points":3000,
		"dominant":[&"graphics",&"technology"],"fixed_library":true,
		"technology_skill_tree":false,"upgrades_available":false,"library":LIBRARY.duplicate()}
