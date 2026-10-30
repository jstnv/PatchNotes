## Synchronous code-owned authority fence. Services/transaction scratch fields
## are not saved state. Never retain this projection across a successful action.
extends RefCounted

const Replay := preload("res://scripts/simulation/development_replay.gd")
const SCRATCH := ["_productive_cycle_in_progress","_committing_cycle_cash","_publishing_cycle","_cycle_plan","_pending_relationship_plan","_preparing_project"]
const DATA_PROOF_LIMIT:=128
const DATA_PROOF_BYTES:=8*1024*1024
static var _data_proofs: Array[PackedByteArray]=[]
static var _data_proof_bytes:=0
static var _data_lock:=Mutex.new()

static func authority(value: Object) -> Dictionary:
	var result := {}
	for property in value.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.name not in SCRATCH:
			result[property.name] = Replay.freeze(value.get(property.name))
	return result


## A transient comparison fence, never a save/replay format. Large data-only
## histories use exact typed bytes rather than allocating a Dictionary for
## every integer. Containers with live objects retain the full old projection;
## serializing object IDs alone would miss changes to their internal state.
static func fingerprint(value: Object) -> Dictionary:
	var result: Dictionary={}
	for property in value.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.name not in SCRATCH:
			var item: Variant=value.get(property.name)
			var bytes:=var_to_bytes(item)
			result[property.name]={"data":bytes} if _known_data(item,bytes) else {"projection":Replay.freeze(item)}
	return result


static func _known_data(value: Variant,key: PackedByteArray) -> bool:
	var type:=typeof(value)
	if type not in [TYPE_ARRAY,TYPE_DICTIONARY]:return type not in [TYPE_OBJECT,TYPE_CALLABLE,TYPE_SIGNAL,TYPE_RID]
	# The typed encoding includes every nested Variant tag. A previously proven
	# data-only encoding cannot become a live Object with identical bytes.
	_data_lock.lock()
	var known:=_data_proofs.has(key)
	_data_lock.unlock()
	if known:return true
	if not _data_only(value):return false
	if key.size()>DATA_PROOF_BYTES:return true
	_data_lock.lock()
	if not _data_proofs.has(key):
		_data_proofs.append(key);_data_proof_bytes+=key.size()
	while _data_proofs.size()>DATA_PROOF_LIMIT or _data_proof_bytes>DATA_PROOF_BYTES:
		_data_proof_bytes-=_data_proofs.pop_front().size()
	_data_lock.unlock()
	return true


static func _data_only(value: Variant) -> bool:
	var type:=typeof(value)
	if type in [TYPE_OBJECT,TYPE_CALLABLE,TYPE_SIGNAL,TYPE_RID]:return false
	if type==TYPE_ARRAY:
		for item: Variant in value:
			var child:=typeof(item)
			if child in [TYPE_OBJECT,TYPE_CALLABLE,TYPE_SIGNAL,TYPE_RID]:return false
			if child in [TYPE_ARRAY,TYPE_DICTIONARY] and not _data_only(item):return false
	elif type==TYPE_DICTIONARY:
		for key: Variant in value:
			if not _data_only(key):return false
			var item: Variant=value[key]
			var child:=typeof(item)
			if child in [TYPE_OBJECT,TYPE_CALLABLE,TYPE_SIGNAL,TYPE_RID]:return false
			if child in [TYPE_ARRAY,TYPE_DICTIONARY] and not _data_only(item):return false
	return true

static func copy_fields(source: Object, destination: Object) -> void:
	for property in source.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var value: Variant = source.get(property.name)
			destination.set(property.name,value.duplicate(true) if value is Array or value is Dictionary else value)
