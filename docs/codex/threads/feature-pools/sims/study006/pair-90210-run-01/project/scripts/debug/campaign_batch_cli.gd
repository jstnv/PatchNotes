## Explicit test-only cohort benchmark. Independent campaigns are not a rival
## world, and measured throughput includes exact trace hashing and persistence.
extends SceneTree

const Batch := preload("res://scripts/simulation/campaign_batch.gd")
const Fixture := preload("res://scripts/simulation/finite_fixture_policy.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")

func _initialize() -> void:
	await process_frame
	var options := {"config":OS.get_environment("PN_CAMPAIGN_BATCH_CONFIG"),"output-dir":OS.get_environment("PN_CAMPAIGN_BATCH_OUTPUT"),"cohort":OS.get_environment("PN_CAMPAIGN_BATCH_COUNT"),"samples":OS.get_environment("PN_CAMPAIGN_BATCH_SAMPLES"),"warmups":OS.get_environment("PN_CAMPAIGN_BATCH_WARMUPS"),"output":OS.get_environment("PN_CARD_FRAME_OUTPUT")}
	for argument in OS.get_cmdline_user_args():
		var pair := argument.trim_prefix("--").split("=",true,1)
		if pair.size() == 2 and options.has(pair[0]): options[pair[0]] = pair[1]
	for field in ["config","cohort","samples","warmups"]:
		if options[field].is_empty():
			print("Usage: -- --config=<case-template.json> --output-dir=<new-directory> --cohort=<positive-count> --samples=<positive-count> --warmups=<nonnegative-count> [--output=<report.json>]")
			quit(2)
			return
	if options["output-dir"].is_empty() and not options.output.is_empty(): options["output-dir"] = options.output+".batch"
	if options["output-dir"].is_empty() or not _count(options.cohort,1) or not _count(options.samples,1) or not _count(options.warmups,0):
		quit(2)
		return
	var template: Variant = JSON.parse_string(FileAccess.get_file_as_string(options.config))
	if template is Dictionary and template.get("format") == "patch-notes-development-replay": template = Batch.load_case(options.config)
	if not template is Dictionary or not Batch.valid_case(template) or not template.initial.get("recipe") is Dictionary or not Fixture.valid_config(template.policy.config):
		print("A valid explicit fresh-Studio case template and finite fixture config are required")
		quit(2)
		return
	if template.policy.id != Fixture.POLICY_ID or template.policy.version != Fixture.POLICY_VERSION or template.policy.source_identity != FileAccess.get_sha256("res://scripts/simulation/finite_fixture_policy.gd"):
		print("Fixture policy identity mismatch")
		quit(2)
		return
	var recipe: Dictionary = template.initial.recipe
	if not recipe.get("seed") is String or not recipe.seed.is_valid_int() or int(recipe.seed) < 0 or int(recipe.seed) > RunState.MAX_SIGNED_INT-RunRandom.STREAMS.size()-int(options.cohort):
		print("Invalid cohort seed range")
		quit(2)
		return
	var cases: Array = []
	for index in range(int(options.cohort)):
		var item: Dictionary = template.duplicate(true)
		item.case_id = "%s-%04d" % [template.case_id,index]
		item.initial.recipe.studio_id = "%s-%04d" % [recipe.studio_id,index]
		item.initial.recipe.seed = str(int(recipe.seed)+index)
		cases.append(item)
	var definitions: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var warmups: Array = []
	var samples: Array = []
	var all_ok := true
	var expected_results := ""
	for index in range(int(options.warmups)+int(options.samples)):
		var warming: bool = index < int(options.warmups)
		var sample_index: int = index if warming else index-int(options.warmups)
		var label := "%s-%03d" % ["warmup" if warming else "sample",sample_index]
		var batch := Batch.run_cases(cases,definitions,Fixture.factory,options["output-dir"].path_join(label))
		all_ok = all_ok and batch.ok
		var identity := Replay.digest(batch.results)
		if expected_results.is_empty(): expected_results = identity
		elif identity != expected_results:
			all_ok = false
			batch["repeat_divergence"] = true
		if warming: warmups.append(batch)
		else: samples.append(batch)
	var elapsed: Array[float] = []
	var throughput: Array[float] = []
	for sample: Dictionary in samples:
		var microseconds := 0
		var commands := 0
		for metric: Dictionary in sample.metrics: microseconds += int(metric.elapsed_us)
		for result: Dictionary in sample.results: commands += int(result.commands)
		elapsed.append(float(microseconds)/1000000.0)
		throughput.append(float(commands)*1000000.0/maxi(1,microseconds))
	var report := {"ok":all_ok,"schema_version":"1","cohort":int(options.cohort),"warmup_count":int(options.warmups),"sample_count":int(options.samples),"scope":"independent test campaigns, not a shared-calendar AI world","deterministic_result_identity":expected_results,"samples":samples,"warmups":warmups,"measurement":{"elapsed_seconds":elapsed,"instrumented_commands_per_second":throughput,"timing_includes":"setup, policy, legal execution, full-state trace hashing and artifact persistence; excludes final metrics-file write","memory_scope":"Godot static allocation counters; process cumulative peak is not per-case resident memory"}}
	var report_path: String = options.output if not options.output.is_empty() else options["output-dir"].path_join("batch-report.json")
	if not Batch._write_json(report_path,report):
		print("Could not persist batch report")
		quit(1)
		return
	print(JSON.stringify({"ok":all_ok,"cohort":report.cohort,"warmups":report.warmup_count,"samples":report.sample_count,"measurement":report.measurement}))
	quit(0 if all_ok else 1)

func _count(value: String,minimum: int) -> bool:
	return value.is_valid_int() and int(value) >= minimum and int(value) <= 1000000
