from pathlib import Path
out=Path(__file__).resolve().parent;root=out.parents[3]
for name in ['scripts/cards/balanced_production.gd','scripts/market/rival_world_checkpoint.gd','scripts/debug/verify_balanced_boost.gd']:
 p=root/'patch-notes'/name;t=out/'before'/name;t.parent.mkdir(parents=True,exist_ok=True);t.write_bytes(p.read_bytes())
runner=(out.parent/'balanced-boost-20261026-v1/run.py').read_text()
(out/'run.py').write_text(runner.replace('balanced-boost','balanced-small-hand'))
