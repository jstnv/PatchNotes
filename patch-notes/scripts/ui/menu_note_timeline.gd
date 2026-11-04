extends RefCounted
## Deterministic presentation-only scheduler. Time is the audible, unwrapped
## transport cursor; each note-on is retained, including simultaneous voices.

var _track: StringName = &""
var _events: Array = []
var _intro_events: Array = []
var _loop_seconds := 0.0
var _intro_seconds := 0.0
var _cursor := 0.0

func _ordered(events: Array) -> Array:
	var result := []
	for index in events.size():
		var event: Dictionary = events[index].duplicate()
		event["_order"] = index
		result.append(event)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a._order) < int(b._order) if float(a.time) == float(b.time) else float(a.time) < float(b.time))
	return result

func configure(track: StringName, events: Array, loop_length: float, at_seconds: float) -> void:
	_track = track
	_events = _ordered(events)
	_intro_events.clear()
	_intro_seconds = 0.0
	_loop_seconds = maxf(0.0, loop_length)
	_cursor = at_seconds

func configure_intro(track: StringName, intro_events: Array, intro_length: float, loop_events: Array, loop_length: float, at_seconds: float) -> void:
	configure(track, loop_events, loop_length, at_seconds)
	_intro_events = _ordered(intro_events)
	_intro_seconds = maxf(0.0, intro_length)

func advance(track: StringName, seconds: float, audible: bool, max_history: float = INF) -> Array:
	var result := []
	if track != _track: return result
	if seconds < _cursor:
		_cursor = seconds
		return result
	# Presentation callers may skip trails that have already traversed the
	# screen after a long suspend, without replaying an unbounded backlog.
	var previous := maxf(_cursor, seconds - max_history)
	_cursor = seconds
	if not audible or seconds == previous: return result
	for source: Dictionary in _intro_events:
		var event_time := float(source.time)
		if event_time > previous and event_time <= seconds:
			result.append(_event(source,event_time))
	if _loop_seconds <= 0.0 or seconds < _intro_seconds: return result
	var start_cycle := maxi(0, floori(maxf(0.0, previous - _intro_seconds) / _loop_seconds))
	var end_cycle := maxi(0, floori((seconds - _intro_seconds) / _loop_seconds))
	for cycle in range(start_cycle,end_cycle + 1):
		var offset := _intro_seconds + cycle * _loop_seconds
		for source: Dictionary in _events:
			var event_time := offset + float(source.time)
			if event_time > previous and event_time <= seconds:
				result.append(_event(source,event_time))
	return result

func _event(source: Dictionary, absolute_time: float) -> Dictionary:
	var result := source.duplicate()
	result.erase("_order")
	result["absolute_time"] = absolute_time
	result["color_index"] = 1 if StringName(source.kind) == &"bass" else 0
	return result
