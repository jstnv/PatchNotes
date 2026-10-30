from pathlib import Path
import shutil
out=Path(__file__).resolve().parent;root=out.parents[3]
previous=out.parent/'studio-glow-20261029-v1'
for name in ['pin.py','run.py']:
    (out/name).write_text((previous/name).read_text(encoding='utf-8').replace('studio-glow-','studio-beams-'),encoding='utf-8')
for rel in ['scripts/ui/studio_audio_glow.gd','scripts/ui/gameplay_hud.gd','scripts/market/rival_world_checkpoint.gd']:
    target=out/'before'/rel;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(root/'patch-notes'/rel,target)
for name in ['source.json','baseline.json']:shutil.copyfile(previous/'source.json',out/name)
(out/'PLAN.md').write_text('''# Studio downward beams —2026-10-29

User likes the header glow and asks for light extending downward below the top UI. Keep the dim header wash and reuse its actual audio levels for three softly widening/fading cones below it. A separate input-ignoring paint layer inside HUD, before its header and behind Studio content, shares the existing observer: no extra analyzer, audio transport or bus change. Clip to the viewport area above the footer, fade to zero, preserve narrow header illumination. Hide/cleanup both layers together and keep pause behavior.

Verify actual Studio layering/beam bounds/soft fade at1152/1280/1920, existing FFT/mute/pause/passive-state/departure/teardown checks, native WASAPI captures, existing HUD/sales and exact predecessor source compatibility. Keep dirty edits/.codex-godot-temp. No build/commit/push or broad performance claim.
''',encoding='utf-8')
print('Prepared beam refinement snapshots')
