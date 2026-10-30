extends SceneTree
const Replay:=preload("res://scripts/simulation/development_replay.gd")
var failures:=0
func check(ok:bool,label:String) -> void:
	if not ok:failures+=1;print("FAIL: ",label)
func _initialize() -> void:
	await process_frame
	var path:="res://../docs/codex/findings/store-era-20261027-v1/campaign-run-final-v6/cases/action-4417-three-releases/"
	var tape:=Replay.load_tape(path+"replay.tape.json")
	check(not tape.is_empty(),"Trusted exact campaign tape loads")
	if tape.is_empty():quit(1);return
	check(tape.source_identity==Replay.source_identity(),"Final campaign tape is pinned to the current executable source")
	var expected:Array=["player_level_editor","ability_gated_exploration","switchable_protagonists","character_skill_checks"]
	var counts:Dictionary={}
	var records:Array=[]
	for index in tape.steps.size():
		var step:Dictionary=tape.steps[index]
		for event:Dictionary in step.result.get("events",[]):
			if event.get("type")=="feature_exhausted" and event.id in expected:
				counts[event.id]=int(counts.get(event.id,0))+1
				records.append({"step":index,"project":str(step.command.project_id),"card":event.id,"event":event})
	for id in expected:check(counts.get(id,0)==1,"Legal candidate draw/play/exhaustion occurs exactly once: "+id)
	var envelope:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path+"studio_checkpoint.json"))
	var adapter:=StudioCheckpoint.new();var run:=adapter.hydrate(envelope.studio_payload)
	check(run!=null,"Actual final campaign Studio cold-hydrates: "+adapter.error)
	if run!=null:
		check(run.get_released_game_ids().size()==3 and run.get_completed_run_cycles()==213,"Three legal releases at exact213 boundary")
		check(run.get_store_era_status(1984).receipt_id==&"era-v4-4417:project:2","First qualifying release receives1984 slot")
		check(run.get_store_era_status(1990).receipt_id==&"era-v4-4417:project:3" and not run.get_store_era_status(1990).eligible,"Next distinct release banked for1990 without bypassing calendar")
		check(run.get_financial_block_reason().is_empty(),"Final campaign has no overdue blocking bills")
		check(run.get_cash_cents()==2333094,"Actual settled cash matches final receipt")
		for id in expected:check(run.owns_feature(StringName(id)) and run.get_feature_familiarity(StringName(id))==1,"Researched child played once in committed project: "+id)
	var report:Dictionary={"ok":failures==0,"failures":failures,"commands":tape.steps.size(),"finite_play_counts":counts,"events":records,"scope":"Unfunded fresh v4 campaign; public commands and actual committed Feature exhaustion. Not AI policy or final balance approval."}
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report));quit(failures)
