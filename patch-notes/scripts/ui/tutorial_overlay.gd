class_name TutorialOverlay
extends CanvasLayer

signal closed

const TOPICS := {
	&"predevelopment": [
		{"title": "Name Your Game", "body": "Choose a required game name, Genre and Theme. These choices stay with the project. Themes have no gameplay effects yet."},
		{"title": "Begin Development", "body": "Editing and cancelling are free. Begin Development needs no cash and advances the run calendar by one cycle. Your new project starts at cycle 0 with four redraws."},
	],
	&"design": [
		{"title": "Design: Set Priorities", "body": "Allocate exactly 100 priority points in 5-point steps, keeping each category between 5 and 50. Priorities weight future draws. Begin Design is free; changing priorities afterward costs one cycle."},
		{"title": "Design: Build a Hand", "body": "Select exactly four candidate cards, then Implement. A successful hand advances one cycle. Features exhaust after use; Passes are renewable. Watch your Scope and Core Scores."},
		{"title": "Design: Redraw and Synergy", "body": "Select candidates to replace and use Redraw. Each selected card costs one shared redraw, with no cycle cost. Successful production restores one redraw. Matching or balanced hands can trigger synergies."},
	],
	&"alpha": [
		{"title": "Alpha: Expand and Test", "body": "Set Alpha priorities, then build four-card hands to expand your game. Host Playtests help you evaluate the project. Features are finite, Passes are renewable, and productive actions advance time."},
		{"title": "Alpha: Prepare for Beta", "body": "Watch Scope, Core Scores and Bug Pressure as you produce. Finalize Alpha through its existing phase controls before moving into Beta."},
	],
	&"beta": [
		{"title": "Beta: Find and Fix Bugs", "body": "Set Beta priorities and choose four-card hands. Search for Bugs reveals Hidden Bugs; Debug fixes Known Bugs. The HUD shows Known and Fixed totals."},
		{"title": "Beta: Prepare to Launch", "body": "Balance testing, fixes and marketing before finalizing Beta. Launch freezes the release results and enters Studio automatically at no navigation cost."},
	],
	&"studio": [
		{"title": "Studio: Between Games", "body": "Produce your first game, then return to browse release summaries, the Feature Store and available Contracts. Browsing costs no cycles or cash."},
		{"title": "Studio: Productive Time", "body": "Purchases and productive actions use the shared run calendar. Historical sales earn and settle through that boundary. Produce Next Game preserves your run progression and creates a fresh project."},
	],
	&"review": [
		{"title": "Review: Inspect Your Release", "body": "Use the five tabs to inspect the frozen release results. Back to Summary returns to Studio for free; viewing results never rerolls or pays them again."},
	],
	&"contract": [
		{"title": "Contracts: Two Production Hands", "body": "The fixed Primitive Contract has two four-card hands. Set priorities, use eligible finite Features and renewable Passes, and aim for its displayed targets."},
		{"title": "Contracts: Shared Resources", "body": "Contracts share your run calendar and redraw budget. Acceptance is free, but an accepted contract cannot be abandoned. Completion pays the cash reward once."},
	],
	&"feature_store": [
		{"title": "Feature Store: Follow the Tree", "body": "Select a node to inspect its prerequisites, price and familiarity discount. Owned Features carry into future projects; playing prerequisite Features can reduce a child's price."},
		{"title": "Feature Store: Purchase Carefully", "body": "Opening and closing are free. A successful purchase costs its displayed cash price and one productive cycle. Locked nodes require their prerequisites; unaffordable nodes need more cash."},
	],
}

var topic: StringName = &"design"
var pages: Array = TOPICS[&"design"]
var shade: ColorRect
var dialog: PanelContainer
var step_label: Label
var title_label: Label
var body_label: Label
var back_button: Button
var next_button: Button
var skip_button: Button
var page_index := 0
var previous_focus: Control


func _ready() -> void:
	layer = 30
	visible = false
	shade = ColorRect.new()
	shade.name = "TutorialBlocker"
	shade.color = Color("#080409")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.offset_bottom = -46.0
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	dialog = PanelContainer.new()
	dialog.name = "TutorialDialog"
	dialog.theme = preload("res://resources/ui/workspace_theme.tres")
	dialog.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	dialog.offset_left = -340
	dialog.offset_right = 340
	dialog.offset_top = -210
	dialog.offset_bottom = 210
	shade.add_child(dialog)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	dialog.add_child(content)
	step_label = Label.new()
	step_label.add_theme_color_override("font_color", Color("#79d4da"))
	content.add_child(step_label)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color("#f5bd59"))
	content.add_child(title_label)
	body_label = Label.new()
	body_label.custom_minimum_size = Vector2(620, 220)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 18)
	content.add_child(body_label)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	content.add_child(actions)
	back_button = Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(130, 40)
	back_button.pressed.connect(previous_page)
	actions.add_child(back_button)
	next_button = Button.new()
	next_button.custom_minimum_size = Vector2(180, 40)
	next_button.pressed.connect(next_page)
	actions.add_child(next_button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	skip_button = Button.new()
	skip_button.text = "Close Tips"
	skip_button.custom_minimum_size = Vector2(150, 40)
	skip_button.pressed.connect(close)
	actions.add_child(skip_button)


func open(context: StringName = &"design") -> void:
	topic = context if TOPICS.has(context) else &"design"
	pages = TOPICS[topic]
	previous_focus = get_viewport().gui_get_focus_owner()
	page_index = 0
	visible = true
	_refresh_page()
	next_button.grab_focus()


func close() -> void:
	if not visible: return
	visible = false
	if is_instance_valid(previous_focus) and previous_focus.is_inside_tree():
		previous_focus.grab_focus()
	closed.emit()


func next_page() -> void:
	if not visible: return
	if page_index == pages.size() - 1:
		close()
		return
	page_index += 1
	_refresh_page()


func previous_page() -> void:
	if not visible or page_index == 0: return
	page_index -= 1
	_refresh_page()


func _refresh_page() -> void:
	var page: Dictionary = pages[page_index]
	step_label.text = "PHASE TIPS  ·  %d / %d" % [page_index + 1, pages.size()]
	title_label.text = page.title
	body_label.text = page.body
	back_button.disabled = page_index == 0
	next_button.text = "Got It" if page_index == pages.size() - 1 else "Next Tip"


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
