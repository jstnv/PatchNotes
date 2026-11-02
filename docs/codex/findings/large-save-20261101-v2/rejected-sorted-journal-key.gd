extends RefCounted

## Finance validation observes field names/types and action-array order, never
## Dictionary insertion order. Preserve container/leaf types while ordering keys.
static func encode(value: Dictionary) -> PackedByteArray:
	return var_to_bytes(_ordered(value))

static func _before(a: Variant,b: Variant) -> bool:
	if typeof(a)!=typeof(b):return typeof(a)<typeof(b)
	if typeof(a) in [TYPE_INT,TYPE_STRING,TYPE_STRING_NAME]:return a<b
	return var_to_bytes(a).hex_encode()<var_to_bytes(b).hex_encode()

static func _ordered(value: Variant) -> Variant:
	if value is Dictionary:
		var result: Dictionary=value.duplicate();result.clear()
		var keys: Array=value.keys();keys.sort_custom(_before)
		for key: Variant in keys:result[key]=_ordered(value[key])
		return result
	if value is Array:
		var result: Array=value.duplicate()
		for i in result.size():result[i]=_ordered(value[i])
		return result
	return value
