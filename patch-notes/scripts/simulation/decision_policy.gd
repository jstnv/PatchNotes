## Optional observation contract for an in-process decision policy. Plain
## Callables continue to receive the complete CampaignSession observation.
extends RefCounted

func observation(session: RefCounted) -> Dictionary:
	return session.observation()

## Explicit policy decisions mirror the former automatic future supply. These
## transactions never alter a frozen project and do not create paid ownership.
static func engine_configuration_choice(view: Dictionary) -> Dictionary:
	var state: Dictionary=view.get("engine_features",{})
	var engine: StringName=StringName(view.get("selected_engine_id",&""))
	if not state.get("engines",{}).has(engine) or state.engines[engine].kind!=&"proprietary":return {}
	var row: Dictionary=state.engines[engine]
	var staged: Array[StringName]=[];staged.assign(row.staged)
	for id: StringName in view.get("engine_available_features",row.implemented):
		if FeatureStoreCatalog.is_active(id) and id not in row.committed and id not in staged:staged.append(id)
	if staged!=row.staged:return {"type":&"stage_engine_features","payload":{"feature_ids":staged}}
	var quote: Dictionary=view.get("engine_configuration",{})
	if quote.get("can_commit",false):return {"type":&"commit_engine_configuration","payload":{"quote":quote,"respec":quote.requires_respec}}
	return {}
