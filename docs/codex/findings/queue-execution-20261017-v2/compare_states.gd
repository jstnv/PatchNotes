extends SceneTree
var differences := []
func walk(a: Variant,b: Variant,path: String) -> void:
	if a==b:return
	if a is Dictionary and b is Dictionary:
		for key in a:
			if not b.has(key):differences.append(path+"/"+str(key)+" missing")
			else:walk(a[key],b[key],path+"/"+str(key))
		for key in b:
			if not a.has(key):differences.append(path+"/"+str(key)+" added")
	elif a is Array and b is Array:
		if a.size()!=b.size():differences.append(path+" length")
		for i in range(mini(a.size(),b.size())):walk(a[i],b[i],path+"/"+str(i))
	else: differences.append(path+": "+str(a).left(160)+" -> "+str(b).left(160))
func read(path: String) -> Variant:
	var parsed: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	return bytes_to_var(Marshalls.base64_to_raw(parsed.payload)) if parsed.has("payload") else parsed
func _initialize() -> void:
	var args:=OS.get_cmdline_user_args()
	walk(read(args[0]),read(args[1]),"")
	FileAccess.open(args[2],FileAccess.WRITE).store_string(JSON.stringify(differences,"\t"))
	print("Exact state differences: ",differences.size())
	for line in differences.slice(0,12):print(line)
	quit()
