## Isolated legal player launch/Studio-save boundary; no player balance study.
extends SceneTree
const Factory:=preload("res://scripts/simulation/run_factory.gd")
const Trial:=preload("res://scripts/market/rival_trial.gd")
const Codec:=preload("res://scripts/market/rival_world_checkpoint.gd")
const Replay:=preload("res://scripts/simulation/development_replay.gd")
const FixturePolicy:=preload("res://scripts/simulation/finite_fixture_policy.gd")
var issues: Array=[]
var reports: Array=[]
var world: RivalWorld
func arg(prefix: String,fallback: String="") -> String:
	for value in OS.get_cmdline_user_args():
		if value.begins_with(prefix):return value.trim_prefix(prefix)
	return fallback
func advance() -> void:
	var report:=world.advance_committed_player_cycle(Trial.policies(world),Trial.ZERO_STEPS)
	reports.append(report)
	if not report.ok:issues.append(report)
func _initialize() -> void:
	await process_frame
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog();var session: RefCounted=Factory.create_fresh_session({"schema_version":1,"studio_id":"live-cold-player","studio_name":"Boundary verifier","specialty":"action","traits":["family_funding","cult_following"],"seed":"717"},catalog)
	var rng: Dictionary=session.run.random_streams.snapshot();var initial_scope:=0
	for id: StringName in session.run.get_future_project_feature_ids():initial_scope+=int(session.run._feature_definitions[id].scope)
	if arg("--trusted-prior=")=="1":
		var cert: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(arg("--prior-certificate=","res://certified/rival-opening-5607-v1.json")))
		# Narrow test-only import of our exact preceding certified fixture. The
		# production new-save loader has no predecessor/source override.
		if cert.source_identity not in ["e3b8fe12b9adbbcb8ffc053380f395d3a6a27571268325c7f79a2de5d18fe31e","0d8e6b57ddaa3c2a71c05af7ba92a4a4495cad5da80c7dad38b4b038f991fc99"]:issues.append("Unknown test control source")
		else:world=Codec.new().restore(cert.fixture.world,StudioCheckpoint.new().capture(session.run),session.run,catalog,cert.source_identity)
	else:world=Trial.create_world(session.run,catalog)
	if world==null:issues.append("World unavailable");finish({});return
	if initial_scope!=12 or session.run.random_streams.snapshot()!=rng or world.studios.size()!=8:issues.append("Fresh player/owner isolation")
	session.run.calendar_changed.connect(advance)
	var policy:=FixturePolicy.factory({"genre":"action","theme":"fantasy","name_prefix":"Boundary","selection":"features_first","hands":{"design":2,"alpha":2,"beta":3}})
	var commands:=0
	while session.run.get_released_game_ids().size()<2 and commands<180 and issues.is_empty():
		var choice: Dictionary=policy.call(session.observation());var result: Dictionary=session.execute(session.command(StringName(choice.type),choice.get("payload",{})));commands+=1
		if not result.ok:issues.append({"command":choice,"error":result.get("error","")})
		if not session.in_studio and not session.export_checkpoint().is_empty():issues.append("Player active progress became Continue checkpoint")
	for id: StringName in world.studios:
		var owner: RefCounted=world.studios[id]
		if owner.in_studio or owner.phase()!=&"alpha":continue
		var finite: bool=not owner.development.hand._available_features.is_empty()
		for card: CardData in owner.development.hand._candidate_cards:
			if card.card_type==&"feature":finite=true
		if not finite and owner.development.project.get_current_scope()<owner.development.project.get_required_scope():issues.append("Unreleasable live Scope: "+str(id))
	var adapter:=StudioCheckpoint.new();var player:=adapter.capture(session.run);var codec:=Codec.new();var saved:=codec.capture(world);var restored_player:=adapter.hydrate(player);var restored: RivalWorld
	if not saved.is_empty() and restored_player!=null:restored=codec.restore(saved,player,restored_player,catalog)
	if restored==null:issues.append("Post-launch cold save: "+codec.error)
	var result:={"commands":commands,"cycle":world.cycle,"rival_count":world.studios.size(),"player_initial_scope":initial_scope,"player_releases":session.run.get_released_game_ids().size(),"player_studio_only":session.in_studio,"restored":restored!=null,"world":saved,"player":player,"reports":reports}
	finish(result)
func finish(result: Dictionary) -> void:
	result.issues=issues;result.source=Replay.source_identity();FileAccess.open(arg("--output="),FileAccess.WRITE).store_string(JSON.stringify(result,"	"));print("QUALITY_LIVE "+JSON.stringify({"issues":issues,"cycle":result.get("cycle",-1),"restored":result.get("restored",false)}));quit(0 if issues.is_empty() else 1)
