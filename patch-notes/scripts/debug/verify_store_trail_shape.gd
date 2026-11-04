extends SceneTree

# Render the production trail overlay against black so its shape is testable
# without static arrows, game saves, or changes to the Store's visual state.
const TRAILS = preload("res://scripts/ui/feature_store_trails.gd")
const SCREEN := Vector2i(640, 360)
var checks := 0
var failures := 0
var overlay: Control

func check(ok: bool, description: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", description)
	if not ok: failures += 1

func _initialize() -> void:
	verify.call_deferred()

func energy(image: Image, x: int, y: int) -> float:
	var c := image.get_pixel(x, y)
	return maxf(c.r, maxf(c.g, c.b))

func render_route(path: PackedVector2Array, length: float, distance: float) -> Image:
	overlay.active_edges = {"test": {"path": path, "length": length, "bounds": Rect2(Vector2.ZERO, Vector2(SCREEN)), "started": 0.0}}
	overlay._clock = distance / overlay.SPEED
	overlay.set_process(false)
	overlay.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func verify() -> void:
	if DisplayServer.get_name() == "headless":
		print("SKIP: trail shape requires a rendered native viewport")
		quit(2)
		return
	root.min_size = Vector2i.ZERO
	root.size = SCREEN
	root.content_scale_size = SCREEN
	var background := ColorRect.new()
	background.color = Color.BLACK
	background.size = Vector2(SCREEN)
	root.add_child(background)
	var viewport := ScrollContainer.new()
	viewport.size = Vector2(SCREEN)
	viewport.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(viewport)
	overlay = TRAILS.new()
	overlay.size = Vector2(SCREEN)
	overlay.map_view = viewport
	root.add_child(overlay)
	for i in range(8): await process_frame

	# A moving pulse part-way along a horizontal arrow has a fading tail,
	# stays inside the arrow's narrow shaft and never appears past its head.
	var horizontal := PackedVector2Array([Vector2(40, 80), Vector2(400, 80)])
	var straight := await render_route(horizontal, 360.0, 200.0)
	var output := OS.get_environment("PN_TRAIL_TEST_OUTPUT")
	if not output.is_empty(): straight.save_png(output.path_join("straight.png"))
	check(energy(straight, 220, 80) > energy(straight, 150, 80) + 0.03, "Straight shaft brightens from fading tail toward pulse head")
	check(energy(straight, 120, 80) < 0.02 and energy(straight, 250, 80) < 0.02, "Pulse stays between its tail and moving head")
	var shaft_leaks := 0
	for x in range(150, 235):
		for y in range(70, 91):
			if abs(y - 80) > 3 and energy(straight, x, y) > 0.04: shaft_leaks += 1
	check(shaft_leaks == 0, "Straight highlight stays within the three-unit arrow shaft")

	# When the pulse reaches the end, the highlight may expand only within the
	# same nine-unit-long, six-unit-halfwidth triangle as the static arrowhead.
	var endpoint := await render_route(horizontal, 360.0, 360.0)
	if not output.is_empty(): endpoint.save_png(output.path_join("endpoint.png"))
	check(energy(endpoint, 392, 77) > 0.04 and energy(endpoint, 392, 83) > 0.04, "Arrowhead lights on both sides of its shaft at arrival")
	check(energy(endpoint, 395, 85) < 0.04 and energy(endpoint, 402, 80) < 0.04, "Endpoint highlight stays within the triangular arrowhead")

	# Reverse direction checks that the triangle follows its own arrow, rather
	# than an axis-specific mask.
	var reverse := PackedVector2Array([Vector2(400, 120), Vector2(40, 120)])
	var reversed := await render_route(reverse, 360.0, 360.0)
	if not output.is_empty(): reversed.save_png(output.path_join("reverse.png"))
	check(energy(reversed, 48, 117) > 0.04 and energy(reversed, 48, 123) > 0.04, "Left-pointing arrowhead lights symmetrically")
	check(energy(reversed, 45, 125) < 0.04 and energy(reversed, 38, 120) < 0.04, "Reverse highlight stays inside the arrowhead")
	var vertical := PackedVector2Array([Vector2(500, 40), Vector2(500, 300)])
	var down := await render_route(vertical, 260.0, 260.0)
	if not output.is_empty(): down.save_png(output.path_join("vertical.png"))
	check(energy(down, 497, 292) > 0.04 and energy(down, 503, 292) > 0.04, "Vertical arrowhead lights symmetrically")
	check(energy(down, 505, 295) < 0.04 and energy(down, 500, 302) < 0.04, "Vertical endpoint stays inside the arrowhead")

	# The tail crosses an L-bend without cutting across the empty corner.
	var bent := PackedVector2Array([Vector2(40, 190), Vector2(180, 190), Vector2(180, 300)])
	var corner := await render_route(bent, 250.0, 190.0)
	if not output.is_empty(): corner.save_png(output.path_join("bent.png"))
	check(energy(corner, 150, 190) > 0.04 and energy(corner, 180, 220) > 0.04, "Trail follows both legs of a bent arrow")
	check(energy(corner, 170, 200) < 0.04 and energy(corner, 190, 200) < 0.04, "Trail does not fill the inside or outside of a bend")

	# The Store overview commonly shrinks the graph to about one third scale.
	# The thin shaft must remain visible without becoming a wide rectangle.
	overlay.scale = Vector2.ONE * 0.33
	var overview := await render_route(horizontal, 360.0, 200.0)
	if not output.is_empty(): overview.save_png(output.path_join("overview.png"))
	var overview_peak := 0.0
	for x in range(70, 76):
		for y in range(25, 29): overview_peak = maxf(overview_peak, energy(overview, x, y))
	check(overview_peak > 0.04, "Trail remains visible at overview zoom")
	check(energy(overview, 73, 31) < 0.04 and energy(overview, 73, 22) < 0.04, "Overview trail does not widen into a block")

	print("STORE_TRAIL_SHAPE checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
