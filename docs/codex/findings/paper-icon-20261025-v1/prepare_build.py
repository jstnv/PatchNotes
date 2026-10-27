"""Freeze an adapted copy of the previously verified standalone build recipe."""
from pathlib import Path
import hashlib, json

HERE = Path(__file__).resolve().parent
prior = HERE.parent/'logo-icon-20261024-v1'
text = (prior/'build.py').read_text(encoding='utf8')
changes = {
    "pn-logo-icon-20261024-v1": "pn-paper-icon-build-20261025-v1",
    "Patch Notes v0.02 - Logo": "Patch Notes v0.02 - Paper Icon",
    "C:/Users/64jus/AppData/Local/Temp/pn-guided-tutorial-20261024-v1/native-final/profile/APPDATA/Godot/app_userdata/Patch Notes/saves/studio/checkpoint.1.json":
    "C:/Users/64jus/AppData/Local/Temp/pn-save-tutorial-20261024-v1/green/profiles/verify_save_tutorial_invitation-qh8qysv3/APPDATA/Godot/app_userdata/Patch Notes/saves/studio/checkpoint.1.json",
    "pe = module('icon_pe', HERE/'inspect_icon.py')": "pe = module('icon_pe', HERE.parent/'logo-icon-20261024-v1/inspect_icon.py')",
    "assets/branding/patch_notes.ico": "assets/branding/patch_notes_paper.ico",
    "This refresh includes the transparent logo icon and guided tutorial.": "This refresh uses the folded-paper icon and includes the current tutorial/save invitation.",
}
for old, new in changes.items():
    assert old in text, old
    text = text.replace(old,new)
target = HERE/'build.py'
assert not target.exists()
target.write_text(text,encoding='utf8')
provenance = {'base_recipe':str(prior/'build.py'), 'base_sha256':hashlib.sha256((prior/'build.py').read_bytes()).hexdigest(),
              'adapted_sha256':hashlib.sha256(target.read_bytes()).hexdigest(), 'replacements':changes}
(HERE/'build-recipe.json').write_text(json.dumps(provenance,indent=2)+'\n',encoding='utf8')
print('Prepared versioned paper-icon build recipe.')
