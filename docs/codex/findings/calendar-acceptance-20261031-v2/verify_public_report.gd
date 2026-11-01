extends SceneTree
func _initialize() -> void:
 await process_frame
 var run:=RunState.new();assert(run.initialize_cash(0) and run.create_studio_with_traits("Public report",&"action",[]) and run.finalize_starter_selection())
 var p:=ProjectState.new(30);assert(p.set_engine_id(run.get_selected_engine_id(),run.get_selected_engine_capacity()))
 p.initialize_snapshots(&"fast_follower",&"stable_market");p.finalize_design_bugs(false,0,[&"text"],[]);p.finalize_alpha(0,[],[]);p.finalize_beta()
 p.commit_review_result(ReviewResult.new(PrimitiveReviewCalculator.get_baseline_profile(),{},0.0,0.0,0.0,7.0,1.0,0,0.0,1.0,50,0.0,7.0,7.0))
 p.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(p,run));var snapshots:=PrimitiveSnapshotDatabase.new();snapshots.load_ledgers()
 p.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(p,snapshots))
 p.set("_units_sold_result",UnitsSoldResult.new(&"primitive_units_sold_v1",&"month_1",500,70,70,100,200,300,10000,10000,751,1,751.0,751));p.commit_month_one_sales_revenue_result(PrimitiveMonthOneSalesRevenueCalculator.calculate(p));assert(run.register_release(p))
 var failures:=0
 for cycle in range(1,5):
  assert(run.complete_productive_action())
  var report:=run.get_released_game_monthly_report(p.get_release_id())
  var expected: int=report.net_cents-report.net_cents*3000/10000
  var paid: int=report.settled_cents-report.settled_cents*3000/10000
  if report.studio_net_cents!=expected or report.studio_settled_cents!=paid:failures+=1;push_error("Public report claims platform proceeds before its existing royalty at cycle"+str(cycle))
 print("PUBLIC_REPORT failures=",failures);quit(1 if failures else 0)
