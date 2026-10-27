# Floating score choreography implementation plan

2026-10-26. Execute inline; preserve dirty canonical work and temp. User supplied the animation spec and delegated visual choices. Spec: current request plus shared music-clock/presentation constraints in Core/Studio design.

Chosen interpretation: values disappear behind the cards before card removal begins. Multi-Core cards show combined Core above each card; exact per-category gains stay authoritative. Normal card rise/score/grounded cadence remains140/min. Replace the sequential specialization bonus card wave with simultaneous numeric multipliers; this supersedes the old visual wave only, not gameplay re-triggers.

Architecture: new bounded music-sampled `card_score_floats.gd` renders clipped centered tokens and a central Balanced hub. `hand_presentation.gd` owns the shared timeline and deposits the already committed final snapshot only after all values sink. `production_scoreboard.gd` owns an independent short scale/tint/rotation settle used by both live HUD and tutorial. No RNG, resolution, rule, state-schema or audio transport changes.

Synergy map relative to popup: Specialization pairs rise0–1 subdivisions, merge1–2, shake2–3, hold3–4. Balanced gathers0–0.5, splits sum/×1.25 at0.5–1, merges1–2, splits exact four category gains2–3, holds3–4. Both bounce/sink4–5; deposit then card slide at5. Normal values hold through the base wave, sink over one subdivision, then deposit/slide. Redraw remains unchanged. All clocks/rejoin/cancel/low-FPS steps must remain safe.

- [x] Capture real pre-edit paired save/source; write failing tests for float lifetime, symmetry, music timing and delayed HUD updates.
- [x] Implement the sampled token component and master sequence; preserve once-only action, precise final category/QA/rounding values, pause/rejoin and cleanup.
- [x] Add bounded HUD punch with rapid-update/teardown cleanup; reuse it in tutorial. Refresh superseded motion expectations.
- [x] Run focused normal/Specialization/Balanced/QA/low-FPS/rejoin/cancel checks, maintained timing/lifecycle checks, native captures at both sizes and exact predecessor restore.
- [x] Inspect changes and captures; persist design/status/evidence/log. No new player export, commit or push requested. [Result](2026-10-26-floating-scores-v1.md).

Risks: multiple Core entries and hand rounding; QA caps/zero actual effects; floating text clipping/large strings; simultaneous pairs at narrow tutorial widths; delayed HUD leakage during signals; rapid pause or cancellation and source-bound save compatibility.
