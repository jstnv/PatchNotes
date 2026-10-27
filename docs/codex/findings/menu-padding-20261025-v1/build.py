"""Isolated versioned menu-spacing refresh using the pinned package builder."""
from pathlib import Path
import hashlib,json
HERE=Path(__file__).resolve().parent
SOURCE=HERE.parent/'paper-icon-20261025-v1/build.py'
text=SOURCE.read_text(encoding='utf8')
text=text.replace('pn-paper-icon-build-20261025-v1','pn-menu-spacing-build-20261025-v1').replace('Patch Notes v0.02 - Paper Icon','Patch Notes v0.02 - Menu Spacing')
start=text.index('# Genuine unchanged Studio generation');end=text.index("export = module('version_export'",start)
text=text[:start]+'''# Genuine current-editor world from36 legal unchanged model commands.
fixture=json.loads(Path('C:/Users/64jus/AppData/Local/Temp/pn-menu-padding-20261025-v1/current-world/result.json').read_text(encoding='utf8'))
(OUT/'editor-world').mkdir()
sim.write_json(OUT/'editor-world/result.json',fixture)
editor_identity=fixture['world']['source_identity']

'''+text[end:]
text=text.replace("HERE/'package_probe.gd'","HERE.parent/'paper-icon-20261025-v1/package_probe.gd'")
text=text.replace('This refresh uses the folded-paper icon and includes the current tutorial/save invitation.','This refresh preserves menu padding through entrance animations and includes the root-first starting pools, transparent Store toolbar and first-release Studio action fix.')
(HERE/'builder-provenance.json').write_text(json.dumps({'base':str(SOURCE),'base_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'executed_sha256':hashlib.sha256(text.encode('utf8')).hexdigest(),'changes':['separate Menu Spacing output/delivery','genuine current editor world','reuse strict paper-icon package probe','updated delivery note']},indent=2)+'\n',encoding='utf8')
exec(compile(text,str(HERE/'build.py'),'exec'),{'__file__':str(HERE/'build.py'),'__name__':'__main__'})
