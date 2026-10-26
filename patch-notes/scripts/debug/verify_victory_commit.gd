extends SceneTree
const Factory:=preload("res://scripts/simulation/run_factory.gd")
const World:=preload("res://scripts/market/rival_world.gd")
const Codec:=preload("res://scripts/market/rival_world_checkpoint.gd")
const Legacy:=preload("res://scripts/legacy/legacy_world.gd")
const Founder:=preload("res://scripts/legacy/founder_profile.gd")
const Ownership:=preload("res://scripts/legacy/ownership_book.gd")
const Replay:=preload("res://scripts/simulation/development_replay.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error("Victory commit: "+label)
func _initialize() -> void:
	await process_frame
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var studios: Dictionary={}
	var runs: Array=[]
	var books: Dictionary={}
	for index in 11:
		var id: String="root" if index==0 else "sub"+str(index)
		var session: RefCounted=Factory.create_fresh_session({"schema_version":1,"studio_id":id,"studio_name":id,"specialty":"action","traits":[],"seed":str(7000+index)},catalog)
		runs.append(session)
		if index>0: studios[StringName(id)]=session
		books[id]=Ownership.create(id,{("founder:tester" if index==0 else "studio:root" if index<10 else "outside:seller"):1000000})
	var world: RefCounted=World.new()
	check(world.initialize(runs[0].run,studios),"explicit eleven-Studio in-memory fixture")
	check(Legacy.initialize(world,Founder.create("tester","root",0),books),"nine controlled subsidiaries at explicit formation")
	check(world.legacy.victory.claims.is_empty(),"formation grants no achievement")
	var terms: Dictionary={"studio_id":"sub10","tx_id":"tenth","expected_revision":0,"buyer":"studio:root","seller":"outside:seller","units":600001,"price_cents":1000}
	check(Legacy.offer(world,"secondary",terms),"tenth acquisition quote")
	check(world.legacy.victory.claims.is_empty(),"quote grants no achievement")
	var before:=Replay.digest(world.legacy)
	check(not Legacy.commit(world,"tenth",true) and Replay.digest(world.legacy)==before,"unconsented acquisition is atomic")
	check(Legacy.consent(world,"tenth","studio:root") and Legacy.consent(world,"tenth","outside:seller"),"both actual participants consent")
	var cash: int=world.player.get_cash_cents()
	var rng: Dictionary=world.player.random_streams.snapshot()
	var observations: Array=[]
	var observer:=func(): observations.append(Legacy.valid(world.legacy,world) and world.legacy.victory.claims.size()==1)
	world.player.cash_changed.connect(observer)
	check(Legacy.commit(world,"tenth",true),"atomic finance/ownership transaction awards tenth subsidiary")
	world.player.cash_changed.disconnect(observer)
	check(observations==[true] and world.player.get_cash_cents()==cash-1000 and world.player.random_streams.snapshot()==rng and world.cycle==0,"observers see settled cash/shares/claim once with zero cycles/RNG")
	check(world.legacy.victory.claims[0].studio_ids.size()==10 and world.legacy.founder.milestone_ids==["victory:subsidiaries"],"exact threshold and once-only milestone")
	before=Replay.digest(world.legacy)
	check(not Legacy.commit(world,"tenth",true) and Replay.digest(world.legacy)==before,"duplicate cannot pay or award again")
	var decoded:=Legacy.decode(JSON.parse_string(JSON.stringify(Legacy.encode(world.legacy))))
	check(decoded==world.legacy and Legacy.valid(decoded,world),"awarded claim exact integer serialization")
	var corrupt:=decoded.duplicate(true);corrupt.version=2.0
	check(not Legacy.valid(corrupt,world),"float version rejected")
	corrupt=decoded.duplicate(true);corrupt.victory.schema_version=1.0
	check(not Legacy.valid(corrupt,world),"float victory schema rejected")
	corrupt=decoded.duplicate(true);corrupt.victory.claims[0].books.phantom=Ownership.create("phantom",{"outside:phantom":1000000})
	check(not Legacy.valid(corrupt,world),"frozen proof cannot invent a Studio")
	corrupt=decoded.duplicate(true);corrupt.victory.claims[0].books.root.transaction_ids.append("future")
	check(not Legacy.valid(corrupt,world),"frozen proof cannot contain future/uncommitted transactions")
	check(Codec.new().capture(world).is_empty(),"unchanged eight-rival capacity explicitly prevents shipping this fixture")
	print("VICTORY_COMMIT checks=%d failures=%d"%[checks,failures]);quit(failures)
