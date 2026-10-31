## Isolated candidate only. Exact founding membership; never a player roster version.
extends RefCounted
const ID: StringName = &"rival-founder-active-1977-v2"
const CONTROL: StringName = &"rival-current-trial-1977-control-v1"
const MEMBERS := {
  "action": [
    "text",
    "sprites",
    "4_color_palette",
    "8_bit_sound",
    "keyboard_and_mouse",
    "controller",
    "scrolling",
    "menu_system",
    "controls",
    "enemies",
    "levels",
    "maps",
    "exploration",
    "lives_system",
    "simple_story",
    "inventory_system",
    "timer_system",
    "score_system",
    "dialogue"
  ],
  "adventure": [
    "text",
    "4_color_palette",
    "keyboard_and_mouse",
    "controller",
    "score_system",
    "lives_system",
    "simple_story",
    "dialogue",
    "character_backstories",
    "controls",
    "levels",
    "maps",
    "exploration",
    "secrets",
    "enemies",
    "8_bit_sound",
    "inventory_system",
    "timer_system",
    "sprites",
    "scrolling"
  ],
  "role_playing": [
    "text",
    "4_color_palette",
    "keyboard_and_mouse",
    "controller",
    "menu_system",
    "score_system",
    "lives_system",
    "simple_story",
    "dialogue",
    "character_backstories",
    "controls",
    "levels",
    "maps",
    "enemies",
    "exploration",
    "8_bit_sound",
    "inventory_system",
    "timer_system",
    "sprites",
    "secrets"
  ],
  "strategy": [
    "text",
    "4_color_palette",
    "8_bit_sound",
    "keyboard_and_mouse",
    "controller",
    "scrolling",
    "menu_system",
    "score_system",
    "lives_system",
    "controls",
    "enemies",
    "general_combat",
    "levels",
    "simple_story",
    "inventory_system",
    "timer_system",
    "exploration",
    "dialogue",
    "character_backstories",
    "secrets"
  ],
  "simulation": [
    "text",
    "4_color_palette",
    "8_bit_sound",
    "keyboard_and_mouse",
    "controller",
    "scrolling",
    "menu_system",
    "score_system",
    "controls",
    "levels",
    "lives_system",
    "simple_story",
    "inventory_system",
    "timer_system",
    "exploration",
    "sprites",
    "dialogue",
    "character_backstories",
    "secrets",
    "enemies"
  ],
  "puzzle": [
    "text",
    "4_color_palette",
    "keyboard_and_mouse",
    "controller",
    "scrolling",
    "menu_system",
    "score_system",
    "lives_system",
    "simple_story",
    "dialogue",
    "character_backstories",
    "controls",
    "levels",
    "enemies",
    "exploration",
    "8_bit_sound",
    "inventory_system",
    "timer_system",
    "sprites",
    "secrets"
  ],
  "sports": [
    "text",
    "4_color_palette",
    "8_bit_sound",
    "keyboard_and_mouse",
    "controller",
    "scrolling",
    "menu_system",
    "controls",
    "levels",
    "lives_system",
    "simple_story",
    "recorded_sounds",
    "inventory_system",
    "timer_system",
    "score_system",
    "sprites",
    "enemies",
    "general_combat"
  ],
  "racing": [
    "text",
    "sprites",
    "4_color_palette",
    "8_bit_sound",
    "keyboard_and_mouse",
    "controller",
    "scrolling",
    "menu_system",
    "controls",
    "levels",
    "maps",
    "lives_system",
    "simple_story",
    "inventory_system",
    "timer_system",
    "score_system",
    "dialogue",
    "character_backstories",
    "exploration",
    "secrets"
  ]
}
static func describe(genre: StringName,run: RunState,profile_id: StringName=ID) -> Dictionary:
	if not MEMBERS.has(str(genre)) or run==null:return {}
	var ids: Array[StringName]=[]
	for id: String in MEMBERS[str(genre)]:ids.append(StringName(id))
	if profile_id==CONTROL:
		ids.assign(StudioSpecialties.preview(genre,5).ids)
		var extras: Array=[&"music",&"dialogue",&"secrets"] if genre==&"action" else [&"sprites",&"8_bit_music",&"music"] if genre==&"adventure" else []
		if extras.is_empty():return {}
		for id: StringName in extras:
			if id not in ids:ids.append(id)
	elif profile_id!=ID:return {}
	var graph:=FeatureStoreCatalog.graph(run._feature_definitions,run._feature_offers)
	if graph.has("error"):return {}
	var scope:=0
	var cores: Array[int]=[0,0,0,0]
	var connected:=true
	for id: StringName in ids:
		var card: Dictionary=run._feature_definitions.get(id,{})
		if card.is_empty() or (profile_id!=CONTROL and not FeatureStoreCatalog.is_active(id)) or card.get("phase","") not in ["design","alpha"]:return {}
		for parent: StringName in graph.parents[id]:
			if parent not in ids:connected=false
		scope+=int(card.scope)
		for prefix: String in ["primary","secondary"]:
			var index: int=["graphics","sound","technology","design"].find(str(card.get(prefix+"_stat","")))
			if index>=0:cores[index]+=int(card.get(prefix+"_value",0))
	return {"profile":str(profile_id),"genre":str(genre),"ids":ids,"count":ids.size(),"scope":scope,"cores":cores,"parent_connected":connected}

static func apply(run: RunState,profile_id: StringName=ID) -> bool:
	if run==null or run.get_completed_run_cycles()!=0 or not run._rival_founder_profile.is_empty() or not run.needs_starter_selection() or not run.get_released_game_ids().is_empty():return false
	var info:=describe(run.get_studio_specialty(),run,profile_id)
	if info.is_empty() or (profile_id!=CONTROL and not info.parent_connected):return false
	var owned: Dictionary={}
	for id: StringName in info.ids:owned[id]=true
	run._owned_features=owned
	run._rival_founder_profile=profile_id
	run._calendar_start_year=1977
	return true
