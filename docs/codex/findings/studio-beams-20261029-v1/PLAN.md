# Studio downward beams —2026-10-29

User likes the header glow and asks for light extending downward below the top UI. Keep the dim header wash and reuse its actual audio levels for three softly widening/fading cones below it. A separate input-ignoring paint layer inside HUD, before its header and behind Studio content, shares the existing observer: no extra analyzer, audio transport or bus change. Clip to the viewport area above the footer, fade to zero, preserve narrow header illumination. Hide/cleanup both layers together and keep pause behavior.

Verify actual Studio layering/beam bounds/soft fade at1152/1280/1920, existing FFT/mute/pause/passive-state/departure/teardown checks, native WASAPI captures, existing HUD/sales and exact predecessor source compatibility. Keep dirty edits/.codex-godot-temp. No build/commit/push or broad performance claim.
