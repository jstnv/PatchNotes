# Bounded private rival Theme-variety refresh — 2026-10-17

**COMPLETE at the two-rival/20-cycle scope; CANDIDATE only.** This follows the queued variety-before-pressure work and the earlier retained Theme timeout. [Plan](AI-VARIETY-PLAN.md), [run provenance](ai-variety-run-v2/run-report.json), [copied-file hashes](variety-port.json), [repeat audit](closeout-audit.json). No canonical AI policy, target, sales coefficient or active market effect changed.

New independent version: `ai-market-variety-implementation-v1`, owner `ai-competitors`, canonical creation identity `f7baf91f2775d9f4f50c75c1a9e4bef992640919dfdf9eb26f75d8031bef67bb`, candidate identity `e1b9ad8f60242761e75ff33350dd7305fd6bbcba8407f6b65bd9072e64870e3e`. The full source manifests distinguish those file-set identities from gameplay replay identities. The three copied candidate files are the private rival Theme selection, pure shadow calculator and verifier. Metadata/baseline archives are untouched.

The first capture rejected concurrent canonical debug-file drift. It is retained as `ai-variety-run-v1`; fresh `ai-variety-run-v2` passed the provenance fence. Each focused process used a new profile/port, 240-second external bound and the original 90-second internal timer. **Plan correction:** its description mistakenly said the existing timer was 45 seconds. Inspection confirms source was 90 seconds throughout this refresh; neither it nor the candidate was changed after the runs. The earlier design-thread timeout is still historical incomplete evidence.

| Actual legal release | Cycle | Genre | Theme | Review | Earned units at cycle 20 | Settled cents |
|---|---:|---|---|---:|---:|---:|
| Arcade Foundry 1 | 7 | Action | Fantasy | 1.9 | 338 | 236,363 |
| Wayfinder Works 1 | 7 | Adventure | Fantasy | 1.8 | 253 | 176,922 |
| Arcade Foundry 2 | 14 | Action | War | 2.9 | 333 | 232,866 |
| Wayfinder Works 2 | 14 | Adventure | Mystery | 1.6 | 240 | 167,832 |

Two Genres, three Themes, four releases. Genres stay on their original specialties; this is a deterministic two-project Theme variation, not broad dynamic Genre choice or stronger-AI evidence. Actual finite card draws/plays remain under the two-hand policy. The second project's Core vectors are `[17,14,24,17]` and `[17,14,11,18]`; the first pair are `[15,21,17,15]` and `[13,13,16,24]` in the existing Core order.

[First process](ai-variety-rivals-1/rival-verifier.command.json) exits 0 in 53.109 seconds; [second](ai-variety-rivals-2/rival-verifier.command.json) exits 0 in 52.562 seconds. Each passes **213/213**, 20 cycles. The complete `MARKET_SHADOW_*` and final assertion output matches exactly between runs, including state/RNG digests, 20 sales projections and snapshot rows. Existing six-instance ObjectDB exit warnings are retained; there are no script/runtime errors. A representative one-release, 18-command player smoke and [fresh exact replay](ai-variety-replay-v1/run-report.json) pass.

All actual rival Reviews remain below the private >=7.0 quality gate, so the legal routes provide no positive market Core-lift observation. Shadow Genre/Theme factors are projections only; the real units/cents above are unchanged by those projections. This refresh checks repeatability and variety counting; it does not repeat the prior source's separate canonical-control comparison or approve the 12-cycle window, quality threshold, lifts, weights/floor.

The next active-effects candidate still requires tentative player preflight, a single committed month snapshot, project-frozen standards, per-release-age-month factor ledgers, exact cents, rejection rollback and named-source/missing-Core migration. Keep it as a separate DESIGN experiment before an adoption handoff. No active-effects handoff is sealed by this result.
