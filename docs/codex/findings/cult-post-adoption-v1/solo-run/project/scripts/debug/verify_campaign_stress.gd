## Baseline and independently seeded-policy determinism; four-release horizon.
extends "res://scripts/debug/campaign_stress_suite.gd"

func declared_cases() -> Array:
	return [_case("action-4417","4417","action",[],"configured")]

func repeat_first_case() -> bool:
	return true
