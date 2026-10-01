## Separate calendar-grind stress: real changed priority commits, no free Wait.
extends "res://analysis/task24_current_v2.gd"

func _develop_game(game: Control,policy: String,focus: String,mode: String,seed_value: int,number: int,out: Dictionary) -> bool:
	if number==1:return await super._develop_game(game,policy,focus,mode,seed_value,number,out)
	await process_frame
	var project:ProjectState=game.project_state
	var run:RunState=game.run_state
	active_project=project
	var design:DesignPhase=game.get("_active_phase")
	design.get("_deal_rng").seed=seed_value+1
	design.get("_finalization_rng").seed=seed_value+2
	if not design.get_workspace().overlay.commit_draft():return false
	if not _production_hand(design,project,run,"synergy",focus,"design",number,out):return false
	var boundary:=1104
	for checkpoint:int in [96,240,480,720,960,1104]:
		if checkpoint>run.get_completed_run_cycles():boundary=checkpoint;break
	var step:=0
	while run.get_completed_run_cycles()<boundary:
		var distribution:Dictionary={0:40,1:20,2:20,3:20} if step%2==0 else {0:20,1:40,2:20,3:20}
		var before:=_state(game)
		if not design.commit_priority_distribution(distribution):return false
		out.actions.append({"phase":"priority_grind","distribution":distribution,"before":before,"after":_state(game)})
		step+=1
	design.call("_on_proceed_to_alpha_pressed")
	var alpha:AlphaPhase=game.get("_active_phase")
	alpha.get("_deal_rng").seed=seed_value+3
	alpha.get("_finalization_rng").seed=seed_value+4
	if not alpha.get_workspace().overlay.commit_draft():return false
	alpha.request_proceed_to_beta()
	if alpha.get_node("%UnderScopeDialog").visible:alpha.get_node("%UnderScopeDialog").confirmed.emit()
	if not game.get("_active_phase") is BetaPhase:return false
	var beta:BetaPhase=game.get("_active_phase")
	beta.get("_deal_rng").seed=seed_value+5
	if not beta.get_workspace().overlay.commit_draft():return false
	game.set("_controlled_review_roll",-1)
	game.get("_review_rng").seed=seed_value+7
	var launched:=beta.request_launch()
	if not launched:launched=beta.confirm_launch_for_verification()
	return launched
