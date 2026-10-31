extends Control

## Presentation only. The wallet and bills always remain RunState authority.
const RISE:=60.0/140.0
const HOLD:=0.16
const FALL:=60.0/140.0
var button: Button
var presented_cents:=0
var target_cents:=0
var from_cents:=0
var initialized:=false
var flying:=false
var infinite:=false
var elapsed:=0.0
var warning_mix:=0.0
var _warning: Tween
var _styles: Dictionary={}
var _live_styles: Dictionary={}
var _painted_warning:=-1.0
var _font_colors: Dictionary={}
var _window: Control
var _label: Label
var _flash:=1.0
var _flash_sign:=0
var _base_x:=0.0
var _offset:=0.0

static func balance(cash: int,overdue: int) -> int:return cash-overdue
static func amount(cents: int) -> String:
	return ("-" if cents<0 else "")+CashFormatter.format_exact_cents(absi(cents))
static func difference(before: int,after: int) -> String:
	# Opposite signed balances can differ by more than INT64_MAX cents.
	var whole: int=0;var fraction: int=0
	if (before<0 and after>=0) or (before>=0 and after<0):
		whole=absi(before)/100+absi(after)/100;fraction=absi(before)%100+absi(after)%100
		whole+=fraction/100;fraction%=100
	else:
		var distance:=absi(after-before);whole=distance/100;fraction=distance%100
	return ("+" if after>before else "-" if after<before else "")+"$%d.%02d"%[whole,fraction]
static func pose(seconds: float) -> float:
	if seconds<RISE:
		var u:=clampf(seconds/RISE,0,1);var c:=1.70158
		return 112.0-70.0*(1.0+(c+1.0)*pow(u-1.0,3)+c*pow(u-1.0,2))
	if seconds<RISE+HOLD:return 42.0
	var t:=clampf((seconds-RISE-HOLD)/FALL,0,1)
	if t<0.3:return 42.0-18.0*(1.0-pow(1.0-t/0.3,2))
	return lerpf(24.0,112.0,pow((t-0.3)/0.7,2))

func configure(current: Button) -> void:
	button=current;mouse_filter=Control.MOUSE_FILTER_IGNORE;process_mode=Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for key in [&"normal",&"hover",&"pressed",&"disabled"]:
		var original:=button.get_theme_stylebox(key)
		if original is StyleBoxFlat:
			_styles[key]=original.duplicate();_live_styles[key]=original.duplicate();button.add_theme_stylebox_override(key,_live_styles[key])
	for key in [&"font_color",&"font_hover_color",&"font_pressed_color",&"font_focus_color",&"font_disabled_color"]:_font_colors[key]=button.get_theme_color(key)
	_window=Control.new();_window.mouse_filter=Control.MOUSE_FILTER_IGNORE;_window.clip_contents=true;add_child(_window)
	_label=Label.new();_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_label.size=Vector2(240,38);_label.add_theme_font_size_override("font_size",24)
	_label.add_theme_font_override("font",button.get_theme_font("font"))
	_label.add_theme_color_override("font_outline_color",Color("182027"));_label.add_theme_constant_override("outline_size",4)
	_window.add_child(_label);_window.hide()
func reset(value: int,debug_infinity:=false) -> void:
	_restore_position();initialized=true;presented_cents=value;target_cents=value;from_cents=value;infinite=debug_infinity
	flying=false;_flash=1.0;_window.hide();_clear_flash()
	_write();_warn()
func observe(value: int,debug_infinity:=false) -> void:
	if not initialized or infinite!=debug_infinity:reset(value,debug_infinity);return
	if infinite or value==target_cents:return
	target_cents=value
	if not flying:from_cents=presented_cents;elapsed=0;flying=true;_window.show()
	_label.text=difference(from_cents,target_cents)
	_label.add_theme_color_override("font_color",Color("7cd7aa") if target_cents>from_cents else Color("ed7e82") if target_cents<from_cents else Color("e0dfd6"))
func _write() -> void:
	button.text="Cash: ∞" if infinite else "Cash: "+amount(presented_cents)
func _warn() -> void:
	if _warning!=null:_warning.kill()
	_warning=create_tween();_warning.tween_property(self,"warning_mix",1.0 if presented_cents<=0 and not infinite else 0.0,0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
func _restore_position() -> void:
	if is_instance_valid(button) and not is_zero_approx(_offset):button.position.x-=_offset
	_offset=0.0
func _clear_flash() -> void:
	for key: StringName in _font_colors:button.remove_theme_color_override(key)
func _process(delta: float) -> void:
	if not is_instance_valid(button):return
	if not is_equal_approx(_painted_warning,warning_mix):
		_painted_warning=warning_mix
		for key: StringName in _styles:
			_live_styles[key].bg_color=_styles[key].bg_color.lerp(Color("9d3546"),warning_mix*0.65)
	if flying:
		elapsed+=delta
		var rect:=button.get_global_rect();_window.position=Vector2(rect.get_center().x-120,rect.position.y-112)-global_position;_window.size=Vector2(240,112)
		_label.position=Vector2(0,pose(elapsed))
		if elapsed>=RISE+HOLD+FALL:
			_flash_sign=1 if target_cents>presented_cents else -1 if target_cents<presented_cents else 0
			presented_cents=target_cents;flying=false;_window.hide();_write();_warn();_flash=0;_base_x=button.position.x
	if _flash<0.38:
		_flash+=delta
		if not is_equal_approx(button.position.x,_base_x+_offset):_base_x=button.position.x
		_offset=sin(_flash*85.0)*4.0*maxf(0,1.0-_flash/0.24);button.position.x=_base_x+_offset
		for key: StringName in _font_colors:
			var base: Color=_font_colors[key]
			var flash:=Color("7cd7aa") if _flash_sign>0 else Color("ed7e82") if _flash_sign<0 else base
			button.add_theme_color_override(key,base.lerp(flash,maxf(0,1.0-_flash/0.38)))
		if _flash>=0.38:_restore_position();_clear_flash()
func _exit_tree() -> void:_restore_position()
