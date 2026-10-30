extends SceneTree
func _initialize() -> void:
	var native := {"commission_deals":{},"release_metadata":{},"studio_finance":{"actions":[{"kind":&"publisher_receipt","source_id":&"studio:project:5:commission"}]}}
	var rejected := not RunState.Commission.valid_save(native)
	print("ORPHAN_RECEIPT_REJECTED=",rejected)
	quit(0 if rejected else 1)
