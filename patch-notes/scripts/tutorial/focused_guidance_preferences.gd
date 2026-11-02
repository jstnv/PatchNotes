extends RefCounted
const Catalog=preload("res://scripts/tutorial/focused_guidance_catalog.gd")
var path: String
var error:=""
var _loaded:=false
var _studios: Dictionary={}
func _init(value: String="user://focused-guidance-v1.cfg") -> void:path=value
func _load() -> void:
 if _loaded:return
 _loaded=true
 if not FileAccess.file_exists(path):return
 var file:=ConfigFile.new()
 if file.load(path)!=OK or file.get_value("format","version",0)!=1:error="Unreadable focused guidance preferences";return
 for id: String in file.get_section_keys("studios") if file.has_section("studios") else PackedStringArray():
  var value: Variant=file.get_value("studios",id)
  if not value is Array:continue
  var valid: Array[StringName]=[]
  for topic: Variant in value:
   if (topic is String or topic is StringName) and StringName(topic) in Catalog.IDS and StringName(topic) not in valid:valid.append(StringName(topic))
  _studios[id]=valid
func seen(studio: String,topic: StringName) -> bool:
 _load();return topic in _studios.get(studio,[])
func mark(studio: String,topic: StringName) -> bool:
 if studio.is_empty() or topic not in Catalog.IDS:return false
 _load()
 if seen(studio,topic):return true
 if not _studios.has(studio):_studios[studio]=[]
 _studios[studio].append(topic)
 var file:=ConfigFile.new();file.set_value("format","version",1)
 for id: String in _studios:file.set_value("studios",id,_studios[id])
 var result:=file.save(path+".tmp")
 if result==OK:result=DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))
 error="" if result==OK else "Could not remember focused guidance; the current session can continue."
 return result==OK
