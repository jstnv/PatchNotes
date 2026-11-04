extends "res://scripts/ui/menu_audio_visualizer.gd"
## Reuses the existing spectrum observer and its exact Music-bus ownership.
const Geometry:=preload("res://scripts/ui/circuit_geometry.gd")
const Field:=preload("res://scripts/ui/circuit_pulse_field.gd")
const Tuning:=preload("res://scripts/ui/circuit_flow_settings.gd")
const NoteTimeline:=preload("res://scripts/ui/menu_note_timeline.gd")
const NOTE_DATA := "res://assets/boot/sequence_v1/menu_visual_notes.json"
const CYAN:=Color("22e7ef")
const ORANGE:=Color("ff994f")
@export var flow_settings:Tuning=Tuning.new()
var geometry:=Geometry.new()
var field:=Field.new()
var readability_right:=440.0
var _board:Control
var _ribbons:Control
var _mesh:ArrayMesh
var _shader:=ShaderMaterial.new()
var _pulse_data:=PackedVector4Array()
var _elapsed:=0.0
var _last_debug:=false
var _last_trace_opacity:=-1.0
var draw_microseconds:=0
var _note_data: Dictionary = {}
var _note_timelines: Dictionary = {}

class Board extends Control:
	var owner_flow:Control
	func _draw()->void:owner_flow.draw_board(self)

class Ribbons extends Control:
	var owner_flow:Control
	func _draw()->void:
		if owner_flow._mesh!=null and not owner_flow.flow_settings.debug_white_traces:
			draw_mesh(owner_flow._mesh,null)

func _ready()->void:
	super._ready()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(NOTE_DATA))
	if parsed is Dictionary and parsed.get("version") == 1: _note_data = parsed
	if flow_settings==null:flow_settings=Tuning.new()
	field.bind(geometry,flow_settings)
	_board=Board.new();_board.owner_flow=self;_board.name="CircuitGeometry"
	_board.mouse_filter=Control.MOUSE_FILTER_IGNORE;_board.show_behind_parent=true
	add_child(_board);_board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shader.shader=preload("res://scripts/ui/circuit_glow.gdshader")
	_pulse_data.resize(Field.HARD_LIMIT)
	_ribbons=Ribbons.new();_ribbons.owner_flow=self;_ribbons.name="CircuitLightRibbons"
	_ribbons.mouse_filter=Control.MOUSE_FILTER_IGNORE;_ribbons.show_behind_parent=true;_ribbons.material=_shader
	add_child(_ribbons);_ribbons.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if OS.get_environment("PN_CIRCUIT_DEBUG")=="1":flow_settings.debug_white_traces=true
	resized.connect(_rebuild_geometry);_rebuild_geometry()

func set_active(value: bool) -> void:
	if value != _active: _note_timelines.clear()
	super.set_active(value)

func _note_events(track: String, offset: float = 0.0) -> Array:
	var result := []
	var data: Dictionary = _note_data.get("tracks",{}).get(track,{})
	var rate := float(_note_data.get("sample_rate",48000))
	for pair in [["bass",&"bass"],["chords",&"chord"]]:
		for row: Array in data.get(pair[0],[]):
			if row.size() < 3: continue
			result.append({"time":float(row[0]) / rate + offset,"pitch":int(row[1]),"velocity":int(row[2]),"kind":pair[1]})
	return result

func _make_note_timeline(id: StringName, at_seconds: float) -> RefCounted:
	var timeline := NoteTimeline.new()
	var rate := float(_note_data.get("sample_rate",48000))
	var loop_length := float(_note_data.get("loop_frames",0)) / rate
	var switch_length := float(_note_data.get("switch_frames",0)) / rate
	if id == &"boot":
		var loops := _note_events("loop_a")
		loops.append_array(_note_events("loop_b",loop_length))
		timeline.configure_intro(id,_note_events("startup"),loop_length,loops,loop_length * 2.0,at_seconds)
	elif id == &"switch_menu":
		timeline.configure_intro(id,_note_events("switch"),switch_length,_note_events("menu"),loop_length,at_seconds)
	else:
		timeline.configure(id,_note_events("menu"),loop_length,at_seconds)
	return timeline

func _music_note_events() -> Variant:
	var song := get_node_or_null("/root/Soundtrack")
	if _note_data.is_empty() or song == null or not song.has_method("visual_note_clocks"): return null
	var clocks: Array = song.visual_note_clocks()
	if clocks.is_empty():
		_note_timelines.clear()
		return null
	var result := []
	var seen := {}
	for clock: Dictionary in clocks:
		var id := StringName(clock.timeline)
		if id not in [&"boot",&"switch_menu",&"menu"]: continue
		seen[id] = true
		var seconds := float(clock.seconds)
		if not _note_timelines.has(id):
			# New tracks include their first sample; attaching to an already
			# playing track never replays its earlier notes.
			var newly_switched := id == &"switch_menu" and _note_timelines.has(&"boot")
			_note_timelines[id] = _make_note_timeline(id,-0.000001 if newly_switched or seconds < 0.1 else seconds)
		var timeline: RefCounted = _note_timelines[id]
		var audible := not _quiet
		for event: Dictionary in timeline.advance(id,seconds,audible,12.0):
			event["gain"] = clampf(float(clock.gain),0.0,1.0)
			event["age"] = maxf(0.0,seconds - float(event.absolute_time))
			result.append(event)
	for id: StringName in _note_timelines.keys():
		if not seen.has(id): _note_timelines.erase(id)
	return result
func _rebuild_geometry()->void:
	if size.x<2 or size.y<2 or geometry.area==size:return
	# Preserve each pulse's route progress through window/aspect changes.
	for p in field.pulses:
		if p.active:p.distance/=maxf(1,geometry.routes[p.route].get_baked_length())
	geometry.rebuild(size)
	_mesh=geometry.ribbon_mesh()
	for p in field.pulses:
		if p.active:p.distance*=geometry.routes[p.route].get_baked_length()
	_board.queue_redraw();_ribbons.queue_redraw();queue_redraw()
func spectrum_groups()->Vector3:
	var groups:=Vector3.ZERO
	for i in BANDS:
		# Musical regions of the mixed track, not isolated instrument stems.
		# Bass: ~40–210 Hz; chords: ~210–1400 Hz; hook: ~550–3700 Hz.
		if i<7:groups.x+=levels[i]/7.0
		if i>=7 and i<15:groups.y+=levels[i]/8.0
		if i>=11 and i<19:groups.z+=levels[i]/8.0
	return groups
func _process(delta:float)->void:
	super._process(delta)
	if flow_settings==null:flow_settings=Tuning.new()
	field.settings=flow_settings
	_elapsed+=delta
	var groups:=spectrum_groups()
	field.step(delta,groups,_instance!=null and not _quiet and groups.length_squared()>.0001,_music_note_events())
	if _last_debug!=flow_settings.debug_white_traces or not is_equal_approx(_last_trace_opacity,flow_settings.inactive_trace_opacity):
		_last_trace_opacity=flow_settings.inactive_trace_opacity
		_last_debug=flow_settings.debug_white_traces;_board.queue_redraw();_ribbons.queue_redraw()
func set_debug_geometry(enabled:bool)->void:
	flow_settings.debug_white_traces=enabled
	if is_instance_valid(_board):_board.queue_redraw();_ribbons.queue_redraw()
	queue_redraw()
func _visibility_at(x:float)->float:
	return lerpf(.22,1.0,smoothstep(readability_right-30,readability_right+180,x))
func draw_board(canvas:Control)->void:
	var s:=size;var u:=geometry.unit
	# Cached decorative geometry: no animated texture, blur pass or per-dot nodes.
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(0,32),Vector2(s.x*.25,32),Vector2(s.x*.08,s.y*.21),Vector2(0,s.y*.21)]),Color("181b21"))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(s.x,s.y-38),Vector2(s.x*.73,s.y-38),Vector2(s.x*.84,s.y*.83),Vector2(s.x,s.y*.83)]),Color("181b21"))
	var dots:=PackedVector2Array()
	for y in range(45,int(s.y)-40,20):
		for x in range(20,int(s.x)-20,20):
			dots.append(Vector2(x,y));dots.append(Vector2(x+.7,y))
	canvas.draw_multiline(dots,Color(.45,.51,.60,.16),1,true)
	var white:bool=flow_settings.debug_white_traces
	var trace:=Color.WHITE if white else Color(Color("a3b6c6"),flow_settings.inactive_trace_opacity)
	for path in geometry.paint_paths:canvas.draw_polyline(path,trace,1.6*u,true)
	for point in geometry.junctions:
		canvas.draw_rect(Rect2(point-Vector2.ONE*5*u,Vector2.ONE*10*u),trace,false,1.5*u,true)
	for center in [Vector2(s.x*.72,s.y*.12),Vector2(s.x*.80,s.y*.47),Vector2(s.x*.30,s.y*.90)]:
		for i in 3:
			canvas.draw_rect(Rect2(center+Vector2(i*10,(i%2)*13)*u,Vector2.ONE*6*u),Color(Color("79728e"),.22))
func _draw()->void:
	if geometry.routes.is_empty():return
	var started:=Time.get_ticks_usec();var u:=geometry.unit
	var used_slots := 0
	for i in Field.HARD_LIMIT:
		var p=field.pulses[i]
		_pulse_data[i]=Vector4(p.route,p.distance,maxf(1,field.tail*(.58 if p.secondary else 1.0)),p.strength*(1 if p.color_index==0 else -1)) if p.active else Vector4(-1,0,1,0)
		if p.active: used_slots = i + 1
	_shader.set_shader_parameter("pulses",_pulse_data)
	_shader.set_shader_parameter("pulse_slots",used_slots)
	_shader.set_shader_parameter("unit_scale",u)
	_shader.set_shader_parameter("brightness",field.luminosity)
	_shader.set_shader_parameter("bass",field.energy.x)
	_shader.set_shader_parameter("bloom",field.bloom)
	_shader.set_shader_parameter("title_right",readability_right)
	if flow_settings.debug_white_traces:return
	for p in field.pulses:
		if not p.active:continue
		var curve:Curve2D=geometry.routes[p.route]
		if p.distance<curve.get_baked_length():
			var head:=curve.sample_baked(p.distance)
			var shine:=field.luminosity*p.strength*_visibility_at(head.x)
			var color:=CYAN if p.color_index==0 else ORANGE
			for junction in geometry.junctions:
				var near:=1.0-clampf(head.distance_to(junction)/(34*u),0,1)
				if near<=0:continue
				var flicker:=.65+.35*field.energy.z*absf(sin(_elapsed*29))
				draw_rect(Rect2(junction-Vector2.ONE*6*u,Vector2.ONE*12*u),Color(color,shine*near*flicker),false,2*u,true)
	draw_microseconds=Time.get_ticks_usec()-started
