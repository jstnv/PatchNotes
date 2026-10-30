class_name PrimitiveSnapshotDatabase
extends RefCounted

const COMPETITOR_LEDGER_PATH := "res://data/primitive_competitor_ledger.json"
const FORECAST_LEDGER_PATH := "res://data/primitive_market_forecast_ledger.json"
const TOTAL_WEIGHT := 100

const COMPETITOR_ROSTER := [
	[&"reckless_upstart", "Reckless Upstart", 10, 20],
	[&"fast_follower", "Fast Follower", 12, 30],
	[&"established_rival", "Established Rival", 16, 30],
	[&"obsessive_polisher", "Obsessive Polisher", 20, 20],
]
const FORECAST_ROSTER := [
	[&"market_crash", "Market Crash", 7500, 10],
	[&"market_slump", "Market Slump", 9000, 20],
	[&"stable_market", "Stable Market", 10000, 40],
	[&"market_surge", "Market Surge", 11500, 20],
	[&"market_boom", "Market Boom", 13000, 10],
]

var _competitors: Array[CompetitorDefinition] = []
var _forecasts: Array[MarketForecastDefinition] = []
var _competitors_by_id: Dictionary[StringName, CompetitorDefinition] = {}
var _forecasts_by_id: Dictionary[StringName, MarketForecastDefinition] = {}
var _loaded := false


func load_ledgers(competitor_path: String = COMPETITOR_LEDGER_PATH, forecast_path: String = FORECAST_LEDGER_PATH) -> bool:
	if _loaded:
		return true
	var competitor_data: Variant = _read_json_array(competitor_path)
	var forecast_data: Variant = _read_json_array(forecast_path)
	if not validate_competitor_data(competitor_data) or not validate_forecast_data(forecast_data):
		return false
	for index in range(COMPETITOR_ROSTER.size()):
		var entry: Dictionary = competitor_data[index]
		var definition: CompetitorDefinition = CompetitorDefinition.new(StringName(entry.id), entry.display_name, int(entry.target_release_cycle), int(entry.selection_weight))
		_competitors.append(definition)
		_competitors_by_id[definition.get_id()] = definition
	for index in range(FORECAST_ROSTER.size()):
		var entry: Dictionary = forecast_data[index]
		var definition: MarketForecastDefinition = MarketForecastDefinition.new(StringName(entry.id), entry.display_name, int(entry.launch_demand_basis_points), int(entry.selection_weight))
		_forecasts.append(definition)
		_forecasts_by_id[definition.get_id()] = definition
	_loaded = true
	return true


func get_competitors() -> Array[CompetitorDefinition]:
	return _competitors.duplicate()


func get_competitor(id: StringName) -> CompetitorDefinition:
	return _competitors_by_id.get(id)


func has_competitor(id: StringName) -> bool:
	return _competitors_by_id.has(id)


func get_forecasts() -> Array[MarketForecastDefinition]:
	return _forecasts.duplicate()


func get_forecast(id: StringName) -> MarketForecastDefinition:
	return _forecasts_by_id.get(id)


func has_forecast(id: StringName) -> bool:
	return _forecasts_by_id.has(id)


func select_competitor_id(roll: Variant) -> StringName:
	return _select_id(_competitors, roll)


func select_forecast_id(roll: Variant) -> StringName:
	return _select_id(_forecasts, roll)


static func validate_competitor_data(data: Variant) -> bool:
	if not data is Array or data.size() != COMPETITOR_ROSTER.size():
		return false
	var seen: Dictionary[StringName, bool] = {}
	var total := 0
	for index in range(data.size()):
		var entry: Variant = data[index]
		if not entry is Dictionary or not _has_exact_keys(entry, [&"id", &"display_name", &"target_release_cycle", &"selection_weight"]):
			return false
		var expected: Array = COMPETITOR_ROSTER[index]
		if not _is_stable_id(entry.id) or StringName(entry.id) != expected[0] or typeof(entry.display_name) != TYPE_STRING or entry.display_name != expected[1]:
			return false
		if not _is_exact_positive_integer(entry.target_release_cycle) or int(entry.target_release_cycle) != expected[2]:
			return false
		if not _is_exact_positive_integer(entry.selection_weight) or int(entry.selection_weight) != expected[3] or seen.has(StringName(entry.id)):
			return false
		seen[StringName(entry.id)] = true
		total += int(entry.selection_weight)
	return total == TOTAL_WEIGHT


static func validate_forecast_data(data: Variant) -> bool:
	if not data is Array or data.size() != FORECAST_ROSTER.size():
		return false
	var seen: Dictionary[StringName, bool] = {}
	var total := 0
	for index in range(data.size()):
		var entry: Variant = data[index]
		if not entry is Dictionary or not _has_exact_keys(entry, [&"id", &"display_name", &"launch_demand_basis_points", &"selection_weight"]):
			return false
		var expected: Array = FORECAST_ROSTER[index]
		if not _is_stable_id(entry.id) or StringName(entry.id) != expected[0] or typeof(entry.display_name) != TYPE_STRING or entry.display_name != expected[1]:
			return false
		if not _is_exact_positive_integer(entry.launch_demand_basis_points) or int(entry.launch_demand_basis_points) != expected[2]:
			return false
		if not _is_exact_positive_integer(entry.selection_weight) or int(entry.selection_weight) != expected[3] or seen.has(StringName(entry.id)):
			return false
		seen[StringName(entry.id)] = true
		total += int(entry.selection_weight)
	return total == TOTAL_WEIGHT


func _select_id(definitions: Array, roll: Variant) -> StringName:
	if not _loaded or typeof(roll) != TYPE_INT or roll < 0 or roll >= TOTAL_WEIGHT:
		return StringName()
	var cumulative := 0
	for index in range(definitions.size()):
		var definition: Variant = definitions[index]
		cumulative += definition.get_selection_weight()
		if roll < cumulative or index == definitions.size() - 1:
			return definition.get_id()
	return StringName()


static func _read_json_array(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Could not open Primitive snapshot ledger: %s" % path)
		return null
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Array:
		push_warning("Primitive snapshot ledger must contain a JSON array: %s" % path)
		return null
	return parsed


static func _has_exact_keys(entry: Dictionary, expected: Array[StringName]) -> bool:
	if entry.size() != expected.size():
		return false
	for key: StringName in expected:
		if not entry.has(key):
			return false
	return true


static func _is_exact_positive_integer(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT and value > 0) or (typeof(value) == TYPE_FLOAT and is_finite(value) and value > 0.0 and value == floor(value))


static func _is_stable_id(value: Variant) -> bool:
	if typeof(value) != TYPE_STRING and typeof(value) != TYPE_STRING_NAME:
		return false
	var text := String(value)
	return not text.is_empty() and text == text.to_lower() and text == text.strip_edges() and text.is_valid_identifier()
