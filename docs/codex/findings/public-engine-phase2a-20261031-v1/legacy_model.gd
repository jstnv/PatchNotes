extends SceneTree
func _initialize() -> void:
 var run:=RunState.new()
 var valid: bool=run.get_engine_feature_state().engines.has(&"legacy_engine")
 FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"legacy_model_available":valid}))
 if not valid:push_error("Unnamed legacy model lost its built-in compatibility engine")
 quit(0 if valid else 1)
