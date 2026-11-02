extends Control

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)

func _draw() -> void:
	var ink:=Color("141519");var accent:=Color("6F42FF")
	draw_rect(Rect2(Vector2.ZERO,size),ink)
	draw_colored_polygon(PackedVector2Array([Vector2.ZERO,Vector2(size.x-100,0),Vector2(size.x-126,25),Vector2(size.x*0.66,25),Vector2(size.x*0.65,16),Vector2(0,16)]),accent)
	draw_colored_polygon(PackedVector2Array([Vector2(0,size.y-16),Vector2(size.x*0.2,size.y-16),Vector2(size.x*0.21,size.y-30),Vector2(size.x-115,size.y-30),Vector2(size.x-135,size.y),Vector2(0,size.y)]),accent)
	for i in 3:
		var x:=size.x-90+i*25
		for y in [6.0,size.y-24]:
			draw_colored_polygon(PackedVector2Array([Vector2(x,y),Vector2(x+19,y),Vector2(x+3,y+17),Vector2(x-16,y+17)]),accent)
	for i in 3:
		draw_rect(Rect2(size.x-94+i*10,88-i*10,9,9),Color(accent,0.35+i*0.2))
