## Explicit TEST policy adapter, not an activated rival purchasing policy.
## Only the choice whitelist/classification is extended; all effects, world
## calendar/market plans and persistence use production owners unchanged.
extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Finite := preload("res://scripts/simulation/finite_fixture_policy.gd")
const Codec := preload("res://scripts/market/rival_world_checkpoint.gd")
const Legacy := preload("res://scripts/legacy/legacy_world.gd")
const Ownership := preload("res://scripts/legacy/ownership_book.gd")
const Founder := preload("res://scripts/legacy/founder_profile.gd")
var checks: Array = []

class ExerciseWorld extends RivalWorld:
	func _choice(policy: Callable, session: RefCounted) -> Dictionary:
		var raw: Variant = policy.call(session.observation())
		if not raw is Dictionary or not raw.get("payload",{}) is Dictionary: return {}
		if StringName(raw.get("type",&""))==&"":return {}
		return {"type":StringName(raw.get("type",&"")),"payload":raw.get("payload",{}).duplicate(true)}
	func _productive_choice(choice: Dictionary, session: RefCounted) -> bool:
		if choice.type==&"contract": return choice.payload.request.type in [&"play",&"priorities"]
		return super._productive_choice(choice,session)

func check(ok: bool, label: String) -> void:
	checks.append({"pass":ok,"check":label});print("PASS: " if ok else "FAIL: ",label)
func _initialize() -> void: execute.call_deferred()
func finish(path: String) -> void:
	var failures := checks.filter(func(row: Dictionary) -> bool:return not row["pass"]).size()
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	quit(0 if failures==0 else 1)

## Pure fixture decisions: world peeks never advance a policy counter. Hand
## revision is public and no redraws/priorities are used by this fixture.
func actor_choice(view: Dictionary, scoring: RefCounted, commission_hands: int=10) -> Dictionary:
	if view.phase==&"studio":
		for offer: Dictionary in view.studio_actions.contract_offers:
			if offer.kind==&"ironclad":return {"type":&"accept_contract","payload":{"kind":&"ironclad"}}
		if view.publisher_relationships[&"sidestreet"].reputation_bp<2000:
			for offer: Dictionary in view.studio_actions.contract_offers:
				if offer.kind==&"sidestreet_brief":return {"type":&"accept_contract","payload":{"kind":offer.kind,"offer_id":offer.offer_id}}
		var payload := {"name":"World pilot "+str(view.releases.size()+1),"genre":"sports","theme":"fantasy"}
		if view.publisher_relationships[&"sidestreet"].reputation_bp>=2000:
			if view.commission_quote.is_empty():return {"type":&"quote_commission","payload":payload}
			payload.commission_quote=view.commission_quote.duplicate(true)
		return {"type":&"begin_development","payload":payload}
	if view.phase==&"contract":
		var state: Dictionary=view.contract
		if state.completed:return {"type":&"dismiss_contract"}
		if state.candidates.is_empty():return scoring.command(view,&"begin")
		var cards: Array=state.candidates.duplicate(true)
		var hand: Array=[]
		if state.offer_id==ContractState.CONTRACT_ID:
			cards.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
				if a.renewable!=b.renewable:return not a.renewable
				return int(a.token)<int(b.token))
			hand=cards.slice(0,4)
		else:
			var best := -9223372036854775807
			for a in range(4):
				for b in range(a+1,5):
					for c in range(b+1,6):
						for d in range(c+1,7):
							var candidate := [cards[a],cards[b],cards[c],cards[d]]
							var projected: Dictionary=scoring.project(state,candidate)
							var excess := 0
							var deficit := 0
							for score: int in projected.cores:excess+=maxi(0,score-6);deficit+=maxi(0,6-score)
							var rank: int=scoring.grade(projected.scope,projected.cores,10)*1000-excess
							if state.hand_count==0:
								rank=-deficit*1000-absi(projected.scope-5)*100-mini(excess,99)
								if projected.scope<3 or projected.scope>7:rank-=1000000
							if rank>best:best=rank;hand=candidate
		var tokens: Array[int]=[]
		for card: Dictionary in hand:tokens.append(int(card.token))
		return scoring.command(view,&"play",{"candidate_ids":tokens})
	var current: Dictionary=view.development
	if current.finalized:return {"type":&"launch"} if current.phase=="beta" else Finite._development(view,&"enter_next_phase")
	if current.confirmation_pending:return Finite._development(view,&"confirm_exit")
	if not current.active:return Finite._development(view,&"begin")
	var desired: int=({"design":3,"alpha":5,"beta":4} if view.releases.is_empty() else {"design":2,"alpha":2,"beta":2})[current.phase]
	if view.commission_deals.has(view.project_id):desired=commission_hands
	if current.hand_revision>=desired+1:return Finite._development(view,&"request_exit")
	var cards: Array=current.candidates.duplicate(true)
	cards.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if (a.type=="feature")!=(b.type=="feature"):return a.type=="feature"
		return int(a.token)<int(b.token))
	var tokens: Array[int]=[]
	for card: Dictionary in cards.slice(0,4):tokens.append(int(card.token))
	return Finite._development(view,&"play",{"candidate_ids":tokens})

func execute() -> void:
	var args := OS.get_cmdline_user_args()
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var player := Factory.create_fresh_session({"schema_version":1,"studio_id":"world-observer","studio_name":"World Observer","specialty":"action","traits":[],"seed":"99"},catalog)
	var actor := Factory.create_fresh_session({"schema_version":1,"studio_id":"commission-p1-sports-1112","studio_name":"Sports Actor","specialty":"sports","traits":[],"seed":"1112"},catalog)
	var player_policy := Finite.factory({"genre":"action","theme":"fantasy","name_prefix":"Observer release","selection":"features_first","hands":{"design":2,"alpha":2,"beta":2}})
	var prefix: RefCounted = load(args[0]).new()
	prefix.cfg={"arm":"balanced","label":"active-rival-fixture","development_first":{"genre":"sports","theme":"fantasy","name_prefix":"Commission Study","selection":"features_first","hands":{"design":3,"alpha":5,"beta":4}},"development_later":{"genre":"sports","theme":"fantasy","name_prefix":"Commission Study","selection":"features_first","hands":{"design":2,"alpha":2,"beta":2}}}
	prefix.first=Finite.factory(prefix.cfg.development_first);prefix.later=Finite.factory(prefix.cfg.development_later)
	var full: RefCounted = load(args[1]).new()
	full.cfg={"label":"active-rival-fixture","research":["maps","sprites","general_combat"],"commission":true,"development":{"genre":"sports","theme":"fantasy","name_prefix":"Scope Gate","selection":"features_first","hands":{"design":5,"alpha":7,"beta":6}}}
	full.play=Finite.factory(full.cfg.development)
	var world := ExerciseWorld.new()
	check(world.initialize(player.run,{actor.run._bank_run_id:actor}),"fresh independent Studios initialize at cycle0")
	world.historical_archive[actor.run._bank_run_id]=[{"id":&"explicit-fixture-1979","title":"Fixture archive","year":1979,"genre":&"sports","theme":&"fantasy","review_tenths":70}]
	var policy := func(view: Dictionary) -> Dictionary:
		return actor_choice(view,prefix)
	for tick in range(80):
		if actor.run.has_pending_commission(): break
		var before: int = player.run.get_completed_run_cycles()
		for zero_step in range(12):
			var chosen: Dictionary = player_policy.call(player.observation())
			var outcome: Dictionary = player.execute(player.command(StringName(chosen.type),chosen.get("payload",{})))
			if not outcome.ok: check(false,"fixture player action rejected: "+str(outcome));break
			if player.run.get_completed_run_cycles()==before+1: break
		if player.run.get_completed_run_cycles()!=before+1:check(false,"fixture player productive boundary unavailable");break
		var advanced := world.advance_committed_player_cycle({actor.run._bank_run_id:policy},12)
		if not advanced.ok: check(false,"world bounded policy rejected: "+str(advanced));break
	check(actor.run.has_pending_commission() and actor.development!=null,"legal actor commands reach active commissioned development within80 cycles")
	if not actor.run.has_pending_commission(): finish(args[2]);return
	# Continue the same observed player policy to its real Studio boundary. The
	# fixture rival uses ten hands per commissioned phase, declared above, so
	# its project remains active while the player finishes the current title.
	for command_index in range(50):
		if player.in_studio:break
		var cycle_before: int=player.run.get_completed_run_cycles()
		var chosen: Dictionary=player_policy.call(player.observation())
		var outcome: Dictionary=player.execute(player.command(StringName(chosen.type),chosen.get("payload",{})))
		if not outcome.ok:check(false,"finishing player boundary rejects: "+str(outcome));break
		if player.run.get_completed_run_cycles()!=cycle_before:
			var advance:=world.advance_committed_player_cycle({actor.run._bank_run_id:policy},12)
			if not advance.ok:check(false,"finishing world boundary rejects: "+str(advance));break
	check(player.in_studio and actor.run.has_pending_commission(),"player reaches actual Studio while rival commission remains active")
	if not player.in_studio or not actor.run.has_pending_commission():finish(args[2]);return
	check(player.run._commission_deals.is_empty() and player.run._publisher_relationships.events.is_empty(),"another Studio receives no pending deal or standing")
	var books := {}
	for id in Legacy.runs(world): books[id]=Ownership.create(id,{"founder:pilot-fixture":1000000})
	check(Legacy.initialize(world,Founder.create("pilot-fixture","world-observer",0),books),"explicit populated Founder ownership fixture initializes")
	var issue := {"studio_id":"world-observer","tx_id":"pilot-ownership-1","expected_revision":0,"buyer":"studio:"+str(actor.run._bank_run_id),"investment_cents":1000,"pre_money_cents":1000000}
	check(Legacy.offer(world,"primary",issue) and Legacy.consent(world,issue.tx_id,"founder:pilot-fixture") and Legacy.consent(world,issue.tx_id,issue.buyer) and Legacy.commit(world,issue.tx_id,true),"real ownership cash/share transaction preserves active commission")
	var adapter := StudioCheckpoint.new()
	var saved_player := adapter.capture(player.run)
	var codec := Codec.new()
	var saved := codec.capture(world)
	check(not saved.is_empty() and codec.validate(saved,saved_player).is_empty(),"populated world with active commission validates: "+codec.error)
	if saved.is_empty(): finish(args[2]);return
	var restored := codec.restore(saved,saved_player,adapter.hydrate(saved_player),catalog)
	check(restored!=null and codec.capture(restored)==saved,"active commission, Founder ownership, market, RNG and finance restore exactly")
	var row: Dictionary = saved.studios[0]
	var id: StringName = actor.development.project.get_release_id()
	var decoded: Dictionary = CheckpointCodec.new().decode(row.run,CheckpointSchema.root(true,true))
	for both in [false,true]:
		var corrupt := saved.duplicate(true)
		var native := decoded.duplicate(true)
		native.run.commission_deals[id].terms.required_scope=1
		corrupt.studios[0].run=CheckpointCodec.new().encode(native,CheckpointSchema.root(true,true))
		if both: corrupt.studios[0].development.project._required_scope="1"
		check(not codec.validate(corrupt,saved_player).is_empty() and codec.restore(corrupt,saved_player,adapter.hydrate(saved_player),catalog)==null,"world rejects altered active Scope, jointly changed project="+str(both))
	check(codec.capture(world)==saved and player.run._commission_deals.is_empty(),"failed restores preserve original world and Studio isolation")
	FileAccess.open(args[2]+".fixture.json",FileAccess.WRITE).store_string(JSON.stringify({"player":saved_player,"world":saved},"\t"))
	var before_handoff:=codec.capture(world)
	check(not Legacy.handoff(world,actor.run._bank_run_id,true) and codec.capture(world)==before_handoff,"operator cannot enter active commissioned development or bypass Studio boundary")
	# Separate bounded ownership fixture: finish this already accepted project
	# with two observed hands per phase, at most20 shared cycles. No grants or
	# claim of full delivery; only the resulting actual fee/rights are inspected.
	var completion_policy:=func(view: Dictionary) -> Dictionary:
		return {} if view.phase==&"studio" else actor_choice(view,prefix,2)
	for tick in range(20):
		if actor.in_studio:break
		var before_cycle: int=player.run.get_completed_run_cycles()
		if not player.run.complete_productive_action(Callable(),0,before_cycle):check(false,"Studio observer idle cycle rejects");break
		var advanced:=world.advance_committed_player_cycle({actor.run._bank_run_id:completion_policy},12)
		if not advanced.ok:check(false,"world commission completion rejects: "+str(advanced));break
	check(actor.in_studio and not actor.run.has_pending_commission(),"legal shared-world actions finish rival commission within20 cycles")
	if actor.in_studio:
		check(actor.execute(actor.command(&"acknowledge_publishers")).ok,"completed rival acknowledges ordinary publisher notices")
		var original_player:=adapter.capture(player.run)
		var commissioned_studio:=adapter.capture(actor.run)
		var old_player_id: StringName=player.run._bank_run_id
		var actor_id: StringName=actor.run._bank_run_id
		check(Legacy.handoff(world,actor_id,true),"populated Founder hands control to completed commissioned Studio")
		check(adapter.capture(world.player)==commissioned_studio and adapter.capture(world.studios[old_player_id].run)==original_player,"operator handoff transfers no standing, fee, rights, sales, finance or RNG between Studios")
		check(Legacy.handoff(world,old_player_id,true),"same Founder returns to original Studio at safe boundary")
		check(adapter.capture(world.player)==original_player and adapter.capture(world.studios[actor_id].run)==commissioned_studio,"return handoff preserves exact Studio-owned ledgers")
		var operator_player:=adapter.capture(world.player)
		var operator_world:=codec.capture(world)
		var operator_restored:=codec.restore(operator_world,operator_player,adapter.hydrate(operator_player),catalog)
		check(operator_restored!=null and codec.capture(operator_restored)==operator_world,"completed commission and operator periods cold DTO restore exactly")
		FileAccess.open(args[2]+".operator-fixture.json",FileAccess.WRITE).store_string(JSON.stringify({"player":operator_player,"world":operator_world},"\t"))
	finish(args[2])
