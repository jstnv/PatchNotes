extends SceneTree
func _initialize() -> void:
	var payload: Dictionary={"marker":"ok"}
	payload.sequence="1"
	var codec:=CheckpointCodec.new()
	var read:=codec.open_envelope(codec.envelope(payload))
	for item: Dictionary in [payload,read]:
		for key: Variant in item:
			print(str(key)," key=",type_string(typeof(key))," value=",type_string(typeof(item[key]))," typed=",item.is_typed())
	print("same=",StudioCheckpointStore._same_typed_payload(payload,read)," wire_nodes=",StudioCheckpointStore._wire_nodes(payload))
	quit()
