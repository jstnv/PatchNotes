extends SceneTree

const Trial := preload("res://scripts/market/rival_trial.gd")
const WorldCodec := preload("res://scripts/market/rival_world_checkpoint.gd")
const Policy := preload("res://scripts/simulation/decision_policy.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var checks := 0
var failures := 0

class Observer extends Policy:
	var reads := 0
	func observation(_session: RefCounted) -> Dictionary:
		reads+=1
		return {"small":true}
	func choose(view: Dictionary) -> Dictionary:
		return {"type":&"blocked","payload":{"reason":"small" if view.get("small",false) else "full"}}

func expect(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error("FAIL: "+label)

func _initialize() -> void:
	await process_frame
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../tools/fixtures/background_checkpoint_v003_c96.json"))
	var player:=StudioCheckpoint.new().hydrate(fixture.player)
	var world: RivalWorld=WorldCodec.new().restore(fixture.world,fixture.player,player,catalog)
	expect(world!=null,"Exact late-save fixture restores")
	if world==null:quit(1);return
	var session: RefCounted=world.studios.values()[0]
	var observer:=Observer.new()
	var choice:=world._choice(observer.choose,session)
	expect(observer.reads==1 and choice.payload.reason=="small","Explicit policy observer supplies its view exactly once")
	var generic:=func(view: Dictionary)->Dictionary:
		return {"type":&"blocked","payload":{"reason":"complete" if view.has("studio_actions") and view.has("releases") and view.has("research_quotes") else "missing"}}
	expect(world._choice(generic,session).payload.reason=="complete","Existing Callables retain complete public observations")
	var prior_player:=StudioCheckpoint.new().hydrate(fixture.player)
	var prior_world: RivalWorld=WorldCodec.new().restore(fixture.world,fixture.player,prior_player,catalog)
	# Keep original full-view policy decisions and compare each actual command,
	# ordered event, state, releases and RNG at every shared calendar boundary.
	var original_policies: Dictionary={}
	for id: StringName in prior_world.studios:
		var original: RefCounted=prior_world.studios[id]
		var genre: String=String(original.run.get_studio_specialty())
		var label: String=original.run.get_studio_name()
		var enabled:=Trial.uses_synergy_trial(id,original.run)
		original_policies[id]=func(view: Dictionary)->Dictionary:return Trial._feature_maximal_choice(view,original,genre,label,enabled)
	var phases: Dictionary={}
	for boundary in 24:
		for id: StringName in world.studios:
			phases[str(world.studios[id].phase())]=true
		expect(player.complete_productive_action() and prior_player.complete_productive_action(),"Both player boundaries legally commit")
		var current:=world.advance_committed_player_cycle(Trial.policies(world),Trial.ZERO_STEPS)
		var prior:=prior_world.advance_committed_player_cycle(original_policies,Trial.ZERO_STEPS)
		if boundary==0 and current!=prior: print("FIRST_BOUNDARY ",JSON.stringify({"current":current,"prior":prior}))
		expect(var_to_bytes(current)==var_to_bytes(prior),"Same ordered rival commands/events at boundary "+str(boundary))
		expect(var_to_bytes(WorldCodec.new().snapshot(world))==var_to_bytes(WorldCodec.new().snapshot(prior_world)),"Same whole world, sales, finance and RNG at boundary "+str(boundary))
	var result: Dictionary={"ok":failures==0,"checks":checks,"failures":failures,"phases":phases.keys(),"source_identity":Replay.source_identity()}
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(result))
	print(JSON.stringify(result))
	quit(1 if failures else 0)
