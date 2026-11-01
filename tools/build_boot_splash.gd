## Render the native PNG boot splash from the unmodified studio logo and existing
## Godot mark/font. Run from the project with --script ../tools/build_boot_splash.gd.
## This build tool is outside gameplay and is never run during normal startup.
extends SceneTree

const OUTPUT := "res://assets/branding/joocebox_boot_splash.png"
const LOGO := "res://assets/branding/joocebox_logo.png"

func _initialize() -> void:
	_build.call_deferred()

func _build() -> void:
	root.title = "JooceBox Splash Builder"
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var background := ColorRect.new()
	background.color = Color.BLACK
	background.size = Vector2(1920, 1080)
	viewport.add_child(background)
	var original := Image.load_from_file(LOGO)
	assert(original != null and not original.is_empty(), "Studio logo must decode")
	_picture(viewport, ImageTexture.create_from_image(original), Rect2(680, 100, 560, 560))
	var font: Font = load("res://assets/fonts/chakrapetch/ChakraPetch-SemiBold.ttf")
	_label(viewport, "JooceBox Studios", font, 64, 710, Color("f3f0e8"))
	_label(viewport, "MADE WITH", font, 17, 852, Color("939ca7"))
	var godot := Image.new()
	assert(godot.load_svg_from_string(FileAccess.get_file_as_string("res://icon.svg"), 2.0) == OK)
	_picture(viewport, ImageTexture.create_from_image(godot), Rect2(924, 900, 72, 72))
	for frame in range(4):
		await process_frame
	RenderingServer.force_draw()
	var rendered := viewport.get_texture().get_image()
	assert(rendered != null and rendered.get_size() == Vector2i(1920, 1080))
	assert(rendered.save_png(OUTPUT) == OK, "Boot splash must save as PNG")
	print("BOOT_SPLASH_BUILT ", OUTPUT, " ", rendered.get_size())
	viewport.queue_free()
	await process_frame
	quit()

func _picture(parent: Node, texture: Texture2D, bounds: Rect2) -> void:
	var picture := TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture = texture
	picture.position = bounds.position
	picture.size = bounds.size
	parent.add_child(picture)
	assert(picture.size == bounds.size, "Texture minimum size must not expand the layout")

func _label(parent: Node, text: String, font: Font, font_size: int, y: float, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = Vector2(0, y)
	label.size = Vector2(1920, font_size * 1.6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
