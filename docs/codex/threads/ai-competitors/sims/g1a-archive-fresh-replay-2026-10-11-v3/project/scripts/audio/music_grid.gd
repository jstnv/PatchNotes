class_name MusicGrid
extends RefCounted

const STEP := 60.0 / 140.0
const STEPS_PER_LOOP := 64
var seconds := 0.0
var loops := 0
var previous_position := -1.0

func unwrap(position: float, length: float, elapsed: float, paused: bool) -> int:
	if paused: return loops
	if previous_position >= 0.0 and length > 0.0:
		# WAV's get_loop_count() returns zero. Wall elapsed only disambiguates
		# the integer lap after a long frame; fractional timing remains audio-led.
		loops += maxi(0, roundi((elapsed - (position - previous_position)) / length))
	previous_position = position
	return loops

func sample(position: float, loops: int, length: float, since_mix: float, latency: float, paused: bool) -> float:
	if paused or length <= 0.0: return seconds
	# The WAV is rounded to a whole sample. Map its endpoint to exactly 64
	# subdivisions, preventing that sub-sample error accumulating each loop.
	var scale_to_grid := STEPS_PER_LOOP * STEP / length
	var heard := (loops * length + position + since_mix - latency) * scale_to_grid
	seconds = maxf(seconds, maxf(0.0, heard)) # Audio-thread jitter never rewinds.
	return seconds
