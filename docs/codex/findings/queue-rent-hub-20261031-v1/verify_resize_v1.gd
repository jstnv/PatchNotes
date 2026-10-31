extends SceneTree
func _initialize() -> void:
	await process_frame
	var motion=MenuTransitions.new();motion.automatic_entrances=false;root.add_child(motion)
	var base=Control.new();root.add_child(base);base.size=Vector2(400,300);motion.set_root(base)
	var child=Control.new();root.add_child(child);child.size=Vector2(400,300)
	motion.animate=false;motion.push_from_bottom(child,null,Callable(),300)
	base.size.y=500;child.size.y=500;motion.animate=true;motion.pop()
	await create_timer(0.22).timeout
	var ok=child.position.y>350
	await create_timer(0.06).timeout
	FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"ok":ok,"input_released":not root.gui_disable_input}));quit(0 if ok else 1)
