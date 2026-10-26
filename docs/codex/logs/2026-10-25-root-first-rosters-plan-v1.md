# Root-first founding rosters implementation plan

> Execute inline with superpowers:executing-plans; one fresh read-only review at completion. Preserve shared dirty source and `.codex-godot-temp`; isolated immutable imports/profiles. No commit/push.

**Goal:** new specialty pools follow connected parent paths; replace skipped-ahead grants rather than add their missing parents for free, as the user explicitly selected2026-10-25.

**Architecture:** explicit fixed v3 deltas on the preserved v2 rosters. The current validated Store graph is an independent acceptance oracle, not an ongoing automatic grant generator. Follow authored first-parent branch anchors when moving backward through convergence; if an earlier node is already present, deduplicate. No extra free branch to satisfy a two-parent node. Keep the existing27 authored Primitive grant boundary: step past High Scores to Score System and Branching Dialogue to Dialogue, since later Store cards have unapproved play costs. v1/v2 preview/hydration and all old ownership remain unchanged. Exact grant counts/Scope change with substitutions; final balance remains OPEN, with no score/price/research-rule change.

**Stack:** Godot4.7.1, existing StudioSpecialties/StudioCheckpoint/Store graph, immutable verifier runner and pinned Windows export helpers.

## Steps

- [x] Freeze current source and independently audit all eight rosters against full parent graph. Record exact v3 IDs, counts/Scope/Core totals and removed/added IDs. Add failing default-v3/no-orphan tests; retain exact v1/v2 fixtures.
- [x] Implement fixed v3 grant patches/preview totals, allow current v3 checkpoint metadata and named old-source compatibility. Creation and simulator use the existing once-only grant path; no old-save reconstruction grants. Update only fixtures that intentionally expect the old starting membership; preserve historical oracle worlds explicitly as v2.
- [x] Verify all8 closed paths, no automatic extra grants, zero familiarity, once-only grants, optional child acquisition, old1/2 save equality, current checkpoints, source-pinned old editor/EXE worlds, bounded fresh all-genre runs and native preview/Store state. Review scoped implementation. Build a separate current EXE/ZIP including the earlier Studio-button fix; test the actual package. Persist evidence/design/TODO/state/session.

## Fixed proposed v3 result

| Genre | Count | Printed Scope | Core G/S/T/D |
|---|---:|---:|---|
| Action |18|27|21/9/30/12|
| Adventure |17|22|14/4/17/19|
| Role-Playing |17|23|14/3/22/18|
| Strategy |17|25|10/8/28/19|
| Simulation |15|21|8/8/25/14|
| Puzzle |17|23|11/3/27/18|
| Sports |15|22|8/15/25/12|
| Racing |16|24|18/8/27/12|

Ruling: these are structural replacements from the existing authored graph, not newly tuned balance targets. No candidate values or unrelated Contract Search adoption. Fixed deltas prevent future catalog additions from silently changing founding grants. New snapshots only; preserve all historical state. The user already approved the replacement approach; no extra approval round is needed to execute these bounded details.

## Additional direct request — transparent Store controls

2026-10-25 user asks to see the Feature Store behind Research, the budget warning, zoom and Core legend. Ruling: the map fills the body beneath a transparent sibling toolbar; locally duplicate button styles and clear their fills, preserving hover/focus borders and disabled text. Containers/labels pass empty-area input to the map; `_input` explicitly excludes actual toolbar buttons so it cannot steal their GUI gestures. Fit/focus retain a top safety inset, while free pan may show nodes behind controls. Debug/details/dropdown surfaces remain readable. No purchase, queue, scoring, calendar or RNG changes. The transparent-overlay test failed48 assertions on the predecessor before the runtime edit;87/87 native assertions now pass. Full HUD/native checks and final packaging are recorded in the linked finding at completion.

Ruling: extraction golden traces intentionally retain their explicit historical v2 Action roster; new-v3 full campaign/live parity and eight-Genre action replay cover current grants. Do not rewrite historical digests or pretend old fixtures were current starts.
