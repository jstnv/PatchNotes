extends CanvasLayer

## A choice over the existing Redraw action. Preview/cancel never mutate the fan.
var phase: Control
var choices: Array=[]
var selected: Dictionary={}
var panel: PanelContainer
var options: VBoxContainer
var preview: CardView
var description: Label
var confirm_button: Button
var back_button: Button
var ordinary_button: Button
var _entrance: Tween
var _host: Container

class CenteredHost extends Container:
	func _notification(what: int) -> void:
		if what!=NOTIFICATION_SORT_CHILDREN:return
		var target:=Vector2(minf(720,size.x-40),minf(496,size.y-40))
		for child in get_children():
			if child is Control:fit_child_in_rect(child,Rect2((size-target)/2,target))

func _ready() -> void:
	layer=25
	add_to_group(PauseMenu.CANCEL_OWNER_GROUP)
	var shade:=ColorRect.new();shade.color=Color.TRANSPARENT
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
	_host=CenteredHost.new();shade.add_child(_host);_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_host.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel=FolderUI.surface(_host)
	var body:=VBoxContainer.new();body.add_theme_constant_override("separation",12);panel.add_child(body)
	back_button=FolderUI.header(body,"Align a Pass","Production Specialist · one normal redraw",close).get_node("Back")
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",24);row.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_child(row)
	var left:=VBoxContainer.new();left.size_flags_horizontal=Control.SIZE_EXPAND_FILL;left.add_theme_constant_override("separation",8);row.add_child(left)
	description=FolderUI.label(left,"");description.custom_minimum_size=Vector2(360,80)
	options=VBoxContainer.new();options.add_theme_constant_override("separation",8);left.add_child(options)
	var card_host:=Control.new();card_host.custom_minimum_size=Vector2(168,236);row.add_child(card_host)
	preview=preload("res://scenes/cards/card_view.tscn").instantiate();card_host.add_child(preview);preview.scale=Vector2.ONE*0.7;preview.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var actions:=HBoxContainer.new();actions.add_theme_constant_override("separation",12);body.add_child(actions)
	confirm_button=FolderUI.button(actions,"Replace Pass · 1 redraw",_replace,&"PrimaryButton")
	ordinary_button=FolderUI.button(actions,"Ordinary redraw · 1",_ordinary)
	hide()

func open_for(controller: Control, offers: Array) -> void:
	phase=controller;choices=offers.duplicate(true);selected={}
	ordinary_button.disabled=false
	if _entrance!=null and _entrance.is_valid():_entrance.kill()
	_host.queue_sort()
	for child in options.get_children():options.remove_child(child);child.queue_free()
	for offer: Dictionary in choices:
		FolderUI.button(options,offer.target_name+" · +2 "+str(offer.primary).capitalize(),func():_select(offer))
	if choices.is_empty():return
	_select(choices[0]);show();back_button.grab_focus()
	var resting:=(get_viewport().get_visible_rect().size-Vector2(720,496))/2
	panel.position=resting+Vector2(28,0);panel.modulate.a=0.0
	_entrance=create_tween().set_parallel();var tween:=_entrance;tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel,"position",resting,MenuTransitions.ENTRANCE_SECONDS)
	tween.tween_property(panel,"modulate:a",1.0,MenuTransitions.ENTRANCE_SECONDS)

func _select(offer: Dictionary) -> void:
	selected=offer.duplicate(true)
	var actions: RefCounted=phase._capture_development_actions()
	preview.set_card(actions.catalog.get_card(offer.target_id))
	description.text="Choose the exact Pass to receive.\nMatches visible %s.\nOne slot changes · 0 cycles · no extra card."%offer.feature_name
	confirm_button.disabled=false
	for index in options.get_child_count():options.get_child(index).theme_type_variation=&"PrimaryButton" if choices[index].target_id==offer.target_id else &"Button"

func _still_current() -> bool:
	if not is_instance_valid(phase) or selected.is_empty():return false
	var actions: RefCounted=phase._capture_development_actions()
	var slots: Array[int]=phase._redraw_slots()
	if slots.size()!=1 or actions.hand.candidate_ids[slots[0]]!=selected.quote.source_token:return false
	return actions.alignment_quote(selected.quote.source_token,selected.quote.target_id,selected.quote.feature_token)==selected.quote

func _replace() -> void:
	if not _still_current():_stale();return
	hide()
	if not phase._workspace.present_redraw(func():phase.redraw_selected_cards([] as Array[float],selected.quote)):show();_stale()

func _ordinary() -> void:
	if not _still_current():_stale();return
	hide()
	if not phase._workspace.present_redraw(Callable(phase,"redraw_selected_cards")):show();_stale()

func _stale() -> void:
	description.text="This hand, redraw budget or save state changed. Return to the hand and review a fresh choice. Nothing was spent."
	confirm_button.disabled=true;ordinary_button.disabled=true;back_button.grab_focus()

func close() -> void:
	hide()
	if is_instance_valid(phase):phase.get_node("%RedrawButton").grab_focus()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close();get_viewport().set_input_as_handled()
