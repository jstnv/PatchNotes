# Crown Brief preview — design review handoff v1

2026-10-25. **DESIGN review; no canonical implementation queued.** [Specification](CROWN-PREVIEW-DESIGN-2026-10-25-v1.md) · [source/evidence](CROWN-PREVIEW-FINDINGS-2026-10-25-v1.md). User delegated design work; rewards unchanged and redraw research parked. This is a documentation delta, with no new runtime patch or simulator variant.

| Item | Status | Action and acceptance criteria | Dependencies |
|---|---|---|---|
| Exact selected-hand preview design | **proposed** | Adopt current→projected Scope/Cores, separate completion/balance, limiting-factor text, provisional hand-1 wording and exact final-hand award. No future draws/probabilities or auto-selected cards. | User review of this specification |
| Pure projection query | **proposed; gated** | Four valid current tokens; shared frozen evaluator; correct primary/secondary/synergy and integer floors; separate finance legality; no state, counter, RNG, receipt or exhaustion changes. Repeated previews must be byte/state/RNG inert. Hand-1 zero settlement fields cannot be mistaken for zero score value. | Approved Crown Brief terms and structural adoption design; reconcile current canonical source |
| Existing Contract view integration | **proposed; gated** | Only Crown Brief; preserve cash Contracts and SideStreet. Incomplete selection hides provisional reward; score decrease and limit shown without color alone; raw excess scores retained; animation locks hide stale preview. Revalidate confirmation and refresh after existing redraw/priority actions without changing those rules. | Projection query; current shared UI layout and source |
| Completion and cap wording | **proposed; gated** | Preview agrees with actual frozen settlement on valid final hand. R99/+8.18 displays +1.00 credit; R100 full grade shows zero capped credit, still full result. No duplicate settlement on view/dismiss/restore. | Trusted P1 requested/credited event and unchanged cap authority |
| Acceptance coverage | **proposed; gated** | Replay-derived full/partial/zero and constructed cap/rounding/over-target examples; invalid/stale selection and affordability rejection preserve state/RNG; native/current export at supported sizes; keyboard/Details/animation behavior; human explanation checks. Report each PASS/FAIL/NOT RUN. | Implemented approved scope in PN Implementation; prior CB3 migration/active-rival/atomic rejection acceptance remains required |
| Local design evidence | **implemented and verified — evidence extraction only** | 12 recorded selected-hand projections and eight constructed examples; six final awards match the old frozen campaign results; 16 bounded assertions. No new campaign or UI acceptance claimed. | `studies/crown-preview-20261025-v1/evidence.json` |

## Exact changes and handoff boundary

This packet adds proposed copy, state transitions, pure-query requirements, two annotated wireframes and acceptance criteria. It does not alter the CB2b policy, Crown rules or current gameplay/UI. Retain the [CB2b source and adoption gates](CROWN-TWOHAND-HANDOFF-2026-10-25-v1.md); prior sealed runtime material is historical review input, not a patch to overwrite current canonical UI or persistence work.

Canonical adoption belongs to PN Implementation after explicit approval. Updating the existing Crown DESIGN TODO reference is review routing only; do not promote these tasks to QUEUED implementation, send another chat a message or treat recommendations as approved rules. Current shared To Do List, authority and unrelated entries must be preserved.
