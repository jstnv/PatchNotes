extends SceneTree

var failures := 0
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	print(("PASS: " if value else "FAIL: ") + message)
	if not value: failures += 1

func _initialize() -> void:
	if not ResourceLoader.exists("res://scripts/ui/studio_notice_queue.gd"):
		check(false, "Studio notice queue exists")
		quit(1)
		return
	var queue = load("res://scripts/ui/studio_notice_queue.gd").new()
	queue.enqueue({"id":"first", "kind":"tip", "title":"First"})
	queue.enqueue({"id":"second", "kind":"tip", "title":"Second"})
	check(queue.count() == 2, "Both unopened notices remain queued")
	check(queue.peek().id == "first", "Notices retain arrival order")
	check(queue.peek().id == "first" and queue.count() == 2, "Viewing the queue does not consume a notice")
	check(queue.take().id == "first" and queue.take().id == "second", "Dismissal advances exactly one notice")
	check(queue.take().is_empty(), "Empty queue produces no notice")
	queue.enqueue({"id":"third", "kind":"tip", "title":"Third"})
	queue.enqueue({"id":"fourth", "kind":"tip", "title":"Fourth"})
	check(queue.contains_id("fourth"), "Pending IDs can be checked without consuming them")
	check(queue.select(1).id == "fourth" and queue.peek().id == "fourth", "The unread list can select a later notice without losing the others")
	var state: Dictionary = queue.snapshot_state()
	var restored = load("res://scripts/ui/studio_notice_queue.gd").new()
	check(restored.load_state(state) and restored.take().id == "fourth" and restored.take().id == "third", "Unread order survives checkpoint restoration")
	var reopened = load("res://scripts/ui/studio_notice_queue.gd").new()
	check(reopened.load_state(restored.snapshot_state()) and reopened.was_dismissed("fourth"), "Acknowledgments survive checkpoint restoration")
	check(reopened.load_state({}) and reopened.count() == 0, "A legacy checkpoint starts with an empty queue")
	check(not reopened.load_state({"version":2,"pending":[],"dismissed":[]}), "Unknown queue versions are rejected")
	print("Studio notice queue: %d checks, %d failures" % [checks, failures])
	quit(failures)
