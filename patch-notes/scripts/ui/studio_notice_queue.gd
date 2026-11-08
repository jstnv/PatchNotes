extends RefCounted
## Ordered, presentation-only Studio notifications.

var _pending: Array[Dictionary] = []
var _dismissed: Array[String] = []

func enqueue(notice: Dictionary) -> void:
	_pending.append({"id":str(notice.get("id","")),"kind":str(notice.get("kind","")),"topic":str(notice.get("topic","")),"title":str(notice.get("title","")),"body":str(notice.get("body",""))})

func count() -> int:
	return _pending.size()

func peek() -> Dictionary:
	return {} if _pending.is_empty() else _pending[0].duplicate(true)

func take() -> Dictionary:
	if _pending.is_empty(): return {}
	var notice: Dictionary = _pending.pop_front()
	var id := str(notice.get("id", ""))
	if not id.is_empty() and id not in _dismissed: _dismissed.append(id)
	return notice

func was_dismissed(id: String) -> bool:
	return id in _dismissed

func contains_id(id: String) -> bool:
	for notice: Dictionary in _pending:
		if str(notice.get("id", "")) == id: return true
	return false

func select(index: int) -> Dictionary:
	if index < 0 or index >= _pending.size(): return {}
	var notice: Dictionary = _pending.pop_at(index)
	_pending.push_front(notice)
	return notice.duplicate(true)

func entries() -> Array[Dictionary]:
	return _pending.duplicate(true)

func snapshot_state() -> Dictionary:
	return {"version":1,"pending":_pending.duplicate(true),"dismissed":_dismissed.duplicate()}

func load_state(state: Dictionary) -> bool:
	_pending.clear()
	_dismissed.clear()
	if state.is_empty(): return true
	if not preload("res://scripts/tutorial/studio_notice_state.gd").valid(state): return false
	for notice: Dictionary in state.pending: _pending.append(notice.duplicate(true))
	for id: String in state.dismissed: _dismissed.append(id)
	return true
