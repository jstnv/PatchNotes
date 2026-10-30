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

func _ready() -> void:
	theme = FolderUI.THEME
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
	for name in [&"Music",&"Master"]:
		var bus := AudioServer.get_bus_index(name)
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
	return Rect2(0,76,size.x,maxf(16.0,size.y-118.0))

func bar_rect(index: int) -> Rect2:
	var graph := graph_rect()
	var cell := graph.size.x/BANDS
	var height := maxf(2.0,floorf(levels[index]*graph.size.y/4.0)*4.0)
	return Rect2(floorf(index*cell)+1,graph.end.y-height,maxf(1.0,floorf(cell)-3),height)

func _draw() -> void:
	if levels.size() != BANDS or size.x < 120: return
	var muted := FolderUI.color(&"muted")
	var cyan := FolderUI.color(&"cyan")
	var orange := FolderUI.color(&"orange")
	var mono := get_theme_font("font",&"MetadataLabel")
	var heading := get_theme_font("font",&"HeadingLabel")
	draw_string(mono,Vector2(0,12),"SOUNDTRACK / TEST",HORIZONTAL_ALIGNMENT_LEFT,-1,11,muted)
	draw_string(heading,Vector2(0,43),"CRUNCH TIME",HORIZONTAL_ALIGNMENT_LEFT,-1,mini(24,int(size.x/8)),FolderUI.color(&"text"))
	var graph := graph_rect()
	for fraction in [0.0,0.25,0.5,0.75]:
		var y := roundf(graph.end.y-graph.size.y*fraction)
		draw_line(Vector2(0,y),Vector2(size.x,y),Color(muted,0.13),1.0)
	for index in BANDS:
		var bar := bar_rect(index)
		draw_rect(bar,Color(cyan,0.55+0.35*levels[index]))
		if levels[index] > 0.01:
			draw_rect(Rect2(bar.position.x,graph.end.y+4,bar.size.x,minf(10,bar.size.y*0.06)),Color(cyan,0.07))
		if peaks[index] > 0.01:
			draw_rect(Rect2(bar.position.x,roundf(graph.end.y-peaks[index]*graph.size.y),bar.size.x,2),Color(orange,0.9))
	draw_string(mono,Vector2(0,graph.end.y+22),"40 Hz",HORIZONTAL_ALIGNMENT_LEFT,-1,11,muted)
	if size.x >= 300:
		var mid := log(1000.0/LOW_HZ)/log(HIGH_HZ/LOW_HZ)
		draw_string(mono,Vector2(size.x*mid-18,graph.end.y+22),"1 kHz",HORIZONTAL_ALIGNMENT_LEFT,-1,11,muted)
	draw_string(mono,Vector2(size.x-34,graph.end.y+22),"12kHz",HORIZONTAL_ALIGNMENT_LEFT,-1,11,muted)
	draw_string(mono,Vector2(0,size.y-2),"70 BPM / "+("QUIET" if _quiet else "LIVE"),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(muted,0.75))

func _exit_tree() -> void:
	_release()
