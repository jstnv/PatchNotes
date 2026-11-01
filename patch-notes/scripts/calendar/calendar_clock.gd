## Calendar only: raw productive/project/event counters never change units.
## Missing profile is historical2/month. Version2 keeps that prefix through
## legacy_until, then advances one quarter-month per subsequent action.
extends RefCounted
const MONTHS_PER_YEAR := 12
const CYCLES_PER_MONTH := 4
const CYCLES_PER_YEAR := 48
const MAX_INT := 9223372036854775807

static func fresh() -> Dictionary:
	return {"version":2,"legacy_until":0}

static func valid(profile: Dictionary) -> bool:
	return profile.is_empty() or (profile.size()==2 and profile.get("version") is int and profile.version==2 and profile.get("legacy_until") is int and profile.legacy_until>=0)

## Presentation boundary only: typed checkpoint uints are stored as decimal
## strings. Validators still require native, fully decoded clock profiles.
static func from_saved_profile(value: Variant) -> Dictionary:
	if not value is Dictionary:return {"invalid":true}
	if valid(value):return value.duplicate(true)
	if value.size()!=2:return {"invalid":true}
	var result: Dictionary={}
	for key: String in ["version","legacy_until"]:
		var raw: Variant=value.get(key)
		if raw is int:result[key]=raw
		elif raw is String and raw.is_valid_int() and str(int(raw))==raw:result[key]=int(raw)
		else:return {"invalid":true}
	return result if valid(result) else {"invalid":true}

static func upgrade(profile: Dictionary, cycle: int) -> Dictionary:
	return {"version":2,"legacy_until":cycle} if profile.is_empty() else profile.duplicate(true)

static func position(cycle: int, profile: Dictionary={}) -> Dictionary:
	if cycle<0 or not valid(profile):return {}
	if profile.is_empty() or cycle<=int(profile.legacy_until):
		return {"month_index":cycle/2,"quarter":(cycle%2)*2}
	var base: int=profile.legacy_until
	var delta: int=cycle-base
	var quarters: int=(base%2)*2+delta%4
	return {"month_index":base/2+delta/4+quarters/4,"quarter":quarters%4}

static func month(cycle: int, profile: Dictionary={}) -> int:
	return int(position(cycle,profile).get("month_index",-1))+1

static func month_of_year(cycle: int, profile: Dictionary={}) -> int:
	return int(position(cycle,profile).get("month_index",0))%MONTHS_PER_YEAR+1

static func year(cycle: int, start_year: int=1980, profile: Dictionary={}) -> int:
	return start_year+int(position(cycle,profile).get("month_index",0))/MONTHS_PER_YEAR

static func is_boundary(cycle: int, profile: Dictionary={}) -> bool:
	return cycle>0 and int(position(cycle,profile).get("quarter",-1))==0

static func cycle_at(month_index: int, quarter: int=0, profile: Dictionary={}) -> int:
	if month_index<0 or quarter<0 or quarter>=4 or not valid(profile):return -1
	if profile.is_empty():
		if quarter%2!=0 or month_index>(MAX_INT-quarter/2)/2:return -1
		return month_index*2+quarter/2
	var base: int=profile.legacy_until
	var base_month: int=base/2
	var base_quarter: int=(base%2)*2
	if month_index<base_month or (month_index==base_month and quarter<=base_quarter):
		return cycle_at(month_index,quarter,{})
	var months: int=month_index-base_month
	if months>(MAX_INT-4)/4:return -1
	var delta: int=months*4+quarter-base_quarter
	if delta<0 or delta>MAX_INT-base:return -1
	return base+delta

static func month_start(cycle: int, profile: Dictionary={}) -> int:
	return cycle_at(month(cycle,profile)-1,0,profile)

## End of absolute run month1 is the opening boundary of run month2.
static func month_end(month_number: int, profile: Dictionary={}) -> int:
	return cycle_at(month_number,0,profile)

static func next_month_end(cycle: int, profile: Dictionary={}) -> int:
	return month_end(month(cycle,profile),profile)

static func first_full_month_end(cycle: int, profile: Dictionary={}) -> int:
	return month_end(month(cycle,profile)+int(position(cycle,profile).quarter!=0),profile)

static func action_month(cycle: int, productive: bool, profile: Dictionary={}) -> int:
	return month(maxi(0,cycle-1) if productive else cycle,profile)

static func quarters_between(first: int, last: int, profile: Dictionary={}) -> int:
	var a:=position(first,profile);var b:=position(last,profile)
	if a.is_empty() or b.is_empty():return -1
	var months: int=int(b.month_index)-int(a.month_index)
	if months>MAX_INT/4-1:return MAX_INT
	if months<-(MAX_INT/4-1):return -MAX_INT
	return months*4+int(b.quarter)-int(a.quarter)

static func elapsed_months(first: int, last: int, profile: Dictionary={}) -> float:
	return float(quarters_between(first,last,profile))/4.0

static func retarget_cycle(cycle: int, source_profile: Dictionary, target_profile: Dictionary) -> int:
	var date:=position(cycle,source_profile)
	return -1 if date.is_empty() else cycle_at(date.month_index,date.quarter,target_profile)

## Projected1977 owners retain their raw72-action offset. Rebase only the
## profile anchor when converting their local dates to shared-world dates.
static func shift(profile: Dictionary, offset: int) -> Dictionary:
	return {} if profile.is_empty() else {"version":2,"legacy_until":maxi(0,int(profile.legacy_until)-offset)}

static func label(cycle: int, start_year: int=1980, profile: Dictionary={}) -> String:
	var date:=position(cycle,profile)
	if date.is_empty():return "Date unavailable"
	var period: String="Week %d"%(int(date.quarter)+1)
	if profile.is_empty():period="First Half" if date.quarter==0 else "Second Half"
	return "%d · Month %d, %s"%[year(cycle,start_year,profile),month_of_year(cycle,profile),period]
