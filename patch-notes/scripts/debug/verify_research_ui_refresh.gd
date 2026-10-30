extends SceneTree
var failures:=0
var checks:=0
class CountingHUD extends GameplayHUD:
	var refreshes:=0
	func refresh()->void:
		refreshes+=1
		super.refresh()
class CountingStudio extends StudioPhase:
	var summaries:=0
	func _refresh_summary()->void:
		summaries+=1
		super._refresh_summary()
class CountingStore extends FeatureStore:
	var refreshes:=0
	func _refresh()->void:
		refreshes+=1
		super._refresh()
func expect(ok: bool,label: String)->void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+label)
func _initialize()->void:
	await process_frame
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../tools/fixtures/background_checkpoint_v003_c96.json"))
	var run:=StudioCheckpoint.new().hydrate(fixture.player)
	var hud:=CountingHUD.new();root.add_child(hud);hud.setup(null,run)
	await process_frame
	hud.refreshes=0
	run.cash_changed.emit();run.features_changed.emit();run.finance_changed.emit();run.fans_changed.emit();run.calendar_changed.emit()
	expect(hud.refreshes==0,"One atomic signal burst queues HUD work outside the action callback")
	await process_frame;await process_frame
	expect(hud.refreshes==1,"One atomic burst produces exactly one final HUD refresh")
	expect(hud.footer.text.contains("Cycle: 96"),"Deferred HUD shows final calendar")
	var studio: StudioPhase=load("res://scenes/phases/studio_phase.tscn").instantiate()
	studio.set_script(CountingStudio)
	root.add_child(studio)
	var snapshots:=PrimitiveSnapshotDatabase.new();snapshots.load_ledgers()
	expect(studio.setup(null,run,snapshots),"Actual late Studio sets up")
	await process_frame;await process_frame
	studio._open_feature_store()
	await process_frame;await process_frame
	studio.summaries=0
	run.sales_changed.emit();run.calendar_changed.emit()
	await process_frame;await process_frame
	expect(studio.summaries==0,"Research does not rebuild hidden post-game summaries")
	studio._feature_store.hide()
	await process_frame;await process_frame
	expect(studio.get_node("Dashboard").visible,"Closing Store restores Dashboard")
	studio.open_summary()
	await process_frame;await process_frame
	studio.summaries=0
	run.sales_changed.emit();run.calendar_changed.emit()
	expect(studio.summaries==0,"Visible Summary signal burst is deferred")
	await process_frame;await process_frame
	expect(studio.summaries==1,"Visible Summary signal burst coalesces once")
	var store:=CountingStore.new();root.add_child(store);store.setup(run);store.open_store()
	store._select_node(&"secrets");store._purchase()
	await process_frame;await process_frame
	store.refreshes=0
	store._admission_dialog.get_ok_button().pressed.emit()
	expect(store.refreshes<=1,"Admission handler never duplicates a map refresh")
	await process_frame;await process_frame
	expect(store.refreshes==1,"Admission rebuilds the map exactly once")
	store.refreshes=0
	store._research_button.pressed.emit()
	expect(store.refreshes<=1,"Research handler never duplicates a map refresh")
	await process_frame;await process_frame
	expect(store.refreshes==1 and run.owns_feature(&"secrets"),"Research rebuilds the final owned map exactly once")
	var report: Dictionary={"ok":failures==0,"checks":checks,"failures":failures}
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(report));print(JSON.stringify(report))
	store.free();studio.free();hud.free();await process_frame;quit(1 if failures else 0)
