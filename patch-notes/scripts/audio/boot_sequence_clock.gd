extends RefCounted

const SAMPLE_RATE := 48000
const SWITCH_FRAMES := 329143
const BEAT_SECONDS := 60.0 / 70.0

func track_for_loop(loop: int) -> int:
	return 0 if loop <= 0 else 1 + ((loop - 1) % 2)

func next_beat(now: float) -> float:
	return (floori(maxf(0.0, now) / BEAT_SECONDS) + 1) * BEAT_SECONDS

func switch_length() -> float:
	return float(SWITCH_FRAMES) / SAMPLE_RATE

func logo_reveal_at() -> float:
	return switch_length() - 2.0
