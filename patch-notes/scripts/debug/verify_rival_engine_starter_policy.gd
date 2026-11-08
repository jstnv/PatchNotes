## Career policy must produce legal starts for fixed, owned and legacy engines.
## Isolated seeded sessions only; no player saves, external files or UI input.
extends SceneTree

const Factory := preload("res://scripts/simulation/run_factory.gd")
const Career := preload("res://scripts/market/rival_career_decision.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var checks := 0
var failures := 0

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("Rival engine starter policy: " + label)

func _initialize() -> void:
	await process_frame
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	for engine_case: String in ["public", "proprietary", "legacy"]:
		var recipe := {"schema_version":1,"studio_id":"policy-regression-"+engine_case,"studio_name":"Policy Regression","specialty":"action","traits":[],"seed":"4417"}
		if engine_case == "legacy": recipe.rival_founder_profile="rival-founder-active-1977-v2"
		var session: RefCounted = Factory.create_fresh_session(recipe,catalog)
		expect(session!=null,engine_case+" session initializes")
		if session==null: continue
		if engine_case == "proprietary":
			var quote: Dictionary = session.run.get_proprietary_engine_creation_quote("Owned regression engine")
			var creation: Dictionary = session.run.create_proprietary_engine(quote)
			expect(creation.get("ok",false),"actual proprietary engine creation succeeds")
			var selected: bool = creation.get("ok",false) and session.run.select_engine(creation.get("engine_id",&""))
			expect(selected,"created proprietary engine can be selected")
			if not selected: continue
		var engine_id: StringName = session.run.get_selected_engine_id()
		expect((engine_case=="public" and engine_id==&"public_action") or (engine_case=="legacy" and engine_id==&"legacy_engine") or (engine_case=="proprietary" and engine_id not in [&"public_action",&"legacy_engine"]),engine_case+" selected engine matches setup")
		expect(session.run.needs_starter_selection(),engine_case+" starts before initial project")
		var policy := Career.new(session,{})
		var prior_state := Replay.digest(Replay.state(session))
		var prior_rng := Replay.digest(session.run.random_streams.snapshot())
		var choice: Dictionary = policy.choose(policy.observation(session),null)
		expect(Replay.digest(Replay.state(session))==prior_state and Replay.digest(session.run.random_streams.snapshot())==prior_rng,engine_case+" choice does not mutate gameplay or RNG")
		var expected: StringName = &"starter_purchase" if engine_case=="legacy" else &"begin_development"
		expect(choice.get("type")==expected,engine_case+" selects expected legal starting action")
		var result: Dictionary = session.execute(session.command(StringName(choice.get("type","")),choice.get("payload",{})))
		expect(result.get("ok",false),engine_case+" selected action commits: "+str(result.get("error","")))
		if engine_case=="legacy":
			expect(session.in_studio, "legacy starter purchase remains in Studio")
		else:
			expect(not session.in_studio and session.development!=null and session.development.project.get_engine_id()==engine_id,engine_case+" project freezes selected engine")
	print("RIVAL_ENGINE_STARTER_POLICY checks=%d failures=%d" % [checks,failures])
	quit(0 if failures==0 else 1)
