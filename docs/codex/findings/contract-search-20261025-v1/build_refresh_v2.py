"""Preserve v1 delivery; execute the audited builder with new versioned outputs."""
from pathlib import Path
HERE=Path(__file__).resolve().parent
text=(HERE/'build.py').read_text(encoding='utf8')
text=text.replace('pn-contract-search-build-20261025-v1','pn-contract-search-build-20261025-v2')
text=text.replace('Contract Search','Contract Search Refresh')
text=text.replace('pn-contract-search-20261025-v1/current-world/result.json','pn-contract-search-20261025-v1/final-world-v2/result.json')
text=text.replace("sim.write_json(HERE/'result.json'","sim.write_json(HERE/'refresh-v2/result.json'")
text=text.replace("sim.write_json(HERE/'source.json'","sim.write_json(HERE/'refresh-v2/source.json'")
text=text.replace('shutil.copy2(OUT/name,HERE/name)','shutil.copy2(OUT/name,HERE/\'refresh-v2\'/name)')
(HERE/'refresh-v2').mkdir(exist_ok=False)
(HERE/'refresh-v2/executed-builder.py.txt').write_text(text,encoding='utf8')
exec(compile(text,str(HERE/'build.py'),'exec'),{'__file__':str(HERE/'build.py'),'__name__':'__main__'})
