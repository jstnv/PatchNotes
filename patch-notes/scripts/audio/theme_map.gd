extends RefCounted
## Shared timing contract. Studio pool harmonies may differ and never overlap
## during an in-Studio variation switch.
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
const HARMONY := ["Dm9", "G13", "Cmaj9", "A7alt", "Dm9", "Bbmaj9", "Em7b5", "A7b9"] # Historical main/Studio Smooth reference.
const MAIN_A := "res://assets/audio/crunch_time_70/crunch_time_A_jazz.wav"
const MAIN_B := "res://assets/audio/crunch_time_70/crunch_time_B_techno.wav"
const MENU := "res://assets/boot/sequence_v1/crunch_time_menu_theme_echo_dreamwave_bass_v03.wav"
const MENU_OPENER := MENU
const STUDIO_SMOOTH := "res://assets/audio/crunch_time_70/crunch_time_studio_smooth_D_minor.wav"
const STUDIO := "res://assets/audio/crunch_time_70/studio_pool/crunch_time_studio_idle_70bpm.wav"
const STUDIO_POOL := [
	STUDIO,
	"res://assets/audio/crunch_time_70/studio_pool/crunch_time_studio_main_70bpm.wav",
	"res://assets/audio/crunch_time_70/studio_pool/crunch_time_studio_active_70bpm.wav",
	"res://assets/audio/crunch_time_70/studio_pool/crunch_time_studio_bass_led_idle_70bpm.wav",
	"res://assets/audio/crunch_time_70/studio_pool/crunch_time_studio_bass_led_main_70bpm.wav",
	"res://assets/audio/crunch_time_70/studio_pool/crunch_time_studio_bass_led_active_70bpm.wav",
]

static func compatible(stream: AudioStreamWAV) -> bool:
	return stream != null and stream.mix_rate == SAMPLE_RATE and stream.stereo and absf(stream.get_length() - LENGTH) < 0.5 / SAMPLE_RATE
