## Bounded, exact-value reuse of pure productive-cycle preflights. Nothing in
## this cache commits a command, owns a Run, retains callbacks or consumes RNG.
extends RefCounted

const ENTRY_LIMIT := 128
const BYTE_LIMIT := 32 * 1024 * 1024
static var _keys: Array[PackedByteArray]=[]
static var _values: Array[Dictionary]=[]
static var _sizes: Array[int]=[]
static var _bytes:=0
static var _lock:=Mutex.new()

static func read(key: PackedByteArray) -> Dictionary:
	if key.size()>BYTE_LIMIT:return {}
	_lock.lock()
	var index:=_keys.find(key)
	var result: Dictionary={} if index<0 else _values[index].duplicate(true)
	_lock.unlock()
	return result

## A private feasibility check consumes only these two scalar amounts. Never
## return a reference to the retained plan or its mutable nested dictionaries.
static func read_preflight_summary(key: PackedByteArray, expected_records: Dictionary = {}, expected_rights: Dictionary = {}, expected_assessments: Dictionary = {}) -> Dictionary:
	if key.size()>BYTE_LIMIT:return {}
	_lock.lock()
	# A partial internal entry must not be returned to the ordinary cache reader
	# after the shortcut rejects it. Drop the cache if its parallel arrays drift.
	if _keys.size()!=_values.size() or _keys.size()!=_sizes.size() or _bytes<0:
		_keys.clear();_values.clear();_sizes.clear();_bytes=0
		_lock.unlock()
		return {}
	var index:=_keys.find(key)
	var result: Dictionary={}
	if index>=0:
		var value: Dictionary=_values[index]
		var valid: bool = value.size()==6 and value.get("payable") is int and value.get("earned") is int and value.get("records") is Dictionary and value.get("fans") is Dictionary and value.get("support_rights") is Dictionary and value.get("support_assessments") is Dictionary
		if valid:
			valid=value.payable>=0 and value.earned>=0 and not value.fans.is_empty() and value.records.size()==expected_records.size() and value.support_rights==expected_rights and value.support_assessments==expected_assessments
		if valid:
			for id in expected_records:
				if not value.records.has(id) or not value.records[id] is Dictionary:
					valid=false
					break
		if valid:
			result={"payable":value.payable,"earned":value.earned}
		else:
			# The next full planner must recompute instead of consuming corruption.
			if _sizes[index]<0 or _sizes[index]>_bytes:
				_keys.clear();_values.clear();_sizes.clear();_bytes=0
			else:
				_bytes-=_sizes[index];_keys.remove_at(index);_values.remove_at(index);_sizes.remove_at(index)
	_lock.unlock()
	return result

static func remember(key: PackedByteArray,value: Dictionary) -> void:
	if value.is_empty() or key.size()>BYTE_LIMIT:return
	var size:=key.size()+var_to_bytes(value).size()
	if size>BYTE_LIMIT:return
	# The cache owns detached data; every reader also receives a detached copy.
	var stored:=value.duplicate(true)
	_lock.lock()
	if not _keys.has(key):
		_keys.append(key);_values.append(stored);_sizes.append(size);_bytes+=size
	while _keys.size()>ENTRY_LIMIT or _bytes>BYTE_LIMIT:
		_keys.pop_front();_values.pop_front();_bytes-=_sizes.pop_front()
	_lock.unlock()
