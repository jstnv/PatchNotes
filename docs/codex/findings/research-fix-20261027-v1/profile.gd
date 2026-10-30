extends RefCounted
static var active := false
static var counts := {}
static var caller := 0
static func start() -> void:
	counts={};caller=OS.get_thread_caller_id();active=true
static func add(key: String, us: int) -> void:
	if not active or OS.get_thread_caller_id()!=caller: return
	if not counts.has(key): counts[key]={"count":0,"us":0,"max_us":0}
	counts[key].count+=1;counts[key].us+=us;counts[key].max_us=maxi(counts[key].max_us,us)
static func finish() -> Dictionary:
	active=false
	return counts.duplicate(true)
