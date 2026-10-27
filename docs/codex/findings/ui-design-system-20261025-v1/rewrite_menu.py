"""One-time structural UI rewrite; retain the canonical setup evaluators below."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[4]
p=ROOT/'patch-notes/scripts/phases/main_menu.gd'
s=p.read_text(encoding='utf8')
s=s.replace('var _play: Button','''var _play: Button
var navigation: MenuTransitions
var _actions: Dictionary = {}
var _title_screen: VBoxContainer
var _setup_surface: PanelContainer
var _back: Button
var _discard_dialog: ConfirmationDialog
var _replacement_acknowledged := false''')
start=s.index('func _ready() -> void:')
end=s.index('func _submit() -> void:')
s=s[:start]+'''func _ready() -> void:
	theme = FolderUI.THEME
	set_meta("folder_navigation_managed",true)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	var background := ColorRect.new()
	background.color = FolderUI.color(&"background")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var root := Control.new()
	root.name = "CenterContainer"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	_title_screen = VBoxContainer.new()
	_title_screen.name = "MenuLayout"
	_title_screen.add_theme_constant_override("separation",8)
	root.add_child(_title_screen)
	var logo := TextureRect.new()
	logo.name = "PatchNotesLogo"
	var artwork := AtlasTexture.new()
	artwork.atlas = preload("res://assets/branding/patch_notes_logo.png")
	artwork.region = Rect2(40,300,1200,620)
	logo.texture = artwork
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(0,190)
	_title_screen.add_child(logo)
	FolderUI.label(_title_screen,"Build your studio. Shape your next game.")
	for entry in [["StartGame","Start Game"],["Continue","Continue"],["HowToPlay","How to Play"],["Settings","Settings"],["Quit","Quit"]]:
		var id: String = entry[0]
		var button := FolderUI.button(_title_screen,entry[1],_activate_action.bind(id),&"MenuButton")
		button.name = id
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(320,44)
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_actions[id] = button
	_actions.Continue.disabled = checkpoint_info.status != &"valid"
	if checkpoint_info.status != &"empty": _actions.StartGame.text = "New Run"
	if checkpoint_info.status == &"valid":
		var saved: Dictionary = checkpoint_info.payload.run
		FolderUI.label(_title_screen,"%s · %d · Month %d"%[saved.studio_name,1980+int(saved.completed_run_cycles)/24,int(saved.completed_run_cycles)/2+1],&"MetadataLabel")
	var recovery := FolderUI.button(_title_screen,"Saved Studio needs attention",func(): recovery_requested.emit())
	recovery.name = "CheckpointRecovery"
	recovery.visible = checkpoint_info.status not in [&"empty",&"valid"]
	_actions.CheckpointRecovery = recovery
	FolderUI.label(_title_screen,"PROTOTYPE",&"MetadataLabel")
	_setup_surface = FolderUI.surface(root)
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
	metadata.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation",16)
	_setup.add_child(name_row)
	FolderUI.label(name_row,"STUDIO NAME",&"MetadataLabel").vertical_alignment=VERTICAL_ALIGNMENT_CENTER
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
	navigation = MenuTransitions.new()
	navigation.automatic_entrances=false
	add_child(navigation)
	navigation.set_root(_title_screen)
	_name_input.text_changed.connect(func(_value: String): _draft_changed())
	_name_input.text_submitted.connect(func(_value: String): _submit())
	_specialty.item_selected.connect(func(_index: int): _draft_changed())
	resized.connect(_layout_title)
	_layout_title.call_deferred()
	_actions.StartGame.grab_focus.call_deferred()

func _layout_title() -> void:
	if not is_instance_valid(_title_screen): return
	_title_screen.size.x=minf(520,size.x-80)
	_title_screen.size.y=_title_screen.get_combined_minimum_size().y
	_title_screen.position=Vector2(48,maxf(12,(size.y-_title_screen.size.y)/2))

func action_button(id: String) -> Button: return _actions.get(id)

func _activate_action(id: String) -> void:
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
		_replace_dialog=ConfirmationDialog.new()
		_replace_dialog.title="Replace saved Studio?"
		_replace_dialog.dialog_text="Your existing checkpoint will be archived. Replacement happens only after the new Studio is created."
		add_child(_replace_dialog)
		_replace_dialog.confirmed.connect(func():
			_replacement_acknowledged=true
			_push_setup())
		_replace_dialog.popup_centered()
		_replace_dialog.get_cancel_button().grab_focus()
		return
	_push_setup()

func _push_setup() -> void:
	if _submitted or navigation.busy or navigation.depth()!=1: return
	_setup.show()
	if _visited.is_empty(): _open_folder(&"genre")
	navigation.push(_setup_surface,_name_input)

func navigate_back() -> void:
	if _submitted: return
	if navigation.pop():
		_actions.StartGame.text="Resume setup"

func _confirm_discard() -> void:
	if navigation.busy or _submitted: return
	if is_instance_valid(_discard_dialog): _discard_dialog.queue_free()
	_discard_dialog=ConfirmationDialog.new()
	_discard_dialog.title="Discard this setup?"
	_discard_dialog.dialog_text="Clear the studio name, Genre and trait choices? Your saved Studio will not change."
	add_child(_discard_dialog)
	_discard_dialog.confirmed.connect(discard_setup)
	_discard_dialog.popup_centered()
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
	navigation.pop()
	_actions.StartGame.text="Start Game" if checkpoint_info.status==&"empty" else "New Run"

''' + s[end:]
start=s.index('func _build_folders(')
end=s.index('func _draft_signature()')
s=s[:start]+'''func _build_folders() -> void:
	var tabs := FolderUI.tabs(_setup)
	_setup.move_child(tabs,2)
	var group := ButtonGroup.new()
	for id: StringName in FOLDERS:
		var button := FolderUI.button(tabs,FOLDERS[id],_open_folder.bind(id),&"FolderTab")
		button.name=String(id)
		button.toggle_mode=true
		button.button_group=group
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		_folder_buttons[id]=button
	_folder_surface=FolderUI.surface(_setup,true)
	_folder_surface.name="FolderContent"
	_folder_surface.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_setup.move_child(_folder_surface,3)
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


''' + s[end:]
s=s.replace('func _build_traits(layout: VBoxContainer)','func _build_traits(layout: Node)')
s=s.replace('Color("9dd3bd") if positive else Color("e3aa9f")','FolderUI.color(&"cyan") if positive else FolderUI.color(&"orange")')
s=s.replace('if _submitted or not is_inside_tree(): return','if _submitted or not is_inside_tree() or navigation.busy or not navigation.is_top(_setup_surface): return')
s=s.replace('\tif _setup.visible: _setup.get_node("Back").pressed.emit()','\tif navigation.busy:\n\t\tget_viewport().set_input_as_handled()\n\t\treturn\n\tif navigation.is_top(_setup_surface): navigate_back()')
p.write_text(s,encoding='utf8')
