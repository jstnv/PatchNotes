from pathlib import Path
ROOT=Path(__file__).resolve().parents[4]
P=ROOT/'docs/codex/threads/contracts/simulators/crown-feedback-20261026-v1/project'
def edit(name, changes):
 p=P/name;s=p.read_text(encoding='utf-8')
 for old,new in changes:
  assert s.count(old)==1,(name,old[:100],s.count(old))
  s=s.replace(old,new)
 p.write_text(s,encoding='utf-8',newline='\n')
edit('scripts/phases/contract_phase.gd',[
('var _completion_modal: CanvasLayer','''var _completion_modal: CanvasLayer
const CrownFeedback := preload("res://scripts/contracts/crown_feedback.gd")
var _crown_row: HBoxContainer
var _crown_summary: Label
var _crown_warning: Label
var _crown_details_button: Button
var _crown_details_modal: CanvasLayer
var _crown_details_text: Label
var _crown_result_details: Button
var _crown_completion_title: Label
var _crown_feedback_key := ""
var _crown_feedback_value: Dictionary = {}
'''),
('\tvar priority_row := HBoxContainer.new()','''\t_crown_row=HBoxContainer.new()
\tlayout.add_child(_crown_row)
\tvar crown_copy:=VBoxContainer.new()
\tcrown_copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL
\t_crown_row.add_child(crown_copy)
\t_crown_summary=Label.new();_crown_summary.name="CrownGradeSummary"
\t_crown_summary.add_theme_font_size_override("font_size",14)
\t_crown_summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
\tcrown_copy.add_child(_crown_summary)
\t_crown_warning=Label.new();_crown_warning.name="CrownZeroWarning"
\t_crown_warning.add_theme_font_size_override("font_size",14)
\t_crown_warning.add_theme_color_override("font_color",Color("#f0c76b"))
\t_crown_warning.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
\tcrown_copy.add_child(_crown_warning)
\t_crown_details_button=Button.new();_crown_details_button.text="Details";_crown_details_button.name="CrownGradeDetails"
\t_crown_details_button.pressed.connect(_open_crown_details)
\t_crown_row.add_child(_crown_details_button)
\t_crown_row.hide()
\tvar priority_row := HBoxContainer.new()'''),
('\tvar title := Label.new()\n\ttitle.text = "Contract Complete"','''\tvar title := Label.new()
\t_crown_completion_title=title
\ttitle.text = "Contract Complete"'''),
('\tvar dismiss := Button.new()\n\tdismiss.name = "DismissCompletionButton"','''\t_crown_result_details=Button.new();_crown_result_details.text="Details";_crown_result_details.name="CrownResultDetails"
\t_crown_result_details.pressed.connect(_open_crown_details)
\tcontent.add_child(_crown_result_details)
\t_crown_result_details.hide()
\t_crown_details_modal=CanvasLayer.new();_crown_details_modal.layer=35;add_child(_crown_details_modal)
\tvar details_content:=_modal_content(_crown_details_modal,Vector2(640,430))
\tdetails_content.get_parent().custom_minimum_size=Vector2(640,430)
\tvar detail_title:=Label.new();detail_title.text="Crown Brief · Grade details";details_content.add_child(detail_title)
\tvar detail_scroll:=ScrollContainer.new();detail_scroll.custom_minimum_size=Vector2(600,280)
\tdetail_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
\tdetail_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
\tdetails_content.add_child(detail_scroll)
\t_crown_details_text=Label.new();_crown_details_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
\t_crown_details_text.add_theme_font_size_override("font_size",15)
\t_crown_details_text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
\tdetail_scroll.add_child(_crown_details_text)
\tvar details_back:=Button.new();details_back.text="Back";details_back.name="CrownDetailsBack"
\tdetails_back.pressed.connect(_close_crown_details);details_content.add_child(details_back)
\t_crown_details_modal.hide()
\tvar dismiss := Button.new()
\tdismiss.name = "DismissCompletionButton"'''),
('\t_title.text = _state.get_title()','''\t_title.text = _state.get_title()
\tif _state.get_contract_id()==ContractDefinitions.CROWN_BRIEF:_candidate_row.custom_minimum_size.y=180'''),
('\tif _state.is_completed() or hand_motion.busy or _priority_modal.visible or view not in _candidate_row.card_views(): return','\tif _state.is_completed() or hand_motion.busy or _priority_modal.visible or _crown_details_modal.visible or view not in _candidate_row.card_views(): return'),
('\t_selected_views.clear()\n\t_candidate_row.hide()','''\tif _state.get_contract_id()==ContractDefinitions.CROWN_BRIEF:
\t\tvar grade:=CrownFeedback.completed(_run,_state)
\t\t_crown_completion_title.text="Brief complete"
\t\t_crown_result_details.visible=not grade.is_empty()
\t\t_completion_stats.text=CrownFeedback.summary(grade,true) if not grade.is_empty() else "Brief result unavailable."
\t\tif not grade.is_empty():
\t\t\t_completion_stats.text+="\\n"+grade.reason+"\\nCash: $0.00 · Promotion: 0 · Investment: 0"
\t\t\tif grade.cap_limited:_completion_stats.text+="\\nGrade value +%.2f; cap limits the added Reputation."%[grade.requested_bp/100.0]
\t\t\tvar advice:=CrownFeedback.reminder(grade.history)
\t\t\tif grade.history.at_cap:_completion_stats.text+="\\nCrown Reputation is at 100."
\t\t\telif grade.history.remind:_completion_stats.text+="\\n"+advice
\t_selected_views.clear()
\t_candidate_row.hide()'''),
('\tguidance_changed.emit()\n\n\nfunc _selected_cards()', '\t_refresh_crown_feedback()\n\tguidance_changed.emit()\n\n\nfunc _selected_cards()')
])
with (P/'scripts/phases/contract_phase.gd').open('a',encoding='utf-8',newline='\n') as f:f.write('''
func _refresh_crown_feedback() -> void:
\tif _crown_row==null:return
\t_crown_row.visible=_state!=null and _state.get_contract_id()==ContractDefinitions.CROWN_BRIEF and not _state.is_completed()
\tif not _crown_row.visible:return
\tvar coherent:=not _command_busy and not hand_motion.busy and not hand_motion.capturing and _presented_scores.is_empty()
\tif not coherent:
\t\t_crown_summary.text="";_crown_warning.hide();_crown_details_button.disabled=true
\t\t_crown_feedback_key="";_crown_feedback_value={};_crown_details_modal.hide()
\t\treturn
\tvar session:=_capture_contract()
\tvar selected: Array=[]
\tfor view in _selected_views:
\t\tvar slot:=_candidate_row.card_views().find(view)
\t\tif slot>=0:selected.append(session.candidate_ids[slot])
\tvar key:=CrownFeedback.identity(session,_run)+JSON.stringify(selected)
\tif key!=_crown_feedback_key:
\t\t_crown_feedback_value=CrownFeedback.query(session,_run,selected,true)
\t\t_crown_feedback_key=key
\tvar value: Dictionary=_crown_feedback_value.get("selected",{})
\t_crown_summary.text=CrownFeedback.summary(value)
\tif not value.is_empty() and not value.final:
\t\t_crown_summary.text=_crown_summary.text.replace("\\nOne hand remains."," · One hand remains.")
\t_crown_warning.text=_crown_feedback_value.get("warning","")
\t_crown_warning.visible=not _crown_warning.text.is_empty()
\t_crown_details_button.disabled=value.is_empty()
\tif not _crown_feedback_value.get("available",false):_crown_summary.text="Grade preview unavailable."

func _open_crown_details() -> void:
\tif hand_motion.busy or hand_motion.capturing:return
\tvar value:=CrownFeedback.completed(_run,_state) if _state.is_completed() else _crown_feedback_value.get("selected",{})
\tif value.is_empty():return
\t_crown_details_text.text=CrownFeedback.details(value)
\t_crown_details_modal.show()
\t(_crown_details_modal.get_child(0).find_child("CrownDetailsBack",true,false) as Button).grab_focus()

func _close_crown_details() -> void:
\t_crown_details_modal.hide()
\t(_crown_result_details if _state.is_completed() else _crown_details_button).grab_focus()

func _unhandled_input(event: InputEvent) -> void:
\tif event.is_action_pressed("ui_cancel") and _crown_details_modal.visible:
\t\t_close_crown_details();get_viewport().set_input_as_handled()
''')
edit('scripts/run_state.gd',[
('\tvar brief := get_sidestreet_brief_offer()\n\tif not brief.is_empty(): choices.append', '\tvar crown := get_crown_brief_offer()\n\tif not crown.is_empty():choices.append({"offer_id":crown.offer_id,"label":"Crown & Quill — Reputation Brief (no cash)"})\n\tvar brief := get_sidestreet_brief_offer()\n\tif not brief.is_empty(): choices.append')
])
edit('scripts/phases/studio_phase.gd',[
('var _search_work: OptionButton','var _search_work: OptionButton\nvar _search_publisher: OptionButton'),
('\tvar publisher_label:=FolderUI.label(search_row,"SideStreet · Search for work",&"SecondaryLabel")\n\tpublisher_label.autowrap_mode=TextServer.AUTOWRAP_OFF\n\tpublisher_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER','''\t_search_publisher=OptionButton.new();_search_publisher.name="ContractSearchPublisher"
\tfor publisher in [&"sidestreet",&"crown_quill"]:
\t\t_search_publisher.add_item(PublisherCatalog.name_for(publisher));_search_publisher.set_item_metadata(_search_publisher.item_count-1,publisher)
\t_search_publisher.item_selected.connect(func(_index):_refresh_contract_search())
\tsearch_row.add_child(_search_publisher)'''),
('\tvar brief := _run_state.get_sidestreet_brief_offer()\n\tif not brief.is_empty() and brief.offer_id == _selected_contract_offer_id:\n', '''\tvar crown:=_run_state.get_crown_brief_offer()
\tif not crown.is_empty() and crown.offer_id==_selected_contract_offer_id:
\t\t_selected_contract_quote={}
\t\ttitle.text="Crown Reputation Brief"
\t\tdetails.text="Search: 1 cycle · Brief: 2 hands · Four cards per hand\\nUp to 10.00 Crown Reputation; no cash, advance, Promotion or Investment.\\nTargets: Scope 9 · Graphics / Sound / Technology / Design 4 each.\\nThe lower of Work completion and Core balance sets the grade. Full balance at Core spread ≤2; zero at ≥6.\\nEach hand advances normal sales and bills. Acceptance is free. An existing offer needs no repeat Search."
\t\tvar history:=preload("res://scripts/contracts/crown_feedback.gd").history(_run_state)
\t\tif history.get("at_cap",false):details.text+="\\nCrown Reputation is at 100."
\t\telif history.get("remind",false):details.text+="\\n"+preload("res://scripts/contracts/crown_feedback.gd").reminder(history)
\t\treturn
\tvar brief := _run_state.get_sidestreet_brief_offer()
\tif not brief.is_empty() and brief.offer_id == _selected_contract_offer_id:\n'''),
('\tvar brief := _run_state.get_sidestreet_brief_offer()\n\tif not brief.is_empty() and brief.offer_id == _selected_contract_offer_id: state =', '\tvar crown := _run_state.get_crown_brief_offer()\n\tvar brief := _run_state.get_sidestreet_brief_offer()\n\tif not crown.is_empty() and crown.offer_id == _selected_contract_offer_id:state=_run_state.accept_crown_brief(_selected_contract_offer_id)\n\telif not brief.is_empty() and brief.offer_id == _selected_contract_offer_id: state ='),
('\t_search_quote=_run_state.get_contract_search_quote(&"sidestreet",work)','\tvar publisher: StringName=_search_publisher.get_selected_metadata()\n\tfor i in range(_search_work.item_count):_search_work.set_item_disabled(i,publisher==&"crown_quill" and _search_work.get_item_metadata(i)!=&"brief")\n\tif publisher==&"crown_quill":_search_work.select(1);work=&"brief"\n\t_search_quote=_run_state.get_contract_search_quote(publisher,work)'),
('\tvar reputation: int=standing.get(&"sidestreet",{}).get("reputation_bp",0)\n\tvar blocker:=_run_state.contract_search_blocker(&"sidestreet",work)','\tvar reputation: int=standing.get(publisher,{}).get("reputation_bp",0)\n\tvar blocker:=_run_state.contract_search_blocker(publisher,work)'),
('\t_prepare_found.visible=not _run_state.ContractSearch.invitation(_run_state).is_empty()','''\tif publisher==&"crown_quill":
\t\t_search_status.text+="\\nSearch: 1 cycle · Brief: 2 hands · Up to 10.00 Reputation · No cash, Promotion or Investment"
\t\tvar h:=preload("res://scripts/contracts/crown_feedback.gd").history(_run_state)
\t\tif h.get("at_cap",false):_search_status.text+="\\nCrown Reputation is at 100."
\t\telif h.get("remind",false):_search_status.text+="\\n"+preload("res://scripts/contracts/crown_feedback.gd").reminder(h)
\t_prepare_found.visible=not _run_state.ContractSearch.invitation(_run_state).is_empty()''')
])
print('Private UI integration complete')
