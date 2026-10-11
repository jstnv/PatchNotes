extends RefCounted
static func factory(_config: Dictionary) -> Callable:
	return func(_view: Dictionary) -> Dictionary: return {"unexpected":true}
