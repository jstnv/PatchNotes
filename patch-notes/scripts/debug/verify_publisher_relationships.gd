extends SceneTree

const Ledger := preload("res://scripts/contracts/publisher_relationships.gd")
const Rules := preload("res://scripts/contracts/publisher_relationship_rules.gd")
var checks := 0
var failures := 0
var facts := {}

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
	else: print("PASS: " + label)

func fixture(event_request: Dictionary) -> Dictionary:
	if not facts.has(event_request.source_id): return {}
	var fact: Dictionary = facts[event_request.source_id]
	if fact.request != event_request: return {}
	return fact.amounts.duplicate(true)

func request(id: StringName, publisher: StringName, cycle: int, rep: int, inv: int) -> Dictionary:
	var event := {"event_id":StringName("event:"+str(id)),"source_id":id,"publisher_id":publisher,"kind":&"fixture_credit_v1","cycle":cycle}
	facts[id] = {"request":event.duplicate(true),"amounts":{"reputation_bp":rep,"investment_bp":inv}}
	return event

func pure_checks() -> void:
	var empty := Ledger.create(&"owner-a")
	var a := request(&"first",&"sidestreet",1,6000,1500)
	var p := Ledger.plan(empty,&"owner-a",a,1,fixture)
	check(not p.is_empty() and p.changed and empty.events.is_empty(),"pure plan leaves original empty")
	if p.is_empty(): return
	var one: Dictionary = p.ledger
	var retry := Ledger.plan(one,&"owner-a",a,1,fixture)
	check(not retry.is_empty() and not retry.changed and retry.ledger == one,"exact retry is no-op")
	var wrong := a.duplicate(true); wrong.publisher_id = &"neon_circuit"
	check(Ledger.plan(one,&"owner-a",wrong,1,fixture).is_empty(),"event ID cannot change publisher")
	wrong = a.duplicate(true); wrong.event_id = &"different-event"
	check(Ledger.plan(one,&"owner-a",wrong,1,fixture).is_empty(),"new ID cannot credit same source/kind twice")
	var b := request(&"second",&"sidestreet",2,6000,10000)
	var two := Ledger.plan(one,&"owner-a",b,2,fixture)
	check(two.event.credited_reputation_bp == 4000 and two.event.credited_investment_bp == 8500,"independent clipping at candidate representation cap")
	var c := request(&"third",&"sidestreet",3,100,100)
	var three := Ledger.plan(two.ledger,&"owner-a",c,3,fixture)
	check(three.changed and three.event.credited_reputation_bp == 0 and three.event.credited_investment_bp == 0,"qualifying event retained at cap with zero actual credit")
	var other := request(&"fourth",&"neon_circuit",4,250,500)
	var four := Ledger.plan(three.ledger,&"owner-a",other,4,fixture)
	var totals := Ledger.reconstruct(four.ledger,&"owner-a",4,fixture)
	check(totals[&"sidestreet"].reputation_bp == 10000 and totals[&"neon_circuit"].reputation_bp == 250 and totals[&"ironclad"].investment_bp == 0,"publishers remain isolated")
	check(Ledger.reconstruct(four.ledger,&"owner-b",4,fixture).is_empty(),"another Studio cannot hydrate owner-a history")
	check(not Ledger.plan(Ledger.create(&"owner-b"),&"owner-b",a,1,fixture).is_empty(),"same source text in separate Studio is independent")
	for field in ["ordinal","requested_reputation_bp","credited_reputation_bp","requested_investment_bp","credited_investment_bp"]:
		var forged: Dictionary = four.ledger.duplicate(true); forged.events[0][field] += 1
		check(Ledger.reconstruct(forged,&"owner-a",4,fixture).is_empty(),"forged "+field+" rejects")
	var bad: Dictionary = four.ledger.duplicate(true); bad.events.reverse()
	check(Ledger.reconstruct(bad,&"owner-a",4,fixture).is_empty(),"reordered history rejects")
	bad = four.ledger.duplicate(true); bad.events.append(bad.events[0].duplicate(true))
	check(Ledger.reconstruct(bad,&"owner-a",4,fixture).is_empty(),"duplicate history rejects")
	check(Ledger.reconstruct(four.ledger,&"owner-a",3,fixture).is_empty(),"future-cycle event rejects")
	check(Ledger.plan(one,&"owner-a",request(&"backdated",&"sidestreet",0,1,1),1,fixture).is_empty(),"backdated append rejects")
	for amounts: Array in [[-1,1],[1,-1],[10001,0],[0,10001]]:
		var invalid := request(StringName("bad:"+str(amounts)),&"crown_quill",4,amounts[0],amounts[1])
		check(Ledger.plan(four.ledger,&"owner-a",invalid,4,fixture).is_empty(),"invalid credit bound rejects "+str(amounts))
	var float_request := a.duplicate(true); float_request.cycle = 1.0
	check(Ledger.plan(empty,&"owner-a",float_request,1,fixture).is_empty(),"float counter rejects")
	var codec := CheckpointCodec.new()
	var encoded: Variant = codec.encode(four.ledger,Ledger.schema())
	var decoded: Variant = codec.decode(JSON.parse_string(JSON.stringify(encoded)),Ledger.schema())
	check(codec.error.is_empty() and decoded == four.ledger and Ledger.reconstruct(decoded,&"owner-a",4,fixture) == totals,"nonzero fixture typed JSON roundtrip")
	var production := func(event: Dictionary) -> Dictionary: return Rules.resolve({},event)
	check(Ledger.reconstruct(four.ledger,&"owner-a",4,production).is_empty(),"fixture credits rejected by production resolver")
	check(Ledger.plan(empty,&"owner-a",a,1,production).is_empty(),"P1 enables no award producer")
	p.event.credited_reputation_bp = 99
	check(one.events[0].credited_reputation_bp == 6000,"detached event cannot mutate planned history")
	totals[&"neon_circuit"].reputation_bp = 999
	check(Ledger.reconstruct(four.ledger,&"owner-a",4,fixture)[&"neon_circuit"].reputation_bp == 250,"observation cannot mutate history")

func native_checks() -> void:
	var run := RunState.new(); run.initialize_cash(0)
	check(run.create_studio_with_traits("P1 native",&"action",[]),"legal Studio creation")
	var adapter := StudioCheckpoint.new()
	var saved := adapter.capture(run)
	check(not saved.is_empty(),"new Studio checkpoint captures: "+adapter.error)
	check(run.get_publisher_relationships().size() == 5 and run._publisher_relationships.events.is_empty(),"new Studio has five zero relationships and no events")
	var observed := run.get_publisher_relationships(); observed[&"sidestreet"].reputation_bp = 999
	check(run.get_publisher_relationships()[&"sidestreet"].reputation_bp == 0,"RunState observation detached")
	var rejected := request(&"runtime",&"sidestreet",0,1000,1000)
	check(not run.commit_publisher_relationship_event(rejected) and adapter.capture(run) == saved,"disabled event preserves full runtime and RNG")
	run._relationship_commit_in_progress = true
	check(not run.commit_publisher_relationship_event(rejected),"reentrant producer rejects")
	run._relationship_commit_in_progress = false
	run.checkpoint_mutations_allowed = false
	check(not run.commit_publisher_relationship_event(rejected),"checkpoint mutation fence preserved")
	run.checkpoint_mutations_allowed = true
	var restored := adapter.hydrate(saved)
	check(restored != null and adapter.capture(restored) == saved,"native full checkpoint roundtrip exact")
	var wrong := saved.duplicate(true); wrong.run.publisher_relationships.owner = "another-studio"
	check(adapter.hydrate(wrong) == null and adapter.capture(run) == saved,"wrong owner rejects without damaging live Studio")
	wrong = saved.duplicate(true); wrong.run.publisher_relationships.events = [{"unexpected":"reward"}]
	check(adapter.hydrate(wrong) == null,"malformed event payload rejects")
	wrong = saved.duplicate(true); wrong.run.erase("publisher_relationships")
	check(adapter.hydrate(wrong) == null,"current revision cannot omit relationship ledger")
	wrong = saved.duplicate(true); wrong.content_revision = "unknown"
	check(adapter.hydrate(wrong) == null,"unknown content revision rejects")
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var world: RivalWorld = preload("res://scripts/market/rival_trial.gd").create_world(run,catalog)
	var world_codec: RefCounted = load("res://scripts/market/rival_world_checkpoint.gd").new()
	var current: Dictionary = world_codec.capture(world)
	check(not current.is_empty(),"current world includes valid Studio relationship records")
	var mismatched := current.duplicate(true)
	mismatched.source_identity = "6a54626db35988186fd6a1fd7f47af9191dfb4421dc798720a0725032a75f8c1"
	check(not world_codec.validate(mismatched,saved).is_empty(),"known old source cannot claim relationship schema")
	mismatched = current.duplicate(true)
	mismatched.studios[0].run = StudioCheckpoint.RelationshipPrevious.new().capture(world.studios[StringName(mismatched.studios[0].id)].run)
	check(not world_codec.validate(mismatched,saved).is_empty(),"current source cannot mix predecessor and current Studio schemas")
	# Save the valid generation after the rejection checks for a separate process.
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2 and args[0] == "write":
		var file := FileAccess.open(args[1],FileAccess.WRITE)
		check(file != null,"isolated fixture file opens")
		if file != null: file.store_string(JSON.stringify(saved)); file.close()

func file_checks(args: PackedStringArray) -> void:
	var input: Variant = JSON.parse_string(FileAccess.get_file_as_string(args[1]))
	check(input is Dictionary,"retained input parses")
	if not input is Dictionary: return
	var payload: Dictionary = input.get("studio_payload",input)
	var before := payload.duplicate(true)
	var adapter := StudioCheckpoint.new()
	if args[0] == "cold":
		var run := adapter.hydrate(payload)
		check(run != null and adapter.capture(run) == payload,"fresh-process current native restore exact: "+adapter.error)
		if run != null:
			check(run.get_publisher_relationships()[&"sidestreet"].reputation_bp == 0,"cold no reward minted")
	else:
		var upgraded := adapter.upgrade_relationship_predecessor(payload)
		check(not upgraded.is_empty(),"exact predecessor migrates: "+adapter.error)
		if upgraded.is_empty(): return
		var projected := upgraded.duplicate(true)
		projected.run.erase("publisher_relationships"); projected.content_revision = payload.content_revision
		check(projected == payload and payload == before,"migration preserves every preexisting encoded field and input bytes")
		var run := adapter.hydrate(payload)
		check(run != null and adapter.capture(run) == upgraded,"old native payload hydrates directly and captures upgraded shape")
		if run != null: check(run._publisher_relationships.events.is_empty(),"migration does not backfill completed Contracts")
		var malformed := payload.duplicate(true); malformed.run.cash_cents = "999999"
		check(adapter.upgrade_relationship_predecessor(malformed).is_empty(),"old accounting corruption fails original validator")
		malformed = payload.duplicate(true); malformed.run.publisher_relationships = upgraded.run.publisher_relationships
		check(adapter.upgrade_relationship_predecessor(malformed).is_empty(),"mixed old/new shape rejects")
		malformed = payload.duplicate(true); malformed.content_revision = "unknown"
		check(adapter.upgrade_relationship_predecessor(malformed).is_empty(),"unknown predecessor rejects")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2 and args[0] in ["cold","migrate"]:
		file_checks(args)
	else:
		pure_checks()
		native_checks()
	print("P1 checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
