extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Trial := preload("res://scripts/market/rival_trial.gd")
const WorldCodec := preload("res://scripts/market/rival_world_checkpoint.gd")
const Legacy := preload("res://scripts/legacy/legacy_world.gd")
const Ownership := preload("res://scripts/legacy/ownership_book.gd")
const Founder := preload("res://scripts/legacy/founder_profile.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var failures := 0
var checks := 0

func check(value: bool, label: String) -> void:
	checks+=1
	if value: print("PASS: ",label)
	else: failures+=1;push_error("FAIL: "+label)

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	create_timer(90).timeout.connect(func(): quit(2))
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var player: RefCounted=Factory.create_fresh_session({"schema_version":1,"studio_id":"legacy-player","studio_name":"Legacy Player","specialty":"action","traits":[],"seed":"4417"},catalog)
	var world := Trial.create_world(player.run,catalog)
	var books := {}
	for id in Legacy.runs(world): books[id]=Ownership.create(id,{"founder:tester":1000000})
	check(Legacy.initialize(world,Founder.create("tester","legacy-player",0),books),"Explicit fixture formation initializes without a gameplay default")
	var buyer := "incumbent-arcade-foundry"
	var issue := {"studio_id":"legacy-player","tx_id":"issue-1","expected_revision":0,"buyer":"studio:"+buyer,"investment_cents":10000,"pre_money_cents":1000000}
	check(Legacy.offer(world,"primary",issue),"Positive-priced primary offer stored")
	var before := Replay.digest(world.legacy)
	check(not Legacy.commit(world,"issue-1",true) and Replay.digest(world.legacy)==before,"Unconsented offer cannot move cash or shares")
	check(Legacy.consent(world,"issue-1","founder:tester") and Legacy.consent(world,"issue-1","studio:"+buyer),"Actual holder and buyer consent recorded")
	var cash: int = world.player.get_cash_cents()+world.studios[StringName(buyer)].run.get_cash_cents()
	var rng := world.player.random_streams.snapshot()
	var observations: Array[bool]=[]
	var observer := func(): observations.append(Legacy.valid(world.legacy,world) and not Legacy.commit(world,"issue-1",true))
	world.player.cash_changed.connect(observer)
	check(not Legacy.commit(world,"issue-1"),"Missing safe Studio boundary rejects")
	check(Legacy.commit(world,"issue-1",true),"Primary issuance commits finance and shares atomically")
	world.player.cash_changed.disconnect(observer)
	check(observations==[true],"Observers see both cash legs and shares; reentrant commit rejects")
	check(world.player.get_cash_cents()+world.studios[StringName(buyer)].run.get_cash_cents()==cash and world.cycle==0 and world.player.random_streams.snapshot()==rng,"Conserved exact cash; zero cycles and RNG draws")
	check(world.legacy.books["legacy-player"].issued_units==1010000 and world.legacy.books["legacy-player"].holders["studio:"+buyer]==10000,"Exact primary issuance and dilution")
	check(world.player.get_studio_finance_report().rows[0].net_profit_cents==0 and world.studios[StringName(buyer)].run.get_studio_finance_report().rows[0].net_profit_cents==0,"Capital is excluded from operating profit and credit inputs")
	check(not Legacy.commit(world,"issue-1",true),"Duplicate commit inert")
	var sale := {"studio_id":"legacy-player","tx_id":"sale-1","expected_revision":1,"buyer":"studio:incumbent-wayfinder-works","seller":"studio:"+buyer,"units":5000,"price_cents":12345}
	check(Legacy.offer(world,"secondary",sale),"Corporate secondary sale proposed")
	check(Legacy.consent(world,"sale-1",sale.buyer) and Legacy.consent(world,"sale-1",sale.seller),"Secondary buyer and seller consent")
	var target_cash := world.player.get_cash_cents()
	check(Legacy.commit(world,"sale-1",true) and world.player.get_cash_cents()==target_cash,"Secondary proceeds go to seller, never target")
	var all_before := Replay.digest(world.legacy)
	var poor := sale.duplicate(true);poor.tx_id="poor";poor.expected_revision=2;poor.units=1;poor.price_cents=90000000
	check(Legacy.offer(world,"secondary",poor),"Unfunded quote can be inspected")
	Legacy.consent(world,"poor",poor.buyer);Legacy.consent(world,"poor",poor.seller)
	var unfunded := Replay.digest(world.legacy)
	check(not Legacy.commit(world,"poor",true) and Replay.digest(world.legacy)==unfunded,"Insufficient funds reject without partial settlement")
	var saved_player := StudioCheckpoint.new().capture(world.player)
	var codec := WorldCodec.new()
	var saved_world := codec.capture(world)
	check(not saved_player.is_empty() and not saved_world.is_empty(),"Whole world including capital journals checkpoints")
	var corrupt := saved_world.duplicate(true)
	corrupt.legacy.events[0].cash_legs[0].delta_cents.integer="999"
	check(codec.restore(corrupt,saved_player,StudioCheckpoint.new().hydrate(saved_player),catalog)==null,"Mismatched ownership cash event cannot restore")
	corrupt=saved_world.duplicate(true)
	corrupt.legacy.events[0].cash_legs[0].delta_cents.integer="invalid"
	check(codec.restore(corrupt,saved_player,StudioCheckpoint.new().hydrate(saved_player),catalog)==null,"Malformed exact integer cannot restore as a sentinel")
	var restored_player := StudioCheckpoint.new().hydrate(JSON.parse_string(JSON.stringify(saved_player)))
	var restored := codec.restore(JSON.parse_string(JSON.stringify(saved_world)),saved_player,restored_player,catalog)
	check(restored!=null,"Whole-world exact integer codec restores "+codec.error)
	if restored==null: quit(1);return
	check(restored.legacy==world.legacy and restored.player.get_studio_finance_snapshot()==world.player.get_studio_finance_snapshot(),"Ownership, consents, finance and external settlement restore exactly")
	var former_cash := world.player.get_cash_cents()
	var former_state := StudioCheckpoint.new().capture(world.player)
	check(not Legacy.handoff(world,&"incumbent-wayfinder-works",false),"Active phase cannot hand off")
	check(Legacy.handoff(world,&"incumbent-wayfinder-works",true),"Safe Studio handoff chooses one manual operator")
	check(world.player._bank_run_id==&"incumbent-wayfinder-works" and world.studios.has(&"legacy-player") and world.studios[&"legacy-player"].run.get_cash_cents()==former_cash,"Former Studio retains cash and becomes autonomous")
	check(StudioCheckpoint.new().capture(world.studios[&"legacy-player"].run)==former_state,"Handoff retains every former Studio finance, pool, employee, history and RNG field")
	check(world.player.complete_productive_action(Callable(),0,0),"New operator commits a productive boundary")
	check(world.advance_committed_player_cycle(Trial.policies(world),Trial.ZERO_STEPS).ok,"Former Studio advances through legal AI commands")
	check(world.studios[&"legacy-player"].phase()!=&"studio" and world.studios[&"legacy-player"].run.get_completed_run_cycles()==1,"Old Studio continues development on shared calendar")
	var moved_player := StudioCheckpoint.new().capture(world.player)
	var moved_world := codec.capture(world)
	check(not moved_world.is_empty(),"Post-handoff active former Studio captures")
	var cold := codec.restore(moved_world,moved_player,StudioCheckpoint.new().hydrate(moved_player),catalog)
	check(cold!=null and cold.legacy.founder.active_studio_id==str(world.player._bank_run_id),"Post-handoff Continue preserves sole operator "+codec.error)
	# A real disk envelope is consumed by the separate fresh-process probe.
	var path := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"player":moved_player,"world":moved_world,"digest":Replay.digest(codec.capture(cold))},"\t"))
	print("Legacy world: %d checks, %d failures"%[checks,failures]);quit(failures)
