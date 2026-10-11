## Trusted explicit policies against scene-free campaigns. No default AI policy.
## tools/simulate.py supplies the frozen project and isolated process profile.
extends SceneTree

const Batch := preload("res://scripts/simulation/campaign_batch.gd")

func _initialize() -> void:
	await process_frame
	var options := {"config":"","output-dir":"","output":""}
	for argument in OS.get_cmdline_user_args():
		var pair := argument.trim_prefix("--").split("=",true,1)
		if pair.size() == 2 and options.has(pair[0]): options[pair[0]] = pair[1]
	for field in options:
		if options[field].is_empty():
			print("Usage: -- --config=<explicit-experiment.json> --output-dir=<new-cases-directory> --output=<report.json>")
			quit(2)
			return
	var config: Variant = JSON.parse_string(FileAccess.get_file_as_string(options.config))
	if not config is Dictionary or config.get("schema_version") != "1" or not config.get("policy") is Dictionary or not config.get("cases") is Array:
		_finish(options.output,{"ok":false,"error":"Malformed experiment schema"})
		return
	var declaration: Dictionary = config.policy
	if not declaration.get("script") is String or not declaration.script.begins_with("res://") or not declaration.script.ends_with(".gd"):
		_finish(options.output,{"ok":false,"error":"Policy script must be in the frozen project"})
		return
	for field in ["id","version","source_identity"]:
		if not declaration.get(field) is String or declaration[field].is_empty():
			_finish(options.output,{"ok":false,"error":"Missing explicit policy identity"})
			return
	if FileAccess.get_sha256(declaration.script) != declaration.source_identity:
		_finish(options.output,{"ok":false,"error":"Policy source hash mismatch"})
		return
	for item: Variant in config.cases:
		if not item is Dictionary or not Batch.valid_case(item):
			_finish(options.output,{"ok":false,"error":"Malformed explicit case"})
			return
		for field in ["id","version","source_identity"]:
			if item.policy[field] != declaration[field]:
				_finish(options.output,{"ok":false,"error":"Case policy does not match trusted factory"})
				return
	var policy_script: Variant = load(declaration.script)
	if not policy_script is GDScript or not policy_script.has_method("factory"):
		_finish(options.output,{"ok":false,"error":"Policy requires static factory(config: Dictionary) -> Callable"})
		return
	var factory := Callable(policy_script,"factory")
	var definitions: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var report := Batch.run_cases(config.cases,definitions,factory,options["output-dir"])
	report["scope"] = "Explicit trusted policies; independent campaigns, not shared-calendar AI competitors"
	_finish(options.output,report)

func _finish(path: String,report: Dictionary) -> void:
	if not Batch._write_json(path,report):
		print("Could not persist experiment report")
		quit(1)
		return
	print(JSON.stringify({"ok":report.get("ok",false),"error":report.get("error",""),"cases":report.get("results",[]).size()}))
	quit(0 if report.get("ok",false) else 1)
