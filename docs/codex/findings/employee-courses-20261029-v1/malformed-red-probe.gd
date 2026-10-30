extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var adapter:=StudioCheckpoint.new()
	for raw: Variant in [{"employees":{"events":[null]}},{"employees":{"events":{}}},{"employees":[]},[],null]:
		var payload:={"content_revision":adapter.pre_course_revision(),"run":raw}
		checks+=2
		if adapter.validate(payload).is_empty():failures+=1;push_error("Malformed predecessor validation accepted")
		if adapter.hydrate(payload)!=null:failures+=1;push_error("Malformed predecessor hydrated")
	print("MALFORMED_CAREER_PREDECESSOR checks=%d failures=%d"%[checks,failures]);quit(failures)
