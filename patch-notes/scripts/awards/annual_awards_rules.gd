extends RefCounted

## Pure frozen ranking. Inputs never mutate; an invalid plan has no partial result.
const VERSION := 1
const NOMINEE_FANS := 10
const WINNER_FANS := 40
const WINNER_AWARENESS := 5
const MAX_INT := 9223372036854775807
const AWARD_IDS := [&"graphics",&"sound",&"technology",&"design",&"rising_studio",&"studio_of_the_year",&"game_of_the_year"]
const AWARD_NAMES := ["Graphics","Sound","Technology","Design","Rising Studio","Studio of the Year","Game of the Year"]
const METRICS := [&"core",&"core",&"core",&"core",&"gained_fans",&"fans",&"review_tenths"]

static func rank(year: int, cutoff_cycle: int, studios: Array, games: Array) -> Dictionary:
	if year < 1980 or cutoff_cycle < 0: return {}
	var owners := {}
	var frozen_studios: Array = []
	for item: Variant in studios:
		if not item is Dictionary: return {}
		if not _id(item.get("studio_id")) or not _text(item.get("studio_name")): return {}
		if not _uint(item.get("fans")) or not _uint(item.get("gained_fans")): return {}
		var id := StringName(item.studio_id)
		if owners.has(id): return {}
		var owner := {"studio_id":id,"studio_name":item.studio_name,"fans":item.fans,"gained_fans":item.gained_fans}
		owners[id] = owner
		frozen_studios.append(owner)
	frozen_studios.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return str(a.studio_id) < str(b.studio_id))
	var seen_games := {}
	var eligible_owners := {}
	var frozen_games: Array = []
	for item: Variant in games:
		if not item is Dictionary: return {}
		if not _id(item.get("release_id")) or not _id(item.get("studio_id")) or not _text(item.get("title")): return {}
		var release_id := StringName(item.release_id)
		var owner_id := StringName(item.studio_id)
		if seen_games.has(release_id) or not owners.has(owner_id): return {}
		seen_games[release_id] = true
		if not _uint(item.get("release_cycle")) or not _uint(item.get("release_year")): return {}
		if not _uint(item.get("review_tenths")) or item.review_tenths > 100: return {}
		if not item.get("cores") is Array or item.cores.size() != 4: return {}
		for core: Variant in item.cores:
			if not _uint(core): return {}
		if item.release_year != year or item.release_cycle > cutoff_cycle: continue
		eligible_owners[owner_id] = true
		frozen_games.append({"release_id":release_id,"studio_id":owner_id,"title":item.title,"cores":item.cores.duplicate(),"review_tenths":item.review_tenths,"release_cycle":item.release_cycle,"release_year":item.release_year})
	frozen_games.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if a.studio_id != b.studio_id: return str(a.studio_id) < str(b.studio_id)
		return str(a.release_id) < str(b.release_id))
	var awards: Array = []
	var gifts := {}
	for category in range(7):
		var candidates: Array = []
		if category == 4 or category == 5:
			for owner: Dictionary in frozen_studios:
				if not eligible_owners.has(owner.studio_id): continue
				candidates.append(_nominee(owner,&"","",owner.gained_fans if category == 4 else owner.fans))
		else:
			for game: Dictionary in frozen_games:
				var score: int = game.cores[category] if category < 4 else game.review_tenths
				candidates.append(_nominee(owners[game.studio_id],game.release_id,game.title,score))
		candidates.sort_custom(_ranked_before)
		candidates.resize(mini(3,candidates.size()))
		for place in range(candidates.size()):
			var nominee: Dictionary = candidates[place]
			nominee.rank = place + 1
			if not gifts.has(nominee.studio_id):
				gifts[nominee.studio_id] = {"studio_id":nominee.studio_id,"nominations":0,"wins":0,"fans":0,"awareness":0}
			var gift: Dictionary = gifts[nominee.studio_id]
			gift.nominations += 1
			gift.fans += NOMINEE_FANS
			if place == 0:
				gift.wins += 1
				gift.fans += WINNER_FANS
				gift.awareness += WINNER_AWARENESS
		awards.append({"id":AWARD_IDS[category],"name":AWARD_NAMES[category],"metric_kind":METRICS[category],"nominees":candidates})
	var rewards: Array = []
	for owner: Dictionary in frozen_studios:
		if not gifts.has(owner.studio_id): continue
		var gift: Dictionary = gifts[owner.studio_id]
		# A maximum of 21 nominations and seven wins bounds every gift calculation.
		# Check the unbounded owner balance before adding the complete planned gift.
		if owner.fans > MAX_INT - gift.fans: return {}
		rewards.append(gift)
	return {"rules_version":VERSION,"year":year,"cutoff_cycle":cutoff_cycle,"studios":frozen_studios,"games":frozen_games,"awards":awards,"rewards":rewards}

static func _nominee(owner: Dictionary, release_id: StringName, title: String, score: int) -> Dictionary:
	return {"studio_id":owner.studio_id,"studio_name":owner.studio_name,"release_id":release_id,"title":title,"score":score,"rank":0}

static func _ranked_before(a: Dictionary, b: Dictionary) -> bool:
	if a.score != b.score: return a.score > b.score
	if a.studio_id != b.studio_id: return str(a.studio_id) < str(b.studio_id)
	return str(a.release_id) < str(b.release_id)

static func _id(value: Variant) -> bool:
	return (typeof(value) == TYPE_STRING_NAME or typeof(value) == TYPE_STRING) and not str(value).strip_edges().is_empty()

static func _text(value: Variant) -> bool:
	return typeof(value) == TYPE_STRING and not value.strip_edges().is_empty()

static func _uint(value: Variant) -> bool:
	return typeof(value) == TYPE_INT and value >= 0

static func schema() -> Dictionary:
	var studio := {"studio_id":"id","studio_name":"text","fans":"uint","gained_fans":"uint"}
	var game := {"release_id":"id","studio_id":"id","title":"text","cores":CheckpointSchema.array_of("uint"),"review_tenths":"uint","release_cycle":"uint","release_year":"uint"}
	var nominee := {"studio_id":"id","studio_name":"text","release_id":"id","title":"text","score":"uint","rank":"uint"}
	var award := {"id":"id","name":"text","metric_kind":"id","nominees":CheckpointSchema.array_of(nominee)}
	var reward := {"studio_id":"id","nominations":"uint","wins":"uint","fans":"uint","awareness":"uint"}
	return {"rules_version":"uint","year":"uint","cutoff_cycle":"uint","studios":CheckpointSchema.array_of(studio),"games":CheckpointSchema.array_of(game),"awards":CheckpointSchema.array_of(award),"rewards":CheckpointSchema.array_of(reward)}
