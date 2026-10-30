## Bounded, exact-value reuse of pure productive-cycle preflights. Nothing in
## this cache commits a command, owns a Run, retains callbacks or consumes RNG.
extends RefCounted

const ENTRY_LIMIT := 36
const BYTE_LIMIT := 16 * 1024 * 1024
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
