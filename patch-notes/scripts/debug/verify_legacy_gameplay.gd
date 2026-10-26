extends "res://scripts/debug/verify_rival_gameplay_activation.gd"
const Legacy := preload("res://scripts/legacy/legacy_world.gd")
const Ownership := preload("res://scripts/legacy/ownership_book.gd")
const Founder := preload("res://scripts/legacy/founder_profile.gd")

func _initialize() -> void:
	await process_frame
	create_timer(60).timeout.connect(func(): quit(2))
	node_added.connect(_replace_store)
	var gameplay: Control=load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(gameplay);await process_frame
	gameplay._on_studio_created("Legacy API",&"action",[],gameplay._active_phase)
	await process_frame
	var world: RivalWorld=gameplay.rival_world
	var books := {}
	for id in Legacy.runs(world): books[id]=Ownership.create(id,{"founder:test":1000000})
	expect(Legacy.initialize(world,Founder.create("test",str(world.player._bank_run_id),0),books),"Explicit formation initializes")
	var offer := {"studio_id":str(world.player._bank_run_id),"tx_id":"gameplay-issue","expected_revision":0,"buyer":"studio:incumbent-arcade-foundry","investment_cents":10000,"pre_money_cents":1000000}
	expect(Legacy.offer(world,"primary",offer) and Legacy.consent(world,offer.tx_id,offer.buyer) and Legacy.consent(world,offer.tx_id,"founder:test"),"Consented offer prepared")
	expect(gameplay.commit_ownership_offer(offer.tx_id),"Gameplay commit succeeds at Studio")
	await process_frame
	var info: Dictionary=gameplay.checkpoints.store.inspect()
	print("Save status: ",info.get("status")," reason=",info.get("reason")," coordinator=",gameplay.checkpoints.failure)
	expect(info.status==&"valid" and info.payload.rival_world.has("legacy"),"Coordinator atomically saves ownership with world")
	var old_id: StringName=gameplay.run_state._bank_run_id
	expect(gameplay.handoff_founder_operator(&"incumbent-wayfinder-works"),"Gameplay handoff succeeds at Studio")
	await process_frame
	expect(gameplay.run_state==gameplay.rival_world.player and gameplay.checkpoints.run==gameplay.run_state,"Manual run and checkpoint coordinator follow the new operator")
	expect(gameplay._active_phase is StudioPhase and gameplay.rival_world.studios.has(old_id),"New Studio view and autonomous former Studio bound")
	var saved: Dictionary=gameplay.checkpoints.store.inspect().payload
	expect(gameplay._begin_next_project(gameplay._active_phase,"Unsaved",&"adventure",&"fantasy"),"Normal unsaved project begins")
	await process_frame
	expect(not gameplay.handoff_founder_operator(old_id) and not gameplay.commit_ownership_offer(offer.tx_id),"Mid-phase ownership commands reject")
	gameplay._continue_checkpoint();await process_frame
	var after: Dictionary=gameplay.checkpoints.store.inspect().payload
	expect(after==saved and gameplay.project_state==null and gameplay.run_state._bank_run_id==&"incumbent-wayfinder-works","Continue rolls back unsaved cycle without repeating ownership or handoff")
	print("LEGACY_GAMEPLAY checks=%d failures=%d"%[checks,failures])
	gameplay.checkpoints.store.release_writer();quit(0 if failures==0 else 1)
