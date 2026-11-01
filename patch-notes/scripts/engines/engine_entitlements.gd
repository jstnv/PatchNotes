## Pure entitlement and license quote data. Callers commit both finance ledgers.
extends RefCounted

const Marketplace := preload("res://scripts/engines/engine_marketplace.gd")
const VERSION := 1
const LEGACY_ID := &"legacy_engine"
const Public := preload("res://scripts/engines/public_action_engine.gd")

## New Studios receive access, never ownership or an automatic proprietary engine.
static func create_public(studio_id: StringName) -> Dictionary:
	if studio_id.is_empty(): return {}
	return {"version":2,"studio_id":studio_id,"owned_ids":[] as Array[StringName],
		"licensed_ids":[] as Array[StringName],"public_ids":[Public.ID] as Array[StringName],"selected_engine_id":Public.ID}

static func accessible_ids(state: Dictionary) -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(state.get("public_ids",[])+state.get("owned_ids",[])+state.get("licensed_ids",[]))
	return ids

static func create(studio_id: StringName) -> Dictionary:
	if studio_id.is_empty(): return {}
	var owned: Array[StringName] = [LEGACY_ID]
	for listing: Dictionary in Marketplace.starting_listings():
		if listing.creator_id == studio_id: owned.append(listing.id)
	return {"version": VERSION, "studio_id": studio_id, "owned_ids": owned, "licensed_ids": [] as Array[StringName], "selected_engine_id": LEGACY_ID}

static func valid(state: Dictionary,registered: Array[StringName]=[]) -> bool:
	var public_access: bool = state.get("version") == 2
	if state.size() != (6 if public_access else 5) or state.get("version") not in [VERSION,2] or not state.get("studio_id") is StringName or state.studio_id.is_empty(): return false
	if not state.get("owned_ids") is Array or not state.get("licensed_ids") is Array or not state.get("selected_engine_id") is StringName: return false
	var seen: Dictionary = {}
	if public_access:
		if not state.get("public_ids") is Array or state.public_ids != [Public.ID]: return false
		if not state.public_ids[0] is StringName: return false
		seen[Public.ID] = true
	for key in ["owned_ids", "licensed_ids"]:
		for id: Variant in state[key]:
			if not id is StringName or seen.has(id): return false
			if id == LEGACY_ID:
				if key != "owned_ids" or public_access: return false
			else:
				var listing: Dictionary = Marketplace.find(id)
				if listing.is_empty():
					if id not in registered or key!="owned_ids":return false
				elif (listing.creator_id == state.studio_id) != (key == "owned_ids"): return false
			seen[id] = true
	return (public_access or state.owned_ids.has(LEGACY_ID)) and seen.has(state.selected_engine_id)

static func plan_license(state: Dictionary, engine_id: StringName, buyer_cash_cents: int, creator_id: StringName, creator_cash_cents: int,registered: Array[StringName]=[]) -> Dictionary:
	if not valid(state,registered): return {}
	var listing: Dictionary = Marketplace.find(engine_id)
	if engine_id == Public.ID: return {}
	if listing.is_empty() or listing.creator_id != creator_id or state.studio_id == creator_id: return {}
	if engine_id in state.owned_ids or engine_id in state.licensed_ids: return {}
	var price: int = listing.license_cents
	if buyer_cash_cents < price or creator_cash_cents < 0 or creator_cash_cents > ProjectState.MAX_SIGNED_INT - price: return {}
	var next := state.duplicate(true)
	next.licensed_ids.append(engine_id)
	return {"next_state": next, "buyer_delta_cents": -price, "creator_delta_cents": price, "creator_id": creator_id, "receipt_id": StringName("engine-license:%s:%s" % [state.studio_id, engine_id])}
