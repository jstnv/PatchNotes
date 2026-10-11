extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Bootstrap := preload("res://scripts/debug/campaign_replay_cli.gd")
var failures := 0
var checks := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", label)
	if not ok: failures += 1

func _initialize() -> void: _run.call_deferred()

func snapshot(run: RunState) -> Array:
	return [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_owned_feature_ids(), run._historical_titles.duplicate(true), run._opening_snapshot.duplicate(true), run.get_studio_finance_snapshot(), run.random_streams.snapshot()]

func _run() -> void:
	var recipe := {"schema_version":1,"studio_id":"archive-validation","studio_name":"Archive validation","specialty":"action","traits":[],"seed":"4417"}
	var fixture := {"owned_features":["music","dialogue","secrets"],"historical_titles":[{"id":"history-1979","title":"Historical title","genre":"action","theme":"fantasy","year":1979,"review_tenths":78}]}
	var negatives: Array = []
	for id in ["archive-validation:project:1", "archive-validation:project:2", "archive-validation:project:9223372036854775807", "other:project:1"]:
		var negative := fixture.duplicate(true)
		negative.historical_titles[0].id = id
		negatives.append(negative)
	var empty := fixture.duplicate(true)
	empty.historical_titles = []
	negatives.append(empty)
	var duplicate := fixture.duplicate(true)
	duplicate.historical_titles.append(duplicate.historical_titles[0].duplicate(true))
	negatives.append(duplicate)
	var missing_parent := fixture.duplicate(true)
	missing_parent.owned_features = ["branching_nodes"]
	negatives.append(missing_parent)
	for negative: Dictionary in negatives:
		var session := Bootstrap.create_fresh_session(recipe, root.get_node("CardDatabase"))
		check(session != null, "Fresh control")
		var before := snapshot(session.run)
		check(not Factory._apply_incumbent(session.run, negative) and snapshot(session.run) == before, "Invalid archive rejects atomically without ownership/cash/RNG mutation")
		var request := recipe.duplicate(true)
		request.incumbent = negative
		check(Bootstrap.create_fresh_session(request, root.get_node("CardDatabase")) == null, "Invalid initial recipe rejected before commands")
	var request := recipe.duplicate(true)
	request.incumbent = fixture
	var valid := Bootstrap.create_fresh_session(request, root.get_node("CardDatabase"))
	check(valid != null, "Valid historical archive boots")
	var adapter := StudioCheckpoint.new()
	var payload := adapter.capture(valid.run)
	check(not payload.is_empty() and adapter.validate(payload).is_empty(), "Valid opening checkpoint")
	var restored := adapter.hydrate(payload)
	check(restored != null and snapshot(restored) == snapshot(valid.run), "Opening checkpoint restores exact archive/state")
	for id in ["archive-validation:project:1", "archive-validation:project:100", "other:project:1"]:
		var corrupt := payload.duplicate(true)
		corrupt.run.historical_titles[0].id = StringName(id)
		check(not adapter.validate(corrupt).is_empty() and adapter.hydrate(corrupt) == null, "Restored archives reject future/live namespace: " + id)
	var corrupt := payload.duplicate(true)
	corrupt.run.historical_titles = []
	check(not adapter.validate(corrupt).is_empty(), "Empty inconsistent opening rejected at restore")
	check(adapter.capture(valid.run) == payload, "Rejected restores leave original valid state unchanged")
	print("Incumbent validation: %d checks, %d failures" % [checks, failures])
	quit(failures)
