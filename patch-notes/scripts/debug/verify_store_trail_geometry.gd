extends SceneTree

# Exercise the actual trail drawing path at large map coordinates, including
# tiny segments near a bend and very narrow portions of an arrowhead. Run with
# stderr captured: any rendering-server errors make the external check fail.
class StressTrail:
	extends "res://scripts/ui/feature_store_trails.gd"
	var samples := 0

	func _draw() -> void:
		for origin in [Vector2(1000, 1000), Vector2(4000, 4000), Vector2(10000, 10000)]:
			for direction in [Vector2.RIGHT, Vector2.DOWN, Vector2(1, 1).normalized()]:
				for length in [0.011, 0.02, 0.05, 0.1, 0.2, 0.5, 1.0, 3.0]:
					var path := PackedVector2Array([origin, origin + direction * 10.0])
					_draw_range(path, 0.0, length, 100.0, Color.WHITE, 1.5)
					_draw_tip(path, 10.0, 10.0 - length, 10.0, 10.0, Color.WHITE)
					samples += 2

func _initialize() -> void:
	verify.call_deferred()

func verify() -> void:
	var item := StressTrail.new()
	item.size = Vector2(12000, 12000)
	root.add_child(item)
	item.queue_redraw()
	for i in range(5): await process_frame
	print("STORE_TRAIL_GEOMETRY samples=", item.samples)
	quit(0 if item.samples >= 144 else 1)
