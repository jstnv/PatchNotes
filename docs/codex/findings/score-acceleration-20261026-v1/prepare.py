from pathlib import Path
out=Path(__file__).resolve().parent;root=out.parents[3]
for name in ['scripts/ui/card_score_floats.gd','scripts/market/rival_world_checkpoint.gd','scripts/debug/verify_score_floats.gd']:
    target=out/'before'/name
    target.parent.mkdir(parents=True,exist_ok=True)
    assert not target.exists()
    target.write_bytes((root/'patch-notes'/name).read_bytes())
runner=(out.parent/'score-easing-20261026-v1/run.py').read_text()
(out/'run.py').write_text(runner.replace('score-easing','score-acceleration'))
(out/'audit.py').write_text((out.parent/'score-easing-20261026-v1/audit.py').read_text())
