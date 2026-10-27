extends "res://scripts/debug/verify_market_browser.gd"

func expect(value: bool, label: String) -> void:
	if not value:
		var button: Control = root.find_child("MarketButton", true, false)
		var hud: Control = root.find_child("GameplayHUD", true, false)
		print("MARKET_DIAGNOSTIC ", {"label":label,"window":root.size,"canvas":root.content_scale_size,
			"paused":paused,"button":button.get_global_rect() if button else Rect2(),
			"button_visible":button.is_visible_in_tree() if button else false,
			"button_disabled":button.disabled if button else true,
			"focus":str(root.gui_get_focus_owner()),
			"footer":hud.footer_panel.get_global_rect() if hud else Rect2()})
	super.expect(value,label)
