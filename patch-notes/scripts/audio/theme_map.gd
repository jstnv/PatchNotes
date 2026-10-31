extends RefCounted
## Arrangement contract v1. New dynamic themes use this same harmonic timeline.
const REVISION := "crunch-time-d-minor-70-v1"
const BPM := 70.0
const BEATS_PER_BAR := 4
const BARS := 8
const STEPS_PER_BEAT := 2
const STEPS_PER_BAR := BEATS_PER_BAR * STEPS_PER_BEAT
const STEPS_PER_LOOP := BARS * STEPS_PER_BAR
const STEP := 60.0 / BPM / STEPS_PER_BEAT
const SAMPLE_RATE := 48000
const FRAMES := 1316571
const LENGTH := float(FRAMES) / SAMPLE_RATE
const HARMONY := ["Dm9", "G13", "Cmaj9", "A7alt", "Dm9", "Bbmaj9", "Em7b5", "A7b9"]
const MAIN_A := "res://assets/audio/crunch_time_70/crunch_time_A_jazz.wav"
const MAIN_B := "res://assets/audio/crunch_time_70/crunch_time_B_techno.wav"
const MENU := "res://assets/audio/crunch_time_70/crunch_time_menu_theme_echo_reverb_v02.wav"
const MENU_OPENER := "res://assets/audio/crunch_time_70/crunch_time_menu_dream_groove_v01.wav"
const STUDIO := "res://assets/audio/crunch_time_70/crunch_time_studio_smooth_D_minor.wav"

static func compatible(stream: AudioStreamWAV) -> bool:
	return stream != null and stream.mix_rate == SAMPLE_RATE and stream.stereo and absf(stream.get_length() - LENGTH) < 0.5 / SAMPLE_RATE
