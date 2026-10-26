extends RefCounted
## Gains follow absolute mix position, never accumulated frame deltas or Tweens.
const Map := preload("res://scripts/audio/theme_map.gd")
const BAR := Map.STEP * Map.STEPS_PER_BAR
const FADE := Map.STEP * Map.STEPS_PER_BEAT # one quarter note
const ENTRY_STEP := Map.STEP # title -> Studio: next eighth note
const ENTRY_FADE := Map.STEP
var requested := 0.0
var weight := 0.0
var pending := false
var boundary := 0.0
var fade_start := -FADE
var fade_from := 0.0
var fade_to := 0.0
var fade_duration := FADE
var pending_duration := FADE

func request(studio: bool, seconds: float, quick_entry: bool = false) -> void:
	sample(seconds)
	var target := 1.0 if studio else 0.0
	if requested == target: return # Scene reconstruction cannot postpone a cue.
	requested = target
	pending = true
	var interval := ENTRY_STEP if quick_entry and studio else BAR
	boundary = (floor(seconds / interval + 0.000000001) + 1.0) * interval
	pending_duration = ENTRY_FADE if quick_entry and studio else FADE
	if is_equal_approx(weight, target) and fade_to == target:
		pending = false # Cancel a request that never became audible.

func _at(seconds: float) -> float:
	if seconds >= fade_start + fade_duration: return fade_to
	return lerpf(fade_from, fade_to, clampf((seconds - fade_start) / fade_duration, 0.0, 1.0))

func sample(seconds: float) -> float:
	if pending and seconds >= boundary:
		fade_from = _at(boundary)
		fade_to = requested
		fade_start = boundary
		fade_duration = pending_duration
		pending = false
	weight = _at(seconds)
	return weight
