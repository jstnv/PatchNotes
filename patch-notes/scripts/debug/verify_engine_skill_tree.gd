extends SceneTree
var failures:=0
func check(ok: bool,label: String) -> void:
	if not ok:failures+=1;push_error(label)
func _initialize() -> void:verify.call_deferred()
func verify() -> void:
	var run:=RunState.new()
	check(run.initialize_cash(0) and run.create_studio_with_traits("Skill Tree Studio",&"action",[]),"Studio fixture")
	var created:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Own Engine"))
	check(created.get("ok",false),"Create proprietary engine")
	if not created.get("ok",false):quit(1);return
	var id: StringName=created.engine_id
	var row:=run.get_proprietary_engine_row(id)
	check(row.challenge_progress.is_empty() and row.branch_progress.is_empty(),"Independent branches start at zero")
	var project:=ProjectState.new(30)
	check(project.set_engine_id(id,25),"Project binds engine")
	var card:=CardData.new();card.card_type=&"feature";card.phase=&"design";card.primary_stat=&"graphics";card.primary_value=5;card.secondary_stat=&"design";card.secondary_value=3
	run.credit_engine_skill_feature(project,card)
	row=run.get_proprietary_engine_row(id)
	check(row.challenge_progress.get(&"graphics")==5 and row.challenge_progress.get(&"design")==3 and not row.challenge_progress.has(&"sound"),"Primary and secondary count in their own branches")
	var cash:=run.get_cash_cents();var cycle:=run.get_completed_run_cycles()
	var quote:=run.get_engine_skill_quote(id,&"graphics")
	check(not quote.is_empty(),"Completed graphics challenge quotes")
	var bought:=run.purchase_engine_skill(quote)
	check(bought.get("ok",false) and run.get_cash_cents()==cash-12500 and run.get_completed_run_cycles()==cycle,"Generation I costs $125 without cycle")
	check(not run.purchase_engine_skill(quote).get("ok",false),"Cannot repeat purchase")
	row=run.get_proprietary_engine_row(id)
	check(row.branch_progress.get(&"graphics")==1 and not row.challenge_progress.has(&"graphics") and row.pass_efficiency.get(&"graphics")==20,"Own branch advances and resets")
	check(run.get_engine_feature_state().engines[id].capacity==25,"Single branch does not expand Scope")
	for branch: StringName in [&"sound",&"technology",&"design"]:
		var next:=run.ProprietaryEngines.node(branch,1)
		var direct:=run.get_proprietary_engine_state()
		direct.engines[id].challenge_progress[branch]=next.threshold
		run._proprietary_engines=direct
		check(run.purchase_engine_skill(run.get_engine_skill_quote(id,branch)).get("ok",false),"Generation I "+str(branch))
	check(run.get_engine_feature_state().engines[id].capacity==30,"Four purchases grant exactly +5 Scope")
	var generation_one_project:=ProjectState.new(30)
	check(generation_one_project.set_engine_id(id,run.get_engine_feature_state().engines[id].capacity) and generation_one_project.add_scope(30) and not generation_one_project.add_scope(1),"Generation I project accepts exactly 30 Scope")
	check(project.get_engine_max_scope()==25 and project.add_scope(25) and not project.add_scope(1),"Started project retains its frozen 25-Scope capacity")
	for branch: StringName in run.ProprietaryEngines.BRANCHES:
		var next:=run.ProprietaryEngines.node(branch,2)
		var direct:=run.get_proprietary_engine_state()
		direct.engines[id].challenge_progress[branch]=next.threshold
		run._proprietary_engines=direct
		check(run.purchase_engine_skill(run.get_engine_skill_quote(id,branch)).get("ok",false),"Generation II "+str(branch))
	check(run.get_engine_feature_state().engines[id].capacity==35,"Four Generation II purchases grant exactly +5 Scope")
	var generation_two_project:=ProjectState.new(30)
	check(generation_two_project.set_engine_id(id,run.get_engine_feature_state().engines[id].capacity) and generation_two_project.add_scope(35) and not generation_two_project.add_scope(1),"Generation II project accepts exactly 35 Scope")
	var pass_card:=CardData.new();pass_card.card_type=&"pass";pass_card.primary_stat=&"graphics";pass_card.primary_value=8
	var scores: Dictionary={0:8}
	var ordinary:=preload("res://scripts/simulation/production_hand.gd").calculate([{"primary_stat":&"graphics"}],scores,false)
	var effects:=preload("res://scripts/engines/engine_skill_effects.gd")
	var first_effect: Dictionary=effects.pass_effect([pass_card],scores,ordinary,{},run.get_proprietary_engine_row(id),{})
	var second_effect: Dictionary=effects.pass_effect([pass_card],scores,ordinary,{},run.get_proprietary_engine_row(id),first_effect.remainders)
	check(first_effect.additions[0]==8 and first_effect.remainders.graphics==8 and second_effect.additions[0]==9 and second_effect.remainders.graphics==6,"Pass marginal carries fractional score across hands")
	var bug_card:=CardData.new();bug_card.card_type=&"feature";bug_card.primary_stat=&"technology";bug_card.primary_value=6;bug_card.secondary_stat=&"design";bug_card.secondary_value=3;bug_card.scope=2
	var command:=preload("res://scripts/simulation/design_hand_command.gd").new();command._run_state=run;command._project_state=project
	check(absf(command._calculate_feature_bug_pressure(bug_card)-0.85)<0.00001,"Technology and Design reduce only their printed Feature portions")
	check(command._selected_budget_delta([card]).bonus_centi==160,"Generation I weights printed primary and secondary Core for budget only")
	var alpha_command:=preload("res://scripts/simulation/alpha_hand_command.gd").new();alpha_command._run_state=run;alpha_command._project_state=project
	check(alpha_command._selected_budget_delta([card]).bonus_centi==160,"Alpha gets the same independent budget weighting")
	check(run.valid_engine_state(),"Purchases validate against receipts and Scope")
	var other_created:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Second Tree"))
	check(other_created.get("ok",false),"Second engine stays independent")
	var other_id: StringName=other_created.get("engine_id",&"")
	if not other_id.is_empty():
		var other_project:=ProjectState.new(30);other_project.set_engine_id(other_id,25)
		var partial:=CardData.new();partial.card_type=&"feature";partial.primary_stat=&"graphics";partial.primary_value=3
		run.credit_engine_skill_feature(other_project,partial)
		check(run.get_proprietary_engine_row(other_id).challenge_progress.get(&"graphics")==3 and run.get_proprietary_engine_row(id).branch_progress.get(&"graphics")==2,"Progress stays on its own engine")
	var payload:=StudioCheckpoint.new().capture(run)
	check(not payload.is_empty(),"Skill Tree Studio save captures")
	var adapter:=StudioCheckpoint.new()
	var loaded:=adapter.hydrate(payload) if not payload.is_empty() else null
	check(loaded!=null and loaded.get_engine_feature_state().engines[id].capacity==35 and loaded.get_proprietary_engine_row(id).scope_milestones==[&"generation_1",&"generation_2"],"Skill Tree Studio save hydrates")
	if loaded!=null and not other_id.is_empty():check(loaded.get_proprietary_engine_row(other_id).challenge_progress.get(&"graphics")==3,"Partial challenge survives Studio save")
	var old:=RunState.new()
	check(old.initialize_cash(0) and old.create_studio_with_traits("Old engine save",&"action",[]),"Previous-version fixture")
	var old_created:=old.create_proprietary_engine(old.get_proprietary_engine_creation_quote("Original"))
	if old_created.get("ok",false):
		old._proprietary_engines.version=1
		old._engine_features.version=2
		for legacy_feature_row: Dictionary in old._engine_features.engines.values():legacy_feature_row.erase("enabled")
		var prior: Dictionary=old._engine_features.engines[old_created.engine_id]
		prior.capacity=20
		prior.origin=old.ProprietaryEngines.ORIGIN
		prior.initial.clear();prior.implemented.clear();prior.committed.clear()
		var old_payload:=StudioCheckpoint.new().capture(old)
		var migrated:=StudioCheckpoint.new().hydrate(old_payload) if not old_payload.is_empty() else null
		check(migrated!=null and migrated.get_proprietary_engine_state().version==3 and migrated.get_proprietary_engine_row(old_created.engine_id).challenge_progress.is_empty() and migrated.get_future_project_feature_ids(old_created.engine_id).is_empty(),"Phase 3A inert state migrates without granting nodes or starter Features")
	var browser:=preload("res://scripts/ui/engine_market_browser.gd").new();root.add_child(browser);browser.open(run,null);browser._inspect(id);browser._open_skill_tree()
	check(browser.skill_grid.is_visible_in_tree() and browser.skill_grid.buttons.size()==13 and browser.skill_grid.rows[&"graphics_2"].state=="complete" and browser.skill_grid.rows[&"engine"].status=="35 maximum Scope" and browser.description.text.contains("Maximum played Scope: 35"),"Engines UI shows purchased tree and Scope")
	browser.queue_free()
	var budget:=preload("res://scripts/simulation/pass_budget.gd")
	check(budget.generated(7,1,140)==3 and budget.generated(7,2,140)==11 and absf(budget.effective_progress(7,140)-0.4)<0.00001,"Versioned baselines retain fractional Skill numerator and visible progress")
	print("Engine Skill Tree: %d failures"%failures)
	quit(1 if failures else 0)
