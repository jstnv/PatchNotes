extends SceneTree
func _initialize() -> void:
 await process_frame
 var pair: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_CONTRACT_FIXTURE")))
 var adapter: RefCounted=load("res://../docs/codex/findings/large-save-20261101-v2/instrumented_adapter.gd").new()
 var rows: Array=[{"id":"player","run":pair.player,"development":null}]+pair.world.studios
 for row: Dictionary in rows:
  print("PREDICATE_ACTOR ",row.id)
  var reason: String=adapter._validate_uncached(row.run,row.development!=null)
  assert(reason.is_empty(),reason)
 print("PREDICATE_TRACE_COMPLETE")
 quit()
