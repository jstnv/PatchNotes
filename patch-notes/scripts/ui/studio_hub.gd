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
var overview: Control

func _init() -> void:
	name="StudioHub"
	theme=preload("res://resources/ui/onyx_theme.tres")
	set_meta("folder_navigation_managed",true)
	_root_panel=FolderUI.surface(self)
	_root_choices=VBoxContainer.new();_root_choices.add_theme_constant_override("separation",14);_root_panel.add_child(_root_choices)
	FolderUI.label(_root_choices,"STUDIO",&"HeadingLabel").add_theme_font_size_override("font_size",38)
	_clip=Control.new();_clip.name="CompanionClip";_clip.clip_contents=true;add_child(_clip)
	overview=preload("res://scripts/ui/studio_overview.gd").new();overview.name="StudioOverview";_clip.add_child(overview)
	_companion=FolderUI.surface(_clip);_companion.name="CompanionPanel";_companion.add_to_group(PauseMenu.CANCEL_OWNER_GROUP);_companion.hide()
	_contents=VBoxContainer.new();_contents.add_theme_constant_override("separation",14);_companion.add_child(_contents)
	_heading=FolderUI.label(_contents,"",&"HeadingLabel")
	resized.connect(_fit)
	_root_panel.minimum_size_changed.connect(_queue_fit)
	_companion.minimum_size_changed.connect(_queue_fit)

func add_group(id: StringName,title: String) -> VBoxContainer:
	if id==&"production":
		var divider:=HSeparator.new();divider.custom_minimum_size.y=26;_root_choices.add_child(divider)
		var line:=StyleBoxLine.new();line.color=Color("6F42FF");line.thickness=2;divider.add_theme_stylebox_override("separator",line)
	var button:=FolderUI.button(_root_choices,title,_root_pressed.bind(id));button.custom_minimum_size=Vector2(260,54);button.toggle_mode=true;root_buttons[id]=button
	button.theme_type_variation=&"ArcadePrimary" if id==&"production" else &"HubButton"
	var choices:=VBoxContainer.new();choices.name=String(id).capitalize()+"Choices";choices.add_theme_constant_override("separation",10);_contents.add_child(choices);choices.hide();groups[id]=choices
	return choices

func _root_pressed(id: StringName) -> void:
	# Direct activation toggles the active group; programmatic selection remains
	# idempotent so returning from a destination can restore its parent menu.
	if requested == id: close_group()
	else: select_group(id)

func select_group(id: StringName,focus: Control=null) -> void:
	if not groups.has(id):return
	requested=id
	for key: StringName in root_buttons:root_buttons[key].set_pressed_no_signal(key==id)
	_style_roots()
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
	var root_width:=maxf(330,_root_panel.get_combined_minimum_size().x)
	_root_panel.position=Vector2.ZERO;_root_panel.size=Vector2(root_width,size.y)
	_clip.position=Vector2(root_width+24,0);_clip.size=Vector2(maxf(0,size.x-root_width-24),size.y)
	_companion.size=_clip.size
	overview.position=Vector2.ZERO;overview.size=_clip.size
	if not transitioning:_companion.position=Vector2.ZERO

func _process(_delta: float) -> void:
	overview.visible=requested.is_empty() and selected.is_empty() and not transitioning

func _style_roots() -> void:
	for key: StringName in root_buttons:
		root_buttons[key].theme_type_variation=&"ArcadePrimary" if key==&"production" else &"SelectedButton" if key==requested else &"HubButton"

func settle_motion() -> void:
	for _step in range(4):
		if not transitioning:break
		motion.finish_panel(_companion)
	_fit()

func close_group() -> void:
	settle_motion()
	var had_selection := not requested.is_empty() or not selected.is_empty()
	requested=&""
	for button: Button in root_buttons.values():button.set_pressed_no_signal(false)
	_style_roots()
	if had_selection:selection_changed.emit(&"")
	if selected.is_empty():
		_restore_choices()
		return
	transitioning=true;_disable_choices()
	motion.slide_panel(_companion,_companion.position.x,-_clip.size.x,func():
		groups[selected].hide();selected=&"";_companion.hide();transitioning=false;_restore_choices()
		if not requested.is_empty():_advance())

func _queue_fit() -> void:
	if not is_inside_tree():return
	if not get_tree().process_frame.is_connected(_fit):get_tree().process_frame.connect(_fit,CONNECT_ONE_SHOT)
