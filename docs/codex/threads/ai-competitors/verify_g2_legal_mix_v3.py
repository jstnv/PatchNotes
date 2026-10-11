"""Narrow guard-fix verification; v2 results keep their original identities."""
import importlib.util
import json
from pathlib import Path

BASE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('g2driver',BASE/'run_g2_legal_mix_v2.py')
driver=importlib.util.module_from_spec(spec)
spec.loader.exec_module(driver)
driver.BUNDLE=BASE/'sims/g2-legal-mix-v3-prefix'
driver.PROJECT=driver.BUNDLE/'project'
driver.OUT=BASE/'sims/g2-legal-mix-v3-checks'
driver.OUT.mkdir()
before=driver.hashes()
rows=[]
checkpoint=driver.BUNDLE/'cases/g2-prefix-4417/studio_checkpoint.json'
for label,args in [
    ('unit',['--mode=unit']),
    ('catalog-parity',['--mode=catalog_parity','--checkpoint='+str(checkpoint),
                       '--reference=res://scripts/debug/g2_legal_mix_reference_v2.gd']),
    ('baseline',['--mode=study','--hands=1','--checkpoint='+str(checkpoint)])]:
    row,result=driver.run(label,args)
    rows.append(row)
    if not row['passed']: break
summary={'ok':all(row['passed'] for row in rows) and len(rows)==3 and before==driver.hashes(),
         'rows':rows,'source_unchanged':before==driver.hashes(),'source_hashes':before,
         'scope':'v3 guard/reference fixtures and one fresh 1/1 ceiling; v2 wider study not relabeled'}
(driver.OUT/'summary.json').write_text(json.dumps(summary,indent=2))
raise SystemExit(0 if summary['ok'] else 1)
