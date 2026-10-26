extends RunState
## Constructed pre-Search entitlement/backlog compatibility fixture ONLY.
## Current acquisition is verified through real paid Search in verify_contract_search.
## Never used by a player scene, simulator recipe, or package.
func register_release(project: ProjectState) -> bool:
	if not super.register_release(project):return false
	if project.get_current_scope()<project.get_required_scope():return true
	var source:=project.get_release_id()
	var id:=StringName("%s:%s"%[ContractState.SIDESTREET_CONTRACT_ID,source])
	if not _sidestreet_entitlements.has(source):
		_sidestreet_entitlements[source]={"offer_id":id,"state":null}
		_contract_search.legacy_offers[id]=&"cash"
	return true
