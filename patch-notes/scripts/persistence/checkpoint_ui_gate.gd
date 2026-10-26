extends RefCounted

## UI intent waits; synchronous simulation commands keep their existing guard.
static func coordinator(run: RunState) -> CheckpointCoordinator:
	if run==null or not run.studio_departure_guard.is_valid(): return null
	return run.studio_departure_guard.get_object() as CheckpointCoordinator

static func needs_wait(run: RunState) -> bool:
	var owner:=coordinator(run)
	return owner!=null and owner.background_saves and owner.is_saving()

static func wait_saved(run: RunState) -> bool:
	var owner:=coordinator(run)
	return true if owner==null else await owner.wait_saved()
