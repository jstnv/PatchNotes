extends RefCounted
static func valid(value: Variant) -> bool:
 if not value is Dictionary or value.size() != 3 or value.get("version") != 1: return false
 if not value.get("pending") is Array or not value.get("dismissed") is Array: return false
 var seen := {}
 for notice: Variant in value.pending:
  if not notice is Dictionary or notice.size() != 5: return false
  for key: String in ["id","kind","topic","title","body"]:
   if not notice.get(key) is String or notice[key].length() > 4096: return false
  if notice.kind not in ["tip","guide","publisher","progress"]: return false
  if notice.id.is_empty() and notice.kind != "progress": return false
  if not notice.id.is_empty():
   if seen.has(notice.id): return false
   seen[notice.id] = true
 for id: Variant in value.dismissed:
  if not id is String or id.is_empty() or id.length() > 4096 or seen.has(id): return false
  seen[id] = true
 return true
