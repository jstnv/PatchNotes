## Bounded legal route finder. Detached public observations choose ordinary commands.
## Does not modify player saves, canonical rules, cash, IDs, RNG or checkpoints.
extends SceneTree
const Campaign := preload("res://scripts/simulation/campaign_session.gd")
const Fixture := preload("res://scripts/simulation/finite_fixture_policy.gd")
func _initialize() -> void: plan.call_deferred()
func plan() -> void:
	var codec := CheckpointCodec.new()
	var payload := codec.open_envelope(FileAccess.get_file_as_string(OS.get_environment("PN_SAVED_EVIDENCE")))
	if payload.is_empty(): push_error(codec.error); quit(1); return
	var all_results: Array = []
	for reserve: int in [40000]:
		var adapter := StudioCheckpoint.new()
		var restored := adapter.hydrate(payload)
		if restored == null: push_error(adapter.error); quit(1); return
		var session := Campaign.new()
		session.run = restored
		session.catalog = root.get_node("CardDatabase").get_development_catalog()
		session.snapshots = PrimitiveSnapshotDatabase.new()
		if not session.snapshots.load_ledgers(): quit(1); return
		var actions: Array = []
		var borrowed := false
		var observed_distress := false
		var debt_checkpoint: Dictionary = {}
		var recovered := false
		var stop := "command_bound"
		var fixture := Fixture.factory({"genre":"action","theme":"fantasy","name_prefix":"Distress","selection":"visible_order","hands":{"design":4,"alpha":4,"beta":4}})
		for step in range(80):
			var view: Dictionary = session.observation()
			var finance: Dictionary = view.studio_actions.finance
			if int(finance.get("total_overdue_cents",0)) > 0: observed_distress = true
			var next: Dictionary = {}
			if observed_distress:
				if view.phase == &"studio":
					if debt_checkpoint.is_empty(): debt_checkpoint = view.duplicate(true)
					if not recovered:
						recovered = true
						next = {"type":&"accept_contract","payload":{"kind":&"ironclad"}}
					else:
						var payoff_quotes: Array = view.studio_actions.bank_payoff_quotes
						if payoff_quotes.is_empty(): stop = "paid_off"; break
						next = {"type":&"bank_payoff","payload":{"quote":payoff_quotes[0]}}
				elif view.phase == &"contract":
					if view.contract.completed: next = {"type":&"dismiss_contract"}
					elif view.contract.candidates.is_empty(): next = {"type":&"contract","payload":{"request":session.contract.command(&"begin")}}
					else:
						var tokens: Array[int] = []
						for i in range(4): tokens.append(int(view.contract.candidates[i].token))
						next = {"type":&"contract","payload":{"request":session.contract.command(&"play",{"candidate_ids":tokens})}}
				else:
					var d: Dictionary = view.development
					if d.finalized: next = {"type":&"launch"} if d.phase == "beta" else {"type":&"development","payload":{"request":session.development.command(&"enter_next_phase")}}
					else:
						var kind: StringName = &"confirm_exit" if d.confirmation_pending else (&"begin" if not d.active else &"request_exit")
						next = {"type":&"development","payload":{"request":session.development.command(kind)}}
			elif view.phase == &"studio" and not view.releases.is_empty():
				var quote: Dictionary = session.quote_bank(50000,12)
				if not borrowed and quote.get("eligible",false):
					borrowed = true
					next = {"type":&"bank_borrow","payload":{"quote":quote}}
				elif borrowed:
					# Largest currently legal admission preserving the declared cash reserve.
					var chosen: Dictionary = {}
					for candidate: Dictionary in view.research_quotes:
						if candidate.can_admit and int(candidate.down_cents) <= int(view.cash_cents)-reserve and int(candidate.down_cents) > int(chosen.get("down_cents",0)):
							chosen = candidate
					if not chosen.is_empty(): next = {"type":&"admit_research","payload":{"quote":chosen}}
					if next.is_empty():
						for candidate: Dictionary in view.research_quotes:
							if candidate.can_research and int(candidate.due_cents) <= int(view.cash_cents)-reserve:
								next = {"type":&"research","payload":{"quote":candidate}}
								break
				if next.is_empty():
					for release: Dictionary in view.releases:
						if release.campaign.get("can_purchase",false):
							next = {"type":&"campaign","payload":{"release_id":release.id}}
							break
				if next.is_empty(): next = fixture.call(view)
			else: next = fixture.call(view)
			var request := session.command(next.type,next.get("payload",{}))
			var result := session.execute(request)
			actions.append({"request":request,"result":result,"after":session.observation()})
			if not result.ok: stop = "rejected_action"; break
		var final: Dictionary = session.observation()
		all_results.append({"reserve_cents":reserve,"stop":stop,"borrowed":borrowed,"actions":actions,"final":final,"distressed_studio":debt_checkpoint,"finance_snapshot":restored.get_studio_finance_snapshot()})
		print("Reserve %d: %s, %d commands, c%d, cash %d, overdue %d" % [reserve,stop,actions.size(),final.run_cycle,final.cash_cents,final.studio_actions.finance.get("total_overdue_cents",0)])
		session.run = null
		restored = null
	FileAccess.open(OS.get_environment("PN_PROBE_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(all_results,"  "))
	quit(0)
