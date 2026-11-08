## Scene-free commands use the same per-engine activation authority as live UI.
extends SceneTree
const Factory:=preload("res://scripts/simulation/run_factory.gd")
const RivalDecision:=preload("res://scripts/market/rival_career_decision.gd")
const Replay:=preload("res://scripts/simulation/development_replay.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1;print("PASS: " if ok else "FAIL: ",label)
	if not ok:failures+=1
func _initialize() -> void:verify.call_deferred()

func verify() -> void:
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var recipe: Dictionary={"schema_version":1,"studio_id":"activation-parity","studio_name":"Activation Parity","specialty":"action","traits":[],"seed":"6612"}
	var sim: RefCounted=Factory.create_fresh_session(recipe,catalog)
	var live: RefCounted=Factory.create_fresh_session(recipe,catalog)
	var shadow: RefCounted=Factory.create_fresh_session(recipe,catalog)
	check(sim!=null and live!=null and shadow!=null,"Create identical isolated live and headless Studios")
	if sim==null or live==null or shadow==null:quit(1);return
	var sim_created: Dictionary=sim.run.create_proprietary_engine(sim.run.get_proprietary_engine_creation_quote("Own Engine"))
	var live_created: Dictionary=live.run.create_proprietary_engine(live.run.get_proprietary_engine_creation_quote("Own Engine"))
	var shadow_created: Dictionary=shadow.run.create_proprietary_engine(shadow.run.get_proprietary_engine_creation_quote("Own Engine"))
	check(sim_created.get("ok",false) and sim_created==live_created and sim_created==shadow_created,"Create matching proprietary engines")
	if not sim_created.get("ok",false):quit(1);return
	var engine: StringName=sim_created.engine_id
	check(sim.run.select_engine(engine) and live.run.select_engine(engine) and shadow.run.select_engine(engine) and sim.run.finalize_starter_selection() and live.run.finalize_starter_selection() and shadow.run.finalize_starter_selection(),"Select matching engines and finalize setup")
	var quote: Dictionary=sim.run.get_engine_feature_activation_quote(&"text",engine)
	var direct: Dictionary=live.run.get_engine_feature_activation_quote(&"text",engine)
	var initial: Dictionary=sim.observation()
	check(quote==direct and quote.get("enabled",false) and quote.get("can_toggle",false),"Live and headless expose the same legal activation quote")
	check(initial.feature_activation_quotes.has(quote) and &"text" in initial.engine_available_features,"Studio observation publishes quote and active supply")
	var cycle: int=sim.run.get_completed_run_cycles();var cash: int=sim.run.get_cash_cents();var rng: Dictionary=sim.run.random_streams.snapshot()
	check(live.run.set_engine_feature_active(direct),"Live action disables Text")
	var command: Dictionary=sim.command(&"set_engine_feature_active",{"quote":quote})
	var tape:=Replay.begin(sim)
	var result: Dictionary=Replay.record(sim,tape,command)
	check(result.get("ok",false) and result.events.size()==1 and result.events[0].type=="engine_feature_activation_changed" and not result.events[0].enabled,"Headless command emits a disabled event")
	var replay: Dictionary=Replay.replay(shadow,tape)
	check(replay.get("ok",false) and Replay.state(shadow)==Replay.state(sim),"Activation command replays deterministically with state, event and RNG parity")
	var adapter:=StudioCheckpoint.new()
	check(adapter.capture(sim.run)==adapter.capture(live.run),"Live and headless checkpoints agree after the toggle")
	check(sim.run.get_completed_run_cycles()==cycle and sim.run.get_cash_cents()==cash and sim.run.random_streams.snapshot()==rng,"Toggle consumes no cycle, cash or RNG")
	var after: Dictionary=sim.observation()
	check(&"text" not in after.engine_available_features and &"text" in after.owned_features,"Observation distinguishes disabled supply from implemented ownership")
	var stale: Dictionary=sim.execute(sim.command(&"set_engine_feature_active",{"quote":quote}))
	check(not stale.get("ok",false) and sim.sequence==1 and adapter.capture(sim.run)==adapter.capture(live.run),"Stale quote is rejected without mutation or command advancement")
	var malformed: Dictionary=sim.execute(sim.command(&"set_engine_feature_active",{"quote":{}}))
	check(not malformed.get("ok",false) and sim.sequence==1,"Malformed quote is rejected")
	var rival:=RivalDecision.new(sim,{})
	var rival_view: Dictionary=rival.observation(sim)
	check(rival_view.engine_available_features==sim.run.get_future_project_feature_ids() and &"text" not in rival_view.engine_available_features,"Rival policy observes actual enabled supply")
	var expected_scope:=0
	for id: StringName in sim.run.get_future_project_feature_ids():expected_scope+=int(sim.run._feature_definitions[id].scope)
	check(rival.policy.scope(sim.run)==expected_scope,"Rival scope policy uses enabled supply")
	var envelope: Dictionary=sim.export_checkpoint()
	var resumed: RefCounted=Factory.create({"checkpoint":envelope},catalog) if not envelope.is_empty() else null
	check(resumed!=null and resumed.sequence==sim.sequence and &"text" not in resumed.observation().engine_available_features,"Studio Continue preserves activation and command sequence")
	if resumed==null:quit(1);return
	var enabled_quote: Dictionary=resumed.run.get_engine_feature_activation_quote(&"text",engine)
	check(not enabled_quote.get("enabled",true) and enabled_quote.get("can_toggle",false),"Continued quote can re-enable the Feature")
	var reenabled: Dictionary=resumed.execute(resumed.command(&"set_engine_feature_active",{"quote":enabled_quote}))
	check(reenabled.get("ok",false) and reenabled.events[0].enabled and &"text" in resumed.observation().engine_available_features,"Headless command re-enables after Continue")
	var start: Dictionary=resumed.execute(resumed.command(&"begin_development",{"name":"Frozen","genre":"action","theme":"fantasy"}))
	check(start.get("ok",false),"Begin development through its normal command")
	if start.get("ok",false):
		var frozen: Array=resumed.development.project.get_feature_supply_ids()
		var saved_rng: Dictionary=resumed.run.random_streams.snapshot()
		var development_toggle: Dictionary=resumed.execute(resumed.command(&"set_engine_feature_active",{"quote":resumed.run.get_engine_feature_activation_quote(&"text",engine)}))
		check(not development_toggle.get("ok",false) and resumed.development.project.get_feature_supply_ids()==frozen and resumed.run.random_streams.snapshot()==saved_rng,"Activation is Studio-only and the active project stays frozen")
		check(resumed.export_checkpoint().is_empty(),"Continue remains Studio-only during development")
	print("CAMPAIGN_FEATURE_ACTIVATION checks=%d failures=%d"%[checks,failures])
	quit(1 if failures else 0)
