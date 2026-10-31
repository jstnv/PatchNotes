extends SceneTree
const Factory=preload("res://scripts/simulation/run_factory.gd")
const Trial=preload("res://scripts/market/rival_trial.gd")
const Codec=preload("res://scripts/market/rival_world_checkpoint.gd")
const Replay=preload("res://scripts/simulation/development_replay.gd")
var checks:=0
var failures: Array=[]
var rows: Array=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func arg(prefix: String) -> String:
	for value: String in OS.get_cmdline_user_args():
		if value.begins_with(prefix):return value.trim_prefix(prefix)
	return ""
func cold_checks(world: RivalWorld,catalog: RefCounted,tick: int) -> void:
	var adapter:=StudioCheckpoint.new();var codec:=Codec.new()
	var p: Dictionary=JSON.parse_string(JSON.stringify(adapter.capture(world.player)))
	var w: Dictionary=JSON.parse_string(JSON.stringify(codec.capture(world)))
	check(not p.is_empty() and not w.is_empty(),"Valid committed world at "+str(tick))
	if p.is_empty() or w.is_empty():return
	var player:=adapter.hydrate(p);var cold:=codec.restore(w,p,player,catalog)
	check(cold!=null,"JSON cold world at "+str(tick)+": "+codec.error)
	if cold==null:return
	check(codec.capture(cold)==w and adapter.capture(player)==p,"Exact persisted world/player/counters/RNG "+str(tick))
	var a: Dictionary=Trial.policies(world);var b: Dictionary=Trial.policies(cold)
	var active:=0;var printed:=0;var spent:=0;var legacy:=0
	for id: StringName in world.studios:
		var first: RefCounted=world.studios[id];var second: RefCounted=cold.studios[id]
		var ca: Dictionary=a[id].call(a[id].get_object().observation(first))
		var cb: Dictionary=b[id].call(b[id].get_object().observation(second))
		check(ca==cb,"Exact next legal decision after cold "+str(tick)+" "+str(id))
		check(first.run.random_streams.snapshot()==second.run.random_streams.snapshot(),"Independent exact owner RNG "+str(tick)+" "+str(id))
		if not first.in_studio:
			var budget: Dictionary=first.development.pass_budget_state()
			active+=int(budget.version==1);legacy+=int(budget.version==0);printed+=budget.printed;spent+=budget.spent
	rows.append({"tick":tick,"active_current":active,"legacy":legacy,"printed":printed,"spent":spent})
	for mutation: String in ["missing","version","origin","printed","spent","legacy_origin"]:
		var bad:=w.duplicate(true);var found:=false
		for row: Dictionary in bad.studios:
			if not row.development is Dictionary:continue
			if mutation=="legacy_origin":
				row.development.pass_budget={"version":"0","origin":"unapproved-source","printed":"0","spent":"0"}
			elif mutation=="missing":row.development.erase("pass_budget")
			else:
				if row.development.pass_budget.version!="1":continue
				match mutation:
					"version":row.development.pass_budget.version="2"
					"origin":row.development.pass_budget.origin="unapproved-source"
					"printed":row.development.pass_budget.printed=str(int(row.development.pass_budget.printed)+1)
					"spent":row.development.pass_budget.spent="9999"
			found=true;break
		if found:check(codec.restore(bad,p,player,catalog)==null,"Reject "+mutation+" at "+str(tick))
func _initialize() -> void:
	await process_frame
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var adapter:=StudioCheckpoint.new();var codec:=Codec.new()
	for source: String in codec.BUDGET_PREDECESSORS:check(codec._known_budget_origin(source),"Exact unversioned predecessor origin is retained "+source)
	var prior: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(arg("--prior=")))
	var old_player:=adapter.hydrate(prior.player)
	var old_world:=codec.restore(prior.world,prior.player,old_player,catalog)
	check(old_world!=null,"Genuine immediate-predecessor world hydrates: "+codec.error)
	if old_world!=null:
		var actual:=codec.capture(old_world);actual.source_identity=prior.world.source_identity
		check(actual==prior.world and adapter.capture(old_player)==prior.player,"Predecessor DTO preserved except new source header")
		var bad: Dictionary=prior.world.duplicate(true);bad.studios[0].development.erase("pass_budget")
		check(codec.restore(bad,prior.player,old_player,catalog)==null,"Already-versioned predecessor cannot silently lose counters")
	var session: RefCounted=Factory.create_fresh_session({"schema_version":1,"studio_id":"budget-world-5607","studio_name":"Budget world clock","specialty":"action","traits":["family_funding","cult_following"],"seed":"5607"},catalog)
	var world:=Trial.create_world(session.run,catalog)
	check(world!=null,"Certified opening loads unchanged")
	if world!=null:
		cold_checks(world,catalog,0)
		for tick in range(1,25):
			check(session.run.complete_productive_action(),"Legal empty player calendar action "+str(tick))
			var result:=world.advance_committed_player_cycle(Trial.policies(world),64)
			check(result.ok,"Eight real owner ticks "+str(tick)+": "+str(result.get("reason","")))
			if not result.ok:break
			if tick in [4,8,16,24]:cold_checks(world,catalog,tick)
	check(rows.any(func(row):return row.printed>0 and row.spent>0),"Cold coverage includes earned and consumed current budget")
	check(rows.any(func(row):return row.legacy>0) and rows.any(func(row):return row.active_current>0),"Legacy active projects finish; later projects use prospective2/K8")
	var report:={"checks":checks,"failures":failures,"source":Replay.source_identity(),"rows":rows,"clock_fixture":"24-cycle legal family_funding/cult_following Studio clock; v2 retained ordinary arrears stop at25; not player economy evidence"}
	FileAccess.open(arg("--output="),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("WORLD_BUDGET ",checks," failures=",failures.size());quit(0 if failures.is_empty() else 1)
