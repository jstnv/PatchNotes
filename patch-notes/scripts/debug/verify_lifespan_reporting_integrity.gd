extends "res://scripts/debug/verify_game_lifespan_trial.gd"

func _run() -> void:
	snapshots.load_ledgers()
	var run:=RunState.new()
	run.initialize_cash_cents(200000)
	var first:=_released_project(9.5,751)
	var second:=_released_project(3.0,301)
	first.set("_base_name","Twin")
	second.set("_base_name","Twin")
	check(run.register_release(first),"Synthetic first duplicate-name title registers")
	check(run.complete_productive_action(),"Synthetic first earning half")
	check(run.register_release(second),"Synthetic second duplicate-name title registers")
	var ids:=run.get_released_game_ids()
	check(ids.size()==2 and ids[0]!=ids[1],"Duplicate names have separate immutable IDs")
	var parent:=Control.new()
	parent.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(parent)
	parent.add_child(MenuTransitions.new())
	var view:=MonthlySalesReport.new()
	parent.add_child(view)
	root.size=Vector2i(1152,648)
	root.content_scale_size=root.size
	view.setup(run,ids[0])
	var before:=_snapshot(run,ids[0])
	check(view.get("_report").rows[0].earned_halves==1,"Partial first month has one observed half")
	check(view.get("_table").get_root().get_first_child().get_text(0).contains("partial"),"Partial month label is explicit")
	check(view.get("_forecast").text.begins_with("Forecast only"),"Forecast is separated from actual earnings")
	var selector:OptionButton=view.get("_titles")
	selector.select(1);selector.item_selected.emit(1)
	check(view.get("_report").release_id==ids[1] and view.get("_report").rows.is_empty(),"Selecting newer duplicate does not borrow older earnings")
	selector.select(0);selector.item_selected.emit(0)
	check(view.get("_report").release_id==ids[0],"Older duplicate remains separately selectable")
	for i in range(3):
		view.hide();view.show()
		await create_timer(0.3).timeout
	check(_snapshot(run,ids[0])==before,"Menu animation and rapid reopen do not delay or repeat a transaction")
	var transient:=Control.new()
	transient.name="SummaryPanel"
	parent.add_child(transient)
	transient.free()
	await process_frame
	check(_snapshot(run,ids[0])==before,"Freed menu before deferred binding preserves transactions")
	var meta:Dictionary=run.get("_release_metadata")
	var valid:Dictionary=meta[ids[0]].duplicate(true)
	meta[ids[0]].erase("release_cycle")
	view.refresh()
	check(view.get("_report").is_empty() and view.get("_totals").text.contains("unavailable") and view.get("_table").get_root()==null,"Missing provenance displays unavailable with no invented rows")
	meta[ids[0]]=valid.duplicate(true)
	meta[ids[0]].release_cycle=0.5
	check(run.get_released_game_monthly_report(ids[0]).is_empty(),"Fractional invalid release cycle cannot be coerced into fabricated history")
	meta[ids[0]]=valid.duplicate(true)
	meta[ids[0]].release_cycle=1
	check(run.get_released_game_monthly_report(ids[0]).is_empty(),"Wrong historical alignment is unavailable")
	meta[ids[0]]=valid.duplicate(true)
	view.refresh()
	await create_timer(0.3).timeout
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://design-logs/lifespan-verification-v2/report-integrity.png")
	check(view.get_global_rect().encloses(view.get("_forecast").get_global_rect()),"Report forecast fits supported1152x648")
	parent.queue_free()
	await process_frame
	print("Reporting integrity failures: ",failures)
	quit(failures)
