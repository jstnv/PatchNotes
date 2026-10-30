extends Container

## Development retains its centered workspace. Release menus fill the space
## above the footer, so their nested panels inherit a real, bounded size.
func _notification(what: int) -> void:
	if what != NOTIFICATION_SORT_CHILDREN:
		return
	for child: Node in get_children():
		if not child is Control or not child.visible:
			continue
		if child is StudioPhase or child is PostGameReview or child is ContractPhase or child is FirstProjectSetup or child is MainMenu:
			fit_child_in_rect(child, Rect2(Vector2.ZERO, size))
		else:
			var minimum: Vector2 = child.get_combined_minimum_size()
			fit_child_in_rect(child, Rect2((size - minimum) / 2.0, minimum))
