extends Resource
## Title-only presentation tuning. Speeds and lengths are reference pixels at720p.
@export_range(30,600) var travel_speed:=190.0
@export_range(120,800) var tail_length:=340.0
@export_range(0,2) var brightness:=0.95
@export_range(0,2) var glow_intensity:=0.8
@export_range(2,48) var max_pulses:=24
@export_range(0,3) var bass_sensitivity:=1.25
@export_range(0,3) var mid_sensitivity:=1.1
@export_range(0,3) var treble_sensitivity:=1.5
@export_range(0,1) var branching_probability:=0.24
@export_range(0,0.3) var inactive_trace_opacity:=0.045
@export_range(0.02,1) var audio_smoothing:=0.16
@export var debug_white_traces:=false
