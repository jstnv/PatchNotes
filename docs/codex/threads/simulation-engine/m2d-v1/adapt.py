exec((__import__('pathlib').Path(__file__).parent/'extract.py').read_text(encoding='utf-8').split('shutil.copyfile')[0])

# Definition bootstrap remains the existing autoload. No Node enters the engine.
p=S/'cards/card_database.gd'; t=read(p)
t+='''

func get_development_catalog() -> RefCounted:
\tvar additional: Array[CardData] = []
\tadditional.assign(_store_cards.values())
\treturn preload("res://scripts/simulation/development_catalog.gd").new(get_all_cards(),additional)
'''
write(p,t)
names={'design':['_build_design_feature_history','_is_valid_design_feature_history','_calculate_design_finalization','_is_perfect_production','_are_core_scores_perfect','_get_bug_variance'], 'alpha':['_build_alpha_feature_history','_calculate_alpha_finalization','_get_alpha_bug_variance'], 'beta':['_build_launch_warnings']}
for phase in ['design','alpha','beta']:
    p=S/f'phases/{phase}_phase.gd'; t=read(p)
    t=t.replace('extends Control','extends Control\n\nconst DevelopmentActions := preload("res://scripts/simulation/development_actions.gd")',1)
    t+='''

func _capture_development_actions() -> RefCounted:
\tvar actions:=DevelopmentActions.new()
\tactions.phase=&"PHASE"
\tactions.hand=_capture_PHASE_command()
\tvar database:=get_node_or_null("/root/CardDatabase")
\tif database!=null: actions.catalog=database.get_development_catalog()
FINAL_RNG
\treturn actions

func _redraw_slots() -> Array[int]:
\tvar slots: Array[int] = []
\tfor view: CardView in _selected_card_views: slots.append(view.get_index())
\treturn slots

func _sync_command_tokens(state: RefCounted) -> void:
\t_command_revision=state.revision
\t_command_next_id=state.next_candidate_id
\t_command_view_ids.clear()
\tfor index in range(%HandContainer.get_child_count()):
\t\t_command_view_ids[%HandContainer.get_child(index).get_instance_id()]=state.candidate_ids[index]
'''.replace('PHASE',phase).replace('FINAL_RNG','\tactions.finalization_rng=_finalization_rng' if phase!='beta' else '')
    for name in names[phase]:
        f=function(t,name); signature=f.split('\n')[0]
        args={'_is_valid_design_feature_history':'implemented_ids,unimplemented_ids,definitions','_calculate_design_finalization':'stochastic_roll,variance_roll','_are_core_scores_perfect':'scores','_get_bug_variance':'roll','_build_alpha_feature_history':'report_errors','_calculate_alpha_finalization':'stochastic_roll,variance_roll','_get_alpha_bug_variance':'roll'}.get(name,'')
        t=replace(t,name,signature+'\n\treturn _capture_development_actions().boundary().'+name+'('+args+')\n')
    # Preserve UI planning permission, delegate the productive transaction.
    f=function(t,'commit_priority_distribution')
    start=f.index('\tvar commit :='); end=f.index('\t_sync_priority_controls()',start)
    new='''\tvar publish:=func() -> void:
\t\t_priority_draft=_priority_allocation.GETTER()
\tif not DevelopmentActions.commit_priorities(_project_state,_run_state,_priority_allocation,distribution,publish): return false
'''.replace('GETTER','get_distribution' if phase=='beta' else 'get_priority_distribution')
    t=t.replace(f.rstrip(),(f[:start]+new+f[end:]).rstrip())
    # Data-only preview, then convert failed slots to the original view feedback.
    t=replace(t,'_plan_selected_redraw','''func _plan_selected_redraw(controlled_rolls: Array[float]) -> Dictionary:
\tvar plan: Dictionary = _capture_development_actions().redraw_plan(_redraw_slots(),controlled_rolls)
\tvar failed: Array[CardView] = []
\tfor slot: int in plan.failed_features: failed.append(%HandContainer.get_child(slot))
\tplan.failed_features=failed
\treturn plan
''')
    # Actual redraw shares all mechanics, retaining prepare-before-commit views.
    redraw='''func redraw_selected_cards(controlled_rolls: Array[float] = []) -> bool:
\tif not _can_redraw_selection(): return false
\tBUSY=true
\tvar actions:=_capture_development_actions()
\tvar slots:=_redraw_slots()
\tvar selected:=_selected_card_views.duplicate()
\tvar prepared: Array[CardView] = []
\tvar prepare:=func(cards: Array) -> bool:
\t\tfor card: CardData in cards:
\t\t\tvar view: CardView = INSTANTIATE
\t\t\tif view==null: return false
\t\t\tview.set_card(card)
\t\t\tview.card_pressed.connect(_on_card_pressed)
\t\t\tprepared.append(view)
\t\treturn true
\tvar publish:=func(_plan: Dictionary) -> void:
\t\t_candidate_cards.assign(actions.hand._candidate_cards)
AVAILABLE
\t\tfor index in range(slots.size()):
\t\t\tvar old: CardView = selected[index]
\t\t\t%HandContainer.remove_child(old)
\t\t\told.queue_free()
\t\t\t%HandContainer.add_child(prepared[index])
\t\t\t%HandContainer.move_child(prepared[index],slots[index])
BETA_VIEWS
\t\t_selected_card_views.clear()
\t\t_sync_command_tokens(actions.hand)
\tvar result: Dictionary = actions.redraw(slots,controlled_rolls,prepare,publish)
\tif not result.ok:
\t\tfor view in prepared: view.free()
FAILED
\telse:
SUCCESS
\t\t_sync_command_tokens(actions.hand)
\tBUSY=false
\tUPDATE()
\t_refresh_redraw_controls()
\treturn result.ok
'''.replace('BUSY','_transaction_in_progress' if phase=='beta' else '_hand_command_busy').replace('INSTANTIATE','_instantiate_card_view()' if phase=='beta' else 'CARD_VIEW_SCENE.instantiate() as CardView').replace('AVAILABLE','\t\t_available_features.assign(actions.hand._available_features)' if phase=='design' else '').replace('BETA_VIEWS','\t\t\t_candidate_views[slots[index]]=prepared[index]' if phase=='beta' else '').replace('UPDATE','_update_play_button' if phase=='design' else '_update_play_action').replace('FAILED','\t\tif not result.plan.failed_features.is_empty():\n\t\t\t%RedrawFeedbackLabel.text="No more Feature cards"\n\t\t\tfor slot: int in result.plan.failed_features: (%HandContainer.get_child(slot) as CardView).shake_no()' if phase!='beta' else '').replace('SUCCESS','\t\t%RedrawFeedbackLabel.text=""' if phase!='beta' else '')
    t=replace(t,'redraw_selected_cards',redraw)
    if phase in ['alpha','beta']:
        name='_select_corrective_categories' if phase=='alpha' else '_select_corrective_pass_ids'
        f=function(t,name)
        t=replace(t,name,f.split('\n')[0]+'\n\treturn _capture_development_actions().'+('corrective_categories' if phase=='alpha' else 'corrective_pass_ids')+'()\n')
        if phase=='alpha':
            t=replace(t,'host_playtest','''func host_playtest() -> bool:
\tif not _can_host_playtest(): return false
\t_hand_command_busy=true
\tvar actions:=_capture_development_actions()
\tactions.hand._pending_playtest_categories=_pending_playtest_categories
\tvar accepted: bool = actions.host_playtest()
\t_hand_command_busy=false
\t_update_host_playtest_action()
\treturn accepted
''')
        else:
            f=function(t,'host_playtest'); start=f.index('\tvar pass_ids :='); end=f.index('\tvar names :=')
            replacement='''\t_transaction_in_progress=true
\tvar actions:=_capture_development_actions()
\tactions.hand._pending_corrective_pass_ids=_pending_corrective_pass_ids
\tif not actions.host_playtest():
\t\t_transaction_in_progress=false
\t\t_update_all_actions()
\t\treturn false
\tvar pass_ids:=_pending_corrective_pass_ids.duplicate()
'''
            t=t.replace(f.rstrip(),(f[:start]+replacement+f[end:]).rstrip())
    # Initial pool authority, with existing UI publication left intact.
    if phase=='design':
        f=function(t,'_deal_next_candidate_pool'); f=f.replace('var priority_snapshot := get_priority_distribution()\n\tvar deal := _build_weighted_candidate_definitions(priority_snapshot, controlled_rolls)','var deal: Dictionary = _capture_development_actions().initial_plan(controlled_rolls)')
        t=replace(t,'_deal_next_candidate_pool',f)
        f=function(t,'_publish_refill'); start=f.index('\t_command_revision'); end=f.index('\n\tfor card in deal.cards:',start)
        f=f[:start]+'''\tvar actions:=_capture_development_actions()
\tactions.publish_initial(deal)
\t_candidate_cards.assign(actions.hand._candidate_cards)
\t_available_features.assign(actions.hand._available_features)
'''+f[end:]
        f=f.replace('\tif deal.has("tutorial_stat"):\n\t\t_get_first_game_tutorial().record_deal(deal.tutorial_stat)','\t_sync_command_tokens(actions.hand)')
        t=replace(t,'_publish_refill',f)
    elif phase=='alpha':
        f=function(t,'_deal_next_candidate_pool'); start=f.index('\tvar had_pending'); end=f.index('\tif not deal.valid:',start)
        f=f[:start]+'''\tvar actions:=_capture_development_actions()
\tvar deal: Dictionary = actions.initial_plan(controlled_rolls)
'''+f[end:]
        f=f.replace('\t_candidate_cards.assign(deal.cards)','\tactions.publish_initial(deal)\n\t_candidate_cards.assign(actions.hand._candidate_cards)\n\t_pending_playtest_categories.assign(actions.hand._pending_playtest_categories)')
        start=f.index('\tif had_pending_playtest:'); end=f.index('\t_update_host_playtest_action()',start)
        f=f[:start]+'\t_sync_command_tokens(actions.hand)\n'+f[end:]
        f=f.replace('\t_command_revision += 1\n','')
        t=replace(t,'_deal_next_candidate_pool',f)
    else:
        f=function(t,'begin_beta')
        f=f.replace('var deal := _build_candidate_definitions(definitions, committed_snapshot, category_rolls, definition_rolls)','var actions:=_capture_development_actions()\n\tactions.hand.priorities=committed_snapshot\n\tvar deal: Dictionary = actions.initial_plan(category_rolls,definition_rolls)')
        f=f.replace('\t_candidate_cards.assign(deal.cards)','\tactions.publish_initial(deal)\n\t_candidate_cards.assign(actions.hand._candidate_cards)')
        f=f.replace('\t_command_revision += 1','\t_sync_command_tokens(actions.hand)')
        t=replace(t,'begin_beta',f)
    # Finalized ProjectState mutations now share one engine boundary.
    if phase=='design':
        f=function(t,'_on_proceed_to_alpha_pressed'); start=f.index('\tvar prior_rng'); end=f.index('\t_finalization_requested = true',start)
        f=f[:start]+'''\t_hand_command_busy=true
\tvar result: Dictionary = _capture_development_actions().finalize()
\t_hand_command_busy=false
\tif not result.ok: return
\tvar finalization: Dictionary = result.finalization
'''+f[end:]
        t=replace(t,'_on_proceed_to_alpha_pressed',f)
    elif phase=='alpha':
        f=function(t,'_finalize_alpha'); start=f.index('\tvar feature_history'); end=f.index('\t_retire_alpha()',start)
        f=f[:start]+'''\tvar discarded_playtest:=not _pending_playtest_categories.is_empty()
\t_hand_command_busy=true
\tvar result: Dictionary = _capture_development_actions().finalize([stochastic_roll,variance_roll])
\t_hand_command_busy=false
\tif not result.ok: return false
\tvar feature_history: Dictionary = result.history
\tvar finalization: Dictionary = result.finalization
\t_pending_playtest_categories.clear()
'''+f[end:]
        t=replace(t,'_finalize_alpha',f)
    else:
        f=function(t,'_finalize_beta'); start=f.index('\tvar database :='); end=f.index('\t_pending_corrective_pass_ids.clear()',start)
        f=f[:start]+'''\t_transaction_in_progress=true
\tvar result: Dictionary = _capture_development_actions().finalize()
\tif not result.ok:
\t\t_transaction_in_progress=false
\t\t_launch_confirmation_pending=was_confirming
\t\t_update_all_actions()
\t\treturn false
'''+f[end:]
        t=replace(t,'_finalize_beta',f)
        for name in ['_validate_exhausted_beta_ids','_validate_feature_histories']:
            f=function(t,name)
            t=replace(t,name,f.split('\n')[0]+'\n\treturn _capture_development_actions().boundary().'+name+'(database.get_development_catalog())\n')
    write(p,t)
print('Scene adapters updated')
