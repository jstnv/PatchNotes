extends Control

## Decorative title-only observer. Never owns or advances soundtrack playback.
const BANDS := 24
const LOW_HZ := 40.0
const HIGH_HZ := 12000.0
var levels := PackedFloat32Array()
var peaks := PackedFloat32Array()
var _peak_age := PackedFloat32Array()
var _active := false
var _quiet := false
var _effect: AudioEffectSpectrumAnalyzer
var _instance: AudioEffectSpectrumAnalyzerInstance
var _transferring := false

func transfer_to(parent: Node) -> void:
	# Node.reparent briefly leaves the tree. Keep the live observer only for
	# this synchronous handoff; ordinary teardown must still release it.
	_transferring = true
	reparent(parent)
	_transferring = false

func _ready() -> void:
	theme = preload("res://resources/ui/onyx_theme.tres")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	clip_contents = true
	levels.resize(BANDS);levels.fill(0.0)
	peaks.resize(BANDS);peaks.fill(0.0)
	_peak_age.resize(BANDS);_peak_age.fill(0.0)
	set_process(false)
	hide()
	resized.connect(queue_redraw)

func set_active(value: bool) -> void:
	if value == _active: return
	_active = value
	visible = value
	set_process(value)
	if value: _attach()
	else:
		_release()
		levels.fill(0.0);peaks.fill(0.0);_peak_age.fill(0.0)
	queue_redraw()

func _attach() -> void:
	_release()
	var bus := AudioServer.get_bus_index(&"Music")
	if bus < 0: return
	_effect = AudioEffectSpectrumAnalyzer.new()
	_effect.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_1024
	_effect.buffer_length = 0.1
	AudioServer.add_bus_effect(bus,_effect)
	_instance = AudioServer.get_bus_effect_instance(bus,AudioServer.get_bus_effect_count(bus)-1) as AudioEffectSpectrumAnalyzerInstance

func _release() -> void:
	_instance = null
	if _effect == null: return
	for bus in range(AudioServer.bus_count):
		for slot in range(AudioServer.get_bus_effect_count(bus)-1,-1,-1):
			if AudioServer.get_bus_effect(bus,slot) == _effect:
				AudioServer.remove_bus_effect(bus,slot)
	_effect = null

func _audible_gain() -> float:
	var song := get_node_or_null("/root/Soundtrack")
	if song == null or not is_instance_valid(song.player) or not song.player.playing or song.player.stream_paused: return 0.0
	var gain := 1.0
	for bus_name in [&"Music",&"Master"]:
		var bus := AudioServer.get_bus_index(bus_name)
		if bus < 0 or AudioServer.is_bus_mute(bus): return 0.0
		gain *= db_to_linear(AudioServer.get_bus_volume_db(bus))
	return gain if gain > 0.0001 else 0.0

func _process(delta: float) -> void:
	if _instance == null: _attach()
	var gain := _audible_gain()
	_quiet = gain == 0.0
	for index in BANDS:
		var target := 0.0
		if _instance != null and gain > 0.0:
			var low := LOW_HZ * pow(HIGH_HZ/LOW_HZ,float(index)/BANDS)
			var high := LOW_HZ * pow(HIGH_HZ/LOW_HZ,float(index+1)/BANDS)
			var stereo := _instance.get_magnitude_for_frequency_range(low,high)
			var energy := (stereo.x+stereo.y)*0.5*gain
			target = clampf((linear_to_db(maxf(energy,0.00000001))+72.0)/60.0,0.0,1.0)
		var response := 0.035 if target > levels[index] else 0.18
		levels[index] = lerpf(levels[index],target,1.0-exp(-maxf(0.0,delta)/response))
		if levels[index] >= peaks[index]:
			peaks[index] = levels[index]
			_peak_age[index] = 0.0
		else:
			_peak_age[index] += maxf(0.0,delta)
			if _peak_age[index] > 0.15: peaks[index] = maxf(levels[index],peaks[index]-delta*0.7)
	queue_redraw()

func graph_rect() -> Rect2:
	return Rect2(24,146,maxf(16,size.x-48),maxf(16.0,size.y-176.0))

func bar_rect(index: int) -> Rect2:
	var graph := graph_rect()
	var cell := graph.size.x/BANDS
	var height := maxf(2.0,floorf(levels[index]*graph.size.y/4.0)*4.0)
	return Rect2(graph.position.x+floorf(index*cell)+1,graph.end.y-height,maxf(1.0,floorf(cell)-3),height)

func track_info() -> Dictionary:
	var song:=get_node_or_null("/root/Soundtrack")
	if song==null or song.themes==null:return {"title":"No track playing","bpm":0.0}
	var index:=0
	for i in song.themes.stream_count:
		if song.themes.get_sync_stream_volume(i)>song.themes.get_sync_stream_volume(index):index=i
	var constants:Dictionary=song.get_script().get_script_constant_map()
	var metadata:Dictionary=constants.Map.get_script_constant_map()
	var path:String=song.themes.get_sync_stream(index).resource_path
	if path.is_empty():
		if index==0:path=metadata.get("MAIN_B","") if ProjectSettings.get_setting("audio/soundtrack/prototype_variant","A")=="B" else metadata.get("MAIN_A","")
		elif index==2:path=metadata.get("MENU","")
		elif index==3:path=metadata.get("MENU_OPENER","")
		elif metadata.has("STUDIO_POOL"):
			var slots:Array=constants.get("STUDIO_STREAM_INDICES",[1])
			if index in slots:path=metadata.STUDIO_POOL[slots.find(index)]
		else:path=metadata.get("STUDIO","")
	var title:=path.get_file().get_basename().replace("_"," ").capitalize()
	if "dream_groove" in path:title="Dream Groove"
	elif "echo_reverb" in path:title="Echo Reverb"
	elif "crunch_time_A" in path:title="Crunch Time · Jazz"
	elif "crunch_time_B" in path:title="Crunch Time · Techno"
	return {"title":title if not title.is_empty() else "Soundtrack","bpm":metadata.get("BPM",0.0)}

func _draw() -> void:
	if levels.size() != BANDS or size.x < 120: return
	var muted := Color("C2B9D6")
	var mint := Color("5EF2C2")
	var indigo := Color("6F42FF")
	var mono := get_theme_font("font",&"MetadataLabel")
	var heading := get_theme_font("font",&"HeadingLabel")
	draw_style_box(get_theme_stylebox("panel",&"VisualizerPanel"),Rect2(0,24,size.x,size.y-24))
	draw_colored_polygon(PackedVector2Array([Vector2(0,24),Vector2(20,4),Vector2(size.x*0.55,4),Vector2(size.x*0.55+20,24),Vector2(size.x-12,24),Vector2(size.x,36),Vector2(size.x,42),Vector2(0,42)]),indigo)
	for i in 3:draw_rect(Rect2(24+i*9,24-i*7,7,7),Color("141519"))
	draw_string(heading,Vector2(67,32),"NOW PLAYING",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("FFF3E2"))
	var info:=track_info()
	var title_size:=mini(44,int((size.x-48)/maxf(1,heading.get_string_size(str(info.title),HORIZONTAL_ALIGNMENT_LEFT,-1,1).x)))
	draw_string(heading,Vector2(26,91),str(info.title).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,size.x-48,maxi(18,title_size),Color("FFF3E2"))
	draw_string(mono,Vector2(28,119),"%.0f BPM" % info.bpm,HORIZONTAL_ALIGNMENT_LEFT,-1,16,muted)
	var graph := graph_rect()
	for index in BANDS:
		var bar := bar_rect(index)
		var segments:=int(ceil(levels[index]*16.0))
		for step in segments:
			var y:=graph.end.y-(step+1)*graph.size.y/16.0
			draw_rect(Rect2(bar.position.x,y,bar.size.x,graph.size.y/16.0-2),mint if step==segments-1 else Color(indigo,0.4+0.6*float(step)/16.0))
	draw_string(mono,Vector2(26,size.y-10),"40 Hz – 12 kHz  ·  "+("QUIET" if _quiet else "LIVE"),HORIZONTAL_ALIGNMENT_LEFT,-1,10,muted)

func _exit_tree() -> void:
	if not _transferring: _release()
