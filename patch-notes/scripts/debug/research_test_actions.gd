class_name ResearchTestActions
extends RefCounted

## Existing supply/finance fixtures explicitly perform both new Store actions.
## Dedicated queue tests exercise the intermediate state and failures separately.
static func acquire(run: RunState, id: StringName) -> bool:
	if not run.admit_feature_research(run.get_feature_research_quote(id)): return false
	return run.research_feature(run.get_feature_research_quote(id))
