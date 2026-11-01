extends SceneTree
var checks := 0
var failures := 0
func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1;print("FAIL: ",label)
func _initialize() -> void:
	go.call_deferred()
func go() -> void:
	var base := "res://../docs/codex/findings/annual-awards-20261031-v1/"
	var awarded: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base+"final-second-year/fixture.json")).player
	var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base+"preceding-capture/report.json")).studios[0].player
	expect(awarded.run.fanbase.has("annual_awards"),"Genuine two-year player has award receipts")
	var catalog = root.get_node("CardDatabase").get_development_catalog()
	var coordinator := CheckpointCoordinator.new()
	coordinator.rival_catalog = catalog
	var writer := preload("res://scripts/persistence/checkpoint_write_validator.gd").new()
	writer.rival_catalog = catalog
	var reader := preload("res://scripts/persistence/checkpoint_read_job.gd").ReadValidator.new()
	reader.rival_catalog = catalog
	for owner in [coordinator,writer,reader]:
		expect(not owner._validate_payload(awarded).is_empty(),"Orphaned award owner requires its global world")
		expect(owner._validate_payload(old).is_empty(),"Genuine ordinary player-only compatibility remains")
	var paired_path := OS.get_environment("PN_AWARDS_UI_FIXTURE")
	if not paired_path.is_empty():
		var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(paired_path))
		var paired: Dictionary = fixture.player.duplicate(true)
		paired.rival_world = fixture.world
		for owner in [coordinator,writer,reader]:
			expect(owner._validate_payload(paired).is_empty(),"Genuine awarded paired Studio remains valid")
	coordinator.free()
	print("AWARD_WORLD_REQUIREMENT checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)
