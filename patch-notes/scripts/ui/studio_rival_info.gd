extends PanelContainer
signal closed
var table: Tree
var details: RichTextLabel
var entries: Array=[]
static func rows(world: RivalWorld) -> Array:
	var result: Array=[]
	if world==null:return result
	var ids: Array=world.studios.keys();ids.sort()
	for id: StringName in ids:
		var run: RunState=world.studios[id].run
		var games: Array=[]
		for item: Dictionary in world.live_releases.values():
			if item.studio_id==id:games.append({"id":str(item.release_id),"title":str(item.title)})
		games.sort_custom(func(a,b):return a.id<b.id)
		result.append({"id":id,"name":run.get_studio_name(),"fans":run.get_fans(),"cash_cents":run.get_cash_cents(),"games":games})
	return result
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme=FolderUI.THEME;theme_type_variation=&"FolderPanel"
	add_to_group(PauseMenu.CANCEL_OWNER_GROUP)
	var margin:=MarginContainer.new()
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,20)
	add_child(margin)
	var layout:=VBoxContainer.new();layout.add_theme_constant_override("separation",16);margin.add_child(layout)
	FolderUI.header(layout,"Rival Info","Studios currently operating in your market",close)
	table=Tree.new();table.columns=4;table.hide_root=true;table.column_titles_visible=true;table.select_mode=Tree.SELECT_ROW
	table.size_flags_vertical=Control.SIZE_EXPAND_FILL;layout.add_child(table)
	for i in range(4):
		table.set_column_title(i,["Studio","Live games","Fans","Bankroll"][i]);table.set_column_expand(i,i==0);table.set_column_custom_minimum_width(i,[250,115,100,160][i])
	table.item_selected.connect(_selection)
	details=RichTextLabel.new();details.custom_minimum_size.y=100;layout.add_child(details)
	hide()
func open(world: RivalWorld) -> void:
	entries=rows(world);table.clear();var base:=table.create_item()
	for row: Dictionary in entries:
		var item:=table.create_item(base);item.set_metadata(0,entries.find(row))
		for i in range(4):item.set_text(i,[row.name,str(row.games.size()),str(row.fans),CashFormatter.format_exact_cents(row.cash_cents)][i])
	details.text="No rival Studios in this save." if entries.is_empty() else "Select a Studio to see its live games. Historical titles remain in Daily Chart."
	show();table.grab_focus()
	if not entries.is_empty():base.get_first_child().select(0);_selection()
func _selection() -> void:
	var item:=table.get_selected()
	if item==null:return
	var row: Dictionary=entries[int(item.get_metadata(0))];var titles: Array=[]
	for game: Dictionary in row.games:titles.append(game.title)
	details.text=row.name+"\n"+("No live games yet." if titles.is_empty() else "Live games: "+", ".join(titles))
func close() -> void:
	hide();closed.emit()
func _input(event: InputEvent) -> void:
	if is_visible_in_tree() and MenuTransitions.navigation_input_blocked(self):get_viewport().set_input_as_handled();return
	if is_visible_in_tree() and (event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_B)):
		close();get_viewport().set_input_as_handled()
