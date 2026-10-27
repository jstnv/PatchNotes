extends "res://scripts/debug/verify_gameplay_hud_overlay.gd"

# Render the existing HUD verifier's constructed phase fixtures; no player saves.
var capture_rows: Array = []

func verify_tutorial(hud: GameplayHUD, project: ProjectState, run: RunState, design: DesignPhase) -> void:
	var width := int(OS.get_environment("PN_CAPTURE_WIDTH"))
	root.size = Vector2i(width, 648 if width == 1152 else 720)
	super.verify_tutorial(hud, project, run, design)

func capture(workspace: PhaseWorkspace, suffix: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := OS.get_environment("PN_CAPTURE_DIR").path_join(str(root.size.x) + "-" + suffix + ".png")
	root.get_texture().get_image().save_png(path)
	capture_rows.append({"image": path, "title": workspace.phase_title.text, "selection": workspace.played_hand.text, "progress": workspace.progress.text, "synergy": workspace.synergy_help_button.tooltip_text})
	var output := FileAccess.open(OS.get_environment("PN_CAPTURE_DIR").path_join(str(root.size.x) + ".json"), FileAccess.WRITE)
	output.store_string(JSON.stringify(capture_rows, "\t"))

func verify_overlay(hud: GameplayHUD, phase: Control, project: ProjectState, run: RunState, title: String) -> void:
	await super.verify_overlay(hud, phase, project, run, title)
	var workspace: PhaseWorkspace = phase.get_workspace()
	hud.contextual_tip.dismiss()
	await capture(workspace, title.to_lower())
	if title == "Beta": return
	var selected: Array[CardView] = phase.get_selected_candidate_views()
	var original: Array[CardData] = []
	var stats: Array[StringName] = [&"graphics", &"sound", &"technology", &"design"]
	for index in range(selected.size()):
		original.append(selected[index].card_data)
		var card := CardData.new()
		card.id = StringName("capture_" + str(index))
		card.card_name = "Balanced " + str(stats[index]).capitalize()
		card.card_type = &"feature"
		card.primary_stat = stats[index]
		card.primary_value = 2
		card.phase = StringName(title.to_lower())
		selected[index].set_card(card)
	workspace.refresh()
	workspace.synergy_help_button.pressed.emit()
	await capture(workspace, title.to_lower() + "-balanced")
	for index in range(selected.size()): selected[index].set_card(original[index])
	workspace.refresh()
	hud.contextual_tip.dismiss()
