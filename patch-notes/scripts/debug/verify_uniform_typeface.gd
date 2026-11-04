extends SceneTree

## Focused presentation regression: inspect the live shared theme and controls.
## The project has many lazy destinations; this does not claim exhaustive traversal.
const FONT_PATH := "res://assets/fonts/ibmplexsans/IBMPlexSans[wdth,wght].ttf"
const BOLD_ROLES := [&"ArcadeHeading", &"FolderHeading", &"HeadingLabel", &"SectionHeading"]
var checks := 0
var failures := 0

func check(ok: bool, description: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ",description)
	if not ok: failures += 1

func family_path(font: Font) -> String:
	if font == null: return ""
	if font is FontVariation: return family_path((font as FontVariation).base_font)
	return font.resource_path

func weight(font: Font) -> float:
	if font is FontVariation:
		var axes: Dictionary = (font as FontVariation).variation_opentype
		return float(axes.get("wght",axes.get(TextServerManager.get_primary_interface().name_to_tag("wght"),400.0)))
	return 400.0

func inspect_tree(node: Node, label: String) -> void:
	var total := 0
	var wrong: Array[String] = []
	var pending: Array[Node] = [node]
	while not pending.is_empty():
		var item: Node = pending.pop_back()
		pending.append_array(item.get_children())
		if item is RichTextLabel:
			for key in [&"normal_font", &"bold_font"]:
				var font: Font = item.get_theme_font(key)
				if font != null:
					total += 1
					if family_path(font) != FONT_PATH: wrong.append("%s %s: %s" % [item.get_path(),key,family_path(font)])
		elif item is Label or item is Button or item is LineEdit or item is TextEdit:
			var font: Font = item.get_theme_font(&"font")
			if font != null:
				total += 1
				if family_path(font) != FONT_PATH: wrong.append("%s: %s" % [item.get_path(),family_path(font)])
	check(total > 0 and wrong.is_empty(),"%s uses the single typeface across %d inspected text controls%s" % [label,total,"" if wrong.is_empty() else "; mismatches: " + ", ".join(wrong)])

func capture(label: String) -> void:
	var folder := OS.get_environment("PN_TYPEFACE_CAPTURE")
	if folder.is_empty() or DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(folder.path_join(label + ".png"))==OK,"Native capture saved: " + label)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size=Vector2i(1280,720)
	root.content_scale_size=root.size
	var theme: Theme = preload("res://resources/ui/onyx_theme.tres")
	check(family_path(theme.default_font)==FONT_PATH,"Shared default typeface is IBM Plex Sans")
	for type in theme.get_type_list():
		for role in theme.get_font_list(type):
			var font := theme.get_font(role,type)
			check(family_path(font)==FONT_PATH,"Shared theme font %s/%s uses the same family" % [type,role])
	for role: StringName in BOLD_ROLES:
		var font := theme.get_font(&"font",role)
		check(family_path(font)==FONT_PATH and weight(font)>=700.0,"%s uses weight 700 or greater in the shared family" % role)
	var normal_width := theme.default_font.get_string_size("Graphics",HORIZONTAL_ALIGNMENT_LEFT,-1,32).x
	var bold_width := theme.get_font(&"font",&"HeadingLabel").get_string_size("Graphics",HORIZONTAL_ALIGNMENT_LEFT,-1,32).x
	print("TYPEFACE_METRICS normal_width=%.4f bold_width=%.4f" % [normal_width,bold_width])
	check(bold_width > normal_width + 1.0,"Bold variation changes the renderer's actual glyph metrics")
	check(family_path(theme.get_font(&"bold_font",&"RichTextLabel"))==FONT_PATH and weight(theme.get_font(&"bold_font",&"RichTextLabel"))>=700.0,"Rich text bold uses the same family and bold weight")
	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	var menu := MainMenu.new()
	host.add_child(menu)
	var hud := GameplayHUD.new()
	host.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in 5: await process_frame
	inspect_tree(menu,"Main menu and Studio creation")
	inspect_tree(hud,"Production HUD, Settings and How to Play")
	check(family_path(menu._emphasis.get_theme_font(&"font"))==FONT_PATH,"Studio specialty description uses the same family")
	check(family_path(hud.footer.get_theme_font(&"font"))==FONT_PATH,"Production calendar footer uses the same family")
	var headings: Variant = hud.scoreboard.get("headings")
	check(headings is Array and headings.size()==hud.scoreboard.stats.size(),"Each score value has a separate category heading")
	for index in hud.scoreboard.stats.size():
		var entry: Label = hud.scoreboard.stats[index]
		check(family_path(entry.get_theme_font(&"font"))==FONT_PATH and weight(entry.get_theme_font(&"font"))<700.0,"Production value %d uses the regular family weight" % index)
		if headings is Array and index < headings.size():
			var category: Label = headings[index]
			check(family_path(category.get_theme_font(&"font"))==FONT_PATH and weight(category.get_theme_font(&"font"))>=700.0,"Production category %d is bold in the same family" % index)
	var hidden_heading: Variant = hud.scoreboard.get("hidden_bugs_heading")
	check(hidden_heading is Label and family_path(hidden_heading.get_theme_font(&"font"))==FONT_PATH and weight(hidden_heading.get_theme_font(&"font"))>=700.0,"Hidden Bugs heading uses the same bold family")
	if headings is Array and headings.size()==7:
		hud.scoreboard.set_stats_visible(false)
		check(headings.all(func(label):return not label.is_visible_in_tree()) and hud.scoreboard.stats.all(func(label):return not label.is_visible_in_tree()),"Hiding score columns hides headings and values together")
		hud.scoreboard.set_stats_visible(true)
		check(headings.all(func(label):return label.is_visible_in_tree()) and hud.scoreboard.stats.all(func(label):return label.is_visible_in_tree()),"Showing score columns restores headings and values together")
		var project := ProjectState.new(30)
		hud.scoreboard.show_hidden_bugs=true
		hud.scoreboard.render(project,&"design")
		check(headings[0].text=="Employees" and headings[1].text=="Graphics" and headings[6].text=="Bug Pressure","Design shows the correct category headings")
		check(hud.scoreboard.stats[1].text.begins_with("0") and hud.scoreboard.stats[6].text=="0.00","Design retains score and Bug Pressure values")
		hud.scoreboard.render(project,&"beta")
		check(headings[0].text=="Marketing" and headings[6].text=="Known / Fixed","Beta replaces the correct category headings")
		check(hud.scoreboard.hidden_bugs.is_visible_in_tree() and hidden_heading.is_visible_in_tree(),"Tutorial Hidden Bugs heading and value become visible together")
		hud.scoreboard.render(project,&"design")
		check(not hud.scoreboard.hidden_bugs.is_visible_in_tree() and not hidden_heading.is_visible_in_tree(),"Hidden Bugs heading and value hide together outside Beta")
		for dimensions in [Vector2i(1152,648),Vector2i(1280,720)]:
			root.size=dimensions;root.content_scale_size=dimensions
			for i in 4: await process_frame
			var clipped: Array[String] = []
			for category: Label in headings:
				var font := category.get_theme_font(&"font")
				if font.get_string_size(category.text,HORIZONTAL_ALIGNMENT_LEFT,-1,category.get_theme_font_size(&"font_size")).x > category.size.x + 0.5:
					clipped.append(category.text)
			check(clipped.is_empty(),"Production headers fit at %s%s" % [dimensions,"" if clipped.is_empty() else ": " + ", ".join(clipped)])
	if not OS.get_environment("PN_TYPEFACE_CAPTURE").is_empty() and DisplayServer.get_name()!="headless":
		hud.hide();menu.show()
		menu.action_button("StartGame").pressed.emit()
		await create_timer(0.4).timeout
		await capture("creation-1280")
		menu.hide();hud.show()
		for dimensions in [Vector2i(1152,648),Vector2i(1280,720)]:
			root.size=dimensions;root.content_scale_size=dimensions
			for i in 5: await process_frame
			await capture("hud-%d" % dimensions.x)
	print("UNIFORM_TYPEFACE checks=%d failures=%d" % [checks,failures])
	host.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
