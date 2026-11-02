extends RefCounted

## Finance validation observes field names/types and action-array order, never
## Dictionary insertion order. Preserve container/leaf types while ordering keys.
static func same(a: Variant,b: Variant) -> bool:
	if typeof(a)!=typeof(b):return false
	if a is Dictionary:
		if a.is_typed() or b.is_typed() or a.size()!=b.size():return false
		# Finance fields are String keys. Other containers use the full validator.
		for key: Variant in b:
			if not key is String:return false
		for key: Variant in a:
			if not key is String or not b.has(key) or not same(a[key],b[key]):return false
		return true
	if a is Array:
		if a.is_typed() or b.is_typed() or a.size()!=b.size():return false
		for i in a.size():
			if not same(a[i],b[i]):return false
		return true
	if a is float:return var_to_bytes(a)==var_to_bytes(b)
	return a==b if typeof(a) in [TYPE_NIL,TYPE_BOOL,TYPE_INT,TYPE_STRING,TYPE_STRING_NAME] else false
