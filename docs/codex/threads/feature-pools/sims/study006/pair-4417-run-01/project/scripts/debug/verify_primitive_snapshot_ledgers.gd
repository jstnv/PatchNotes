## Separately invoked Primitive competitor and forecast ledger verification.
extends SceneTree

const COMPETITOR_PATH := "res://data/primitive_competitor_ledger.json"
const FORECAST_PATH := "res://data/primitive_market_forecast_ledger.json"

var _failures := 0


func _initialize() -> void:
	var database := PrimitiveSnapshotDatabase.new()
	_expect(database.load_ledgers(), "Both strict Primitive snapshot ledgers load")
	_verify_competitors(database)
	_verify_forecasts(database)
	_verify_safe_queries(database)
	_verify_strict_validation()
	_finish()


func _verify_competitors(database: PrimitiveSnapshotDatabase) -> void:
	var expected := [
		[&"reckless_upstart", "Reckless Upstart", 10, 20],
		[&"fast_follower", "Fast Follower", 12, 30],
		[&"established_rival", "Established Rival", 16, 30],
		[&"obsessive_polisher", "Obsessive Polisher", 20, 20],
	]
	var definitions := database.get_competitors()
	var total := 0
	_expect(definitions.size() == 4, "Competitor ledger contains exactly four definitions")
	for index in range(expected.size()):
		var definition: CompetitorDefinition = definitions[index]
		var row: Array = expected[index]
		total += definition.get_selection_weight()
		_expect([definition.get_id(), definition.get_display_name(), definition.get_target_release_cycle(), definition.get_selection_weight()] == row, "Competitor definition matches authority: %s" % row[0])
		_expect(database.get_competitor(row[0]) == definition and database.has_competitor(row[0]), "Competitor stable lookup resolves: %s" % row[0])
	_expect(total == 100 and database.get_competitor(&"unknown") == null and not database.has_competitor(&"unknown"), "Competitor weights total 100 and unknown lookup is safe")
	var boundaries := {0: &"reckless_upstart", 19: &"reckless_upstart", 20: &"fast_follower", 49: &"fast_follower", 50: &"established_rival", 79: &"established_rival", 80: &"obsessive_polisher", 99: &"obsessive_polisher"}
	for roll: int in boundaries:
		_expect(database.select_competitor_id(roll) == boundaries[roll], "Competitor half-open boundary %d selects %s" % [roll, boundaries[roll]])


func _verify_forecasts(database: PrimitiveSnapshotDatabase) -> void:
	var expected := [
		[&"market_crash", "Market Crash", 7500, 10, "0.75"],
		[&"market_slump", "Market Slump", 9000, 20, "0.90"],
		[&"stable_market", "Stable Market", 10000, 40, "1.00"],
		[&"market_surge", "Market Surge", 11500, 20, "1.15"],
		[&"market_boom", "Market Boom", 13000, 10, "1.30"],
	]
	var definitions := database.get_forecasts()
	var total := 0
	_expect(definitions.size() == 5, "Forecast ledger contains exactly five definitions")
	for index in range(expected.size()):
		var definition: MarketForecastDefinition = definitions[index]
		var row: Array = expected[index]
		total += definition.get_selection_weight()
		_expect([definition.get_id(), definition.get_display_name(), definition.get_launch_demand_basis_points(), definition.get_selection_weight(), definition.get_launch_demand_multiplier_text()] == row, "Forecast definition matches authority: %s" % row[0])
		_expect(database.get_forecast(row[0]) == definition and database.has_forecast(row[0]), "Forecast stable lookup resolves: %s" % row[0])
	_expect(total == 100 and database.get_forecast(&"unknown") == null and not database.has_forecast(&"unknown"), "Forecast weights total 100 and unknown lookup is safe")
	var boundaries := {0: &"market_crash", 9: &"market_crash", 10: &"market_slump", 29: &"market_slump", 30: &"stable_market", 69: &"stable_market", 70: &"market_surge", 89: &"market_surge", 90: &"market_boom", 99: &"market_boom"}
	for roll: int in boundaries:
		_expect(database.select_forecast_id(roll) == boundaries[roll], "Forecast half-open boundary %d selects %s" % [roll, boundaries[roll]])


func _verify_safe_queries(database: PrimitiveSnapshotDatabase) -> void:
	var competitors := database.get_competitors()
	var forecasts := database.get_forecasts()
	competitors.clear()
	forecasts.clear()
	_expect(database.get_competitors().size() == 4 and database.get_forecasts().size() == 5, "Returned collections cannot mutate database-owned arrays")
	_expect(database.select_competitor_id(-1).is_empty() and database.select_competitor_id(100).is_empty() and database.select_competitor_id(1.0).is_empty(), "Malformed competitor rolls reject")
	_expect(database.select_forecast_id(-1).is_empty() and database.select_forecast_id(100).is_empty() and database.select_forecast_id(1.0).is_empty(), "Malformed forecast rolls reject")


func _verify_strict_validation() -> void:
	var competitors: Array = _read_array(COMPETITOR_PATH)
	var forecasts: Array = _read_array(FORECAST_PATH)
	_expect(PrimitiveSnapshotDatabase.validate_competitor_data(competitors) and PrimitiveSnapshotDatabase.validate_forecast_data(forecasts), "Unmodified ledger JSON passes strict public validation")
	for mutation: Callable in [
		func(data: Array) -> void: data.pop_back(),
		func(data: Array) -> void: data[0].extra = 1,
		func(data: Array) -> void: data[0].erase("display_name"),
		func(data: Array) -> void: data[0].id = "Bad-ID",
		func(data: Array) -> void: data[0].display_name = "",
		func(data: Array) -> void: data[0].target_release_cycle = 0,
		func(data: Array) -> void: data[0].target_release_cycle = 10.5,
		func(data: Array) -> void: data[0].selection_weight = 0,
		func(data: Array) -> void: data[1].id = data[0].id,
		func(data: Array) -> void: data[0].selection_weight = 21,
	]:
		var altered := competitors.duplicate(true)
		mutation.call(altered)
		_expect(not PrimitiveSnapshotDatabase.validate_competitor_data(altered), "Malformed or altered competitor ledger rejects")
	for mutation: Callable in [
		func(data: Array) -> void: data.pop_back(),
		func(data: Array) -> void: data[0].extra = 1,
		func(data: Array) -> void: data[0].erase("display_name"),
		func(data: Array) -> void: data[0].id = "Bad-ID",
		func(data: Array) -> void: data[0].display_name = "",
		func(data: Array) -> void: data[0].launch_demand_basis_points = 0,
		func(data: Array) -> void: data[0].launch_demand_basis_points = 7500.5,
		func(data: Array) -> void: data[0].selection_weight = 0,
		func(data: Array) -> void: data[1].id = data[0].id,
		func(data: Array) -> void: data[0].selection_weight = 11,
	]:
		var altered := forecasts.duplicate(true)
		mutation.call(altered)
		_expect(not PrimitiveSnapshotDatabase.validate_forecast_data(altered), "Malformed or altered forecast ledger rejects")


func _read_array(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Array


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
		return
	_failures += 1
	push_error("FAIL: %s" % description)


func _finish() -> void:
	if _failures == 0:
		print("Primitive snapshot ledger verification passed.")
	quit(_failures)
