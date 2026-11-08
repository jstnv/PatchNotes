class_name FolderUI
extends RefCounted

## Shared presentation primitives. All identity values live in the Godot Theme.
const THEME := preload("res://resources/ui/onyx_theme.tres")
const FRAME_SAFE_VERTICAL_INSET := 42.0

static func enable_menu_gamepad() -> void:
	for action in {&"ui_accept":JOY_BUTTON_A,&"ui_cancel":JOY_BUTTON_B}:
		if InputMap.action_get_events(action).any(func(candidate_event):return candidate_event is InputEventJoypadButton or candidate_event is InputEventJoypadMotion):continue
		var event:=InputEventJoypadButton.new()
		event.button_index=JOY_BUTTON_A if action==&"ui_accept" else JOY_BUTTON_B
		InputMap.action_add_event(action,event)

static func _inherit_theme(panel: Control,parent: Node) -> void:
	var ancestor:=parent
	while ancestor!=null:
		if ancestor is Control and ancestor.theme!=null:
			panel.theme=ancestor.theme
			return
		ancestor=ancestor.get_parent()

class SurfaceHost extends Container:
	# A viewport-sized host must shrink after an autowrapped child's initial
	# minimum settles. Plain Control anchors retain the earlier expanded offsets.
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _notification(what: int) -> void:
		if what != NOTIFICATION_SORT_CHILDREN: return
		var vertical_inset := float(get_meta("surface_vertical_inset",20.0))
		var top_inset := float(get_meta("surface_top_inset",vertical_inset))
		var bottom_inset := float(get_meta("surface_bottom_inset",vertical_inset))
		for child in get_children():
			if child is Control and child.has_meta("bounded_folder"):
				# Keep sizing responsive while the title stack owns horizontal motion.
				var x: float = child.position.x if child.get_meta("folder_navigation_motion",false) else 20.0
				fit_child_in_rect(child,Rect2(Vector2(x,top_inset),(size-Vector2(40,top_inset+bottom_inset)).max(Vector2.ZERO)))
static func panel_vertical_insets(owner: Node) -> Vector2:
	var insets := Vector2.ONE * FRAME_SAFE_VERTICAL_INSET
	var hud := owner.get_parent()
	if hud == null: return insets
	var hud_header := hud.get_node_or_null("PersistentHeader") as Control
	var footer := hud.get_node_or_null("PersistentFooter") as Control
	if hud_header != null and hud_header.is_visible_in_tree():
		insets.x = maxf(insets.x,hud_header.get_global_rect().end.y+8.0)
	if footer != null and footer.is_visible_in_tree():
		insets.y = maxf(insets.y,owner.get_viewport().get_visible_rect().size.y-footer.get_global_rect().position.y+8.0)
	return insets
static func color(token: StringName) -> Color:
	return THEME.get_color(token,&"PatchNotes")
static func surface(parent: Node, document := false) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme = THEME
	_inherit_theme(panel,parent)
	# Constructors build some destinations before attachment to their Studio.
	panel.tree_entered.connect(func():_inherit_theme(panel,parent),CONNECT_ONE_SHOT)
	panel.theme_type_variation = &"DocumentPanel" if document else &"FolderPanel"
	parent.add_child(panel)
	return panel
static func label(parent: Node, text: String, role: StringName = &"SecondaryLabel") -> Label:
	var result := Label.new()
	result.text = text
	result.theme_type_variation = role
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(result)
	return result
static func button(parent: Node, text: String, callback: Callable, role: StringName = &"Button") -> Button:
	var result := Button.new()
	result.text = text
	result.theme_type_variation = role
	result.custom_minimum_size.y = 42
	result.pressed.connect(callback)
	parent.add_child(result)
	return result
static func header(parent: Node, title: String, subtitle: String, back: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",18)
	parent.add_child(row)
	var back_button:=button(row,"← Back",back);back_button.name="Back";standard_back(back_button)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	label(copy,title,&"HeadingLabel").autowrap_mode = TextServer.AUTOWRAP_OFF
	label(copy,subtitle)
	return row
static func tabs(parent: Node) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Folders"
	row.add_theme_constant_override("separation",2)
	parent.add_child(row)
	return row
static func sidebar(parent: Node) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	return box

## Consistent destination affordance; the button retains its original callback.
static func standard_back(control: Button) -> void:
	if control.text!="← Back":control.tooltip_text=control.text
	control.text="← Back"
	control.custom_minimum_size=Vector2(110,54)
	control.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	var row:=control.get_parent() as HBoxContainer
	if row!=null:row.move_child(control,0);row.add_theme_constant_override("separation",18)
