## Shared presentation-only outward grid. Owners perform authoritative actions.
extends Control
signal inspected(id: StringName)
signal action_requested(id: StringName)

const PITCH:=212.0
const NODE_SIZE:=Vector2(156,128)
var rows: Dictionary={}
var buttons: Dictionary={}
var selected_id: StringName=&""
var zoom:=0.74
var scroll: ScrollContainer
var canvas: Control
var tree: Control
var popup: PanelContainer
var action_button: Button
var details_scroll: ScrollContainer
var detail_extension: VBoxContainer
var action_extension: VBoxContainer
var minimum_detail_height:=300.0
var detail_width:=390.0
var _title: Label
var _copy: Label
var _parents: HBoxContainer
var _zoom_label: Label
var _origin:=Vector2.ZERO
var _extent:=Vector2.ZERO
var _drag_origin:=Vector2.ZERO
var _drag_scroll:=Vector2.ZERO
var _panning:=false
var _moved:=false
var _camera_epoch:=0
var _restoring_focus:=false

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_PASS
	custom_minimum_size.y=180
	var box:=VBoxContainer.new();add_child(box);box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tools:=HBoxContainer.new();tools.add_theme_constant_override("separation",8);box.add_child(tools)
	FolderUI.button(tools,"−",func():set_zoom(zoom/1.25))
	FolderUI.button(tools,"+",func():set_zoom(zoom*1.25))
	FolderUI.button(tools,"Show all",fit_all)
	FolderUI.button(tools,"Center",focus_root)
	_zoom_label=FolderUI.label(tools,"",&"MetadataLabel")
	_zoom_label.autowrap_mode=TextServer.AUTOWRAP_OFF
	_zoom_label.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	var help:=FolderUI.label(tools,"Drag: pan · Wheel: zoom · Arrows: browse · Click: inspect",&"SecondaryLabel")
	help.add_theme_font_size_override("font_size",12);help.autowrap_mode=TextServer.AUTOWRAP_OFF;help.clip_text=true;help.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.follow_focus=false;scroll.clip_contents=true;box.add_child(scroll)
	scroll.gui_input.connect(_pointer)
	canvas=Control.new();canvas.size_flags_horizontal=Control.SIZE_EXPAND_FILL;canvas.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.add_child(canvas);canvas.gui_input.connect(_pointer)
	tree=Control.new();canvas.add_child(tree);tree.draw.connect(_draw_edges)
	canvas.resized.connect(_center_canvas)
	popup=PanelContainer.new();popup.name="ProgressionDetails";popup.theme=FolderUI.THEME;popup.theme_type_variation=&"FolderPanel";add_child(popup)
	var margin:=MarginContainer.new();popup.add_child(margin)
	for edge in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+edge,18)
	var detail:=VBoxContainer.new();detail.add_theme_constant_override("separation",10);margin.add_child(detail)
	var heading:=HBoxContainer.new();detail.add_child(heading)
	_title=FolderUI.label(heading,"",&"SectionHeading");_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_title.custom_minimum_size.x=240;_title.add_theme_font_size_override("font_size",20)
	FolderUI.button(heading,"×",close_details).custom_minimum_size=Vector2(36,36)
	var body:=ScrollContainer.new();details_scroll=body;body.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;body.custom_minimum_size.y=80;body.size_flags_vertical=Control.SIZE_EXPAND_FILL;detail.add_child(body)
	var document:=VBoxContainer.new();document.size_flags_horizontal=Control.SIZE_EXPAND_FILL;document.add_theme_constant_override("separation",12);body.add_child(document)
	_copy=FolderUI.label(document,"");_copy.custom_minimum_size.x=280;_copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_copy.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	detail_extension=VBoxContainer.new();document.add_child(detail_extension);document.move_child(detail_extension,0)
	_parents=HBoxContainer.new();detail.add_child(_parents)
	action_button=FolderUI.button(detail,"",func():action_requested.emit(selected_id),&"PrimaryButton")
	action_extension=VBoxContainer.new();detail.add_child(action_extension)
	popup.hide();resized.connect(_fit_popup)

func set_rows(values: Array,reset: bool=false) -> void:
	var initial:=rows.is_empty() or reset
	if reset:selected_id=&"";popup.hide();zoom=0.74
	var focused:=get_viewport().gui_get_focus_owner()
	var focused_id: StringName=&""
	var focused_parent: StringName=&""
	for id: StringName in buttons:
		if buttons[id]==focused:focused_id=id;break
	if is_instance_valid(focused):focused_parent=focused.get_meta("progression_parent",&"")
	for child in tree.get_children():tree.remove_child(child);child.queue_free()
	rows.clear();buttons.clear()
	var low:=Vector2i.ZERO;var high:=Vector2i.ZERO
	for row: Dictionary in values:low=low.min(row.cell);high=high.max(row.cell);rows[row.id]=row
	_origin=Vector2(80,80)-Vector2(low)*PITCH
	_extent=Vector2(high-low)*PITCH+NODE_SIZE+Vector2(160,160)
	for row: Dictionary in values:
		var button:=FolderUI.button(tree,"",_node_pressed.bind(row.id));button.name="Node_"+str(row.id);button.position=_origin+Vector2(row.cell)*PITCH;button.custom_minimum_size=NODE_SIZE;button.size=NODE_SIZE
		button.gui_input.connect(_pointer);button.focus_entered.connect(_reveal.bind(row.id));buttons[row.id]=button
		var box:=VBoxContainer.new();box.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);box.offset_left=10;box.offset_right=-10;box.offset_top=10;box.offset_bottom=-10;button.add_child(box)
		if row.has("branch"):
			var category:=FolderUI.label(box,str(row.branch).capitalize(),&"MetadataLabel");category.add_theme_font_size_override("font_size",12);category.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;category.mouse_filter=Control.MOUSE_FILTER_IGNORE
			category.add_theme_color_override("font_color",FeatureStore.SCORE_COLORS[row.branch])
		var label:=FolderUI.label(box,str(row.title),&"SectionHeading");label.add_theme_font_size_override("font_size",16);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.size_flags_vertical=Control.SIZE_EXPAND_FILL;label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var status:=FolderUI.label(box,str(row.status),&"MetadataLabel");status.add_theme_font_size_override("font_size",12);status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;status.mouse_filter=Control.MOUSE_FILTER_IGNORE
		status.add_theme_color_override("font_color",FolderUI.color(&"mint") if row.state in ["complete","ready"] else FolderUI.color(&"muted"))
	for id: StringName in buttons:
		for pair in [["focus_neighbor_left",Vector2.LEFT],["focus_neighbor_right",Vector2.RIGHT],["focus_neighbor_top",Vector2.UP],["focus_neighbor_bottom",Vector2.DOWN]]:
			buttons[id].set(pair[0],buttons[_neighbor(id,pair[1])].get_path())
	_apply_scale();tree.queue_redraw()
	if not selected_id.is_empty() and rows.has(selected_id) and popup.visible:inspect(selected_id,false)
	_restoring_focus=true
	if buttons.has(focused_id):buttons[focused_id].grab_focus()
	if not focused_parent.is_empty():
		for button in _parents.get_children():
			if button.get_meta("progression_parent",&"")==focused_parent:button.grab_focus();break
	_restoring_focus=false
	if initial:focus_root.call_deferred()

func _node_pressed(id: StringName) -> void:
	if not _moved:inspect(id)

func inspect(id: StringName,focus: bool=true) -> void:
	if not rows.has(id):return
	selected_id=id
	var row: Dictionary=rows[id]
	_title.text=row.title;_copy.text=row.get("description","")
	_parents.show();detail_extension.hide();action_extension.hide()
	for child in _parents.get_children():_parents.remove_child(child);child.queue_free()
	for parent: StringName in row.parents:
		if rows.has(parent):
			var button:=FolderUI.button(_parents,str(rows[parent].title),inspect.bind(parent));button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;button.custom_minimum_size.x=280;button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			button.set_meta("progression_parent",parent)
	configure_action(str(row.action),false);popup.show();_fit_popup();_fit_popup.call_deferred()
	inspected.emit(id)
	if focus:reset_details_scroll();focus_details()

func reset_details_scroll() -> void:
	details_scroll.set_deferred("scroll_vertical",0)

func focus_details() -> void:
	if action_button.visible and not action_button.disabled:action_button.grab_focus()
	else:popup.find_children("*","Button",true,false)[0].grab_focus()

func use_detail_extension() -> void:
	_parents.hide();detail_extension.show();action_extension.show()

func configure_action(text: String,enabled: bool) -> void:
	action_button.text=text;action_button.visible=not text.is_empty();action_button.disabled=not enabled

func set_description(text: String) -> void:_copy.text=text

func close_details() -> void:
	popup.hide()
	if buttons.has(selected_id):buttons[selected_id].grab_focus()

func _fit_popup() -> void:
	if popup==null or not popup.visible:return
	popup.custom_minimum_size.x=minf(detail_width,size.x-32);popup.size=Vector2(minf(detail_width,size.x-32),0);popup.reset_size()
	popup.size.y=minf(maxf(minimum_detail_height,popup.get_combined_minimum_size().y),size.y-20)
	popup.position=Vector2(maxf(10,size.x-popup.size.x-10),maxf(10,size.y-popup.size.y-10))

func _apply_scale() -> void:
	tree.scale=Vector2.ONE*zoom;canvas.custom_minimum_size=_extent*zoom
	_zoom_label.text="%d%%"%roundi(zoom*100)
	_center_canvas.call_deferred()

func _center_canvas() -> void:
	tree.position=((canvas.size-_extent*zoom)*0.5).max(Vector2.ZERO)

func set_zoom(value: float) -> void:
	var point: Vector2=(Vector2(scroll.scroll_horizontal,scroll.scroll_vertical)+scroll.size*0.5)/zoom
	zoom=clampf(value,0.15,1.6);_apply_scale();_camera_epoch+=1
	_move_camera.call_deferred(point*zoom-scroll.size*0.5,_camera_epoch)

func _move_camera(point: Vector2,epoch: int) -> void:
	if epoch!=_camera_epoch:return
	scroll.scroll_horizontal=roundi(point.x);scroll.scroll_vertical=roundi(point.y)

func fit_all() -> void:
	if _extent==Vector2.ZERO:return
	zoom=clampf(minf((scroll.size.x-24)/_extent.x,(scroll.size.y-24)/_extent.y),0.1,1.0);_apply_scale();_camera_epoch+=1
	_move_camera.call_deferred(Vector2.ZERO,_camera_epoch)

func focus_root() -> void:
	_camera_epoch+=1;_move_camera.call_deferred((_origin+NODE_SIZE*0.5)*zoom-scroll.size*0.5,_camera_epoch)

func _reveal(id: StringName) -> void:
	if _panning or _restoring_focus or not buttons.has(id):return
	_camera_epoch+=1;_move_camera.call_deferred((buttons[id].position+NODE_SIZE*0.5)*zoom-scroll.size*0.5,_camera_epoch)

func _input(event: InputEvent) -> void:
	if is_visible_in_tree() and popup.visible and MenuTransitions.cancel_pressed(event):
		close_details();get_viewport().set_input_as_handled();return
	if _panning and event is InputEventMouseButton and not event.pressed and event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_MIDDLE]:
		_panning=false;_reset_pointer.call_deferred()

func _reset_pointer() -> void:_moved=false

func _pointer(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			set_zoom(zoom*(1.15 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1/1.15));get_viewport().set_input_as_handled()
		elif event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_MIDDLE]:
			if event.pressed:_panning=true;_moved=false;_drag_origin=get_global_mouse_position();_drag_scroll=Vector2(scroll.scroll_horizontal,scroll.scroll_vertical)
			else:_panning=false;_reset_pointer.call_deferred()
	elif event is InputEventMouseMotion and _panning:
		var delta:=get_global_mouse_position()-_drag_origin
		if delta.length()>6:_moved=true
		if _moved:scroll.scroll_horizontal=roundi(_drag_scroll.x-delta.x);scroll.scroll_vertical=roundi(_drag_scroll.y-delta.y);get_viewport().set_input_as_handled()

func _draw_edges() -> void:
	for row: Dictionary in rows.values():
		for parent: StringName in row.parents:
			if not rows.has(parent):continue
			var from: Vector2=_origin+Vector2(rows[parent].cell)*PITCH+NODE_SIZE*0.5
			var to: Vector2=_origin+Vector2(row.cell)*PITCH+NODE_SIZE*0.5
			var delta:=to-from
			var points:=PackedVector2Array()
			if absf(delta.x)>0 and absf(delta.y)>0:
				points.append(from+Vector2(0,signf(delta.y)*NODE_SIZE.y*0.5));points.append(Vector2(from.x,to.y));points.append(to-Vector2(signf(delta.x)*NODE_SIZE.x*0.5,0))
			else:
				var inset: Vector2=Vector2(signf(delta.x)*NODE_SIZE.x*0.5,signf(delta.y)*NODE_SIZE.y*0.5)
				points.append(from+inset);points.append(to-inset)
			tree.draw_polyline(points,Color("8170b7"),2.0,true)
			var tip: Vector2=points[-1];var direction: Vector2=(tip-points[-2]).normalized();var normal:=Vector2(-direction.y,direction.x)
			tree.draw_colored_polygon(PackedVector2Array([tip,tip-direction*9+normal*4,tip-direction*9-normal*4]),Color("8170b7"))

func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree():return
	if event.is_action_pressed("ui_cancel") and popup.visible:close_details();get_viewport().set_input_as_handled();return
	var direction:=Vector2.ZERO
	for pair in [["ui_left",Vector2.LEFT],["ui_right",Vector2.RIGHT],["ui_up",Vector2.UP],["ui_down",Vector2.DOWN]]:
		if event.is_action_pressed(pair[0]):direction=pair[1]
	if direction==Vector2.ZERO:return
	var focus:=get_viewport().gui_get_focus_owner()
	var current: StringName=&""
	for id: StringName in buttons:
		if buttons[id]==focus:current=id;break
	if current.is_empty():return
	buttons[_neighbor(current,direction)].grab_focus()
	get_viewport().set_input_as_handled()

func _neighbor(current: StringName,direction: Vector2) -> StringName:
	var best: StringName=current;var score:=INF
	for id: StringName in buttons:
		var delta: Vector2=Vector2(rows[id].cell-rows[current].cell)
		if delta.dot(direction)<=0:continue
		var distance: float=delta.length()+absf(delta.cross(direction))*4
		if distance<score:best=id;score=distance
	return best
