## ACTIVE/TRIAL monthly market. Pure plans commit only after legal player success.
## Values are provisional; frozen project and sales ledgers own past outcomes.
extends RefCounted
const Index := preload("res://queries/market_release_index.gd")
const Book:=preload("res://scripts/market/rival_standard_book.gd")
const Historical := preload("res://scripts/market/historical_standard_trial.gd")
const Clock := preload("res://scripts/calendar/calendar_clock.gd")
const WINDOW_CYCLES := 12
const VERSION := 2
const CALENDAR_VERSION := 5
const WINDOW_QUARTERS := 24 # The existing six-month presence window.
## Every sales record rechecks its complete dated factor history. Many records
## contain identical immutable monthly factors. Reuse only an exact typed-byte
## positive proof of this unchanged predicate; unknown/mutated factors still
## execute every original check, and sales records retain full replay.
const FACTOR_PROOF_LIMIT := 1024
const FACTOR_PROOF_BYTES := 1024 * 1024
static var _factor_proofs: Dictionary = {}
static var _factor_order: Array[PackedByteArray] = []
static var _factor_bytes := 0
static var _factor_lock := Mutex.new()
static func neutral() -> Dictionary:
	return {"version":VERSION,"cycle_start":0,"id":"market-0-neutral","facts":[]}
static func identifier(cycle_start: int, facts: Array, calendar: Dictionary={}) -> String:
	var ordered: Array=[]
	for row: Dictionary in facts:
		ordered.append([row.studio_id,row.release_id,row.release_cycle,row.genre,row.theme,
			row.review_tenths,row.cores_available,row.cores])
	if not calendar.is_empty():return "market-v3-%d-%s"%[cycle_start,var_to_bytes(Book._plain([calendar,ordered])).hex_encode().sha256_text()]
	return "market-v2-%d-%s"%[cycle_start,JSON.stringify(ordered).sha256_text()]
static func calendar_for(snapshot: Dictionary) -> Dictionary:
	return snapshot.get("calendar",{}).duplicate(true)
static func within_window(release_cycle: int, cycle_start: int, calendar: Dictionary={}) -> bool:
	return release_cycle>=0 and release_cycle<cycle_start and Clock.valid(calendar) and Clock.quarters_between(release_cycle,cycle_start,calendar)<=WINDOW_QUARTERS
static func is_book(snapshot: Dictionary) -> bool:
	return snapshot.get("version")==4 or (snapshot.get("version")==CALENDAR_VERSION and snapshot.has("basis"))
static func snapshot(cycle_start: int, facts: Array, calendar: Dictionary={}) -> Dictionary:
	if not Clock.valid(calendar) or cycle_start<0:return {}
	var month:=Clock.month_start(cycle_start,calendar)
	var value: Dictionary={"version":VERSION if calendar.is_empty() else CALENDAR_VERSION,"cycle_start":month,"id":"","facts":facts.duplicate(true)}
	if not calendar.is_empty():value.calendar=calendar.duplicate(true)
	value.id=identifier(month,value.facts,calendar)
	if calendar.is_empty() and month==0:value.id="market-0-neutral"
	return value if valid(value) else {}
static func valid(snapshot: Variant) -> bool:
	if snapshot is Dictionary and is_book(snapshot):return Book.valid_snapshot(snapshot)
	if snapshot is Dictionary and snapshot.get("version")==3: return Historical.valid_snapshot(snapshot)
	if not snapshot is Dictionary:return false
	var dated: bool=snapshot.get("version")==CALENDAR_VERSION
	if snapshot.size()!=(5 if dated else 4) or snapshot.get("version") not in [VERSION,CALENDAR_VERSION] or not snapshot.get("cycle_start") is int or not snapshot.get("id") is String or not snapshot.get("facts") is Array:
		return false
	if dated and (not snapshot.get("calendar") is Dictionary or snapshot.calendar.is_empty() or not Clock.valid(snapshot.calendar)):return false
	var calendar: Dictionary=calendar_for(snapshot)
	if snapshot.cycle_start<0 or Clock.month_start(snapshot.cycle_start,calendar)!=snapshot.cycle_start or snapshot.id.is_empty(): return false
	var prior := ""
	for row: Variant in snapshot.facts:
		if not row is Dictionary or row.size()!=8: return false
		for key: String in ["studio_id","release_id","genre","theme"]:
			if not row.get(key) is String or row[key].is_empty(): return false
		for key: String in ["release_cycle","review_tenths"]:
			if not row.get(key) is int or row[key]<0: return false
		if row.review_tenths>100 or not row.get("cores_available") is bool or not row.get("cores") is Array or row.cores.size() != (4 if row.cores_available else 0): return false
		if not within_window(row.release_cycle,snapshot.cycle_start,calendar): return false
		var identity: String = row.studio_id+"/"+row.release_id
		if not prior.is_empty() and identity<=prior: return false
		prior=identity
		if row.cores_available:
			for core: Variant in row.cores:
				if not core is int or core<0: return false
	if snapshot.cycle_start==0 and not dated:return snapshot.id=="market-0-neutral" and snapshot.facts.is_empty()
	return (snapshot.cycle_start>0 or snapshot.facts.is_empty()) and snapshot.id==identifier(snapshot.cycle_start,snapshot.facts,calendar)
static func preview(world: RivalWorld, target_cycle: int) -> Dictionary:
	if world==null or world.player==null or target_cycle!=world.cycle+1 or target_cycle<1 or not valid(world.market_snapshot): return {}
	var calendar: Dictionary=world.player.get_calendar_profile()
	if not Clock.is_boundary(target_cycle,calendar): return world.market_snapshot.duplicate(true)
	var indexed := Index.query(world)
	if not indexed.get("ok",false): return {}
	var facts: Array = []
	for source: Dictionary in indexed.rows:
		if not within_window(source.release_cycle,target_cycle,calendar): continue
		facts.append({"studio_id":str(source.studio_id),"release_id":str(source.release_id),
			"release_cycle":int(source.release_cycle),"genre":str(source.genre),"theme":str(source.theme),
			"review_tenths":int(source.review_tenths),"cores_available":bool(source.cores_available),
			"cores":source.cores.duplicate()})
	facts.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if a.studio_id!=b.studio_id: return a.studio_id<b.studio_id
		return a.release_id<b.release_id)
	if is_book(world.market_snapshot):return Book.snapshot(world.market_snapshot.basis,target_cycle,72,facts,calendar)
	return snapshot(target_cycle,facts,calendar)
static func commit_after_player(world: RivalWorld, planned: Dictionary) -> bool:
	if world==null or world.player==null or world.player.get_completed_run_cycles()!=world.cycle+1 or not valid(planned): return false
	if planned!=preview(world,world.cycle+1): return false
	world.market_snapshot=planned.duplicate(true)
	return true
static func targets(snapshot: Dictionary, studio_id: String, genre: StringName) -> Dictionary:
	if not valid(snapshot) or studio_id.is_empty() or not PrimitiveReviewCalculator.GENRE_TARGETS.has(genre): return {}
	if is_book(snapshot):return Book.details(snapshot,studio_id,genre)
	if snapshot.version==3: return Historical.details(snapshot,genre)
	var base: Array=PrimitiveReviewCalculator.GENRE_TARGETS[genre]
	var result: Array=base.duplicate()
	var recent_count := 0
	var benchmark_lifts: Array[int] = [0,0,0,0]
	for row: Dictionary in snapshot.facts:
		if row.studio_id==studio_id or row.genre!=str(genre): continue
		recent_count+=1
		if row.review_tenths<70 or not row.cores_available: continue
		for i in range(4):
			benchmark_lifts[i]=maxi(benchmark_lifts[i],mini(8,maxi(0,(row.cores[i]-base[i])/2)))
	var density_lift:=mini(4,2*recent_count)
	for i in range(4): result[i]=base[i]+maxi(density_lift,benchmark_lifts[i])
	return {"snapshot_id":snapshot.id,"cycle_start":snapshot.cycle_start,"standards":result,"base":base.duplicate(),
		"recent_count":recent_count,"density_lift":density_lift,"benchmark_lifts":benchmark_lifts,"historical":false}
static func sales_factor(snapshot: Dictionary, studio_id: String, release_id: String, genre: String, theme: String) -> Dictionary:
	if not valid(snapshot) or studio_id.is_empty() or release_id.is_empty() or genre.is_empty() or theme.is_empty(): return {}
	if snapshot.version==3 or (is_book(snapshot) and snapshot.epoch_offset==0): return neutral_factor()
	var g:=0
	var t:=0
	var p:=0
	for row: Dictionary in snapshot.facts:
		if row.studio_id==studio_id and row.release_id==release_id: continue
		if row.genre==genre and row.theme==theme: p+=1
		elif row.genre==genre: g+=1
		elif row.theme==theme: t+=1
	return {"snapshot_id":snapshot.id,"cycle_start":snapshot.cycle_start,"genre_only":g,"theme_only":t,"pair":p,
		"factor_bp":maxi(7000,10000-600*g-300*t-1200*p),"historical":false}
static func neutral_factor() -> Dictionary:
	return {"snapshot_id":"market-0-neutral","cycle_start":0,"genre_only":0,"theme_only":0,"pair":0,"factor_bp":10000,"historical":false}
static func valid_source(id: String, cycle: int, historical: bool) -> bool:
	if historical:
		if cycle!=0 or not id.begins_with("pre-market-neutral:"): return false
		id=id.trim_prefix("pre-market-neutral:").trim_prefix("content:")
	# A retained legacy standard book can have its first live snapshot at0.
	# Validate its dated prefix/hash below, just like its later snapshots.
	elif cycle==0 and not calendar_source(id) and not id.begins_with("market-book-v1-"): return id=="market-0-neutral"
	else:
		var prefix: String
		if id.begins_with("market-book-v2-"):prefix="market-book-v2-%d-"%cycle
		elif id.begins_with("market-v3-"):prefix="market-v3-%d-"%cycle
		else:prefix=("market-book-v1-%d-" if id.begins_with("market-book-v1-") else "market-v2-%d-")%cycle
		if not id.begins_with(prefix): return false
		id=id.trim_prefix(prefix)
	return id.length()==64 and id.to_lower()==id and id.is_valid_hex_number(false)
static func valid_factor(value: Variant) -> bool:
	if not value is Dictionary or value.size()!=7:return false
	var key:=var_to_bytes(value)
	if key.size()>FACTOR_PROOF_BYTES:return _validate_factor(value)
	_factor_lock.lock()
	var known:=_factor_proofs.has(key)
	_factor_lock.unlock()
	if known:return true
	if not _validate_factor(value):return false
	_factor_lock.lock()
	if not _factor_proofs.has(key):
		_factor_proofs[key]=true
		_factor_order.append(key)
		_factor_bytes+=key.size()
	while _factor_order.size()>FACTOR_PROOF_LIMIT or _factor_bytes>FACTOR_PROOF_BYTES:
		var expired: PackedByteArray=_factor_order.pop_front()
		_factor_proofs.erase(expired)
		_factor_bytes-=expired.size()
	_factor_lock.unlock()
	return true

static func _validate_factor(value: Variant) -> bool:
	if not value is Dictionary or value.size()!=7 or not value.get("snapshot_id") is String or value.snapshot_id.is_empty() or not value.get("historical") is bool: return false
	for key: String in ["cycle_start","genre_only","theme_only","pair","factor_bp"]:
		if not value.get(key) is int or value[key]<0: return false
	if (not calendar_source(value.snapshot_id) and value.cycle_start%2!=0) or value.factor_bp<7000 or value.factor_bp>10000: return false
	if not valid_source(value.snapshot_id,value.cycle_start,value.historical): return false
	if value.historical: return value.factor_bp==10000 and value.genre_only==0 and value.theme_only==0 and value.pair==0
	# Bound contributions before arithmetic so malformed counts cannot overflow.
	var penalty := mini(value.genre_only,5)*600 + mini(value.theme_only,10)*300 + mini(value.pair,3)*1200
	return value.factor_bp==maxi(7000,10000-penalty)
static func valid_details(value: Variant, genre: StringName) -> bool:
	if value is Dictionary and Book.is_details(value):return Book.valid_details(value,genre)
	if value is Dictionary and value.get("historical")==true and str(value.get("snapshot_id","")).begins_with(Historical.PREFIX): return Historical.valid_details(value,genre)
	if not value is Dictionary or value.size()!=8 or not value.get("snapshot_id") is String or value.snapshot_id.is_empty() or not value.get("historical") is bool: return false
	for key: String in ["cycle_start","recent_count","density_lift"]:
		if not value.get(key) is int or value[key]<0: return false
	if (not calendar_source(value.snapshot_id) and value.cycle_start%2!=0) or value.get("base")!=PrimitiveReviewCalculator.GENRE_TARGETS.get(genre,[]): return false
	if not valid_source(value.snapshot_id,value.cycle_start,value.historical): return false
	if not value.get("standards") is Array or value.standards.size()!=4 or not value.get("benchmark_lifts") is Array or value.benchmark_lifts.size()!=4: return false
	if value.density_lift!=mini(2,value.recent_count)*2: return false
	for i in range(4):
		if not value.benchmark_lifts[i] is int or value.benchmark_lifts[i]<0 or value.benchmark_lifts[i]>8 or not value.standards[i] is int: return false
		if value.standards[i]!=value.base[i]+maxi(value.density_lift,value.benchmark_lifts[i]): return false
	return not value.historical or (value.recent_count==0 and value.standards==value.base)
static func calendar_source(id: String) -> bool:
	return id.begins_with("market-v3-") or id.begins_with("market-book-v2-")
static func describe(details: Dictionary,calendar: Dictionary={}) -> String:
	if details.is_empty(): return "Genre base targets; no saved market adjustment."
	if Book.is_details(details):calendar=Book.proof(details.snapshot_id).get("calendar",calendar)
	return "Market trial · Month %d%s\nGenre base %s · %d other same-Genre releases (+%d)\nStrong-release lifts %s · Final %s (larger lift per category)" % [
		Clock.month(details.cycle_start,calendar)," · historical baseline" if details.historical else " · frozen at project start",
		str(details.base),details.recent_count,details.density_lift,str(details.benchmark_lifts),str(details.standards)]
