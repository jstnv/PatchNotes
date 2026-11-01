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
	var puzzle: Dictionary = Marketplace.find(&"puzzle_engine")
	var adventure: Dictionary = Marketplace.find(&"adventure_engine")
	check(listings.all(func(row: Dictionary) -> bool: return row.id!=&"action_engine") and not Marketplace.find(&"action_engine").is_empty(), "Retired Action remains available only for existing licenses")
	check(puzzle.get("creator_id") == &"incumbent-puzzle" and puzzle.get("creator_specialty") == &"puzzle", "Puzzle engine points to the actual Puzzle rival")
	check(adventure.get("creator_id") == &"incumbent-adventure" and adventure.get("creator_specialty") == &"adventure", "Adventure engine points to the actual Adventure rival")
	for listing: Dictionary in listings:
		check(listing.get("max_scope") == 27 and listing.get("license_cents") == 250000 and listing.get("royalty_basis_points") == 1500, "Starting engine terms are exact")
	check(Marketplace.bonus_basis_points(puzzle, &"technology") == 1000 and Marketplace.bonus_basis_points(puzzle, &"design") == 1000, "Puzzle dominant bonuses follow the approved Core targets")
	check(Marketplace.bonus_basis_points(adventure, &"graphics") == 1000 and Marketplace.bonus_basis_points(adventure, &"design") == 1000, "Adventure dominant bonuses use Graphics and Design")
	check(Marketplace.bonus_basis_points(puzzle, &"graphics") == 0 and Marketplace.bonus_basis_points(adventure, &"sound") == 0, "Non-dominant categories receive no engine bonus or penalty")
	var old_puzzle: Dictionary=Marketplace.terms_for_record(&"puzzle_engine",{"origin":"legacy-access-v1"})
	check(old_puzzle.max_scope==25 and old_puzzle.royalty_basis_points==2000,"Existing Puzzle license retains its frozen capacity and royalty")
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../docs/codex/threads/engine-system/2026-10-31-starting-libraries-recommended.json"))
	for listing: Dictionary in listings:
		var key: String="rival_puzzle" if listing.id==&"puzzle_engine" else "rival_adventure"
		var expected: Array[StringName]=[]
		for id: String in manifest.libraries[key].ids:expected.append(StringName(id))
		check(Array(listing.library)==Array(expected),"Exact October 31 fixed library for "+key)
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
