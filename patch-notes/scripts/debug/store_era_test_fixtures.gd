extends RefCounted

static func release(scope: int, required: int = 30) -> ProjectState:
	var snapshots := PrimitiveSnapshotDatabase.new(); snapshots.load_ledgers()
	var project := ProjectState.new(required)
	project.configure_predevelopment("Era fixture",&"action",&"fantasy",[])
	project.add_scope(scope)
	project.initialize_snapshots(&"fast_follower", &"stable_market")
	project.finalize_design_bugs(false,0,[&"text"],[])
	project.finalize_alpha(0,[],[]); project.finalize_beta()
	project.commit_review_result(ReviewResult.new(PrimitiveReviewCalculator.get_baseline_profile(),{},0.0,0.0,0.0,7.0,1.0,0,0.0,1.0,50,0.0,7.0,7.0))
	project.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(project))
	project.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(project,snapshots))
	project.set("_units_sold_result",UnitsSoldResult.new(&"primitive_units_sold_v1",&"month_1",500,70,70,100,200,300,10000,10000,10,1,10.0,10))
	project.commit_month_one_sales_revenue_result(PrimitiveMonthOneSalesRevenueCalculator.calculate(project))
	return project

