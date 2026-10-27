from pathlib import Path
import json
out=Path(__file__).resolve().parent;root=out.parents[3]
paths=['scripts/ui/hand_presentation.gd','scripts/ui/production_scoreboard.gd','scripts/ui/gameplay_hud.gd','scripts/ui/guided_production_tutorial.gd','scripts/market/rival_world_checkpoint.gd','scripts/debug/verify_soundtrack_sync.gd','scripts/debug/verify_card_pop.gd','scripts/debug/verify_card_motion.gd']
for name in paths:
 t=out/'before'/name;t.parent.mkdir(parents=True,exist_ok=True);t.write_bytes((root/'patch-notes'/name).read_bytes())
runner=(out.parent/'balanced-small-hand-20261026-v1/run.py').read_text()
(out/'run.py').write_text(runner.replace('balanced-small-hand','score-floats'))
