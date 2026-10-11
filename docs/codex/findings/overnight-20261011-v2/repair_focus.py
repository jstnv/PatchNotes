from pathlib import Path
ROOT = Path(__file__).resolve().parents[4]
def replace(path, old, new):
    p = ROOT / path
    b = p.read_bytes()
    assert old.encode() in b, path
    p.write_bytes(b.replace(old.encode(), new.encode(), 1))

# Preserve this repository's source bytes and CRLF convention.
replace('patch-notes/scripts/debug/verify_contract_presentation.gd',
        '[Vector2i(1152, 648), Vector2i(1600, 900)]',
        '[Vector2i(1152, 648), Vector2i(1280, 720), Vector2i(1600, 900)]')
replace('patch-notes/scripts/debug/verify_contract_presentation.gd',
        '\t\t\tphase.get("_play_button").pressed.emit()',
        '\t\t\tphase.get("_play_button").grab_focus()\r\n\t\t\tphase.get("_play_button").pressed.emit()')
replace('patch-notes/scripts/debug/verify_contract_presentation.gd',
        '\t\t(panel.find_child("DismissCompletionButton", true, false) as Button).pressed.emit()',
        '\t\tvar dismiss := panel.find_child("DismissCompletionButton", true, false) as Button\r\n'
        '\t\texpect(root.gui_get_focus_owner() == dismiss, "Completion owns keyboard focus after animation cleanup")\r\n'
        '\t\tawait key(KEY_TAB)\r\n'
        '\t\texpect(root.gui_get_focus_owner() == dismiss, "Tab stays inside completion")\r\n'
        '\t\tawait key(KEY_TAB, true)\r\n'
        '\t\texpect(root.gui_get_focus_owner() == dismiss, "Shift Tab stays inside completion")\r\n'
        '\t\tawait key(KEY_ENTER)')
p = ROOT/'patch-notes/scripts/debug/verify_contract_presentation.gd'
p.write_bytes(p.read_bytes() + b'\r\n\r\nfunc key(code: Key, shift := false) -> void:\r\n\tvar event := InputEventKey.new()\r\n\tevent.keycode = code\r\n\tevent.shift_pressed = shift\r\n\tevent.pressed = true\r\n\tInput.parse_input_event(event)\r\n\tawait process_frame\r\n\tevent = event.duplicate()\r\n\tevent.pressed = false\r\n\tInput.parse_input_event(event)\r\n\tawait process_frame\r\n')
