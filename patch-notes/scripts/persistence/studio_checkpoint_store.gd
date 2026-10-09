class_name StudioCheckpointStore
extends RefCounted

## Generation storage only. The coordinator must validate the complete typed
## Studio DTO before save and before hydrating read results. No gameplay hooks.
var directory: String
var validator: Callable
var _writer: TCPServer
var _scan_error := ""
var fault := &"" # Injected by focused verification; never loaded from a save.

func _init(path: String = "user://saves/studio", validate_payload: Callable = Callable()) -> void:
	directory = ProjectSettings.globalize_path(path).simplify_path()
	validator = validate_payload

func acquire() -> bool:
	if _writer != null: return true
	# OS releases this local lease on process exit, including forced termination.
	# A collision refuses a writer; it cannot let two writers own one slot.
	var server := TCPServer.new()
	# One application writer, even when paths differ by case or junction alias.
	if server.listen(62741,"127.0.0.1") != OK: return false
	_writer = server
	return true

func release_writer() -> void:
	if _writer != null: _writer.stop()
	_writer = null

func _generations() -> Array[int]:
	_scan_error = ""
	var result: Array[int] = []
	var dir := DirAccess.open(directory)
	if dir == null: return result
	for name in dir.get_files():
		if not name.begins_with("checkpoint.") or not name.ends_with(".json"): continue
		var codec := CheckpointCodec.new()
		var sequence: Variant = codec.integer(name.trim_prefix("checkpoint.").trim_suffix(".json"))
		if codec.error.is_empty() and sequence > 0: result.append(sequence)
		else: _scan_error = "Malformed generation filename"
	result.sort()
	return result

func _path(sequence: int) -> String:
	return directory.path_join("checkpoint.%d.json" % sequence)

func _read_path(path: String, sequence: int) -> Dictionary:
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null: return {"status":&"io_error","path":path}
	if file.get_length() > CheckpointCodec.LIMIT: return {"status":&"invalid","reason":"SAVE_TOO_LARGE","path":path}
	var bytes := file.get_buffer(file.get_length())
	file.close()
	var source := bytes.get_string_from_utf8()
	if source.to_utf8_buffer() != bytes: return {"status":&"invalid","reason":"Invalid UTF-8","path":path}
	var codec := CheckpointCodec.new()
	var payload := codec.open_envelope(source)
	if not codec.error.is_empty():
		return {"status":&"incompatible" if codec.error == "INCOMPATIBLE_SCHEMA" else &"invalid","reason":codec.error,"path":path}
	if payload.get("sequence") != str(sequence): return {"status":&"invalid","reason":"Generation mismatch","path":path}
	if not validator.is_valid(): return {"status":&"invalid","reason":"No payload validator","path":path}
	var reason: String = validator.call(payload)
	if not reason.is_empty(): return {"status":&"incompatible" if reason.begins_with("INCOMPATIBLE") else &"invalid","reason":reason,"path":path}
	return {"status":&"valid","payload":payload,"sequence":sequence,"path":path}

func inspect() -> Dictionary:
	var generations := _generations()
	if not _scan_error.is_empty(): return {"status":&"invalid","reason":_scan_error}
	if generations.is_empty(): return {"status":&"empty"}
	var current := _read_path(_path(generations[-1]),generations[-1])
	if current.status in [&"valid",&"incompatible"]: return current
	# Never silently hydrate a backup. Preserve the failed current and return
	# a separate validated recovery candidate for explicit consent.
	for index in range(generations.size()-2,-1,-1):
		var prior := _read_path(_path(generations[index]),generations[index])
		if prior.status == &"valid":
			current["backup"] = prior
			break
	return current

func save(payload: Dictionary) -> Dictionary:
	return _publish(payload,false)

## Explicit recovery preserves the damaged current generation as evidence.
func recover_backup() -> Dictionary:
	var inspected := inspect()
	if inspected.status==&"incompatible" or not inspected.has("backup"): return {"status":&"invalid","reason":"No recoverable backup"}
	return _publish(inspected.backup.payload,true)

## Archive first, then publish at a fresh generation. A failed replacement
## leaves every prior generation at its original path as well as the archive.
func replace_run(payload: Dictionary) -> Dictionary:
	if not acquire(): return {"status":&"writer_busy"}
	var names := DirAccess.get_files_at(directory)
	if not names.is_empty():
		var archive := directory.path_join("archive-"+Crypto.new().generate_random_bytes(12).hex_encode())
		if DirAccess.make_dir_recursive_absolute(archive)!=OK: return {"status":&"io_error","reason":"Archive directory"}
		for name in names:
			var from := directory.path_join(name)
			var to := archive.path_join(name)
			if DirAccess.copy_absolute(from,to)!=OK or FileAccess.get_sha256(from)!=FileAccess.get_sha256(to): return {"status":&"io_error","reason":"Archive verification"}
	return _publish(payload,true)

func _publish(payload: Dictionary, explicit_recovery: bool) -> Dictionary:
	if not acquire(): return {"status":&"writer_busy"}
	if not validator.is_valid(): return {"status":&"invalid","reason":"No payload validator"}
	var current := inspect()
	if current.status not in [&"empty",&"valid"] and not explicit_recovery: return current
	var generations := _generations()
	if not _scan_error.is_empty(): return {"status":&"invalid","reason":_scan_error}
	var sequence: int = generations[-1] if not generations.is_empty() else 0
	if sequence == 9223372036854775807: return {"status":&"invalid","reason":"Generation overflow"}
	sequence += 1
	var candidate := payload.duplicate(true)
	candidate.sequence = str(sequence)
	var reason: String = validator.call(candidate)
	if not reason.is_empty(): return {"status":&"invalid","reason":reason}
	var codec := CheckpointCodec.new()
	var source := codec.envelope(candidate)
	if not codec.error.is_empty(): return {"status":&"invalid","reason":codec.error}
	if fault == &"before_write": return {"status":&"io_error","reason":"Injected before write"}
	if DirAccess.make_dir_recursive_absolute(directory) != OK: return {"status":&"io_error","reason":"Create save directory"}
	var temporary := directory.path_join("checkpoint.%d.%s.tmp" % [sequence,Crypto.new().generate_random_bytes(12).hex_encode()])
	if fault == &"permission_denied": return {"status":&"io_error","reason":"Injected permission denied opening temporary generation"}
	var file := FileAccess.open(temporary,FileAccess.WRITE)
	if file == null: return {"status":&"io_error","reason":"Open temporary generation"}
	if fault == &"during_write":
		file.store_string(source.substr(0,source.length()/2))
		file.flush()
		file.close()
		return {"status":&"io_error","reason":"Injected partial write"}
	file.store_buffer(source.to_utf8_buffer())
	file.flush()
	var write_error := file.get_error()
	file.close()
	if fault == &"disk_full": write_error = ERR_FILE_CANT_WRITE
	if write_error != OK: return {"status":&"io_error","reason":"Write/flush generation"}
	if fault == &"after_flush": return {"status":&"io_error","reason":"Injected after flush"}
	var checked := _read_path(temporary,sequence)
	if checked.status != &"valid": return checked
	if fault == &"before_rename": return {"status":&"io_error","reason":"Injected before rename"}
	var final_path := _path(sequence)
	if FileAccess.file_exists(final_path): return {"status":&"io_error","reason":"Generation collision"}
	if DirAccess.rename_absolute(temporary,final_path) != OK: return {"status":&"io_error","reason":"Publish generation"}
	# Publication already committed. Cleanup is best effort and never removes
	# the newest two validated generations or damaged/incompatible evidence.
	if fault not in [&"after_rename",&"during_cleanup"]: _prune_valid_history()
	return {"status":&"saved","sequence":sequence,"path":final_path}

func _prune_valid_history() -> void:
	var generations := _generations()
	if not _scan_error.is_empty(): return
	var retained := 0
	for index in range(generations.size()-1,-1,-1):
		var sequence := generations[index]
		if _read_path(_path(sequence),sequence).status!=&"valid": continue
		retained += 1
		if retained>2: DirAccess.remove_absolute(_path(sequence))
