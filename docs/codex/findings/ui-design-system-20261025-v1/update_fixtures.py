"""Adjust maintained presentation fixtures for relocated controls and explicit discard."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[4]
for p in (ROOT/'patch-notes/scripts/debug').glob('*.gd'):
    if p.name=='verify_ui_folder_navigation.gd':continue
    s=p.read_text(encoding='utf8');original=s
    if 'CenterContainer/MenuLayout' not in s and p.name!='verify_menu_navigation.gd':continue
    for suffix,field in [('StudioName','_name_input'),('FolderContent/genre/Genre/StudioSpecialty','_specialty'),('EnterStudio','_play')]:
        s=re.sub(r'(\w+)\.get_node\("CenterContainer/MenuLayout/StudioSetup/'+suffix+r'"\)',lambda m:m[1]+'.'+field,s)
    s=re.sub(r'(\w+)\.get_node\("CenterContainer/MenuLayout/StudioSetup"\)',lambda m:m[1]+'._setup',s)
    s=s.replace('layout.get_node("StudioSetup/EnterStudio")','menu._play').replace('layout.get_node("StudioSetup/Back")','menu._back')
    s=s.replace('setup.get_node("StudioName")','menu._name_input').replace('setup.get_node("FolderContent/genre/Genre/StudioSpecialty")','menu._specialty').replace('setup.get_node("EnterStudio")','menu._play').replace('setup.get_node("Back")','menu._back')
    # Legacy suites test validation, not transition timing. New focused verifier
    # exercises animated pointer/Esc/stack/teardown; these use the explicit bypass.
    lines=s.splitlines(keepends=True);result=[]
    for line in lines:
        match=re.search(r'(\w+)\.get_node\("CenterContainer/MenuLayout/(?:StartGame|Settings|HowToPlay)"\)',line)
        if match:result.append(line[:len(line)-len(line.lstrip())]+match[1]+'.navigation.animate=false\n')
        elif 'layout.get_node("StartGame").pressed.emit()' in line or 'menu.find_child("StartGame",true,false).pressed.emit()' in line:
            result.append(line[:len(line)-len(line.lstrip())]+'menu.navigation.animate=false\n')
        result.append(line)
    s=''.join(result)
    if p.name=='verify_studio_folder_menu.gd':
        s=s.replace('menu._back.pressed.emit()','menu.discard_setup()')
        s=s.replace('"Cancel clears draft without creation"','"Explicit discard clears draft without creation"')
    if p.name=='verify_studio_specialties.gd':
        s=s.replace('menu._back.pressed.emit()','menu.discard_setup()')
        s=s.replace('"Cancel clears uncommitted choice without granting"','"Explicit discard clears uncommitted choice without granting"')
    if p.name=='verify_studio_traits.gd':
        s=s.replace('for path in ["StudioSetup/EnterStudio", "StudioSetup/Back"]:\n\t\tvar rect: Rect2 = layout.get_node(path).get_global_rect()', 'for control: Button in [menu._play,menu._back]:\n\t\tvar rect: Rect2 = control.get_global_rect()')
        s=s.replace('rect.end.y <= resolution.y - 45','rect.end.y <= resolution.y - 20').replace('"Trait footer stays above HUD: " + path','"Creation controls fit viewport: " + control.name')
        s=s.replace('menu.get("_review").text.contains("Cult Following")','menu._overview_lists[true].get_children().any(func(node): return node.text=="Cult Following")')
    if p.name=='verify_fanbase_ui.gd':
        s=s.replace('menu.get_node("CenterContainer/MenuLayout/Continue").text','menu.find_child("SavedStudio",true,false).text')
    if s!=original:
        p.write_text(s,encoding='utf8');print(p.name)
