"""Requested v0.03 release folder and ZIP; preserve every v0.02 delivery."""
from pathlib import Path
HERE=Path(__file__).resolve().parent
source=(HERE/'build.py').read_text(encoding='utf8')
source=source.replace('pn-contract-search-build-20261025-v1','pn-patch-notes-v003-build-20261025-v1')
source=source.replace('Patch Notes v0.02 - Contract Search','Patch Notes v0.03').replace('Patch Notes v0.02','Patch Notes v0.03')
source=source.replace('0.0.2.0','0.0.3.0').replace("'version':'0.02'","'version':'0.03'")
source=source.replace('pn-contract-search-20261025-v1/current-world/result.json','pn-contract-search-20261025-v1/final-world-v2/result.json')
source=source.replace('config/name="Patch Notes"\\nconfig/version="0.02"','config/name="Patch Notes"')
source=source.replace("sim.write_json(HERE/'result.json'","sim.write_json(HERE/'v003/result.json'")
source=source.replace("sim.write_json(HERE/'source.json'","sim.write_json(HERE/'v003/source.json'")
source=source.replace('shutil.copy2(OUT/name,HERE/name)','shutil.copy2(OUT/name,HERE/\'v003\'/name)')
(HERE/'v003').mkdir(exist_ok=False)
(HERE/'v003/executed-builder.py.txt').write_text(source,encoding='utf8')
exec(compile(source,str(HERE/'build.py'),'exec'),{'__file__':str(HERE/'build.py'),'__name__':'__main__'})
