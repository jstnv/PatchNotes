## Dated actual-Core identity baseline. Existing +8 benchmark/+4 density rules
## are unchanged. Frozen archives provide standards, never active sales facts.
extends RefCounted
const Historical:=preload("res://scripts/market/historical_standard_trial.gd")
const Clock:=preload("res://scripts/calendar/calendar_clock.gd")
const PREFIX:="historical-book-v1:"
const CALENDAR_PREFIX:="historical-book-v2:"
const CALENDAR_VERSION:=5
static func _plain(value: Variant) -> Variant:
	if value is Array:
		var result: Array=[]
		for item: Variant in value:result.append(_plain(item))
		return result
	if value is Dictionary:
		var result: Dictionary={};var keys: Array=value.keys();keys.sort()
		for key: Variant in keys:result[key]=_plain(value[key])
		return result
	return value
static func source(run: RunState,id: StringName) -> Dictionary:
	var m:=run.get_release_metadata(id);var s:=run.get_released_game_sales(id)
	return {"studio_id":str(run._bank_run_id),"release_id":str(id),"release_cycle":int(m.release_cycle),"review_tenths":int(s.review_tenths),"genre":str(m.genre),"cores":m.review.cores.duplicate()}
static func _before(a: Dictionary,b: Dictionary) -> bool:
	if a.release_cycle!=b.release_cycle:return a.release_cycle<b.release_cycle
	return a.studio_id+"/"+a.release_id<b.studio_id+"/"+b.release_id
static func build(sessions: Dictionary,target_cycle: int) -> Dictionary:
	var month:=target_cycle-target_cycle%2;var records: Array=[]
	for session: RefCounted in sessions.values():
		for id: StringName in session.run.get_released_game_ids():
			var row:=source(session.run,id)
			if row.release_cycle<month and row.release_cycle<72:records.append(row)
	return build_records(records,target_cycle)
static func build_records(records: Array,target_cycle: int) -> Dictionary:
	var month:=target_cycle-target_cycle%2
	records=records.filter(func(r: Dictionary)->bool:return r.release_cycle<month and r.release_cycle<72)
	records.sort_custom(_before)
	var result: Dictionary={}
	for row: Dictionary in records:
		if not result.has(row.genre):result[row.genre]={"first":row.duplicate(true),"benchmarks":[]}
	for genre: String in result:
		var group: Dictionary=result[genre];var lifts: Array=[0,0,0,0];var winners: Array=[{},{},{},{}]
		for row: Dictionary in records:
			if row.genre!=genre or row==group.first or row.review_tenths<70:continue
			for i in range(4):
				var lift: int=mini(8,maxi(0,(int(row.cores[i])-int(group.first.cores[i]))/2))
				if lift>int(lifts[i]):lifts[i]=lift;winners[i]=row
		for row: Dictionary in winners:
			if not row.is_empty() and row not in group.benchmarks:group.benchmarks.append(row.duplicate(true))
		group.benchmarks.sort_custom(_before)
	return result
static func valid_group(group: Variant,genre: String,absolute_month: int) -> bool:
	if not group is Dictionary or group.size()!=2 or not Historical.valid_source(group.get("first")) or not group.get("benchmarks") is Array or group.benchmarks.size()>4:return false
	var first: Dictionary=group.first
	if first.genre!=genre or first.release_cycle>=72 or Historical.effective_cycle(first)>absolute_month:return false
	for n: int in first.cores:
		if n<=0:return false
	var seen: Dictionary={};var previous: Dictionary={}
	for row: Variant in group.benchmarks:
		if not Historical.valid_source(row) or row.genre!=genre or row.review_tenths<70 or row.release_cycle>=72 or Historical.effective_cycle(row)>absolute_month or not _before(first,row):return false
		var key: String=row.studio_id+"/"+row.release_id
		if seen.has(key) or (not previous.is_empty() and not _before(previous,row)):return false
		seen[key]=true;previous=row
	return true
static func snapshot(basis: Dictionary,cycle: int,epoch_offset: int=0,facts: Array=[],calendar: Dictionary={}) -> Dictionary:
	if cycle<0 or not Clock.valid(calendar):return {}
	var month:=Clock.month_start(cycle,calendar)
	var data:={"version":4 if calendar.is_empty() else CALENDAR_VERSION,"cycle_start":month,"epoch_offset":epoch_offset,"basis":basis.duplicate(true),"facts":facts.duplicate(true),"id":""}
	if not calendar.is_empty():data.calendar=calendar.duplicate(true)
	data.id=identifier(data);return data
static func identifier(value: Dictionary) -> String:
	if value.has("calendar"):return "market-book-v2-%d-%s"%[int(value.cycle_start),var_to_bytes(_plain([value.calendar,value.epoch_offset,value.basis,value.facts])).hex_encode().sha256_text()]
	return "market-book-v1-%d-%s"%[int(value.cycle_start),var_to_bytes(_plain([value.epoch_offset,value.basis,value.facts])).hex_encode().sha256_text()]
static func _valid_snapshot(value: Variant) -> bool:
	if not value is Dictionary:return false
	var dated: bool=value.get("version")==CALENDAR_VERSION
	if value.size()!=(7 if dated else 6) or value.get("version") not in [4,CALENDAR_VERSION] or not value.get("cycle_start") is int or value.cycle_start<0 or value.get("epoch_offset") not in [0,72] or not value.get("basis") is Dictionary or not value.get("facts") is Array:return false
	if dated and (not value.get("calendar") is Dictionary or value.calendar.is_empty() or not Clock.valid(value.calendar)):return false
	var calendar: Dictionary=value.get("calendar",{})
	if Clock.month_start(value.cycle_start,calendar)!=value.cycle_start or value.get("id")!=identifier(value):return false
	for genre: Variant in value.basis:
		if not genre is String or not PrimitiveReviewCalculator.GENRE_TARGETS.has(StringName(genre)) or not valid_group(value.basis[genre],genre,value.cycle_start+value.epoch_offset):return false
	if value.epoch_offset==0:return value.facts.is_empty()
	var previous:=""
	for row: Variant in value.facts:
		if not row is Dictionary or row.size()!=8:return false
		for key in ["studio_id","release_id","genre","theme"]:
			if not row.get(key) is String or row[key].is_empty():return false
		for key in ["release_cycle","review_tenths"]:
			if not row.get(key) is int or row[key]<0:return false
		if row.review_tenths>100 or row.release_cycle>=value.cycle_start or Clock.quarters_between(row.release_cycle,value.cycle_start,calendar)>24 or not row.get("cores_available") is bool or not row.get("cores") is Array or row.cores.size()!=(4 if row.cores_available else 0):return false
		var key: String=row.studio_id+"/"+row.release_id
		if not previous.is_empty() and key<=previous:return false
		previous=key
		for core: Variant in row.cores:
			if not core is int or core<0:return false
	return value.cycle_start>0 or value.facts.is_empty()
static func proof(id: String) -> Dictionary:
	var prefix:=CALENDAR_PREFIX if id.begins_with(CALENDAR_PREFIX) else PREFIX
	if not id.begins_with(prefix):return {}
	var text:=id.trim_prefix(prefix)
	if text.is_empty() or text.length()>32768 or text.length()%2!=0 or not text.is_valid_hex_number(false):return {}
	var data: Variant=bytes_to_var(text.hex_decode())
	return data if data is Dictionary and prefix+var_to_bytes(_plain(data)).hex_encode()==id else {}
static func is_details(value: Dictionary) -> bool:
	var id: String=str(value.get("snapshot_id",""))
	return id.begins_with(PREFIX) or id.begins_with(CALENDAR_PREFIX)
static func details(value: Dictionary,owner: String,genre: StringName) -> Dictionary:
	if not valid_snapshot(value) or owner.is_empty() or not PrimitiveReviewCalculator.GENRE_TARGETS.has(genre):return {}
	var group: Dictionary=value.basis.get(str(genre),{});var base: Array=PrimitiveReviewCalculator.GENRE_TARGETS[genre].duplicate() if group.is_empty() else group.first.cores.duplicate()
	var lifts: Array=[0,0,0,0];var facts: Array=[];var count:=0
	if not group.is_empty():
		for row: Dictionary in group.benchmarks:
			for i in range(4):lifts[i]=maxi(lifts[i],mini(8,maxi(0,(int(row.cores[i])-int(base[i]))/2)))
	for row: Dictionary in value.facts:
		if row.studio_id==owner or row.genre!=str(genre):continue
		facts.append(row.duplicate(true));count+=1
		if row.review_tenths>=70 and row.cores_available:
			for i in range(4):lifts[i]=maxi(lifts[i],mini(8,maxi(0,(int(row.cores[i])-int(base[i]))/2)))
	var density:=mini(4,2*count);var standards: Array=[]
	for i in range(4):standards.append(int(base[i])+maxi(density,int(lifts[i])))
	var evidence:={"genre":str(genre),"owner":owner,"basis":group.duplicate(true),"facts":facts,"epoch_offset":value.epoch_offset}
	var prefix: String=PREFIX
	if value.has("calendar"):
		evidence.calendar=value.calendar.duplicate(true);prefix=CALENDAR_PREFIX
	return {"snapshot_id":prefix+var_to_bytes(_plain(evidence)).hex_encode(),"cycle_start":value.cycle_start,"standards":standards,"base":base,"recent_count":count,"density_lift":density,"benchmark_lifts":lifts,"historical":true}
static func _valid_details(value: Variant,genre: StringName) -> bool:
	if not value is Dictionary or value.size()!=8 or not value.get("cycle_start") is int or value.get("historical")!=true or not value.get("snapshot_id") is String:return false
	var p:=proof(value.snapshot_id)
	var dated: bool=str(value.snapshot_id).begins_with(CALENDAR_PREFIX)
	if p.size()!=(6 if dated else 5) or p.get("genre")!=str(genre) or not p.get("owner") is String or not p.get("basis") is Dictionary or not p.get("facts") is Array or p.get("epoch_offset") not in [0,72]:return false
	if dated and (not p.get("calendar") is Dictionary or p.calendar.is_empty() or not Clock.valid(p.calendar)):return false
	var basis: Dictionary={} if p.basis.is_empty() else {str(genre):p.basis}
	var s:=snapshot(basis,value.cycle_start,p.epoch_offset,p.facts,p.get("calendar",{}))
	return valid_snapshot(s) and details(s,p.owner,genre)==value

## Exact positive predicates only; no mutable parsed proof or owner escapes.
const PREDICATE_LIMIT:=64
const PREDICATE_BYTES:=512*1024
static var _predicate_keys: Array[PackedByteArray]=[]
static var _predicate_bytes:=0
static var _predicate_lock:=Mutex.new()
static func _checked(kind: String,value: Variant,genre: StringName=&"") -> bool:
	var key:=var_to_bytes([kind,value,genre,PrimitiveReviewCalculator.GENRE_TARGETS])
	if key.size()<=PREDICATE_BYTES:
		_predicate_lock.lock();var known:=_predicate_keys.has(key);_predicate_lock.unlock()
		if known:return true
	var valid:=_valid_snapshot(value) if kind=="snapshot" else _valid_details(value,genre)
	if not valid or key.size()>PREDICATE_BYTES:return valid
	_predicate_lock.lock()
	if not _predicate_keys.has(key):_predicate_keys.append(key);_predicate_bytes+=key.size()
	while _predicate_keys.size()>PREDICATE_LIMIT or _predicate_bytes>PREDICATE_BYTES:_predicate_bytes-=_predicate_keys.pop_front().size()
	_predicate_lock.unlock();return true
static func valid_snapshot(value: Variant) -> bool:return _checked("snapshot",value)
static func valid_details(value: Variant,genre: StringName) -> bool:return _checked("details",value,genre)
