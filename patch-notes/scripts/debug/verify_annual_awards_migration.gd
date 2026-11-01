extends SceneTree

const WorldCodec := preload("res://scripts/market/rival_world_checkpoint.gd")
const Awards := preload("res://scripts/awards/annual_awards_ledger.gd")
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; print("FAIL: ",label)

func _initialize() -> void:
	_test.call_deferred()

func _test() -> void:
	var folder := "res://../docs/codex/findings/annual-awards-20261031-v1/"
	var prior: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder+"preceding-capture/report.json"))
	var late: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder+"prior-late.json"))
	check(prior.source == "ef14cc34682dbe4ab3e739ea13396da9979c3a8efb9c057c7c8cfa25d78980f6" and late.source == prior.source,"Both genuine earlier-build fixtures pin exact source")
	var adapter := StudioCheckpoint.new()
	for row: Dictionary in prior.studios:
		var run := adapter.hydrate(row.player)
		check(run != null,"Actual prior player restores: "+adapter.error)
		if run != null: check(adapter.capture(run) == row.player,"Prior player cash/history/RNG/engine/loan state unchanged")
	var catalog = root.get_node("CardDatabase").get_development_catalog()
	var fixtures: Array = [{"player":prior.world_player,"world":prior.world},{"player":late.player,"world":late.world}]
	var at_cutoff: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder+"prior-cutoff.json"))
	check(at_cutoff.source == prior.source and at_cutoff.rows.size() == 1,"Genuine exact-Week2 prior save pins executing source")
	fixtures.append_array(at_cutoff.rows)
	for fixture: Dictionary in fixtures:
		var player := adapter.hydrate(fixture.player)
		var codec := WorldCodec.new()
		var world = codec.restore(fixture.world,fixture.player,player,catalog)
		check(world != null,"Genuine earlier eight-rival world restores: "+codec.error)
		if world == null: continue
		check(adapter.capture(world.player) == fixture.player,"Old world player DTO retained exactly")
		var current := codec.capture(world)
		check(not current.is_empty(),"Current resave of old world validates: "+codec.error)
		if current.is_empty(): continue
		for index in fixture.world.studios.size():
			check(current.studios[index].run == fixture.world.studios[index].run,"Old rival run/active history/RNG retained "+str(index))
		check(world.annual_awards.entries.is_empty(),"Migration makes no retrospective result or reward")
		var year := int(world.player.get_current_year())
		var due := Awards.due_cycle(world.player,year)
		var expected := year+1 if world.cycle >= due else year
		check(world.annual_awards.first_year == expected,"Old-save first eligible year follows actual cutoff")
		var again = codec.restore(JSON.parse_string(JSON.stringify(current)),fixture.player,adapter.hydrate(fixture.player),catalog)
		check(again != null and again.annual_awards == world.annual_awards,"Resaved migration is repeatable and pays nothing")
		var bad := current.duplicate(true)
		bad.erase("annual_awards")
		check(not codec.validate(bad,fixture.player).is_empty(),"Current-source ledger stripping rejected")
		bad = current.duplicate(true)
		bad.source_identity = "unknown-awards-source"
		check(not codec.validate(bad,fixture.player).is_empty(),"Unknown source remains rejected")
	print("ANNUAL_AWARDS_MIGRATION checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)
