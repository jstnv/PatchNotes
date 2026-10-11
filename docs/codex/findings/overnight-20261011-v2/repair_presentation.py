from pathlib import Path
ROOT = Path(__file__).resolve().parents[4]
def replace(path, old, new):
    p=ROOT/path;b=p.read_bytes();assert old.encode() in b,path
    p.write_bytes(b.replace(old.encode(),new.encode(),1))
replace('patch-notes/scripts/ui/hand_presentation.gd',
 '\tif _restore.is_valid(): _restore.call()\r\n\tif is_instance_valid(_prior_focus) and _prior_focus.is_inside_tree() and _prior_focus.is_visible_in_tree(): _prior_focus.grab_focus()\r\n\t_prior_focus = null',
 '\t# Restore old focus before phase navigation can open a new modal.\r\n\tif is_instance_valid(_prior_focus) and _prior_focus.is_inside_tree() and _prior_focus.is_visible_in_tree(): _prior_focus.grab_focus()\r\n\t_prior_focus = null\r\n\tif _restore.is_valid(): _restore.call()')
replace('patch-notes/scripts/phases/contract_phase.gd',
 '\tdismiss.text = "Return to Studio"',
 '\tdismiss.text = "Return to Studio"\r\n\tdismiss.focus_next = NodePath(".")\r\n\tdismiss.focus_previous = NodePath(".")')

replace('patch-notes/scripts/ui/employee_panel.gd',
 'var quote: Dictionary = {}',
 'var quote: Dictionary = {}\r\nvar _details: Label\r\nvar _scroll: ScrollContainer')
replace('patch-notes/scripts/ui/employee_panel.gd',
 '\tget_label().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART\r\n\tget_label().custom_minimum_size.x = 600',
 '\t# Keep growing training copy inside a bounded scroll surface so the\r\n'
 '\t# confirmation buttons remain reachable after repeated opens/resizes.\r\n'
 '\tget_label().hide()\r\n'
 '\t_scroll = ScrollContainer.new()\r\n'
 '\t_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED\r\n'
 '\tadd_child(_scroll)\r\n'
 '\t_details = Label.new()\r\n'
 '\t_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART\r\n'
 '\t_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL\r\n'
 '\t_scroll.add_child(_details)')
replace('patch-notes/scripts/ui/employee_panel.gd',
 '\tpopup_centered(Vector2i(670,430))',
 '\t_fit_and_open()')
replace('patch-notes/scripts/ui/employee_panel.gd',
 '\t\tdialog_text = "Hiring could not be completed. Cash or bills changed; review the current offer.\\n\\n" + dialog_text',
 '\t\tdialog_text = "Hiring could not be completed. Cash or bills changed; review the current offer.\\n\\n" + dialog_text\r\n\t\t_fit_and_open()')
replace('patch-notes/scripts/ui/employee_panel.gd',
 '\r\n\r\nfunc _input(event: InputEvent) -> void:',
 '\r\n\r\nfunc _fit_and_open() -> void:\r\n'
 '\t_details.text = dialog_text\r\n'
 '\tget_label().hide()\r\n'
 '\tvar available := get_parent().get_viewport().get_visible_rect().size\r\n'
 '\tvar target := Vector2i(mini(760, int(available.x) - 64), mini(480, int(available.y) - 64))\r\n'
 '\t_scroll.custom_minimum_size = Vector2(target.x - 32, target.y - 90)\r\n'
 '\t_scroll.scroll_vertical = 0\r\n'
 '\tpopup_centered(target)\r\n'
 '\tget_cancel_button().grab_focus()\r\n'
 '\r\n\r\nfunc _input(event: InputEvent) -> void:')
replace('patch-notes/scripts/debug/verify_employee_ui.gd',
 '\t\tawait process_frame\r\n\t\tcheck(panel.size.x<=resolution.x and panel.size.y<=resolution.y,"Employee dialog fits viewport")',
 '\t\tfor frame in range(8): await process_frame\r\n'
 '\t\tcheck(Rect2(Vector2.ZERO,Vector2(resolution)).encloses(Rect2(Vector2(panel.position),Vector2(panel.size))),"Employee dialog including settled wrapping fits viewport")\r\n'
 '\t\tcheck(panel._details.text == panel.dialog_text and panel._scroll.size.y > 0,"Complete hiring and training copy is available in scroll surface")\r\n'
 '\t\tcheck(Rect2(Vector2.ZERO,Vector2(panel.size)).encloses(panel.get_ok_button().get_global_rect()) and Rect2(Vector2.ZERO,Vector2(panel.size)).encloses(panel.get_cancel_button().get_global_rect()),"Hire and Back buttons stay inside dialog")')
