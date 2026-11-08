## Studio Genre specialty affects only matching launch Awareness.
extends SceneTree

const GENRES: Array[StringName]=[&"action",&"adventure",&"role_playing",&"strategy",&"simulation",&"puzzle",&"sports",&"racing"]
const BONUS:=20
var checks:=0
var failures:=0

func check(ok: bool, text: String) -> void:
	checks+=1
	print("PASS: " if ok else "FAIL: ",text)
	if not ok:failures+=1

func _initialize() -> void: verify.call_deferred()

func fresh(genre: StringName, traits: Array=[]) -> RunState:
	var run:=RunState.new()
	if not run.initialize_cash(0) or not run.create_studio_with_traits("Genre awareness",genre,traits):return null
	return run

func ready_project(run: RunState,genre: StringName,title: String, marketing: int=0) -> ProjectState:
	var p:=PrimitivePredevelopment.prepare_project(title,genre,&"fantasy",run)
	if p==null:return null
	if not p.set_engine_id(run.get_selected_engine_id(),run.get_selected_engine_capacity()):return null
	p.add_core_scores_and_scope({0:20,1:20,2:20,3:20},30)
	p.add_marketing_output(marketing)
	p.initialize_snapshots(&"fast_follower",&"stable_market")
	p.finalize_design_bugs(false,0,[&"text"],[])
	p.finalize_alpha(0,[],[])
	p.finalize_beta()
	p.commit_review_result(PrimitiveReviewCalculator.calculate(p,50))
	return p

func finish(run: RunState,p: ProjectState) -> bool:
	var awareness:=PrimitiveAwarenessCalculator.calculate(p,run)
	if awareness==null or not p.commit_awareness_result(awareness):return false
	var db:=PrimitiveSnapshotDatabase.new();db.load_ledgers()
	return p.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(p,db)) and p.commit_units_sold_result(PrimitiveUnitsSoldCalculator.calculate(p)) and p.commit_month_one_sales_revenue_result(PrimitiveMonthOneSalesRevenueCalculator.calculate(p))

func verify() -> void:
	for index in GENRES.size():
		var genre:=GENRES[index];var other:=GENRES[(index+1)%GENRES.size()]
		var genre_run:=fresh(genre)
		var matching:=ready_project(genre_run,genre,"Match")
		var nonmatching:=ready_project(genre_run,other,"Other")
		var a:=PrimitiveAwarenessCalculator.calculate(matching,genre_run)
		var b:=PrimitiveAwarenessCalculator.calculate(nonmatching,genre_run)
		check(a!=null and a.get_organic_awareness()==100+BONUS and a.get_total_awareness()==100+BONUS,"Matching %s receives only the intended base bonus"%genre)
		check(b!=null and b.get_organic_awareness()==100 and b.get_total_awareness()==100,"Nonmatching %s receives no specialty bonus"%other)
		var anonymous:=PrimitiveAwarenessCalculator.calculate(matching)
		check(anonymous!=null and anonymous.get_organic_awareness()==100 and anonymous.get_total_awareness()==100,"Null owner never grants specialty bonus for %s"%genre)
	var bare:=RunState.new();bare.initialize_cash(0)
	var anonymous_run:=PrimitiveAwarenessCalculator.calculate(ready_project(fresh(&"action"),&"action","Anonymous"),bare)
	check(anonymous_run!=null and anonymous_run.get_total_awareness()==100,"Uninitialized Studio specialty does not grant bonus")
	var trait_run:=fresh(&"action",[&"studio_buzz",&"unknown_name"])
	var trait_result:=PrimitiveAwarenessCalculator.calculate(ready_project(trait_run,&"action","Traits",25),trait_run)
	check(trait_result!=null and trait_result.get_organic_awareness()==120 and trait_result.get_total_awareness()==138,"Base bonus stacks with Marketing, Buzz and Unknown in existing order")
	var stack_run:=fresh(&"action",[&"studio_buzz",&"unknown_name",&"cult_following"])
	stack_run._promotion_awards[&"isolated_promotion_fixture"]=8
	var stacked:=PrimitiveAwarenessCalculator.calculate(ready_project(stack_run,&"action","Stacked",25),stack_run)
	check(stacked!=null and stacked.get_existing_fans()==20 and stacked.get_fan_awareness()==5 and stacked.get_promotion_awards()=={&"isolated_promotion_fixture":8} and stacked.get_total_awareness()==151,"Bonus stacks once with Fans, Promotion, Marketing and both active launch Traits")
	var overflow_run:=fresh(&"action");var overflow:=ready_project(overflow_run,&"action","Overflow")
	overflow.set("_marketing_output",ProjectState.MAX_SIGNED_INT-100)
	check(PrimitiveAwarenessCalculator.calculate(overflow,overflow_run)==null and not overflow.has_awareness_result(),"Matching bonus overflow rejects without committing")
	var unmatched_overflow:=ready_project(overflow_run,&"puzzle","Exact limit")
	unmatched_overflow.set("_marketing_output",ProjectState.MAX_SIGNED_INT-100)
	check(PrimitiveAwarenessCalculator.calculate(unmatched_overflow,overflow_run)!=null,"Nonmatching project retains previous exact overflow limit")
	var run:=fresh(&"action");var first:=ready_project(run,&"action","First",25)
	check(finish(run,first),"Create complete matching release results")
	var frozen:=first.get_awareness_result().get_total_awareness()
	check(frozen==145 and run.register_release(first),"Register matching release with bonus once")
	var id:=first.get_release_id();var before:=run.get_release_metadata(id).duplicate(true);var sales:=run.get_released_game_sales(id).duplicate(true)
	check(not run.register_release(ProjectState.new(30)) and run.register_release(first),"Failed and duplicate release preserve registered result")
	check(run.get_release_metadata(id)==before and run.get_released_game_sales(id)==sales and first.get_awareness_result().get_total_awareness()==frozen,"Existing frozen release metadata and sales are unchanged")
	print("GENRE_AWARENESS checks=%d failures=%d"%[checks,failures])
	quit(1 if failures else 0)
