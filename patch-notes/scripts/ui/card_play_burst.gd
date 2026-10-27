## Bounded pixel sparks sampled by HandPresentation's music clock, never RNG.
extends Node2D
const LIFETIME := 0.30
var particle_count := 12
var age := 0.0
var half_extents := Vector2(80,112)
var accent := Color("#74d3de")
var phase := 0.0

func sample(seconds: float) -> void:
	if is_equal_approx(age,seconds):return
	age=seconds
	queue_redraw()

func _draw() -> void:
	var fade := clampf(1.0-age/LIFETIME,0.0,1.0)
	for i in range(particle_count):
		var angle := TAU*float(i)/float(particle_count)+phase
		var direction := Vector2(cos(angle),sin(angle))
		var edge := minf(half_extents.x/maxf(absf(direction.x),0.001),half_extents.y/maxf(absf(direction.y),0.001))
		var distance := edge+3.0+(100.0+float(i%3)*35.0)*age
		var point := (direction*distance+Vector2(0,100.0*age*age)).round()
		var color := accent if i%3==0 else Color("#f5ce69") if i%3==1 else Color("#fff2d5")
		color.a=fade
		var pixel := 4.0 if i%3==0 else 3.0
		draw_rect(Rect2(point-Vector2.ONE*floorf(pixel/2.0),Vector2.ONE*pixel),color)
