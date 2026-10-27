"""Isolated versioned title-navigation refresh using the pinned package builder."""
from pathlib import Path
import hashlib,json
HERE=Path(__file__).resolve().parent
SOURCE=HERE.parent/'paper-icon-20261025-v1/build.py'
text=SOURCE.read_text(encoding='utf8')
text=text.replace('pn-paper-icon-build-20261025-v1','pn-title-settings-build-20261025-v1').replace('Patch Notes v0.02 - Paper Icon','Patch Notes v0.02 - Menu Slides')
start=text.index('# Genuine unchanged Studio generation');end=text.index("export = module('version_export'",start)
text=text[:start]+'''# Genuine current editor world,36 unchanged legal model commands.
fixture=json.loads(Path('C:/Users/64jus/AppData/Local/Temp/pn-title-settings-motion-20261025-v1/current-world/result.json').read_text(encoding='utf8'))
(OUT/'editor-world').mkdir()
sim.write_json(OUT/'editor-world/result.json',fixture)
editor_identity=fixture['world']['source_identity']

'''+text[end:]
text=text.replace("HERE/'package_probe.gd'","HERE.parent/'paper-icon-20261025-v1/package_probe.gd'")
text=text.replace('This refresh uses the folded-paper icon and includes the current tutorial/save invitation.','This refresh fixes the Settings forward/back slide in the main menu and includes the menu-padding, starting-pool, Store and Studio fixes.')
(HERE/'builder-provenance.json').write_text(json.dumps({'base':str(SOURCE),'base_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'executed_sha256':hashlib.sha256(text.encode('utf8')).hexdigest(),'changes':['separate Menu Slides output/delivery','genuine current editor world','strict existing package probe','updated delivery note']},indent=2)+'\n',encoding='utf8')
exec(compile(text,str(HERE/'build.py'),'exec'),{'__file__':str(HERE/'build.py'),'__name__':'__main__'})
