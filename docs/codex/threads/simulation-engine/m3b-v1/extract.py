from pathlib import Path
ROOT=Path(__file__).resolve().parents[5]
phase=ROOT/'patch-notes/scripts/phases/contract_phase.gd'
original=phase.read_text(encoding='utf-8')
a=original.index('func _build_candidate_pool(');b=original.index('func _publish_candidate_pool(',a)
draw=original[a:b].replace('var database := get_node_or_null("/root/CardDatabase")','var database: RefCounted = catalog')
engine=ROOT/'patch-notes/scripts/simulation/contract_session.gd'
engine.write_text(engine.read_text(encoding='utf-8')+'\n\n'+draw,encoding='utf-8')
s=original.replace('const HAND_SIZE := 4','''const HAND_SIZE := 4
const ContractSession := preload("res://scripts/simulation/contract_session.gd")
var _command_ids: Dictionary = {}
var _command_next_id := 0
var _command_sequence := 0
var _command_busy := false''')
def replace_function(name,body):
    global s
    start=s.index('func '+name+'(')
    end=s.find('\nfunc ',start+5)
    if end<0:end=len(s)
    s=s[:start]+body+'\n\n'+s[end:]
replace_function('_build_candidate_pool','''func _build_candidate_pool(extra_exhausted: Dictionary = {}, category_rolls: Array[float] = [], definition_rolls: Array[float] = [], candidate_count: int = CANDIDATE_COUNT) -> Array[CardData]:
\treturn _capture_contract()._build_candidate_pool(extra_exhausted,category_rolls,definition_rolls,candidate_count)
''')
replace_function('_draw_one','''func _draw_one(type_filter: StringName, reserved_features: Dictionary, category_roll: float, definition_roll: float, excluded_id: StringName = &"") -> CardData:
\treturn _capture_contract()._draw_one(type_filter,reserved_features,category_roll,definition_roll,excluded_id)
''')
replace_function('commit_priority_distribution','''func commit_priority_distribution(distribution: Dictionary = _priority_draft) -> bool:
\tif _command_busy or _state == null: return false
\t_command_busy = true
\tvar ok := _capture_contract().commit_priorities(distribution)
\t_command_busy = false
\tif not ok: return false
\t_command_sequence += 1
\t_priority_draft = _state.get_priority_distribution()
\t_sync_priority_inputs()
\t_feedback_label.text = "Priorities committed. The current draw is unchanged."
\t_refresh_all()
\treturn true
''')
replace_function('redraw_selected_cards','''func redraw_selected_cards(category_rolls: Array[float] = [], definition_rolls: Array[float] = []) -> bool:
\tif _command_busy or _state == null: return false
\t_command_busy = true
\tvar session := _capture_contract()
\tvar old_views := _selected_views.duplicate()
\tvar slots: Array[int] = []
\tfor view in old_views: slots.append(view.get_index())
\tvar prepared: Array[CardView] = []
\tvar readiness := func(replacements: Array[CardData]) -> bool:
\t\tfor card in replacements: prepared.append(_make_card_view(card))
\t\treturn true
\tvar publish := func(replacements: Array[CardData]) -> void:
\t\tfor index in range(old_views.size()):
\t\t\tvar old_view: CardView = old_views[index]
\t\t\tvar slot: int = slots[index]
\t\t\t_candidate_cards[slot] = replacements[index]
\t\t\t_candidate_row.remove_child(old_view)
\t\t\told_view.queue_free()
\t\t\t_candidate_row.add_child(prepared[index])
\t\t\t_candidate_row.move_child(prepared[index],slot)
\t\t_selected_views.clear()
\tvar result := session.redraw(slots,category_rolls,definition_rolls,readiness,publish)
\tif result.ok:
\t\tsession.sequence += 1
\t\t_sync_contract_tokens(session)
\telse:
\t\tfor view in prepared:
\t\t\tif view.get_parent() == null: view.free()
\t_command_busy = false
\tif not result.ok: return false
\t_feedback_label.text = "Selected cards redrawn."
\t_refresh_all()
\treturn true
''')
replace_function('_play_selected_hand','''func _play_selected_hand() -> bool:
\tif _command_busy or _state == null: return false
\t_command_busy = true
\tvar session := _capture_contract()
\tvar ids: Array[int] = []
\tfor view in _selected_views:
\t\tif not _command_ids.has(view.get_instance_id()):
\t\t\t_command_busy = false
\t\t\treturn false
\t\tids.append(_command_ids[view.get_instance_id()])
\tvar result := session.execute(session.command(&"play",{"candidate_ids":ids}))
\tif not result.ok:
\t\t_command_busy = false
\t\t_feedback_label.text = _run.get_financial_block_reason()
\t\treturn false
\tif _state.is_completed(): _show_completion()
\telse:
\t\t_publish_candidate_pool(result.replacements,true)
\t\t_feedback_label.text = "Hand complete. Draw %d is ready." % (_state.get_successful_hand_count()+1)
\t_sync_contract_tokens(session)
\t_command_busy = false
\t_refresh_all()
\treturn true
''')
s+='''

func _capture_contract() -> RefCounted:
\tvar database := get_node_or_null("/root/CardDatabase") if is_inside_tree() else null
\tvar session := ContractSession.new(_state,_run,database.get_development_catalog() if database != null else null)
\tsession._rng = _rng
\tsession.cards = _candidate_cards.duplicate()
\tsession.next_id = _command_next_id
\tsession.sequence = _command_sequence
\tif _candidate_row != null:
\t\tfor child in _candidate_row.get_children():
\t\t\tif not child is CardView: continue
\t\t\tif not _command_ids.has(child.get_instance_id()):
\t\t\t\t_command_ids[child.get_instance_id()] = session.next_id
\t\t\t\tsession.next_id += 1
\t\t\tsession.candidate_ids.append(_command_ids[child.get_instance_id()])
\t_command_next_id = session.next_id
\treturn session

func _sync_contract_tokens(session: RefCounted) -> void:
\t_command_ids.clear()
\tvar index := 0
\tfor child in _candidate_row.get_children():
\t\tif not child is CardView: continue
\t\t_command_ids[child.get_instance_id()] = session.candidate_ids[index]
\t\tindex += 1
\t_command_next_id = session.next_id
\t_command_sequence = session.sequence
'''
phase.write_text(s,encoding='utf-8')
print('Extracted Contract draw and live action adapters')
