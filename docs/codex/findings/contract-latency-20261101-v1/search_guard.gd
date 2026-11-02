extends SceneTree
var checks:=0
var failures:=0
class Gate extends RefCounted:
	var studio_calls:=0
	var departure_calls:=0
	var allow_studio:=true
	func studio() -> bool:studio_calls+=1;return allow_studio
	func departure() -> bool:departure_calls+=1;return false
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize() -> void:
	await process_frame
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_CONTRACT_FIXTURE")))
	var run:=StudioCheckpoint.new().hydrate(data.player)
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	var state:=run.accept_primitive_contract()
	check(state!=null,"Genuine player accepts introductory work")
	if state==null:quit(1);return
	var contract=load("res://scripts/simulation/contract_session.gd").new(state,run,catalog)
	check(contract.execute(contract.command(&"begin")).ok,"Legal Contract deals")
	for i in 2:check(contract.execute(contract.command(&"play",{"candidate_ids":contract.candidate_ids.slice(0,4)})).ok,"Legal introductory hand")
	check(run._unlocked_publishers.has(&"sidestreet"),"Earned SideStreet unlock")
	var gate:=Gate.new()
	run.studio_departure_guard=gate.departure
	if run.get_property_list().any(func(p: Dictionary):return p.name==&"studio_action_guard"):run.set("studio_action_guard",gate.studio)
	var quote:=run.get_contract_search_quote(&"sidestreet",&"cash")
	var before_search:=StudioCheckpoint.new().capture(run)
	var cycle:=run.get_completed_run_cycles()
	check(not quote.is_empty(),"Legal repeat-work quote")
	check(run.search_contracts(quote),"Nondeparting Search can proceed while departure is unavailable")
	check(gate.departure_calls==0 and gate.studio_calls==1,"Search uses Studio mutation guard rather than departure")
	check(run.get_completed_run_cycles()==cycle+1,"Search preserves one productive cycle")
	var offer: Dictionary=run.get_next_sidestreet_offer()
	if not offer.is_empty():
		check(run.accept_sidestreet_offer(offer.offer_id)==null and gate.departure_calls==1,"Acceptance still requires durable departure")
	gate.allow_studio=false
	var blocked:=StudioCheckpoint.new().hydrate(before_search)
	blocked.studio_departure_guard=gate.departure
	if blocked.get_property_list().any(func(p: Dictionary):return p.name==&"studio_action_guard"):blocked.set("studio_action_guard",gate.studio)
	var other:=blocked.get_contract_search_quote(&"sidestreet",&"cash")
	check(not other.is_empty(),"Outside-Studio test starts from a legal quote")
	check(not blocked.search_contracts(other) and StudioCheckpoint.new().capture(blocked)==before_search,"Blocked Studio Search preserves finance/history/RNG")
	var legacy:=StudioCheckpoint.new().hydrate(before_search)
	legacy.studio_departure_guard=gate.departure
	check(not legacy.search_contracts(legacy.get_contract_search_quote(&"sidestreet",&"cash")),"Existing custom guards remain effective without the new Studio hook")
	print("CONTRACT_SEARCH_GUARD checks=%d failures=%d"%[checks,failures])
	quit(1 if failures else 0)
