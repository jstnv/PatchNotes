extends RefCounted
## Local deterministic presentation RNG; never accesses the game's random stream.
const HARD_LIMIT:=128
const NOTE_CAPACITY:=128
const BASS_START_ROUTES := [6, 4, 2, 0]
const CHORD_START_ROUTES := [1, 3, 5, 7]
class Pulse extends RefCounted:
	var active:=false
	var route:=0
	var distance:=0.0
	var color_index:=0
	var secondary:=false
	var split:=false
	var allow_split:=true
	var strength:=1.0
	var updated_tick:=-1
	var birth_order:=0
var settings:Resource
var geometry:RefCounted
var pulses:Array[Pulse]=[]
var energy:=Vector3.ZERO
var fallback:=true
var speed:=0.0
var tail:=0.0
var luminosity:=0.0
var thickness:=1.0
var bloom:=0.0
var total_spawned:=0
var total_splits:=0
var last_trigger_band:=-1
var trigger_counts:=PackedInt32Array([0,0,0])
var _random:=RandomNumberGenerator.new()
var _spawn_clock:=0.0
var _previous_target:=Vector3.ZERO
var _baseline:=Vector3.ZERO
var _band_cooldowns:=Vector3.ZERO
var _live_weight:=0.0
var _tick:=0
var _birth_order:=0
func _init()->void:
	_random.seed=74291
	for i in HARD_LIMIT:pulses.append(Pulse.new())
func bind(graph:RefCounted,config:Resource)->void:
	geometry=graph;settings=config
func reset()->void:
	for p in pulses:p.active=false
	_spawn_clock=0;energy=Vector3.ZERO;_live_weight=0
	_previous_target=Vector3.ZERO;_baseline=Vector3.ZERO;_band_cooldowns=Vector3.ZERO
	total_spawned=0;total_splits=0;last_trigger_band=-1;trigger_counts.fill(0);_random.seed=74291;_birth_order=0
func count()->int:
	var result:=0
	for p in pulses:
		if p.active:result+=1
	return result
func spawn(route:int,color_index:int,secondary:=false,distance:=0.0,strength:=1.0,capacity_override: int = -1)->Pulse:
	var limit := clampi(settings.max_pulses if capacity_override < 0 else capacity_override,2,HARD_LIMIT)
	if count()>=limit:return null
	for p in pulses:
		if p.active:continue
		p.active=true;p.route=route;p.color_index=color_index;p.secondary=secondary
		p.distance=distance;p.strength=strength;p.split=secondary;p.allow_split=true
		p.updated_tick=_tick
		_birth_order+=1;p.birth_order=_birth_order
		total_spawned+=1;return p
	return null

func spawn_note(kind: StringName, pitch: int, capacity_override: int = -1, strength: float = 1.0, distance: float = 0.0) -> Pulse:
	if kind not in [&"bass", &"chord"]: return null
	var limit := clampi(settings.max_pulses if capacity_override < 0 else capacity_override,2,HARD_LIMIT)
	if count() >= limit:
		# Musical onsets take priority over decorative branches; at saturation,
		# retire the oldest trail so a new note is never silently discarded.
		var oldest: Pulse = null
		for p: Pulse in pulses:
			if not p.active: continue
			if oldest == null or (p.secondary and not oldest.secondary) or (p.secondary == oldest.secondary and p.birth_order < oldest.birth_order): oldest = p
		if oldest != null: oldest.active = false
	# Different starting lanes keep the two instruments visually distinct.
	# The routes may still cross and merge farther across the board.
	var bass_index := clampi(floori(float(pitch - 36) / 6.0),0,BASS_START_ROUTES.size() - 1)
	var chord_index := posmod(pitch + total_spawned,CHORD_START_ROUTES.size())
	var route: int = BASS_START_ROUTES[bass_index] if kind == &"bass" else CHORD_START_ROUTES[chord_index]
	var pulse := spawn(route,1 if kind == &"bass" else 0,false,distance,strength,limit)
	if pulse != null and kind == &"chord": pulse.allow_split = false
	return pulse

func step(delta:float,spectrum:Vector3,audible:bool,note_events: Variant = null)->void:
	var dt:=clampf(delta,0,0.1)
	if dt<=0 or geometry.routes.is_empty():return
	_tick+=1
	var available:=clampi(NOTE_CAPACITY if note_events is Array else settings.max_pulses,2,HARD_LIMIT)
	for p in pulses:
		if p.active:
			if available<=0:p.active=false
			available-=1
	if audible and fallback:
		_spawn_clock=0.0
		_previous_target=Vector3.ZERO
		_baseline=Vector3.ZERO
	fallback=not audible
	var target:=spectrum*Vector3(settings.bass_sensitivity,settings.mid_sensitivity,settings.treble_sensitivity) if audible else Vector3.ZERO
	target=target.clamp(Vector3.ZERO,Vector3.ONE)
	var response:=1.0-exp(-dt/maxf(.02,settings.audio_smoothing))
	energy=energy.lerp(target,response)
	_live_weight=lerpf(_live_weight,1.0 if audible else 0.0,response)
	speed=settings.travel_speed*geometry.unit*(.65+.35*_live_weight+energy.y*.8)
	tail=settings.tail_length*geometry.unit*(.72+.7*energy.x)
	luminosity=settings.brightness*(.13+.40*_live_weight+.6*energy.x)
	thickness=geometry.unit*(1.3+energy.x*1.4)
	bloom=settings.glow_intensity*(.35+.65*_live_weight+energy.x*.6)
	_spawn_clock-=dt
	for band in 3:_band_cooldowns[band]=maxf(0.0,_band_cooldowns[band]-dt)
	if note_events is Array:
		for event: Dictionary in note_events:
			var strength := lerpf(0.65,1.0,clampf(float(event.get("velocity",100)) / 127.0,0.0,1.0)) * clampf(float(event.get("gain",1.0)),0.0,1.0)
			var distance := speed * maxf(0.0,float(event.get("age",0.0)))
			var pulse := spawn_note(StringName(event.kind),int(event.pitch),NOTE_CAPACITY,strength,distance)
			if pulse != null:
				last_trigger_band=0 if StringName(event.kind)==&"bass" else 1
				trigger_counts[last_trigger_band]+=1
		_previous_target=target
		_baseline=_baseline.lerp(target,1.0-exp(-dt/.55))
	elif audible:
		# Choose the most prominent fresh rise above its recent local level.
		# Constant notes do not generate timer-driven duplicates.
		var selected:=-1
		var best:=0.0
		for band in 3:
			var rise_rate:float=(target[band]-_previous_target[band])/dt
			var prominence:float=target[band]-_baseline[band]
			if target[band]>.16 and rise_rate>.48 and prominence>.06 and _band_cooldowns[band]<=0:
				var score:=rise_rate*.01+prominence*.4
				if score>best:best=score;selected=band
		if selected>=0 and _spawn_clock<=0:
			var pulse:=spawn((total_spawned*3)%geometry.BASE_ROUTES,2,selected==2,0,.65+.35*target[selected])
			if pulse!=null:
				last_trigger_band=selected
				trigger_counts[selected]+=1
				_band_cooldowns[selected]=.24 if selected!=1 else .34
				_spawn_clock=.10
		_previous_target=target
		_baseline=_baseline.lerp(target,1.0-exp(-dt/.55))
	elif _spawn_clock<=0:
		spawn((total_spawned*3)%geometry.BASE_ROUTES,2)
		_spawn_clock=1.8
		_previous_target=Vector3.ZERO
		_baseline=Vector3.ZERO
	# Birth/update stamps keep reused slots from advancing twice on their birth frame.
	for i in range(pulses.size()-1,-1,-1):
		var p:=pulses[i]
		if not p.active or p.updated_tick==_tick:continue
		p.updated_tick=_tick
		var before:=p.distance;p.distance+=speed*dt*(1.12 if p.secondary else 1.0)
		if p.distance>geometry.routes[p.route].get_baked_length()+tail:
			p.active=false;continue
		if p.allow_split and not p.split and geometry.forks.has(p.route):
			var fork:Dictionary=geometry.forks[p.route]
			if before<float(fork.distance) and p.distance>=float(fork.distance):
				p.split=true
				if audible and _random.randf()<clampf(settings.branching_probability+energy.z*.45,0,1):
					var child:=spawn(fork.target,p.color_index,p.secondary,p.distance,p.strength*.65)
					if child!=null:child.split=true;total_splits+=1
