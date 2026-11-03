extends Control

const TITLE_SPLICE_GAP := 8.0

var colorful_title := false:
	set(value):
		if colorful_title == value: return
		colorful_title = value
		queue_redraw()

var transparent_base := false:
	set(value):
		if transparent_base == value: return
		transparent_base = value
		queue_redraw()

var entrance_progress := 1.0:
	set(value):
		entrance_progress = clampf(value, 0.0, 1.0)
		queue_redraw()

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)

func _draw() -> void:
	var ink:=Color("141519");var accent:=Color("6F42FF")
	if not transparent_base:draw_rect(Rect2(Vector2.ZERO,size),ink)
	if colorful_title:
		var stages:=_title_entrance_stages()
		_draw_title_top(stages.x,stages.y)
		draw_set_transform(Vector2(0,-30.0*(1.0-stages.z)))
		for i in 3:
			var x:=size.x-90+i*25
			draw_colored_polygon(PackedVector2Array([Vector2(x,6),Vector2(x+19,6),Vector2(x+3,23),Vector2(x-16,23)]),Color(Color("FFF3E2"),stages.z))
		_draw_title_bottom(stages.x,stages.y)
		draw_set_transform(Vector2(0,30.0*(1.0-stages.z)))
		for i in 3:
			var x:=size.x-90+i*25
			var y:=size.y-24
			draw_colored_polygon(PackedVector2Array([Vector2(x,y),Vector2(x+19,y),Vector2(x+3,y+17),Vector2(x-16,y+17)]),Color(Color("FFF3E2"),stages.z))
		draw_set_transform(Vector2.ZERO)
		for i in 3:
			draw_rect(Rect2(size.x-94+i*10,88-i*10,9,9),Color(Color("FFF3E2"),(0.35+i*0.2)*stages.z))
		return
	draw_set_transform(Vector2(0, -30.0 * (1.0 - entrance_progress)))
	draw_colored_polygon(PackedVector2Array([Vector2.ZERO,Vector2(size.x-100,0),Vector2(size.x-126,25),Vector2(size.x*0.66,25),Vector2(size.x*0.65,16),Vector2(0,16)]),accent)
	for i in 3:
		var x:=size.x-90+i*25
		draw_colored_polygon(PackedVector2Array([Vector2(x,6),Vector2(x+19,6),Vector2(x+3,23),Vector2(x-16,23)]),accent)
	draw_set_transform(Vector2(0, 30.0 * (1.0 - entrance_progress)))
	draw_colored_polygon(PackedVector2Array([Vector2(0,size.y-16),Vector2(size.x*0.2,size.y-16),Vector2(size.x*0.21,size.y-30),Vector2(size.x-115,size.y-30),Vector2(size.x-135,size.y),Vector2(0,size.y)]),accent)
	for i in 3:
		var x:=size.x-90+i*25
		var y:=size.y-24
		draw_colored_polygon(PackedVector2Array([Vector2(x,y),Vector2(x+19,y),Vector2(x+3,y+17),Vector2(x-16,y+17)]),accent)
	draw_set_transform(Vector2.ZERO)
	for i in 3:
		draw_rect(Rect2(size.x-94+i*10,88-i*10,9,9),Color(accent,0.35+i*0.2))

func _title_entrance_stages() -> Vector3:
	# Short bars finish first, then tall bars, then the three accent marks.
	return Vector3(smoothstep(0.0,.32,entrance_progress),smoothstep(.32,.72,entrance_progress),smoothstep(.72,1.0,entrance_progress))

func _title_segment(points: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(points,color)
	var outline:=points.duplicate()
	outline.append(points[0])
	draw_polyline(outline,Color("FFF3E2"),1.5,true)

func _title_splice_geometry() -> Dictionary:
	var top_joint:=minf(size.x*.65,size.x-150)
	var top_extrude:=minf(top_joint+size.x*.01,size.x-127)
	var top_skew:=(top_extrude-top_joint)*25.0/9.0
	var bottom_joint:=size.x*.21
	var bottom_skew:=(bottom_joint-size.x*.2)*30.0/14.0
	return {
		"top_start":Vector2(top_extrude-top_skew,0),
		"top_end":Vector2(top_extrude,25),
		"bottom_start":Vector2(bottom_joint,size.y-30),
		"bottom_end":Vector2(bottom_joint-bottom_skew,size.y),
		"gap":TITLE_SPLICE_GAP,
	}

func _draw_title_top(short_progress: float, tall_progress: float) -> void:
	var joint:=minf(size.x*.65,size.x-150)
	var geometry:=_title_splice_geometry()
	var start:Vector2=geometry.top_start
	var end:Vector2=geometry.top_end
	var gap:=Vector2(TITLE_SPLICE_GAP,0)
	draw_set_transform(Vector2(0,-30.0*(1.0-short_progress)))
	_title_segment(PackedVector2Array([Vector2.ZERO,start,Vector2(joint,16),Vector2(0,16)]),Color("FFA954"))
	draw_set_transform(Vector2(0,-30.0*(1.0-tall_progress)))
	_title_segment(PackedVector2Array([start+gap,Vector2(size.x-100,0),Vector2(size.x-126,25),end+gap]),Color("5EF2C2"))

func _draw_title_bottom(short_progress: float, tall_progress: float) -> void:
	var y:=size.y
	var root:=size.x*.2
	var geometry:=_title_splice_geometry()
	var start:Vector2=geometry.bottom_start
	var end:Vector2=geometry.bottom_end
	var gap:=Vector2(TITLE_SPLICE_GAP,0)
	draw_set_transform(Vector2(0,30.0*(1.0-short_progress)))
	_title_segment(PackedVector2Array([Vector2(0,y-16),Vector2(root,y-16),end,Vector2(0,y)]),Color("5EF2C2"))
	draw_set_transform(Vector2(0,30.0*(1.0-tall_progress)))
	_title_segment(PackedVector2Array([start+gap,Vector2(size.x-115,y-30),Vector2(size.x-135,y),end+gap]),Color("6F42FF"))
