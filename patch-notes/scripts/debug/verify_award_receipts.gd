extends "res://scripts/debug/verify_fanbase_checkpoint.gd"

const Clock := preload("res://scripts/calendar/calendar_clock.gd")
var receipt_checks := 0

func check_receipt(ok: bool, label: String) -> void:
	receipt_checks += 1
	expect(ok,label)

func receipt(year: int, cycle: int, nominations: int = 1, wins: int = 1, before: Array = []) -> Dictionary:
	return {"id":StringName("annual-awards:%d"%year),"year":year,"cycle":cycle,"nominations":nominations,"wins":wins,"fans":10*nominations+40*wins,"awareness":5*wins,"before":before}

func _run() -> void:
	var fan := StudioFanbase.create(0,Clock.fresh())
	fan = StudioFanbase.plan(fan,{},{},1)
	var granted := fan.duplicate(true)
	granted.fans = 50
	granted.annual_awards = [receipt(1980,1)]
	var codec := CheckpointCodec.new()
	codec.encode(granted,StudioFanbase.schema())
	check_receipt(codec.error.is_empty(),"Optional award receipts fit Fan typed schema")
	check_receipt(StudioFanbase.validate(granted,{},{},1),"Fan replay applies chronological award grant")
	if FileAccess.file_exists("res://scripts/awards/award_receipts.gd"):
		var awards = load("res://scripts/awards/award_receipts.gd")
		if awards != null:
			verify_helpers(awards,fan)
			verify_checkpoint(awards)
	print("AWARD_RECEIPTS checks=%d failures=%d"%[receipt_checks,failures])
	quit(0 if failures==0 else 1)

func verify_helpers(awards: Script, fan: Dictionary) -> void:
	var before := fan.duplicate(true)
	var row := receipt(1980,1,7,7)
	var next: Dictionary = awards.plan(fan,row)
	check_receipt(next.get("fans",-1)==350 and fan==before,"Seven wins stack 350 Fans without mutating input")
	check_receipt(awards.expected_awareness(next)=={&"annual-awards:1980":35},"Seven wins bank 35 Awareness")
	check_receipt(awards.plan(fan,receipt(1980,1,17,7)).get("fans",-1)==450,"Multiple nominated games stack entries without a seven-nomination cap")
	check_receipt(awards.plan(next,row).is_empty(),"Duplicate year never grants twice")
	check_receipt(awards.plan(fan,receipt(1980,0)).is_empty(),"Award cycle must equal current owner cycle")
	for key in ["year","cycle","nominations","wins","fans","awareness"]:
		var broken := row.duplicate(true)
		broken[key] = -1
		check_receipt(awards.plan(fan,broken).is_empty(),"Reject negative "+key)
	for key in ["fans","awareness","id"]:
		var broken := row.duplicate(true)
		broken[key] = 1 if key!="id" else &"wrong"
		check_receipt(awards.plan(fan,broken).is_empty(),"Reject inconsistent "+key)
	check_receipt(awards.plan(fan,receipt(1980,1,1,2)).is_empty(),"Wins cannot exceed nominations")
	for field in ["nominations","wins"]:
		var broken := row.duplicate(true)
		broken[field] = 9223372036854775807
		check_receipt(awards.plan(fan,broken).is_empty(),"Reject rate multiplication overflow "+field)
	for value in [[],[&"unknown"],[&"duplicate",&"duplicate"],["not-native-id"]]:
		var broken := row.duplicate(true)
		broken.before = value
		if value.is_empty(): broken.nominations=7.0
		check_receipt(awards.plan(fan,broken).is_empty(),"Reject invalid native receipt/pre-award IDs "+str(value))
	var overflow := fan.duplicate(true)
	overflow.fans = 9223372036854775807
	check_receipt(awards.plan(overflow,row).is_empty(),"Fan addition overflow rejects atomically")
	var no_win: Dictionary = awards.plan(fan,receipt(1980,1,1,0))
	check_receipt(no_win.get("fans",-1)==10 and awards.expected_awareness(no_win).is_empty(),"Nomination-only grant has no Promotion map entry")
	var metadata := {&"old":{"release_cycle":0},&"before":{"release_cycle":1},&"after":{"release_cycle":1},&"later":{"release_cycle":2}}
	row = receipt(1980,1,1,1,[&"before"])
	check_receipt(awards.next_release(row,metadata)==&"after","Same-cycle pre-award release cannot consume award bank")
	metadata.erase(&"after")
	check_receipt(awards.next_release(row,metadata)==&"later","Later-cycle successful release consumes bank")
	metadata.erase(&"later")
	check_receipt(awards.next_release(row,metadata)==&"","Bank remains pending without future launch")
	var empty := fan.duplicate(true)
	empty.annual_awards = []
	check_receipt(not StudioFanbase.validate(empty,{},{},1),"Empty optional receipt array is noncanonical")
	check_receipt(StudioFanbase.validate(fan,{},{},1),"No-award Fan replay remains exact")
	var codec := CheckpointCodec.new()
	var old_shape: Variant = codec.encode(fan,StudioFanbase.schema().one_of[1])
	check_receipt(JSON.stringify(codec.encode(fan,StudioFanbase.schema()))==JSON.stringify(old_shape),"No-award encoded Fan DTO bytes remain unchanged")
	var second_year := StudioFanbase.plan(next,{},{},2)
	second_year = awards.plan(second_year,receipt(1981,2,1,0))
	check_receipt(second_year.get("fans",-1)==360 and StudioFanbase.validate(second_year,{},{},2),"Two chronological years replay without inflating monthly recruitment")
	var wrong_order := second_year.duplicate(true)
	wrong_order.annual_awards.reverse()
	check_receipt(not StudioFanbase.validate(wrong_order,{},{},2),"Reject reordered annual receipts")

func verify_checkpoint(awards: Script) -> void:
	var run := fan_run()
	check_receipt(run.complete_productive_action(),"Advance owner to award cycle")
	var first := fan_project(run,5.0,"Before award")
	check_receipt(run.register_release(first),"Real same-cycle pre-award launch")
	check_receipt(awards.plan(run._fanbase,receipt(1980,1)).is_empty(),"Missing committed same-cycle before ID rejects preflight")
	var committed_before: Array[StringName] = [first.get_release_id()]
	var row := receipt(1980,1,1,1,committed_before)
	var next: Dictionary = awards.plan(run._fanbase,row)
	check_receipt(not next.is_empty(),"Award preflights real launch ledger")
	if next.is_empty(): return
	run._fanbase = next
	check_receipt(StudioFanbase.validate(run._fanbase,run._released_games,run._release_metadata,1),"Native typed before-ID array replays before codec conversion")
	run._promotion_awards.merge(awards.expected_awareness(next))
	var adapter := StudioCheckpoint.new()
	var payload := adapter.capture(run)
	check_receipt(not payload.is_empty(),"Award checkpoint validates before next release: "+adapter.error)
	check_receipt(not run.register_release(ProjectState.new(30)) and run.get_pending_promotion()==5,"Failed release preserves award bank")
	var later := fan_project(run,5.0,"After award")
	check_receipt(later.get_awareness_result().get_promotion_awards()=={&"annual-awards:1980":5},"Next preview includes award Awareness")
	check_receipt(run.register_release(later) and run.get_pending_promotion()==0,"Successful same-cycle release consumes bank")
	payload = adapter.capture(run)
	check_receipt(not payload.is_empty(),"Post-award same-cycle checkpoint validates: "+adapter.error)
	if payload.is_empty(): return
	var restored := adapter.hydrate(payload)
	check_receipt(restored!=null and adapter.capture(restored)==payload,"Award checkpoint cold hydrate preserves exact DTO")
	for mutation in ["before","consumption","missing-bank","extra-bank"]:
		var malformed := payload.duplicate(true)
		match mutation:
			"before": malformed.run.fanbase.annual_awards[0].before=[]
			"consumption": malformed.run.promotion_consumed[0].value=String(first.get_release_id())
			"missing-bank": malformed.run.promotion_awards=[]
			"extra-bank": malformed.run.promotion_awards.append({"key":"annual-awards:1981","value":"5"})
		check_receipt(adapter.hydrate(malformed)==null,"Reject forged award "+mutation)
	for i in range(4): check_receipt(run.complete_productive_action(),"Post-award monthly replay cycle")
	check_receipt(not adapter.capture(run).is_empty(),"Award gifts stay outside monthly gross gained journal: "+adapter.error)
	var gained := 0
	for month: Dictionary in run._fanbase.months: gained+=month.gained
	check_receipt(gained==0 and run.get_fans()==50,"Neutral monthly Fans contain none of the 50 award gift")
	# Owner DTO accounting fixture: year legality against world Clock belongs to
	# the global ledger. Three receipts must still count as zero Contracts.
	for year in [1981,1982]:
		check_receipt(run.complete_productive_action(),"Advance isolated multi-receipt owner fixture")
		var annual: Dictionary = awards.plan(run._fanbase,receipt(year,run.get_completed_run_cycles()))
		check_receipt(not annual.is_empty(),"Preflight additional chronological owner receipt")
		run._fanbase=annual
		run._promotion_awards.merge(awards.expected_awareness(annual))
	check_receipt(not adapter.capture(run).is_empty() and not run.get_unlocked_publisher_ids().has(PublisherCatalog.STARWAVE),"Three annual wins do not qualify as three Starwave Contract completions: "+adapter.error)
	var broken := payload.duplicate(true)
	broken.run.fanbase.annual_awards[0].fans="51"
	check_receipt(adapter.hydrate(broken)==null,"Reject altered persisted grant")
