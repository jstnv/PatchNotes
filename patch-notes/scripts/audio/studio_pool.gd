extends RefCounted

## Audio-only randomness. Gameplay RNG and saved Studio state never select music.
const COUNT := 6
var rng := RandomNumberGenerator.new()
var selected := -1
var boundary_loop := 0

func _init() -> void:
	rng.randomize()
	selected = rng.randi_range(0, COUNT - 1)

func on_loop(loop_index: int, active: bool) -> bool:
	# Entry/exit fades retain their current track. Only a fully active Studio
	# changes arrangement, at the first mix update after an eight-bar wrap.
	if not active:
		boundary_loop = loop_index
		return false
	if loop_index <= boundary_loop: return false
	boundary_loop = loop_index
	var draw := rng.randi_range(0, COUNT - 2)
	selected = draw + (1 if draw >= selected else 0)
	return true
