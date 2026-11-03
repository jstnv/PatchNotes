class_name MainMenu
extends Control
const Clock := preload("res://scripts/calendar/calendar_clock.gd")

signal studio_created(name: String, specialty: StringName, trait_ids: Array)
signal tutorial_requested
signal settings_requested
signal continue_requested
signal recovery_requested
signal quit_requested
var checkpoint_info: Dictionary = {"status":&"empty"}
var _replace_dialog: ConfirmationDialog

var _name_input: LineEdit
var _error: Label
var _setup: VBoxContainer
var _specialty: OptionButton
var _preview: Label
var _emphasis: Label
var _traits_step: VBoxContainer
var _review_step: VBoxContainer
var _trait_checks: Dictionary = {}
var _trait_lists: Dictionary = {}
var _overview_lists: Dictionary = {}
var _trait_error: Label
var _points: Label
var _review: Label
var _submitted := false
var _folder_buttons: Dictionary = {}
var _folder_panels: Dictionary = {}
var _visited: Dictionary = {}
var _review_signature: Array = []
var _folder_surface: PanelContainer
var _active_folder: StringName = &"genre"
var _bounces: Dictionary = {}
var _play: Button
var navigation: MenuTransitions
var _actions: Dictionary = {}
var _title_screen: VBoxContainer
var _setup_surface: PanelContainer
var _back: Button
var _discard_dialog: ConfirmationDialog
var _replacement_acknowledged := false
var _setup_focus: WeakRef
var _visualizer: Control
var _button_wave: Node
var _boot_entrance := false
var _boot_entrance_started := false
var _boot_entrance_elapsed := 0.0
var _boot_backdrop: Control
var _boot_logo: TextureRect
var _boot_logo_atlas: AtlasTexture
var _boot_logo_sheets: Array[Texture2D] = []
var _boot_input_modes: Dictionary = {}
var _boot_resume_modes: Dictionary = {}
const Visualizer := preload("res://scripts/ui/menu_circuit_background.gd")

const FOLDERS := {&"genre": "Genre Specializations", &"traits": "Traits", &"overview": "Overview"}

func _ready() -> void:
	_boot_entrance = get_tree().root.has_meta("boot_menu_transition")
	if _boot_entrance: get_tree().root.remove_meta("boot_menu_transition")
	FolderUI.enable_menu_gamepad()
	theme = preload("res://resources/ui/onyx_theme.tres")
	set_meta("folder_navigation_managed",true)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	var background := preload("res://scripts/ui/arcade_backdrop.gd").new()
	_boot_backdrop = background
	if _boot_entrance: background.entrance_progress = 0.0
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var root := FolderUI.SurfaceHost.new()
	root.name = "CenterContainer"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	_title_screen = VBoxContainer.new()
	_title_screen.name = "MenuLayout"
	_title_screen.add_theme_constant_override("separation",10)
	root.add_child(_title_screen)
	background.colorful_title = true
	_title_screen.visibility_changed.connect(func(): background.colorful_title = _title_screen.visible)
	var logo := TextureRect.new()
	logo.name = "PatchNotesLogo"
	var artwork := AtlasTexture.new()
	# The stationary logo is the exact last animation frame, not a second
	# differently cropped or coloured image swapped in at the music cue.
	artwork.atlas = preload("res://assets/boot/start-v10/reveal-09.png")
	artwork.region = Rect2(1020,500,510,250)
	logo.texture = artwork
	_boot_logo = logo
	_boot_logo_atlas = artwork
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(0,180)
	_title_screen.add_child(logo)
	FolderUI.label(_title_screen,"Build your studio. Shape your next game.")
	for entry in [["StartGame","Start Game"],["Continue","Continue"],["HowToPlay","How to Play"],["Settings","Settings"],["Quit","Quit"]]:
		var id: String = entry[0]
		var button := FolderUI.button(_title_screen,entry[1],_activate_action.bind(id),&"TitleMenuButton")
		button.name = id
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(300,50)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if id=="StartGame":button.theme_type_variation=&"ArcadePrimary"
		var icon_path:String={"StartGame":"arrows","HowToPlay":"controller","Settings":"settings","Quit":"quit"}.get(id,"")
		if id=="Continue" and checkpoint_info.status!=&"valid":icon_path="lock"
		if not icon_path.is_empty():
			button.icon=load("res://assets/ui/arcade/"+icon_path+".svg")
			button.add_theme_constant_override("icon_max_width",26)
			button.add_theme_constant_override("h_separation",18)
			button.icon_alignment=HORIZONTAL_ALIGNMENT_RIGHT if id in ["StartGame","Continue"] else HORIZONTAL_ALIGNMENT_LEFT
		_actions[id] = button
	_button_wave=preload("res://scripts/ui/title_button_wave.gd").new()
	_button_wave.name="TitleButtonWave"
	_button_wave.travel=5.0
	# Preserve the previous pixels-per-second speed with a shorter path.
	_button_wave.period=3.6*5.0/7.0
	add_child(_button_wave)
	var wave_buttons: Array[Button]=[]
	for id in ["StartGame","Continue","HowToPlay","Settings","Quit"]:wave_buttons.append(_actions[id])
	_button_wave.bind_buttons(_title_screen,wave_buttons)
	_actions.Continue.disabled = checkpoint_info.status != &"valid"
	_actions.Continue.focus_mode=Control.FOCUS_NONE if _actions.Continue.disabled else Control.FOCUS_ALL
	if checkpoint_info.status != &"empty": _actions.StartGame.text = "New Run"
	if checkpoint_info.status == &"valid":
		var saved: Dictionary = checkpoint_info.payload.run
		FolderUI.label(_title_screen,"%s · %s"%[saved.studio_name,Clock.label(int(saved.completed_run_cycles),int(saved.get("calendar_start_year",1980)),Clock.from_saved_profile(saved.get("calendar",{})))],&"MetadataLabel").name="SavedStudio"
	var recovery := FolderUI.button(_title_screen,"Saved Studio needs attention",func(): recovery_requested.emit())
	recovery.name = "CheckpointRecovery"
	recovery.visible = checkpoint_info.status not in [&"empty",&"valid"]
	_actions.CheckpointRecovery = recovery
	FolderUI.label(_title_screen,"PROTOTYPE",&"MetadataLabel")
	var window := get_tree().root
	var owner:=get_parent().get_parent() if get_parent()!=null else null
	var shared: Node=owner.get_node_or_null("Background/PersistentCircuitBackground") if owner!=null else null
	if shared!=null:
		_visualizer=shared
		background.transparent_base=true
	elif window.has_meta("boot_circuits"):
		_visualizer = window.get_meta("boot_circuits")
		window.remove_meta("boot_circuits")
		_visualizer.transfer_to(background)
	else:
		_visualizer = Visualizer.new()
		background.add_child(_visualizer)
	if shared==null:_visualizer.name = "MenuCircuitBackground"
	_setup_surface = FolderUI.surface(root)
	_setup_surface.set_meta("bounded_folder",true)
	_setup_surface.name = "StudioCreationFolder"
	_setup_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_setup_surface.offset_left=20; _setup_surface.offset_top=20
	_setup_surface.offset_right=-20; _setup_surface.offset_bottom=-20
	_setup = VBoxContainer.new()
	_setup.name = "StudioSetup"
	_setup.add_theme_constant_override("separation",10)
	_setup_surface.add_child(_setup)
	var header := FolderUI.header(_setup,"Studio Creation","Make a studio that is yours. Review each folder before creating it.",navigate_back)
	_back = header.get_node("Back")
	var metadata := FolderUI.label(header,"NEW STUDIO",&"MetadataLabel")
	metadata.autowrap_mode=TextServer.AUTOWRAP_OFF
	metadata.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation",16)
	_setup.add_child(name_row)
	var name_caption := FolderUI.label(name_row,"STUDIO NAME",&"MetadataLabel")
	name_caption.autowrap_mode=TextServer.AUTOWRAP_OFF
	name_caption.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	_name_input = LineEdit.new()
	_name_input.name = "StudioName"
	_name_input.placeholder_text = "Studio name"
	_name_input.max_length = 80
	_name_input.custom_minimum_size.y = 42
	_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(_name_input)
	_specialty = OptionButton.new()
	_specialty.name = "StudioSpecialty"
	_specialty.custom_minimum_size.y=42
	_specialty.add_item("Choose your permanent Genre specialty")
	_specialty.set_item_disabled(0,true)
	for genre: Dictionary in PrimitivePredevelopment.catalog().genres:
		_specialty.add_item(genre.name)
		_specialty.set_item_metadata(_specialty.item_count-1,StringName(genre.id))
	_specialty.select(0)
	_specialty.item_selected.connect(func(_index: int): _refresh_preview())
	_emphasis = Label.new()
	_emphasis.name = "SpecialtyEmphasis"
	_emphasis.theme_type_variation = &"MetadataLabel"
	_emphasis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview = Label.new()
	_preview.name = "SpecialtyRoster"
	_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build_traits(_setup)
	_build_folders()
	_error = FolderUI.label(_setup,"",&"SecondaryLabel")
	_error.name = "ErrorLabel"
	_error.custom_minimum_size.y=22
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation",14)
	_setup.add_child(footer)
	_points.reparent(footer)
	_points.theme_type_variation = &"MetadataLabel"
	_points.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_points.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	FolderUI.button(footer,"Discard setup",_confirm_discard).name="DiscardSetup"
	_play = FolderUI.button(footer,"Create Studio",_submit,&"PrimaryButton")
	_play.name="EnterStudio"
	_play.custom_minimum_size.x=170
	_refresh_preview()
	_setup_surface.hide()
	_setup.hide()
	navigation = MenuTransitions.new()
	navigation.automatic_entrances=false
	add_child(navigation)
	navigation.set_root(_title_screen)
	_name_input.text_changed.connect(func(_value: String): _draft_changed())
	_name_input.text_submitted.connect(func(_value: String): _submit())
	_specialty.item_selected.connect(func(_index: int): _draft_changed())
	resized.connect(_layout_title)
	_title_screen.minimum_size_changed.connect(_layout_title)
	_layout_title.call_deferred()
	if _boot_entrance:
		_prepare_boot_entrance()
	else:
		_actions.StartGame.grab_focus.call_deferred()

func _prepare_boot_entrance() -> void:
	for i in range(1, 10): _boot_logo_sheets.append(load("res://assets/boot/start-v10/reveal-%02d.png" % i))
	_set_boot_logo_frame(0)
	for child: Control in _title_screen.get_children():
		if child == _boot_logo: continue
		child.modulate.a = 0.0
		if child is Button:
			_boot_input_modes[child] = [child.mouse_filter, child.focus_mode]
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			child.focus_mode = Control.FOCUS_NONE
	var soundtrack := get_node("/root/Soundtrack")
	soundtrack.boot_menu_started.connect(_begin_boot_entrance, CONNECT_ONE_SHOT)
	if soundtrack.boot_phase == &"menu": _begin_boot_entrance()

func _begin_boot_entrance() -> void:
	if not _boot_entrance or _boot_entrance_started: return
	_boot_entrance_started = true
	_boot_entrance_elapsed = 0.0
	_boot_backdrop.entrance_progress = 1.0
	_set_boot_logo_frame(202)

static func _menu_reveal_frame(frame: int) -> int:
	# The source types PACH and erases it. Hold the correct PA until the
	# original animation resumes typing PATCH, without moving the music cue.
	if frame >= 91 and frame < 136: return 90
	return frame

func _set_boot_logo_frame(frame: int) -> void:
	var mapped := _menu_reveal_frame(clampi(frame, 0, 202))
	_boot_logo_atlas.atlas = _boot_logo_sheets[mapped / 24]
	var cell := mapped % 24
	_boot_logo_atlas.region = Rect2((cell % 4) * 510, (cell / 4) * 250, 510, 250)

func _update_boot_entrance(delta: float) -> void:
	var soundtrack := get_node("/root/Soundtrack")
	if not _boot_entrance_started:
		var progress := clampf((soundtrack.boot_switch_seconds() - soundtrack._boot_clock.logo_reveal_at()) / 2.0, 0.0, 1.0)
		_boot_backdrop.entrance_progress = progress
		var frame := mini(int(progress * 202.0), 202)
		_set_boot_logo_frame(frame)
		return
	_boot_entrance_elapsed += delta
	var bars := clampf(_boot_entrance_elapsed / 1.25, 0.0, 1.0)
	var index := 0
	for child: Control in _title_screen.get_children():
		if child == _boot_logo: continue
		if child is Button and child in _boot_input_modes:
			if not child.visible: continue
			var progress := clampf((_boot_entrance_elapsed - index * 0.14) / 1.25, 0.0, 1.0)
			child.modulate.a = progress
			child.position.x = -(_title_screen.position.x + child.size.x + 30.0) * pow(1.0 - progress, 3.0)
			index += 1
		else:
			child.modulate.a = bars
	if _boot_entrance_elapsed < 1.25 + 0.14 * max(0, index - 1): return
	for button: Button in _boot_input_modes:
		button.mouse_filter = _boot_input_modes[button][0]
		button.focus_mode = _boot_input_modes[button][1]
		button.modulate.a = 1.0
	for node: Node in _boot_resume_modes:
		if is_instance_valid(node): node.process_mode = _boot_resume_modes[node]
	_boot_resume_modes.clear()
	_boot_entrance = false
	_boot_logo_sheets.clear()
	_actions.StartGame.grab_focus.call_deferred()

func _layout_title() -> void:
	if not is_instance_valid(_title_screen): return
	_title_screen.size.x=clampf(size.x*0.32,300,440)
	_title_screen.size.y=_title_screen.get_combined_minimum_size().y
	_title_screen.position=Vector2(maxf(24,size.x*0.045),maxf(12,(size.y-_title_screen.size.y)/2))
	if is_instance_valid(_visualizer):
		if is_ancestor_of(_visualizer):
			_visualizer.position=Vector2.ZERO
			_visualizer.size=size
		_visualizer.readability_right=_title_screen.position.x+_title_screen.size.x

func _process(delta: float) -> void:
	if not is_instance_valid(_visualizer) or navigation == null: return
	if _boot_entrance:
		_update_boot_entrance(delta)
		_visualizer.set_active(true)
		return
	# Full-screen loading can own focus outside the folder stack.
	var focus_owner:=get_viewport().gui_get_focus_owner()
	var owns_focus:=focus_owner==null or is_ancestor_of(focus_owner)
	_button_wave.advance(delta,owns_focus and is_visible_in_tree() and _title_screen.is_visible_in_tree() and navigation.is_top(_title_screen) and not navigation.busy)
	_visualizer.readability_right=_title_screen.position.x+_title_screen.size.x if owns_focus and _title_screen.is_visible_in_tree() and navigation.is_top(_title_screen) else 0.0
	_visualizer.set_active(true)

func action_button(id: String) -> Button: return _actions.get(id)

func _activate_action(id: String) -> void:
	if _boot_entrance: return
	if navigation.busy or navigation.depth()!=1: return
	match id:
		"StartGame": open_setup()
		"Continue":
			if not _actions.Continue.disabled: continue_requested.emit()
		"HowToPlay": tutorial_requested.emit()
		"Settings": settings_requested.emit()
		"Quit": quit_requested.emit()

func open_setup() -> void:
	if navigation.busy or navigation.depth()!=1 or _submitted: return
	if checkpoint_info.status != &"empty" and not _replacement_acknowledged:
		if is_instance_valid(_replace_dialog) and _replace_dialog.visible: return
		if is_instance_valid(_replace_dialog): _replace_dialog.queue_free()
		_replace_dialog=preload("res://scripts/ui/quit_confirmation.gd").new()
		_replace_dialog.wrap_controls=false
		_replace_dialog.min_size=Vector2i(680,220)
		_replace_dialog.ok_button_text="Continue setup"
		_replace_dialog.title="Replace saved Studio?"
		add_child(_replace_dialog)
		_replace_dialog.dialog_text="Your existing checkpoint will be archived. Replacement happens only after the new Studio is created."
		_replace_dialog.confirmed.connect(func():
			_replacement_acknowledged=true
			_push_setup())
		_replace_dialog.popup_centered(Vector2i(680,220))
		_replace_dialog.get_cancel_button().grab_focus()
		return
	_push_setup()

func _push_setup() -> void:
	if _submitted or navigation.busy or navigation.depth()!=1: return
	_setup.show()
	if _visited.is_empty(): _open_folder(&"genre")
	var focus: Control = _setup_focus.get_ref() if _setup_focus != null else null
	if not is_instance_valid(focus): focus=_name_input
	navigation.push(_setup_surface,focus,func(): _setup.hide())

func navigate_back() -> void:
	if _submitted: return
	if navigation.is_top(_setup_surface) and not navigation.busy:
		var focus := get_viewport().gui_get_focus_owner()
		if focus == _back: focus=_folder_buttons[_active_folder]
		if focus != null and _setup_surface.is_ancestor_of(focus): _setup_focus=weakref(focus)
	if navigation.pop():
		_actions.StartGame.text="Resume setup"

func _confirm_discard() -> void:
	if navigation.busy or _submitted: return
	if is_instance_valid(_discard_dialog): _discard_dialog.queue_free()
	_discard_dialog=preload("res://scripts/ui/quit_confirmation.gd").new()
	# This fixed copy fits the authored surface; avoid Window retaining a
	# transient autowrap minimum while the new folder controls are laid out.
	_discard_dialog.wrap_controls=false
	_discard_dialog.min_size=Vector2i(680,220)
	_discard_dialog.ok_button_text="Discard setup"
	_discard_dialog.title="Discard this setup?"
	add_child(_discard_dialog)
	_discard_dialog.dialog_text="Clear the studio name, Genre and trait choices? Your saved Studio will not change."
	_discard_dialog.confirmed.connect(discard_setup)
	_discard_dialog.popup_centered(Vector2i(680,220))
	_discard_dialog.get_cancel_button().grab_focus()

func discard_setup() -> void:
	if navigation.busy or _submitted: return
	_name_input.clear()
	_specialty.select(0)
	_visited.clear()
	_review_signature.clear()
	_active_folder=&"genre"
	_clear_trait_draft()
	_refresh_preview()
	_replacement_acknowledged=false
	_setup_focus=null
	navigation.pop()
	_actions.StartGame.text="Start Game" if checkpoint_info.status==&"empty" else "New Run"

func _submit() -> void:
	_confirm_studio()


func _build_folders() -> void:
	var folio := VBoxContainer.new()
	folio.add_theme_constant_override("separation",0)
	folio.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_setup.add_child(folio)
	_setup.move_child(folio,2)
	var tabs := FolderUI.tabs(folio)
	var group := ButtonGroup.new()
	for id: StringName in FOLDERS:
		var button := FolderUI.button(tabs,FOLDERS[id],_open_folder.bind(id),&"FolderTab")
		button.name=String(id)
		button.toggle_mode=true
		button.button_group=group
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		_folder_buttons[id]=button
	_folder_surface=FolderUI.surface(folio,true)
	_folder_surface.name="FolderContent"
	_folder_surface.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var genre := VBoxContainer.new()
	genre.name="Genre"
	genre.add_theme_constant_override("separation",12)
	genre.add_child(_specialty)
	genre.add_child(_emphasis)
	var scroll := FolderUI.sidebar(genre)
	scroll.add_child(_preview)
	for pair in [[&"genre",genre],[&"traits",_traits_step],[&"overview",_review_step]]:
		var panel: VBoxContainer=pair[1]
		if panel.get_parent()!=null: panel.get_parent().remove_child(panel)
		_folder_surface.add_child(panel)
		panel.size_flags_vertical=Control.SIZE_EXPAND_FILL
		panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		_folder_panels[pair[0]]=panel
	_open_folder(&"genre")


func _draft_signature() -> Array:
	return [_name_input.text, _specialty.selected, _secondary_ids()]


func _needs_attention(id: StringName) -> bool:
	if not _visited.get(id, false): return true
	match id:
		&"genre": return _specialty.selected <= 0
		&"traits": return not _selection().valid
		&"overview": return _review_signature != _draft_signature()
	return false


func _refresh_attention() -> void:
	for id: StringName in _folder_buttons:
		_folder_buttons[id].text = FOLDERS[id] + (" *" if _needs_attention(id) else "")
		_folder_buttons[id].tooltip_text = "Needs attention" if _needs_attention(id) else "Reviewed"


func _draft_changed() -> void:
	_review_signature.clear()
	if is_instance_valid(_error): _error.text = ""
	_refresh_attention()
	if _active_folder == &"overview": _refresh_review()


func _open_folder(id: StringName) -> void:
	_active_folder = id
	_visited[id] = true
	for key: StringName in _folder_panels:
		_folder_panels[key].visible = key == id
		_folder_buttons[key].set_pressed_no_signal(key == id)
	if id == &"overview":
		_refresh_review()
		_review_signature = _draft_signature().duplicate(true)
	_refresh_attention()


func _bounce(id: StringName) -> void:
	var button: Button = _folder_buttons[id]
	if _bounces.has(id): _bounces[id].kill()
	button.scale = Vector2.ONE
	button.pivot_offset = button.size / 2
	var tween := create_tween()
	_bounces[id] = tween
	tween.tween_property(button, "scale", Vector2(1.035, 1.10), 0.10)
	tween.tween_property(button, "scale", Vector2.ONE, 0.16)


func _refresh_preview() -> void:
	if _specialty.selected <= 0:
		_emphasis.text = "Every Studio starts with Public Action Engine access."
		_preview.text = "17 fixed Features · 27 Scope · No upfront fee · 30% post-platform royalty.\nChoose your Studio specialty; each game can use any Genre."
		return
	var preview := StudioSpecialties.preview(_specialty.get_item_metadata(_specialty.selected))
	if preview.is_empty():
		_emphasis.text = "Specialty roster unavailable."
		_preview.text = ""
		return
	var public_engine:=preload("res://scripts/engines/public_action_engine.gd").definition()
	var definitions: Dictionary={}
	for entry: Dictionary in FeatureStoreCatalog.starting_features()+FeatureStoreCatalog.entries():definitions[StringName(entry.id)]=entry
	var names: Array[String]=[]
	for id: StringName in public_engine.library:names.append(str(definitions[id].name))
	_emphasis.text = "Public Action Engine · 17 Features · 27 printed Scope"
	_preview.text = ", ".join(names)+"\n\nPublic access, not engine ownership. No upfront fee; 30% royalty on post-platform revenue. Fixed library; no upgrades or Technology Skill Tree.\nStudio specialty is permanent; each game's Genre is chosen separately. The engine adds +0.1 Graphics/Technology only on qualifying Specialization hands."

func show_error(message: String) -> void:
	_submitted = false
	_error.text = message
	_setup.show()


func _label(parent: Node, value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


func _button(parent: Node, node_name: String, caption: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = caption
	button.custom_minimum_size.y = 36
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _build_traits(layout: Node) -> void:
	_traits_step = VBoxContainer.new()
	_traits_step.name = "StudioTraits"
	_traits_step.add_theme_constant_override("separation", 8)
	layout.add_child(_traits_step)
	_label(_traits_step, "Studio Traits · Optional choices").theme_type_variation=&"FolderHeading"
	_trait_error = _label(_traits_step, "")
	_trait_error.name = "TraitError"
	var groups := HBoxContainer.new()
	groups.add_theme_constant_override("separation", 18)
	groups.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_traits_step.add_child(groups)
	for selected: bool in [true, false]:
		var roster := VBoxContainer.new()
		roster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		roster.name = "Selected" if selected else "Available"
		groups.add_child(roster)
		_label(roster, roster.name).theme_type_variation=&"FolderHeading"
		var content := _trait_scroll(roster)
		for positive: bool in [true,false]:
			_label(content, "Positive" if positive else "Negative").add_theme_color_override("font_color",FolderUI.color(&"cyan") if positive else FolderUI.color(&"negative"))
			var list := VBoxContainer.new()
			content.add_child(list)
			_trait_lists[Vector2i(int(selected),int(positive))] = list
	for id: StringName in StudioTraits.TRAITS:
		var entry: Dictionary = StudioTraits.TRAITS[id]
		var check := CheckBox.new()
		check.name = String(id)
		check.text = entry.name
		check.tooltip_text = "%s\n%s" % [entry.price,entry.description]
		_trait_lists[Vector2i(0,int(entry.positive))].add_child(check)
		_trait_checks[id] = check
		check.toggled.connect(func(on: bool):
			if on and id in [&"graduate",&"college_dropout"]:
				_trait_checks[&"graduate" if id == &"college_dropout" else &"college_dropout"].set_pressed_no_signal(false)
			_refresh_traits())
	_points = _label(_traits_step, "")
	_points.name = "Points"
	_review_step = VBoxContainer.new()
	_review_step.name = "CreationReview"
	_review_step.add_theme_constant_override("separation", 12)
	layout.add_child(_review_step)
	_label(_review_step, "Your Studio · Overview").theme_type_variation=&"FolderHeading"
	var summary_scroll := _trait_scroll(_review_step)
	summary_scroll.get_parent().custom_minimum_size.y = 116
	_review = _label(summary_scroll, "")
	_review.theme_type_variation=&"MetadataLabel"
	_review.name = "Summary"
	var review_columns := HBoxContainer.new()
	review_columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	review_columns.add_theme_constant_override("separation",18)
	_review_step.add_child(review_columns)
	for positive: bool in [true,false]:
		var column := VBoxContainer.new()
		column.name = "PositiveTraits" if positive else "NegativeTraits"
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		review_columns.add_child(column)
		_label(column,"Positive Traits" if positive else "Negative Traits")
		_overview_lists[positive] = _trait_scroll(column)
	_refresh_traits()


func _trait_scroll(parent: Node) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	parent.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	return content


func _secondary_ids() -> Array:
	var ids: Array = []
	for id: StringName in _trait_checks:
		if _trait_checks[id].button_pressed: ids.append(id)
	return ids


func _selection() -> Dictionary:
	return StudioTraits.evaluate_traits(_secondary_ids())


func _refresh_traits() -> void:
	var selection := _selection()
	_points.text = "Points: %d · Starting cash bonus: %s" % [selection.get("remaining_points",0),CashFormatter.format_exact_cents(selection.get("point_cash_cents",0)+selection.get("family_funding_cents",0))]
	for id: StringName in StudioTraits.TRAITS:
		var check: CheckBox = _trait_checks[id]
		var list: VBoxContainer = _trait_lists[Vector2i(int(check.button_pressed),int(StudioTraits.TRAITS[id].positive))]
		if check.get_parent() != list: check.reparent(list)
		list.move_child(check,list.get_child_count()-1)
	_trait_error.text = selection.reason
	_draft_changed()


func _show_review() -> void:
	_open_folder(&"overview")


func _refresh_review() -> void:
	var selection := _selection()
	for list: VBoxContainer in _overview_lists.values():
		for child in list.get_children(): list.remove_child(child); child.queue_free()
	for id: StringName in _secondary_ids():
		var entry: Dictionary = StudioTraits.TRAITS[id]
		var label := _label(_overview_lists[entry.positive],entry.name)
		label.tooltip_text = "%s\n%s" % [entry.price,entry.description]
	if not selection.valid:
		_review.text = "Check Traits: " + selection.reason
		return
	_review.text = "%s · %s specialty\nPoints: %d · Starting cash bonus: %s\nStarting cash: %s · Monthly rent: %s" % [_name_input.text.strip_edges(), _specialty.get_item_text(_specialty.selected),selection.remaining_points,CashFormatter.format_exact_cents(selection.point_cash_cents+selection.get("family_funding_cents",0)),CashFormatter.format_exact_cents(550000+selection.point_cash_cents+selection.get("family_funding_cents",0)),CashFormatter.format_exact_cents(StudioFinanceLedger.starting_rent_cents(StudioTraits.is_active(selection,&"expensive_lease")))]
	_review.text += "\nStarting Fans: %d%s" % [StudioTraits.starting_fans(selection), " (Cult Following trial; ordinary gains/losses)" if StudioTraits.starting_fans(selection) > 0 else ""]
	if _specialty.selected > 0:
		_review.text += "\nPublic Action Engine access · 17 fixed Features · 27 Scope\nNo upfront fee · 30% post-platform royalty · No upgrades/Technology Skill Tree"


func _confirm_studio() -> void:
	if _submitted or not is_inside_tree() or navigation.busy or not navigation.is_top(_setup_surface): return
	_refresh_attention()
	var blocked := false
	for id: StringName in FOLDERS:
		if _needs_attention(id):
			blocked = true
			_bounce(id)
	if _name_input.text.strip_edges().is_empty():
		_error.text = "Enter a studio name."
		_name_input.grab_focus()
		return
	if blocked:
		_error.text = "Review the folders marked with an asterisk before playing."
		return
	_error.text = ""
	var selection := _selection()
	if not selection.valid or _specialty.selected <= 0 or _name_input.text.strip_edges().is_empty(): return
	_submitted = true
	studio_created.emit(_name_input.text.strip_edges(), _specialty.get_item_metadata(_specialty.selected), selection.trait_ids)


func _clear_trait_draft() -> void:
	for check: CheckBox in _trait_checks.values(): check.set_pressed_no_signal(false)
	_submitted = false
	_refresh_traits()


func _input(event: InputEvent) -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused == null or not is_ancestor_of(focused): return
	if focused is OptionButton and focused.get_popup().visible: return
	if not is_visible_in_tree() or not event.is_action_pressed("ui_cancel"): return
	if navigation.busy:
		get_viewport().set_input_as_handled()
		return
	if navigation.is_top(_setup_surface): navigate_back()
	else: return
	get_viewport().set_input_as_handled()
