extends SceneTree

const Awards := preload("res://scripts/awards/annual_awards_ledger.gd")
const Clock := preload("res://scripts/calendar/calendar_clock.gd")
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ",label)

func _initialize() -> void:
	_test.call_deferred()

func _test() -> void:
	# These are explicit calendar models, not invented historical-save fixtures.
	for row: Dictionary in [
		{"cycle":23,"base":23,"epoch":1980,"year":1981,"label":"legacy1980 DecWeek3"},
		{"cycle":47,"base":47,"epoch":1980,"year":1982,"label":"legacy1981 DecWeek3"},
		{"cycle":22,"base":22,"epoch":1980,"year":1980,"label":"legacy DecWeek1"},
		{"cycle":24,"base":24,"epoch":1980,"year":1981,"label":"legacy January"},
		{"cycle":44,"base":0,"epoch":1980,"year":1980,"label":"fresh DecWeek1"},
		{"cycle":45,"base":0,"epoch":1980,"year":1981,"label":"fresh DecWeek2"},
		{"cycle":46,"base":0,"epoch":1980,"year":1981,"label":"fresh DecWeek3"},
		{"cycle":0,"base":0,"epoch":1980,"year":1980,"label":"fresh January"},
		{"cycle":23,"base":23,"epoch":1977,"year":1980,"label":"pre1980 legacy December"},
		{"cycle":45,"base":0,"epoch":1977,"year":1980,"label":"pre1980 fresh December"},
		{"cycle":72,"base":72,"epoch":1977,"year":1980,"label":"1977 prelude reaches1980 January"}
	]:
		var run := RunState.new()
		run._calendar_start_year = row.epoch
		run._calendar = {"version":2,"legacy_until":row.base}
		check(Awards.first_eligible_year(run,row.cycle) == row.year,row.label+" first eligible year")
	for base: int in [23,47]:
		_model_next_year(base)
	print("ANNUAL_AWARDS_LEGACY_CUTOFF checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)

func _model_next_year(base: int) -> void:
	# Exercise real ranking, settlement and typed ledger validation with a small
	# modeled no-release world. This does not claim full Studio/GlobalWorld validity.
	var run := RunState.new()
	run._bank_run_id = &"legacy-cutoff-model"
	run._studio_name = "Legacy cutoff model"
	run._calendar = {"version":2,"legacy_until":base}
	run._completed_run_cycles = base
	var world := RivalWorld.new()
	world.player = run
	world.cycle = base
	var year := Clock.year(base,1980,run.get_calendar_profile())
	check(Clock.month_of_year(base,run.get_calendar_profile()) == 12 and Clock.position(base,run.get_calendar_profile()).quarter == 2,"Modeled cutover displays DecemberWeek3")
	check(Awards.due_cycle(run,year) == -1,"Skipped old-prefix DecemberWeek2 is unrepresentable")
	check(Awards.initialize(world),"Initialize modeled legacy ledger")
	check(world.annual_awards.first_year == year+1,"Skip unrepresentable expired year")
	check(Awards.valid(world,world.annual_awards),"Initial modeled legacy ledger validates")
	var target := Awards.due_cycle(run,year+1)
	check(target > base,"Next DecemberWeek2 has a future raw cycle")
	run._completed_run_cycles = target
	world.cycle = target
	var months: Array = []
	for month in range(1,Clock.month(target,run.get_calendar_profile())):
		months.append({"month":month,"ending":0,"gained":0})
	run._fanbase = {"months":months,"fans":0,"last_cycle":target,"releases":{}}
	var result := Awards.settle(world)
	check(result.get("ok",false) and result.get("settled",false),"Next year really settles without a dead-year entry")
	check(world.annual_awards.entries.size() == 1 and world.annual_awards.entries[0].result.year == year+1,"Only next-year result exists")
	check(Awards.valid(world,world.annual_awards),"Next-year ledger validates without missing expired year")
	var before := var_to_bytes(world.annual_awards)
	result = Awards.settle(world)
	check(result.get("ok",false) and not result.get("settled",true) and before == var_to_bytes(world.annual_awards),"Repeated next-year settlement is inert")
	var codec := CheckpointCodec.new()
	var encoded: Variant = codec.encode(world.annual_awards,Awards.schema())
	check(codec.error.is_empty(),"Typed ledger checkpoint encodes")
	var decoded = codec.decode(encoded,Awards.schema())
	check(codec.error.is_empty() and decoded == world.annual_awards and Awards.valid(world,decoded),"Typed ledger checkpoint round trip preserves valid next-year result")
