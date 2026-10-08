class_name CheckpointCodec
extends RefCounted

## Data-only, schema-directed codec. Schemas are trusted program constants;
## disk data never supplies types, resource paths, objects or constructors.
const FORMAT := "patch-notes-studio-checkpoint"
const LIMIT := 16 * 1024 * 1024
const MAX_DEPTH := 96
var error := ""
var _text := ""
var _pos := 0
var _nodes := 0

func fail(message: String) -> Variant:
	if error.is_empty(): error = message
	return null

func integer(value: Variant, signed_value: bool = false) -> Variant:
	if not value is String or value.is_empty(): return fail("Expected canonical integer string")
	var negative: bool = value.begins_with("-")
	if negative and not signed_value: return fail("Negative integer forbidden")
	var digits: String = value.substr(1) if negative else value
	if digits.is_empty() or (digits.length() > 1 and digits.begins_with("0")) or (negative and digits == "0"): return fail("Noncanonical integer")
	var bound := "9223372036854775808" if negative else "9223372036854775807"
	if digits.length() > bound.length() or (digits.length() == bound.length() and digits > bound): return fail("Integer overflow")
	# Accumulate negatively so MIN_INT never needs an overflowing positive form.
	var result: int = 0
	for c in digits:
		if c < "0" or c > "9": return fail("Noncanonical integer")
		result = result * 10 - (c.unicode_at(0) - 48)
	return result if negative else -result

func encode(value: Variant, schema: Variant, depth: int = 0) -> Variant:
	if depth == 0: error = ""
	if depth > MAX_DEPTH: return fail("Schema nesting limit")
	if schema is String:
		match schema:
			"uint", "int":
				if typeof(value) != TYPE_INT or (schema == "uint" and value < 0): return fail("Invalid integral field")
				return str(value)
			"text":
				if typeof(value) != TYPE_STRING: return fail("Invalid text field")
				return value
			"id":
				if typeof(value) != TYPE_STRING_NAME: return fail("Invalid ID field")
				return String(value)
			"bool":
				if typeof(value) != TYPE_BOOL: return fail("Invalid flag")
				return value
			"float":
				if typeof(value) != TYPE_FLOAT or not is_finite(value): return fail("Nonfinite or nonfloat field")
				var bytes := PackedByteArray()
				bytes.resize(8)
				bytes.encode_double(0, value)
				bytes.reverse()
				return {"f64":bytes.hex_encode()}
		return fail("Unknown trusted schema")
	if not schema is Dictionary: return fail("Invalid trusted schema")
	if schema.has("nullable"):
		return null if value == null else encode(value, schema.nullable, depth+1)
	if schema.has("array"):
		if not value is Array: return fail("Expected array")
		var out: Array = []
		for item: Variant in value: out.append(encode(item,schema.array,depth+1))
		return out
	if not value is Dictionary: return fail("Expected record")
	if schema.has("map"):
		var entries: Array = []
		for key: Variant in value:
			entries.append({"key":encode(key,schema.map[0],depth+1),"value":encode(value[key],schema.map[1],depth+1)})
		return entries
	if value.size() != schema.size(): return fail("Record field count")
	var out := {}
	for key: String in schema:
		if not value.has(key): return fail("Missing field: " + key)
		out[key] = encode(value[key],schema[key],depth+1)
	return out

func decode(value: Variant, schema: Variant, depth: int = 0) -> Variant:
	if depth == 0: error = ""
	if depth > MAX_DEPTH: return fail("Schema nesting limit")
	if schema is String:
		match schema:
			"uint", "int": return integer(value,schema == "int")
			"text", "id":
				if not value is String: return fail("Expected string")
				return StringName(value) if schema == "id" else value
			"bool":
				if typeof(value) != TYPE_BOOL: return fail("Expected boolean")
				return value
			"float":
				if not value is Dictionary or value.size()!=1 or not value.get("f64") is String: return fail("Invalid float bits")
				var bits: String = value.f64
				if bits.length()!=16: return fail("Invalid float length")
				for c in bits:
					if not c in "0123456789abcdef": return fail("Invalid float hex")
				var bytes := bits.hex_decode()
				bytes.reverse()
				var number := bytes.decode_double(0)
				return number if is_finite(number) else fail("Nonfinite float")
		return fail("Unknown trusted schema")
	if not schema is Dictionary: return fail("Invalid trusted schema")
	if schema.has("nullable"): return null if value == null else decode(value,schema.nullable,depth+1)
	if schema.has("array"):
		if not value is Array: return fail("Expected array")
		var out: Array = []
		for item: Variant in value: out.append(decode(item,schema.array,depth+1))
		return out
	if schema.has("map"):
		if not value is Array: return fail("Expected map entries")
		var out := {}
		for entry: Variant in value:
			if not entry is Dictionary or entry.size()!=2 or not entry.has("key") or not entry.has("value"): return fail("Invalid map entry")
			var key: Variant = decode(entry.key,schema.map[0],depth+1)
			if not error.is_empty(): return null
			if out.has(key): return fail("Duplicate map key")
			out[key] = decode(entry.value,schema.map[1],depth+1)
		return out
	if not value is Dictionary or value.size()!=schema.size(): return fail("Record field count")
	var out := {}
	for key: String in schema:
		if not value.has(key): return fail("Missing field: " + key)
		out[key] = decode(value[key],schema[key],depth+1)
	return out

func envelope(payload: Dictionary) -> String:
	var body := JSON.stringify(payload)
	var result := JSON.stringify({"format":FORMAT,"schema_version":"1","payload_utf8":body,"payload_sha256":body.sha256_text()})
	if result.to_utf8_buffer().size() > LIMIT:
		fail("SAVE_TOO_LARGE")
		return ""
	return result

func open_envelope(source: String) -> Dictionary:
	var outer: Variant = parse(source)
	if not error.is_empty(): return {}
	if not outer is Dictionary or outer.size()!=4: fail("Invalid envelope"); return {}
	for key in ["format","schema_version","payload_utf8","payload_sha256"]:
		if not outer.get(key) is String: fail("Invalid envelope field"); return {}
	if outer.format != FORMAT or outer.schema_version != "1": fail("INCOMPATIBLE_SCHEMA"); return {}
	if outer.payload_utf8.sha256_text() != outer.payload_sha256: fail("CHECKSUM_MISMATCH"); return {}
	var payload: Variant = parse(outer.payload_utf8)
	if not payload is Dictionary: fail("Invalid payload object"); return {}
	return payload if error.is_empty() else {}

## Strict JSON subset: all numbers are forbidden (schema uses decimal strings).
## Duplicate decoded object keys reject before JSON can discard evidence.
func parse(source: String) -> Variant:
	error = ""
	if source.to_utf8_buffer().size() > LIMIT: return fail("SAVE_TOO_LARGE")
	_text = source
	_pos = 0
	_nodes = 0
	var result: Variant = _value(0)
	_space()
	if _pos != _text.length(): return fail("Trailing JSON data")
	return result

func _space() -> void:
	while _pos < _text.length() and _text[_pos] in " \t\r\n": _pos += 1

func _string() -> Variant:
	var start := _pos
	_pos += 1
	while _pos < _text.length():
		var c := _text[_pos]
		_pos += 1
		if c.unicode_at(0) < 32: return fail("Unescaped string control")
		if c == "\\":
			_pos += 1
		elif c == "\"":
			var parser := JSON.new()
			if parser.parse(_text.substr(start,_pos-start)) != OK or not parser.data is String: return fail("Invalid JSON string")
			return parser.data
	return fail("Unterminated JSON string")

func _value(depth: int) -> Variant:
	_nodes += 1
	if depth > MAX_DEPTH or _nodes > 500000: return fail("JSON complexity limit")
	_space()
	if _pos >= _text.length(): return fail("Truncated JSON")
	var c := _text[_pos]
	if c == "\"": return _string()
	for token in ["true","false","null"]:
		if _text.substr(_pos,token.length()) == token:
			_pos += token.length()
			return true if token == "true" else (false if token == "false" else null)
	if c not in ["{","["]: return fail("JSON numbers or invalid tokens forbidden")
	_pos += 1
	var object := c == "{"
	var closing := "}" if object else "]"
	var result: Variant = {} if object else []
	_space()
	if _pos < _text.length() and _text[_pos] == closing:
		_pos += 1
		return result
	while error.is_empty():
		var key: Variant = null
		if object:
			_space()
			if _pos >= _text.length() or _text[_pos] != "\"": return fail("Expected object key")
			key = _string()
			if not error.is_empty(): return null
			if result.has(key): return fail("Duplicate JSON key")
			_space()
			if _pos >= _text.length() or _text[_pos] != ":": return fail("Expected colon")
			_pos += 1
		var item: Variant = _value(depth+1)
		if not error.is_empty(): return null
		if object: result[key] = item
		else: result.append(item)
		_space()
		if _pos >= _text.length(): return fail("Truncated container")
		var separator := _text[_pos]
		_pos += 1
		if separator == closing: return result
		if separator != ",": return fail("Expected comma")
	return null
