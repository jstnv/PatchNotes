extends SceneTree
const Codec:=preload("res://scripts/market/rival_world_checkpoint.gd")
const PRIOR:="25dc0a8892df95b95b93690b5224d12e4242a97426ad5d4dbf4c98d42696af59"
var failures:=0
var checks:=0
func expect(ok: bool,label: String)->void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+label)
func _initialize()->void:
	await process_frame
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../tools/fixtures/research_latency_pre_fix.json"))
	expect(fixture.world.source_identity==PRIOR,"Actual pre-fix producer identity is exact")
	var adapter:=StudioCheckpoint.new()
	expect(fixture.player.content_revision==adapter.revision(),"No content/rule revision changed")
	var run:=adapter.hydrate(fixture.player)
	expect(run!=null,"Prior player passes current full schema/finance validation")
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	# Exercise the ordinary production path without a captured-identity override.
	var codec:=Codec.new()
	var world:=codec.restore(fixture.world,fixture.player,run,catalog)
	expect(world!=null,"Approved exact source pair passes every ordinary world check: "+codec.error)
	if world==null:quit(1);return
	# Compare the actual persisted JSON value types. Capture uses typed native
	# arrays; the original producer file has already crossed JSON parsing.
	expect(var_to_bytes(JSON.parse_string(JSON.stringify(adapter.capture(run))))==var_to_bytes(fixture.player),"Every persisted player field and RNG is wire-exact")
	var actual:=codec.capture(world);actual.erase("source_identity")
	var prior: Dictionary=fixture.world.duplicate(true);prior.erase("source_identity")
	expect(var_to_bytes(JSON.parse_string(JSON.stringify(actual)))==var_to_bytes(prior),"Every persisted world/rival/history/ownership/RNG field is wire-exact")
	var wrong: Dictionary=fixture.world.duplicate(true);wrong.source_identity="0".repeat(64)
	expect(Codec.new().restore(wrong,fixture.player,adapter.hydrate(fixture.player),catalog)==null,"Unknown source remains rejected")
	wrong=fixture.world.duplicate(true);wrong.studios[0].run.run.studio_finance.cash_cents="999999"
	expect(Codec.new().restore(wrong,fixture.player,adapter.hydrate(fixture.player),catalog)==null,"Same-source tampered rival finance still rejects")
	var wrong_player: Dictionary=fixture.player.duplicate(true);wrong_player.content_revision=adapter._rules_revision(StudioCheckpoint.PRE_ERA_RULES)
	expect(Codec.new().restore(fixture.world,wrong_player,run,catalog)==null,"Older player content cannot pair with this source")
	wrong=fixture.world.duplicate(true);wrong.studios[0].run.content_revision=wrong_player.content_revision
	expect(Codec.new().restore(wrong,fixture.player,run,catalog)==null,"Older rival content cannot pair with this source")
	var report: Dictionary={"ok":failures==0,"checks":checks,"failures":failures,"production_compatibility":true,"prior":PRIOR}
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(report));print(JSON.stringify(report));quit(1 if failures else 0)
