## Run with Godot --headless --path patch-notes --script res://scripts/debug/verify_engine_catalog.gd
extends SceneTree

const Marketplace := preload("res://scripts/engines/engine_marketplace.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var listings: Array = Marketplace.starting_listings()
	check(listings.size() == 2, "Exactly two engines are listed at game start")
	var action: Dictionary = Marketplace.find(&"action_engine")
	var puzzle: Dictionary = Marketplace.find(&"puzzle_engine")
	check(action.get("creator_id") == &"incumbent-action" and action.get("creator_specialty") == &"action", "Action engine points to the actual Action rival")
	check(puzzle.get("creator_id") == &"incumbent-puzzle" and puzzle.get("creator_specialty") == &"puzzle", "Puzzle engine points to the actual Puzzle rival")
	for listing: Dictionary in listings:
		check(listing.get("max_scope") == 25 and listing.get("license_cents") == 750000 and listing.get("royalty_basis_points") == 2000, "Starting engine terms are exact")
	check(Marketplace.bonus_basis_points(action, &"graphics") == 1000 and Marketplace.bonus_basis_points(action, &"technology") == 1000, "Action dominant bonuses are Graphics and Technology")
	check(Marketplace.bonus_basis_points(puzzle, &"technology") == 1000 and Marketplace.bonus_basis_points(puzzle, &"design") == 1000, "Puzzle dominant bonuses follow the approved Core targets")
	check(Marketplace.bonus_basis_points(puzzle, &"graphics") == 0 and Marketplace.bonus_basis_points(action, &"sound") == 0, "Non-dominant categories receive no engine bonus or penalty")
	check(Marketplace.find(&"unknown_engine").is_empty(), "Unknown engines are unavailable")
	for path in ["res://certified/rival-opening-5607-v1.json", "res://certified/rival-opening-5613-v1.json"]:
		var certificate: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		check(certificate is Dictionary and certificate.get("fixture", {}).get("world", {}).get("studios", []) is Array, "Certified rival opening is readable")
		if not certificate is Dictionary: continue
		var studios: Array = certificate.fixture.world.studios
		for listing: Dictionary in listings:
			var owners := studios.filter(func(row: Dictionary) -> bool: return row.get("id") == str(listing.creator_id))
			check(owners.size() == 1 and owners[0].run.run.studio_specialty == str(listing.creator_specialty), "Each listing names one real specialist owner in the certified opening")
	print("Engine catalog: %d failures" % failures)
	quit(1 if failures else 0)
