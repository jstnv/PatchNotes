## Studio-only presentation. Owns no Run, calendar, finance or RNG.
extends Control
signal selection_changed(id: StringName)
var motion: MenuTransitions
var root_buttons: Dictionary={}
var groups: Dictionary={}
var requested: StringName=&""
var selected: StringName=&""
var transitioning:=false
var _root_panel: PanelContainer
var _root_choices: VBoxContainer
var _clip: Control
var _companion: PanelContainer
var _contents: VBoxContainer
var _heading: Label
var _disabled: Dictionary={}

func _init() -> void:
	name="StudioHub"
	set_meta("folder_navigation_managed",true)
	_root_panel=FolderUI.surface(self)
	_root_choices=VBoxContainer.new();_root_choices.add_theme_constant_override("separation",12);_root_panel.add_child(_root_choices)
	FolderUI.label(_root_choices,"Studio",&"HeadingLabel")
	_clip=Control.new();_clip.name="CompanionClip";_clip.clip_contents=true;add_child(_clip)
	_companion=FolderUI.surface(_clip);_companion.name="CompanionPanel";_companion.add_to_group(PauseMenu.CANCEL_OWNER_GROUP);_companion.hide()
	_contents=VBoxContainer.new();_contents.add_theme_constant_override("separation",14);_companion.add_child(_contents)
	_heading=FolderUI.label(_contents,"",&"SectionHeading")
	resized.connect(_fit)
	_root_panel.minimum_size_changed.connect(_queue_fit)
	_companion.minimum_size_changed.connect(_queue_fit)

func add_group(id: StringName,title: String) -> VBoxContainer:
	var button:=FolderUI.button(_root_choices,title,select_group.bind(id,null));button.custom_minimum_size=Vector2(260,54);button.toggle_mode=true;root_buttons[id]=button
	var choices:=VBoxContainer.new();choices.name=String(id).capitalize()+"Choices";choices.add_theme_constant_override("separation",10);_contents.add_child(choices);choices.hide();groups[id]=choices
	return choices

func select_group(id: StringName,focus: Control=null) -> void:
	if not groups.has(id):return
	requested=id
	for key: StringName in root_buttons:root_buttons[key].set_pressed_no_signal(key==id)
	selection_changed.emit(id)
	if not transitioning and selected==id:
		if is_instance_valid(focus) and focus.is_visible_in_tree():focus.grab_focus()
		return
	_advance()

func _advance() -> void:
	if transitioning or requested.is_empty():return
	transitioning=true
	_disable_choices()
	if not selected.is_empty():
		motion.slide_panel(_companion,_companion.position.x,-_clip.size.x,func():
			groups[selected].hide();_companion.hide();selected=&"";transitioning=false;_advance())
		return
	selected=requested
	for key: StringName in groups:groups[key].visible=key==selected
	_heading.text=root_buttons[selected].text
	_companion.show();_fit()
	motion.slide_panel(_companion,-_clip.size.x,0,func():
		transitioning=false
		if selected!=requested:_advance()
		else:_restore_choices())

func _disable_choices() -> void:
	for group: Control in groups.values():
		for button: Button in group.find_children("*","Button",true,false):
			if not _disabled.has(button):_disabled[button]=button.disabled
			button.disabled=true

func _restore_choices() -> void:
	for button: Button in _disabled:
		if is_instance_valid(button):button.disabled=_disabled[button]
	_disabled.clear()

func _fit() -> void:
	if not is_inside_tree():return
	var root_height:=_root_panel.get_combined_minimum_size().y
	_root_panel.position=Vector2(0,maxf(0,(size.y-root_height)/2));_root_panel.size=Vector2(292,root_height)
	var width:=maxf(0,minf(470,size.x-310));var height:=minf(size.y,maxf(100,_companion.get_combined_minimum_size().y))
	_clip.position=Vector2(308,maxf(0,(size.y-height)/2));_clip.size=Vector2(width,height)
	_companion.size=_clip.size
	if not transitioning:_companion.position=Vector2.ZERO

func settle_motion() -> void:
	for _step in range(4):
		if not transitioning:break
		motion.finish_panel(_companion)
	_fit()

func close_group() -> void:
	settle_motion()
	requested=&""
	if selected.is_empty():return
	transitioning=true;_disable_choices()
	motion.slide_panel(_companion,_companion.position.x,-_clip.size.x,func():
		groups[selected].hide();selected=&"";_companion.hide();transitioning=false;_restore_choices()
		if not requested.is_empty():_advance())
	for button: Button in root_buttons.values():button.set_pressed_no_signal(false)

func _queue_fit() -> void:
	if not is_inside_tree():return
	if not get_tree().process_frame.is_connected(_fit):get_tree().process_frame.connect(_fit,CONNECT_ONE_SHOT)
