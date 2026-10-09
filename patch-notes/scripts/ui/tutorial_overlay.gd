class_name TutorialOverlay
extends CanvasLayer

signal closed

const TOPICS := {
	&"main_menu": [
		{"title": "Create Your Studio", "body": "Choose Start Game, name your studio and choose one permanent Genre specialty. Preview its free starting Features, then enter Studio. The Store offers optional additions; each game can use any Genre."},
		{"title": "Produce a Game", "body": "Name the game and choose a Genre and Theme. During Design, Alpha and Beta, set priorities, select four cards per hand and decide when to move to the next phase."},
		{"title": "After Release", "body": "Studio keeps your owned Features and released-game history. Browse reviews, sales, the Feature Store and available Contracts. The footer Tutorial button opens detailed help for your current screen."},
	],
	&"predevelopment": [
		{"title": "Name Your Game", "body": "Choose a required game name, Genre and Theme. These choices stay with the project. Themes have no gameplay effects yet."},
		{"title": "Begin Development", "body": "Editing and cancelling are free. Begin Development needs no cash and advances the run calendar by one cycle. Your new project starts at cycle 0 with four redraws."},
	],
	&"design": [
		{"title": "Design: Quality and Scope", "body": "Your four Core scores measure quality: Graphics for visuals, Sound for audio, Technology for technical systems, and Design for gameplay. Cards build these scores toward Review. Scope measures how much game you have built. Feature cards add their printed Scope toward the HUD target. A complete game still needs strong Core scores. Hover over a HUD score for a reminder."},
		{"title": "Design: Priorities and Hands", "body": "Allocate 100 priority points in 5-point steps, with each category from 5 to 50. Higher priorities favor that category in future draws and redraws; they do not add scores. Begin Design is free. Later priority changes cost one cycle. Select exactly four cards, then Implement: a successful hand costs one cycle. Features exhaust for this project; Passes can return."},
		{"title": "Design: Redraw and Synergy", "body": "Redraw selected cards for one shared redraw each and no cycle; successful production restores one. Four cards sharing a primary Core stat trigger Specialization (+50% hand Core gains). Otherwise, a hand with a Feature gains Balanced Production (+20% hand Core gains) when all four projected Core scores are within 20% of their average. Neither bonus raises Scope."},
	],
	&"alpha": [
		{"title": "Alpha: Expand and Test", "body": "Set Alpha priorities, then build four-card hands to expand your game. Host Playtests help you evaluate the project. Features are finite, Passes are renewable, and productive actions advance time."},
		{"title": "Alpha: Synergy and Beta", "body": "Four cards, including Passes, with the same primary Core stat trigger Specialization (+50% hand Core gains). Otherwise, a hand with a Feature gains Balanced Production (+20% hand Core gains) if all four projected Core scores are within 20% of their average. Neither boosts Scope or Bug Pressure. Check those values before moving to Beta."},
	],
	&"beta": [
		{"title": "Beta: Focused Hands", "body": "Set priorities and choose four-card hands. Search reveals Hidden Bugs; Debug fixes Known Bugs. Four QA cards trigger QA Specialization: each card's value is multiplied by 1.50 before its bug formula. Four Marketing cards trigger Marketing Specialization: the summed printed Marketing value is multiplied by 1.50, then rounded down once."},
		{"title": "Beta: Balance and Launch", "body": "A hand with a 2/1/1 mix of QA, Marketing and Insider cards triggers Balanced Operations. It boosts eligible bug work, Marketing and insight chances by 25%, but not cash. Synergy bonuses do not stack. Launch freezes the release results and enters Studio for free."},
	],
	&"studio": [
		{"title": "Studio: Between Games", "body": "Entering Studio refills your redraws to four, including after a release or completed Contract. Browse release summaries, the Feature Store and available Contracts. Browsing costs no cycles or cash."},
		{"title": "Studio: Productive Time", "body": "Productive actions use the shared run calendar, where historical sales earn and settle. Later Feature Store branch and Primitive reserve purchases each take one cycle. Produce Next Game creates a fresh project while preserving the run."},
	],
	&"review": [
		{"title": "Review: Inspect Your Release", "body": "Use the five tabs to inspect the frozen release results. Back to Summary returns to Studio for free; viewing results never rerolls or pays them again."},
	],
	&"contract": [
		{"title": "Contracts: Two Production Hands", "body": "The fixed Primitive Contract has two four-card hands. Four cards sharing a primary Core stat trigger Contract Specialization: primary and secondary Core gains are multiplied by 1.50 while Scope stays printed. There is no Balanced Production bonus here. Eligible Design and Alpha Features are finite; Core Passes renew."},
		{"title": "Contracts: Shared Resources", "body": "Contracts share your run calendar and redraw budget. Acceptance is free, but an accepted contract cannot be abandoned. Completion pays the cash reward once."},
	],
	&"feature_store": [
		{"title": "Feature Store: Follow the Tree", "body": "Select a node to inspect its prerequisites, down payment and next installment. Familiarity reduces research installments when they are paid. Only completed Features carry into future projects."},
		{"title": "Feature Store: Purchase Carefully", "body": "Browsing is free. Initial Primitive purchases stay instant at zero cycles. Later acquisitions enter a FIFO queue: half the base price now, with no cancellation or reordering. Research pays the remaining installment and advances one productive cycle. Only the queue head can progress; ownership begins on completion."},
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
