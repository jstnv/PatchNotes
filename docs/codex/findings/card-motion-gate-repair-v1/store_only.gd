extends "./wrappers/verify_card_motion.gd"

func _verify()->void:
	for dimensions in [Vector2i(1152,648),Vector2i(900,600)]:
		root.size=dimensions
		await _store(dimensions.x)
	FileAccess.open("res://design-logs/candidate-pool-repair-v1/card-motion/animation-traces.json",FileAccess.WRITE).store_string(JSON.stringify(traces))
	print("Store motion verification: %d failures"%failures);quit(failures)
