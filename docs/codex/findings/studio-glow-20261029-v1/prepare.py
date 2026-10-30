from pathlib import Path
import shutil
out=Path(__file__).resolve().parent
root=out.parents[3]
previous=out.parent/'research-confirmation-20261029-v1'
for name in ['pin.py','run.py']:
    text=(previous/name).read_text(encoding='utf-8').replace('research-confirmation-','studio-glow-')
    (out/name).write_text(text,encoding='utf-8')
for rel in ['scripts/ui/gameplay_hud.gd','scripts/market/rival_world_checkpoint.gd']:
    target=out/'before'/rel;target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(root/'patch-notes'/rel,target)
for name in ['baseline.json','source.json']:shutil.copyfile(previous/'source.json',out/name)
(out/'PLAN.md').write_text('''# Studio header reactive light —2026-10-29

Direct user asks for a trial visualizer: really dim audio-reactive light behind the Studio top UI. Reuse the existing Music spectrum observer and its lifecycle/gain/mute handling; draw three broad cyan/warm radial lights capped at7.5% alpha rather than a chart. Place inside the existing header panel before the text/chart row; no new border, layout minimum, input or focus. Studio phase and its browsing overlays only; hide/release when HUD is hidden or production/title becomes active. Continue observing music while paused. Keep music transport/mix and rules untouched.

Focused verifier: actual fresh Gameplay Studio, live FFT changes, bounded alpha/clip/layer/geometry at1152/1280/1920, mute/volume/silence, hide/show/pause/Store and phase departure, effect ownership and teardown, passive state/RNG. Native real WASAPI screenshots and existing title visualizer, HUD/previous-world checks. Preserve existing edits/.codex-godot-temp; no build/commit/push, no blanket performance result. Exact previous-source compatibility remains paired with current content.
''',encoding='utf-8')
print('Prepared narrow source snapshots')
