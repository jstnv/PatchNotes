## Presentation-only pulses on the Store's existing prerequisite routes.
## Eligibility is refreshed with the Store view, never recalculated per frame.
extends Control

const INTERVAL := 1.25
const SPEED := 520.0
const TAIL := 100.0

var active_edges: Dictionary = {}
var _clock := 0.0
var _engine: StringName = &""
var map_view: ScrollContainer

func _init() -> void:
	name = "FeatureTrails"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)

func sync_edges(edges: Array, routes: Dictionary, quotes: Dictionary, run: RunState, engine: StringName) -> void:
	if _engine != engine:
		active_edges.clear()
		_engine = engine
	var next := {}
	for edge: Array in edges:
		var parent := StringName(edge[0])
		var child := StringName(edge[1])
		var key := str(parent) + "->" + str(child)
		var quote: Dictionary = quotes.get(child,{})
		if not run.owns_feature(parent,engine) or run.owns_feature(child,engine) or not quote.get("unlocked",false) or quote.get("queued",false): continue
		var path: PackedVector2Array = routes.get(key,PackedVector2Array())
		if path.size() < 2: continue
		var total := 0.0
		var bounds := Rect2(path[0],Vector2.ZERO)
		for i in range(1,path.size()):
			total += path[i-1].distance_to(path[i])
			bounds = bounds.expand(path[i])
		if total <= 0.0: continue
		next[key] = {"path":path,"length":total,"bounds":bounds.grow(TAIL),"started":active_edges.get(key,{}).get("started",_clock)}
	active_edges = next
	sync_processing()
	queue_redraw()

func clear_edges() -> void:
	active_edges.clear()
	sync_processing()
	queue_redraw()

func sync_processing() -> void:
	set_process(not active_edges.is_empty() and is_visible_in_tree())

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		set_process(false)
		return
	_clock += delta
	queue_redraw()

func pulse_heads(elapsed: float, total: float) -> Array:
	var result := []
	if elapsed < 0.0 or total <= 0.0: return result
	var first := maxi(0,ceili((elapsed - (total + TAIL) / SPEED) / INTERVAL))
	var last := floori(elapsed / INTERVAL)
	for index in range(first,last + 1):
		var distance := (elapsed - float(index) * INTERVAL) * SPEED
		if distance <= total + TAIL: result.append(distance)
	return result

func point_along(path: PackedVector2Array, distance: float) -> Vector2:
	if path.is_empty(): return Vector2.ZERO
	var remaining := maxf(0.0,distance)
	for i in range(1,path.size()):
		var length := path[i-1].distance_to(path[i])
		if length > 0.0 and remaining <= length: return path[i-1].lerp(path[i],remaining / length)
		remaining -= length
	return path[-1]

func _draw_range(path: PackedVector2Array, start: float, end: float, color: Color, width: float) -> void:
	var walked := 0.0
	for i in range(1,path.size()):
		var length := path[i-1].distance_to(path[i])
		if length <= 0.0: continue
		var a := maxf(start,walked)
		var b := minf(end,walked + length)
		if b > a:
			draw_line(path[i-1].lerp(path[i],(a-walked)/length),path[i-1].lerp(path[i],(b-walked)/length),color,width,true)
		walked += length
		if walked >= end: break

func _draw() -> void:
	if active_edges.is_empty() or not is_instance_valid(map_view): return
	var visible := get_global_transform().affine_inverse() * map_view.get_global_rect()
	var scale_factor := maxf(absf(get_global_transform().get_scale().x),0.025)
	var width := maxf(4.0,2.5 / scale_factor)
	for edge: Dictionary in active_edges.values():
		if not visible.intersects(edge.bounds): continue
		var path: PackedVector2Array = edge.path
		var total: float = edge.length
		for head: float in pulse_heads(_clock - float(edge.started),total):
			var start := maxf(0.0,head - TAIL)
			var end := minf(total,head)
			_draw_range(path,start,end,Color(0.37,0.95,0.76,0.35),width * 2.4)
			_draw_range(path,start,end,Color(0.37,0.95,0.76,0.95),width)
			if head <= total: draw_circle(point_along(path,head),width * 0.7,Color("fff3e2"),true,-1.0,true)
