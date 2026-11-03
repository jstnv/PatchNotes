class_name HowToPlayGuide
extends CanvasLayer

signal tour_requested(id: StringName)
var tour_availability: Callable
var tour_scroll: ScrollContainer
var tour_list: VBoxContainer

signal closed

var sections: Array = []
var folder_index := 0
var topic_index := 0
var panel: PanelContainer
var folder_buttons: Array[Button] = []
var topic_buttons: Array[Button] = []
var topic_list: VBoxContainer
var topic_scroll: ScrollContainer
var section_hint: Label
var breadcrumb: Label
var page_title: Label
var summary: Label
var reader: RichTextLabel
var close_button: Button
var previous_button: Button
var next_button: Button
var _return_focus: Control
var _navigation: MenuTransitions
var _surface: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 130
	var shade := ColorRect.new()
	_surface=shade
	shade.color = Color.TRANSPARENT
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	panel = PanelContainer.new()
	panel.name = "GuidePanel"
	panel.theme = preload("res://resources/ui/onyx_theme.tres")
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 24
	panel.offset_right = -24
	panel.offset_top = 20
	panel.offset_bottom = -20
	shade.add_child(panel)
	panel.theme_type_variation=&"FolderPanel"
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation",12)
	panel.add_child(layout)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var heading := Label.new()
	heading.theme_type_variation=&"HeadingLabel"
	heading.text = "How to Play"
	heading.theme_type_variation=&"HeadingLabel"
	heading.add_theme_font_size_override("font_size",30)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	close_button = _button(header,"CloseGuide","← Back  ·  Esc",close)
	header.move_child(close_button,0)
	close_button.custom_minimum_size = Vector2(144,42)
	sections = HowToPlayContent.sections()
	sections[0].topics.append({"id":"guided_tours","title":"Guided system tours","summary":"Focused tours point out real controls without purchases or productive actions.","body":"Open a Studio to replay tours. Locked systems become available as you progress."})
	var folders := HBoxContainer.new()
	folders.name = "Folders"
	folders.add_theme_constant_override("separation",3)
	layout.add_child(folders)
	var group := ButtonGroup.new()
	for index in range(sections.size()):
		var button := _button(folders,sections[index].id,sections[index].label,select_folder.bind(index))
		button.add_theme_font_size_override("font_size",14)
		button.custom_minimum_size.y = 42
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.button_group = group
		_folder_style(button,true)
		folder_buttons.append(button)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation",20)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body)
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size.x = 216
	sidebar.add_theme_constant_override("separation",12)
	body.add_child(sidebar)
	section_hint = Label.new()
	section_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	section_hint.custom_minimum_size.y = 48
	section_hint.add_theme_font_size_override("font_size",15)
	section_hint.theme_type_variation=&"SecondaryLabel"
	sidebar.add_child(section_hint)
	topic_scroll = ScrollContainer.new()
	topic_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	topic_scroll.follow_focus = true
	topic_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_child(topic_scroll)
	topic_list = VBoxContainer.new()
	topic_list.add_theme_constant_override("separation",5)
	topic_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topic_scroll.add_child(topic_list)
	var divider := VSeparator.new()
	body.add_child(divider)
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation",12)
	body.add_child(page)
	breadcrumb = Label.new()
	breadcrumb.add_theme_font_size_override("font_size",13)
	breadcrumb.theme_type_variation=&"MetadataLabel"
	breadcrumb.add_theme_color_override("font_color",FolderUI.color(&"cyan"))
	page.add_child(breadcrumb)
	page_title = Label.new()
	page_title.theme_type_variation=&"HeadingLabel"
	page_title.theme_type_variation=&"HeadingLabel"
	page_title.add_theme_font_size_override("font_size",28)
	page_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(page_title)
	summary = Label.new()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_font_size_override("font_size",18)
	summary.add_theme_color_override("font_color",FolderUI.color(&"mint"))
	page.add_child(summary)
	reader = RichTextLabel.new()
	reader.name = "GuideArticle"
	reader.bbcode_enabled = true
	reader.selection_enabled = true
	reader.focus_mode = Control.FOCUS_ALL
	reader.size_flags_vertical = Control.SIZE_EXPAND_FILL
	reader.add_theme_font_size_override("normal_font_size",18)
	reader.add_theme_font_size_override("bold_font_size",18)
	reader.add_theme_constant_override("line_separation",6)
	page.add_child(reader)
	tour_scroll=ScrollContainer.new();tour_scroll.follow_focus=true;tour_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;tour_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;page.add_child(tour_scroll)
	tour_list=VBoxContainer.new();tour_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tour_list.add_theme_constant_override("separation",8);tour_scroll.add_child(tour_list)
	var navigation := HBoxContainer.new()
	navigation.add_theme_constant_override("separation",8)
	page.add_child(navigation)
	previous_button = _button(navigation,"PreviousTopic","Previous topic",func(): select_topic(topic_index-1))
	next_button = _button(navigation,"NextTopic","Next topic",func(): select_topic(topic_index+1))
	var help := Label.new()
	help.text = "Tab: navigate   ·   PgUp / PgDn: read"
	help.add_theme_font_size_override("font_size",13)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	navigation.add_child(help)
	select_folder(0)
	hide()

func _button(parent: Node,id: String,caption: String,action: Callable) -> Button:
	var button := Button.new()
	button.name = id
	button.text = caption
	button.custom_minimum_size.y = 38
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _folder_style(button: Button, top: bool) -> void:
	button.theme_type_variation = &"FolderTab" if top else &"SidebarButton"

func is_open() -> bool:
	return visible

func open(navigation_host: MenuTransitions = null) -> void:
	if tour_scroll!=null and tour_scroll.visible:select_topic(topic_index)
	if visible or (navigation_host != null and navigation_host.busy): return
	_navigation=navigation_host
	_return_focus = get_viewport().gui_get_focus_owner()
	# A stacked Back hides this Control; ordinary gameplay reuses the same layer.
	_surface.show()
	show()
	if _navigation != null:
		if not _navigation.push(_surface,folder_buttons[folder_index],_finish_close): _finish_close()
	else: folder_buttons[folder_index].grab_focus()

func close() -> void:
	if not visible: return
	if is_instance_valid(_navigation) and _navigation.is_top(_surface):
		_navigation.pop()
		return
	_finish_close()

func _finish_close() -> void:
	_navigation=null
	hide()
	if is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree(): _return_focus.grab_focus()
	closed.emit()

func select_folder(index: int) -> void:
	if index < 0 or index >= sections.size(): return
	folder_index = index
	for i in range(folder_buttons.size()): folder_buttons[i].set_pressed_no_signal(i == index)
	for button in topic_buttons:
		topic_list.remove_child(button)
		button.queue_free()
	topic_buttons.clear()
	var section: Dictionary = sections[index]
	section_hint.text = section.subtitle
	var group := ButtonGroup.new()
	for i in range(section.topics.size()):
		var button := _button(topic_list,section.topics[i].id,section.topics[i].title,select_topic.bind(i))
		button.add_theme_font_size_override("font_size",15)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.tooltip_text = section.topics[i].title
		button.toggle_mode = true
		button.button_group = group
		_folder_style(button,false)
		topic_buttons.append(button)
	topic_scroll.scroll_vertical = 0
	select_topic(0)

func select_topic(index: int) -> void:
	var section: Dictionary = sections[folder_index]
	if index < 0 or index >= section.topics.size(): return
	topic_index = index
	var article: Dictionary = section.topics[index]
	for i in range(topic_buttons.size()): topic_buttons[i].set_pressed_no_signal(i == index)
	topic_scroll.ensure_control_visible.call_deferred(topic_buttons[index])
	breadcrumb.text = "%s   /   %02d OF %02d" % [section.label.to_upper(),index+1,section.topics.size()]
	page_title.text = article.title
	summary.text = article.summary
	reader.text = article.body
	var guided: bool=article.id=="guided_tours"
	reader.visible=not guided;tour_scroll.visible=guided
	for child in tour_list.get_children():tour_list.remove_child(child);child.queue_free()
	if guided:
		var catalog=preload("res://scripts/tutorial/focused_guidance_catalog.gd")
		for id: StringName in catalog.IDS:
			var button:=FolderUI.button(tour_list,str(catalog.LABELS[id]),func():tour_requested.emit(id))
			button.name="Tour_"+str(id);button.custom_minimum_size.y=44
			button.focus_entered.connect(_focus_tour.bind(button))
			button.disabled=not tour_availability.is_valid() or not tour_availability.call(id)
			button.tooltip_text="Open an eligible game context or unlock this system first." if button.disabled else "Read-only guided tour"
	reader.get_v_scroll_bar().value = 0
	previous_button.disabled = index == 0
	next_button.disabled = index == section.topics.size()-1
	# If Next/Previous became disabled, keep keyboard focus inside the article.
	var focus := get_viewport().gui_get_focus_owner()
	if focus is BaseButton and focus.disabled: reader.grab_focus()

func _focus_tour(button: Control) -> void:
	tour_scroll.ensure_control_visible.call_deferred(button)

func _input(event: InputEvent) -> void:
	if not visible: return
	if is_instance_valid(_navigation) and _navigation.busy:
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		close()
	elif event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_focus_prev"):
		var controls: Array = []
		controls.append_array(folder_buttons)
		controls.append_array(topic_buttons)
		if tour_scroll.visible:
			for button in tour_list.get_children():
				if button is Button and not button.disabled:controls.append(button)
		else:controls.append(reader)
		for button in [previous_button,next_button,close_button]:
			if not button.disabled: controls.append(button)
		var direction := -1 if event.is_action_pressed("ui_focus_prev") else 1
		var index := controls.find(get_viewport().gui_get_focus_owner())
		controls[posmod(index+direction,controls.size())].grab_focus()
	elif event.is_action_pressed("ui_page_down") or event.is_action_pressed("ui_page_up"):
		(tour_scroll.get_v_scroll_bar() if tour_scroll.visible else reader.get_v_scroll_bar()).value += reader.size.y * 0.8 * (-1 if event.is_action_pressed("ui_page_up") else 1)
	else:
		var focus := get_viewport().gui_get_focus_owner()
		if focus is Button and focus in folder_buttons and (event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right")):
			select_folder(posmod(folder_index+(-1 if event.is_action_pressed("ui_left") else 1),sections.size()))
			folder_buttons[folder_index].grab_focus()
		elif focus is Button and focus in topic_buttons and (event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down")):
			select_topic(posmod(topic_buttons.find(focus)+(-1 if event.is_action_pressed("ui_up") else 1),topic_buttons.size()))
			topic_buttons[topic_index].grab_focus()
		else: return
	get_viewport().set_input_as_handled()

func _unhandled_input(_event: InputEvent) -> void:
	if visible: get_viewport().set_input_as_handled()
