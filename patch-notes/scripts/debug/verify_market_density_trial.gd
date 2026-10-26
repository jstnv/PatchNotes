## Private active-market density trial. Ordinary world, sales and project commands.
extends SceneTree

const Factory := preload("res://scripts/simulation/run_factory.gd")
const Trial := preload("res://scripts/market/rival_trial.gd")
const Market := preload("res://scripts/market/market_transaction_trial.gd")
const Codec := preload("res://scripts/market/rival_world_checkpoint.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")

var checks:=0
var failures:=0

# Freeze the historical two-hand timing only for this market settlement
# fixture. Live Design/Alpha rivals now exhaust legal visible Features.
static func fixed_market_choice(view: Dictionary, genre: String, label: String, enabled: bool) -> Dictionary:
	if view.phase in [&"design",&"alpha"] and view.development.get("active",false) and not view.development.get("finalized",false) and not view.development.get("confirmation_pending",false) and view.development.get("hand_revision",0)>=3 and view.development.get("can_exit",false):
		return Trial._development(view,&"request_exit")
	return Trial.choose(view,genre,label,enabled,enabled)

static func fixed_market_policies(world: RivalWorld) -> Dictionary:
	var result: Dictionary = {}
	for id: StringName in world.studios:
		var session: RefCounted = world.studios[id]
		var genre: String = str(session.run.get_studio_specialty())
		var label: String = session.run.get_studio_name()
		var enabled: bool = Trial.uses_synergy_trial(id,session.run)
		result[id] = func(view: Dictionary) -> Dictionary: return fixed_market_choice(view,genre,label,enabled)
	return result

func expect(ok: bool, label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error("MARKET_TRANSACTION "+label)

func _initialize() -> void:
	await process_frame
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var path:="user://market-transaction-cold.json"
	if FileAccess.file_exists(path):
		var saved: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
		expect(saved is Dictionary,"cold artifact readable")
		if not saved is Dictionary: quit(1);return
		var player: RunState=StudioCheckpoint.new().hydrate(saved.player)
		expect(player!=null,"cold player restore")
		var cold_codec:=Codec.new()
		var cold_world: RivalWorld=cold_codec.restore(saved.world,saved.player,player,catalog)
		expect(cold_world!=null,"cold world restore "+cold_codec.error)
		if cold_world!=null:
			expect(cold_world.market_snapshot.id==saved.market.id,"cold snapshot identity exact")
			expect(Replay.digest(cold_codec.capture(cold_world))==saved.world_digest,"cold checkpoint exact")
			expect(cold_world.cycle==10 and cold_world.market_snapshot.cycle_start==10,"cold month boundary")
			var active_project: ProjectState=cold_world.studios[&"incumbent-arcade-foundry"].development.project
			expect(active_project.get_market_snapshot_id()==saved.frozen_source and active_project.get_market_snapshot_id()!=cold_world.market_snapshot.id,"cold active project target source frozen")
			var action_id: StringName=cold_world.studios[&"incumbent-arcade-foundry"].run.get_released_game_ids()[0]
			var sales: Dictionary=cold_world.studios[&"incumbent-arcade-foundry"].run.get_released_game_sales(action_id)
			expect(sales.market_factors[1].factor_bp==9700 and sales.market_factors[2].factor_bp==9700 and sales.market_factors[2].snapshot_id==saved.market.id,"cold age-month factors exact")
		print("MARKET_TRANSACTION_COLD checks=%d failures=%d"%[checks,failures])
		quit(0 if failures==0 else 1)
		return
	var session: RefCounted=Factory.create_fresh_session({"schema_version":1,"studio_id":"market-player","studio_name":"Market Player","specialty":"action","traits":[],"seed":"4417"},catalog)
	expect(session!=null,"fresh legal player")
	if session==null: quit(1);return
	var world: RivalWorld=Trial.create_world(session.run,catalog)
	expect(world!=null,"fresh two-rival world")
	if world==null: quit(1);return
	var policies:=fixed_market_policies(world)
	var codec:=Codec.new()
	var first_release_cycle:=-1
	var at8: Dictionary={}
	var frozen_source:=""
	for step in range(10):
		var target:=world.cycle+1
		var plan:=Market.preview(world,target)
		expect(Market.valid(plan),"pure preview cycle "+str(target))
		if plan.is_empty(): break
		var before:=Replay.digest({"player":Replay.state(session),"snapshot":world.market_snapshot,"checkpoint":codec.capture(world)})
		expect(not session.run.complete_productive_action(Callable(),0,target),"stale player action rejects")
		expect(before==Replay.digest({"player":Replay.state(session),"snapshot":world.market_snapshot,"checkpoint":codec.capture(world)}),"rejected action atomic")
		expect(session.run.complete_productive_action(Callable(),0,target-1),"legal player cycle")
		expect(session.run._market_committed_candidate==plan,"player committed exact preflight input")
		var report: Dictionary=world.advance_committed_player_cycle(policies,Trial.ZERO_STEPS)
		expect(report.get("ok",false),"rival advance cycle "+str(target))
		if not report.get("ok",false): break
		expect(world.market_snapshot==plan,"rivals use same immutable snapshot")
		expect(world.cycle==target,"one shared cycle")
		expect(not codec.capture(world).is_empty(),"checkpoint cycle "+str(target)+" "+codec.error)
		if first_release_cycle<0 and not world.live_releases.is_empty(): first_release_cycle=target
		if target==8:
			var active_project: ProjectState=world.studios[&"incumbent-arcade-foundry"].development.project
			frozen_source=active_project.get_market_snapshot_id()
			expect(frozen_source==plan.id and active_project.get_market_standards()==PrimitiveReviewCalculator.GENRE_TARGETS[&"action"],"second project freezes month-8 Core standards")
			var released_id: StringName=world.studios[&"incumbent-arcade-foundry"].run.get_released_game_ids()[0]
			at8=world.studios[&"incumbent-arcade-foundry"].run.get_released_game_sales(released_id)
			expect(at8.market_factors[1].factor_bp==9700 and at8.market_factors[1].snapshot_id==plan.id,"age1 factor first half frozen")
		if target==9:
			var released_id: StringName=world.studios[&"incumbent-arcade-foundry"].run.get_released_game_ids()[0]
			var at9: Dictionary=world.studios[&"incumbent-arcade-foundry"].run.get_released_game_sales(released_id)
			var age1_total:=PrimitiveMonthOneSalesRevenueCalculator._scaled_floor(at9.total_units,9700,10000)
			expect(at9.market_factors.size()==1 and at9.market_factors[1].snapshot_id==at8.market_factors[1].snapshot_id,"age1 second half reuses factor")
			expect(at9.earned_units==age1_total,"age1 second half exact units")
		if target==10:
			var active_project: ProjectState=world.studios[&"incumbent-arcade-foundry"].development.project
			expect(active_project.get_market_snapshot_id()==frozen_source and frozen_source!=plan.id,"new month does not rewrite active project targets")
		print("MARKET_TRANSACTION_CYCLE cycle=%d snapshot=%s facts=%d releases=%d"%[target,plan.id,plan.facts.size(),world.live_releases.size()])
	expect(first_release_cycle==7,"legal zero-cycle releases at cycle 7")
	expect(world.cycle==10 and world.live_releases.size()==2,"ten-cycle route")
	expect(world.market_snapshot.facts.size()==2,"next-month snapshot admits prior releases")
	if world.market_snapshot.facts.size()==2:
		var action_id: String=str(world.studios[&"incumbent-arcade-foundry"].run.get_released_game_ids()[0])
		var factor:=Market.sales_factor(world.market_snapshot,"incumbent-arcade-foundry",action_id,"action","fantasy")
		expect(factor.get("theme_only",-1)==1 and factor.get("genre_only",-1)==0 and factor.get("pair",-1)==0 and factor.get("factor_bp",-1)==9700,"legal Theme-only bucket")
		var sales: Dictionary=world.studios[&"incumbent-arcade-foundry"].run.get_released_game_sales(StringName(action_id))
		var control:=PrimitiveMonthOneSalesRevenueCalculator.calculate_for_total_units(sales.total_units)
		expect(at8.earned_units==PrimitiveMonthOneSalesRevenueCalculator._scaled_floor(control.get_cumulative_units()[0],9700,10000),"first earning units use frozen factor")
		expect(sales.market_factors.size()==2 and sales.market_factors[1].snapshot_id==at8.market_factors[1].snapshot_id and sales.market_factors[2].snapshot_id==world.market_snapshot.id,"age2 has new month source")
		var organic:=LaterMonthSalesCalculator.month_two_organic_scaled(sales.launch_awareness)
		var month2_base:=LaterMonthSalesCalculator.monthly_units(sales.review_tenths,organic,sales.market_bp)
		var month2:=PrimitiveMonthOneSalesRevenueCalculator._scaled_floor(month2_base,9700,10000)
		expect(sales.earned_units==PrimitiveMonthOneSalesRevenueCalculator._scaled_floor(sales.total_units,9700,10000)+month2/2,"age2 first half exact cumulative units")
		expect(sales.entitlement_cents==LaterMonthSalesCalculator.net_cents_for_units(sales.earned_units),"exact cumulative entitlement cents")
		var standards: Dictionary=Market.targets(world.market_snapshot,"market-player",&"action")
		expect(standards.get("standards",[])==[42,28,42,28] and standards.get("recent_count",-1)==1 and standards.get("density_lift",-1)==2,"one real Action rival lifts future player Core targets")
		print("MARKET_DENSITY_REAL cycle=%d count=%d targets=%s"%[world.cycle,standards.get("recent_count",-1),str(standards.get("standards",[]))])
	var synthetic: Dictionary={"studio_id":"strong-other","release_id":"strong-1","release_cycle":7,"genre":"action","theme":"war","review_tenths":80,"cores_available":true,"cores":[56,26,52,26]}
	var strong: Dictionary={"version":Market.VERSION,"cycle_start":8,"facts":[synthetic],"id":""}
	strong.id=Market.identifier(8,strong.facts)
	expect(Market.valid(strong),"synthetic qualifying snapshot valid")
	expect(Market.targets(strong,"market-player",&"action").get("standards",[])==[48,28,46,28],"strong benchmark and population use maximum, not sum")
	synthetic.cores_available=false
	synthetic.cores=[]
	strong.facts=[synthetic]
	strong.id=Market.identifier(8,strong.facts)
	expect(Market.valid(strong) and Market.targets(strong,"market-player",&"action").get("standards",[])==[42,28,42,28],"missing Core counts for density only")
	var second: Dictionary=synthetic.duplicate(true)
	second.studio_id="strong-other-2"
	second.release_id="strong-2"
	strong.facts=[second,synthetic]
	strong.id=Market.identifier(8,strong.facts)
	expect(Market.valid(strong) and Market.targets(strong,"market-player",&"action").get("standards",[])==[44,30,44,30],"two real-identity rows reach density cap")
	second.studio_id="market-player"
	strong.facts=[second]
	strong.id=Market.identifier(8,strong.facts)
	expect(Market.valid(strong) and Market.targets(strong,"market-player",&"action").get("standards",[])==PrimitiveReviewCalculator.GENRE_TARGETS[&"action"],"same Studio excluded from Review pressure")
	var player_payload:=StudioCheckpoint.new().capture(session.run)
	var world_payload:=codec.capture(world)
	expect(not player_payload.is_empty() and not world_payload.is_empty(),"Studio checkpoint pair captured")
	var restored: RivalWorld=codec.restore(world_payload,player_payload,StudioCheckpoint.new().hydrate(player_payload),catalog)
	expect(restored!=null,"same-process world restore "+codec.error)
	if restored!=null: expect(restored.market_snapshot==world.market_snapshot,"restored month snapshot exact")
	var malformed:=world_payload.duplicate(true)
	if not malformed.is_empty():
		malformed.market.facts[0].review_tenths="101"
		expect(not codec.validate(malformed,player_payload).is_empty(),"tampered market row rejected")
	var forged_snapshot:=world.market_snapshot.duplicate(true)
	forged_snapshot.facts[0].review_tenths=80
	forged_snapshot.id=Market.identifier(forged_snapshot.cycle_start,forged_snapshot.facts)
	expect(Market.valid(forged_snapshot),"self-consistent forged snapshot hash")
	var forged_payload:=world_payload.duplicate(true)
	forged_payload.market=CheckpointCodec.new().encode(forged_snapshot,Codec._market_schema())
	expect(not codec.validate(forged_payload,player_payload).is_empty(),"forged valid-hash fact rejected by owner provenance")
	var output:=FileAccess.open(path,FileAccess.WRITE)
	expect(output!=null,"cold artifact opened")
	if output!=null:
		output.store_string(JSON.stringify({"player":player_payload,"world":world_payload,"market":world.market_snapshot,"world_digest":Replay.digest(world_payload),"frozen_source":frozen_source}))
		output.close()
	var begin: Dictionary=session.execute(session.command(&"begin_development",{"name":"Density Followup","genre":"action","theme":"war"}))
	expect(begin.get("ok",false),"legal player begins Action after rival snapshot")
	if begin.get("ok",false):
		expect(session.development.project.get_market_standards()==[42,28,42,28] and session.development.project.get_market_snapshot_id()==world.market_snapshot.id,"legal player project freezes density targets and source")
		expect(PrimitiveReviewCalculator.get_project_profile(session.development.project).get_standard(ProjectState.CoreScore.SOUND)==28,"Review profile reads frozen Sound standard")
		var followup: Dictionary=world.advance_committed_player_cycle(policies,Trial.ZERO_STEPS)
		expect(followup.get("ok",false) and world.cycle==11,"rivals advance after legal player begin")
	print("MARKET_TRANSACTION checks=%d failures=%d cycles=%d releases=%d"%[checks,failures,world.cycle,world.live_releases.size()])
	quit(0 if failures==0 else 1)
