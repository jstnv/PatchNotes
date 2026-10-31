extends SceneTree
const CashMotion=preload("res://scripts/ui/cash_feedback.gd")
var count:=0
var problems: Array[String]=[]
func check(ok: bool,message: String) -> void:
	count+=1
	if not ok:problems.append(message);push_error(message)
func _initialize() -> void:call_deferred("start")
func start() -> void:
	await money()
	var output:=OS.get_cmdline_user_args()[0].trim_prefix("--output=")
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"checks":count,"failures":problems}))
	print("CASH_MOTION ",count," ",problems)
	quit(0 if problems.is_empty() else 1)
func money() -> void:
	root.size=Vector2i(1152,648);root.content_scale_size=root.size
	var host:=Control.new();host.size=root.size;host.theme=load("res://resources/ui/workspace_theme.tres");root.add_child(host)
	var button:=Button.new();host.add_child(button);button.position=Vector2(800,500);button.size=Vector2(220,48)
	var motion:=CashMotion.new();host.add_child(motion);motion.configure(button);motion.set_process(false);motion.reset(10000)
	var original:=button.text;motion.observe(12500);motion.observe(10900)
	motion._process(CashMotion.RISE*0.65);await capture("cash-popup");motion.elapsed=0
	check(motion._label.text=="+$9.00" and button.text==original,"Simultaneous inflow/outflow batches to net; number waits")
	check(is_equal_approx(CashMotion.pose(0),112.0) and CashMotion.pose(CashMotion.RISE*0.65)<CashMotion.pose(CashMotion.RISE),"Popup emerges with overshoot and settles below peak")
	motion._process(CashMotion.RISE+CashMotion.HOLD+CashMotion.FALL-0.01)
	check(button.text==original,"No premature HUD deposit")
	motion._process(0.02);check(motion.presented_cents==10900 and button.text.contains("109.00"),"Value updates exactly on button contact")
	motion.observe(-50000);motion._process(2.0)
	check(button.text=="Cash: -$500.00","Overdue bankroll displays signed amount")
	await create_timer(0.9).timeout;motion._process(0);await capture("overdue-bankroll")
	check(motion.warning_mix>0.99,"Broke background reaches gradual red tint")
	motion._process(0.5);check(not button.has_theme_color_override("font_color"),"Persistent debt warning leaves normal font color")
	motion.observe(15000);motion._process(2);motion._process(0.5);await create_timer(0.9).timeout
	check(motion.warning_mix<0.01 and button.text.contains("150.00"),"Recovery clears warning and updates balance")
	motion.observe(18000);motion.observe(19000);motion._process(2)
	check(motion.presented_cents==19000,"Further changes in flight are retained")
	motion.reset(19000,true);check(button.text=="Cash: ∞" and not motion.flying,"Debug infinity does not produce phantom transactions")
	check(CashMotion.balance(0,100)==-100 and CashMotion.difference(-9223372036854775807,9223372036854775807)=="+$184467440737095516.14","Signed display and full-range delta do not overflow")
	host.free()

func capture(label: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	var output:=OS.get_cmdline_user_args()[0].trim_prefix("--output=").get_base_dir()
	root.get_texture().get_image().save_png(output+"/"+label+".png")
