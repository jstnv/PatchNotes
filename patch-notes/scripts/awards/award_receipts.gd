extends RefCounted

## A detached owner DTO is valid for paired hydration; a player Continue slot
## carrying prizes must also carry the authoritative global award results.
static func missing_world(payload: Dictionary) -> bool:
	if payload.has("rival_world"): return false
	var run: Variant = payload.get("run")
	if not run is Dictionary: return false
	var fans: Variant = run.get("fanbase")
	return fans is Dictionary and fans.has("annual_awards")

## Owner-local, chronological awards. Global results prove the nomination
## counts; this module proves their exact native accounting and launch order.
const MAX_INT := 9223372036854775807
const Rules := preload("res://scripts/awards/annual_awards_rules.gd")
const NOMINATION_FANS := Rules.NOMINEE_FANS
const WIN_FANS := Rules.WINNER_FANS
const WIN_AWARENESS := Rules.WINNER_AWARENESS

static func schema() -> Dictionary:
	var result := CheckpointSchema.fields("year cycle nominations wins fans awareness")
	result.id = "id"
	result.before = CheckpointSchema.array_of("id")
	return result

static func valid(receipt: Dictionary) -> bool:
	if receipt.size()!=8 or not receipt.get("id") is StringName or not receipt.get("before") is Array: return false
	for key in ["year","cycle","nominations","wins","fans","awareness"]:
		if not receipt.get(key) is int or receipt[key]<0: return false
	if receipt.year<1980 or receipt.id!=StringName("annual-awards:%d"%receipt.year) or receipt.nominations==0 or receipt.wins>receipt.nominations: return false
	if receipt.nominations>MAX_INT/NOMINATION_FANS or receipt.wins>MAX_INT/WIN_FANS or receipt.wins>MAX_INT/WIN_AWARENESS: return false
	var base: int = receipt.nominations*NOMINATION_FANS
	var bonus: int = receipt.wins*WIN_FANS
	if base>MAX_INT-bonus or receipt.fans!=base+bonus or receipt.awareness!=receipt.wins*WIN_AWARENESS: return false
	var seen := {}
	for id: Variant in receipt.before:
		if not id is StringName or id.is_empty() or seen.has(id): return false
		seen[id] = true
	return true

static func _ordered(state: Dictionary) -> bool:
	if not state.has("annual_awards"): return true
	if not state.annual_awards is Array or state.annual_awards.is_empty(): return false
	var year := -1
	var cycle := -1
	for row: Variant in state.annual_awards:
		if not row is Dictionary or not valid(row) or row.year<=year or row.cycle<=cycle: return false
		year = row.year
		cycle = row.cycle
	return true

static func plan(state: Dictionary, receipt: Dictionary) -> Dictionary:
	if not valid(receipt) or not _ordered(state) or not state.get("fans") is int or state.fans<0 or receipt.cycle!=state.get("last_cycle") or receipt.fans>MAX_INT-state.fans: return {}
	if state.has("annual_awards"):
		var last: Dictionary = state.annual_awards[-1]
		if receipt.year<=last.year or receipt.cycle<=last.cycle: return {}
	# Every already-registered launch at this owner cycle precedes the grant.
	var before := {}
	for id: Variant in state.get("releases",{}):
		var entry: Dictionary = state.releases[id]
		if int(entry.get("neutral",{}).get("total_earned_cycles",-1))==0: before[id]=true
	if before.size()!=receipt.before.size(): return {}
	for id: StringName in receipt.before:
		if not before.has(id): return {}
	var next := state.duplicate(true)
	if not next.has("annual_awards"): next.annual_awards = []
	next.annual_awards.append(receipt.duplicate(true))
	next.fans += receipt.fans
	return next

static func expected_awareness(state: Dictionary) -> Dictionary:
	if not _ordered(state): return {}
	var result := {}
	for row: Dictionary in state.get("annual_awards",[]):
		if row.awareness>0: result[row.id] = row.awareness
	return result

## Metadata is a committed insertion-order release ledger, as in the existing
## Contract Promotion path. Before IDs are precisely the same-cycle prefix.
static func next_release(receipt: Dictionary, metadata: Dictionary) -> StringName:
	if not valid(receipt): return &""
	for id: StringName in metadata:
		var cycle: int = metadata[id].release_cycle
		if cycle>receipt.cycle or (cycle==receipt.cycle and not receipt.before.has(id)): return id
	return &""

static func validate(state: Dictionary, metadata: Dictionary, cycle: int) -> bool:
	if not _ordered(state): return false
	for row: Dictionary in state.get("annual_awards",[]):
		if row.cycle>cycle: return false
		for id: StringName in row.before:
			if not metadata.has(id) or metadata[id].release_cycle!=row.cycle: return false
		var after := false
		for id: StringName in metadata:
			if metadata[id].release_cycle!=row.cycle: continue
			if row.before.has(id):
				if after: return false
			else: after = true
	return true
