extends SceneTree
const ReadJob := preload("res://scripts/persistence/checkpoint_read_job.gd")
const WorldCodec := preload("res://scripts/market/rival_world_checkpoint.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+label)
	else:print("PASS: "+label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var codec:=CheckpointCodec.new()
	var payload: Dictionary=codec.open_envelope(FileAccess.get_file_as_string(OS.get_environment("PN_PRIOR_SAVE")))
	check(not payload.is_empty() and codec.error.is_empty(),"Genuine private checkpoint checksum and envelope accepted")
	if payload.is_empty():quit(1);return
	var before:=var_to_bytes(payload)
	var expected_player: Dictionary=payload.duplicate(true);expected_player.erase("rival_world")
	var validator=ReadJob.ReadValidator.new()
	validator.rival_catalog=root.get_node("CardDatabase").get_development_catalog()
	var error: String=validator._validate_payload(payload)
	check(error.is_empty(),"Strict current-source player/eight-rival read accepted: "+error)
	if not error.is_empty():quit(1);return
	check(validator.world!=null and validator.world.studios.size()==8,"All eight rivals were strictly restored")
	check(var_to_bytes(validator.player_payload)==var_to_bytes(expected_player),"Detached player payload exactly matches full-copy baseline")
	check(validator.accepted_bytes==before and var_to_bytes(payload)==before,"Exact original input bytes are retained without mutation")
	var before_player:=var_to_bytes(StudioCheckpoint.new().capture(validator.player))
	var candidate_before:=var_to_bytes(validator.candidate)
	validator.player_payload.run.studio_traits["private-test-sentinel"]="changed"
	check(var_to_bytes(validator.candidate)==candidate_before and var_to_bytes(payload)==before,"Nested player-payload edits cannot mutate candidate or input")
	check(var_to_bytes(StudioCheckpoint.new().capture(validator.player))==before_player,"Nested player-payload edits cannot mutate hydrated player or RNG")
	var before_other:=var_to_bytes(validator.player_payload)
	validator.candidate.rival_world.source_identity="private-test-invalid"
	check(var_to_bytes(payload)==before and var_to_bytes(validator.player_payload)==before_other,"Nested candidate edits cannot mutate input or player payload")
	var bad:=payload.duplicate(true);bad.rival_world.source_identity="private-test-invalid"
	var invalid=ReadJob.ReadValidator.new();invalid.rival_catalog=validator.rival_catalog
	check(not invalid._validate_payload(bad).is_empty(),"Unknown rival source rejected")
	bad=payload.duplicate(true);bad.rival_world.erase("annual_awards")
	invalid=ReadJob.ReadValidator.new();invalid.rival_catalog=validator.rival_catalog
	check(not invalid._validate_payload(bad).is_empty(),"Missing awards rejected")
	bad=payload.duplicate(true);bad.content_revision="private-test-invalid"
	invalid=ReadJob.ReadValidator.new();invalid.rival_catalog=validator.rival_catalog
	check(not invalid._validate_payload(bad).is_empty(),"Wrong rules revision rejected")
	print("READ_VALIDATOR_COPY checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
