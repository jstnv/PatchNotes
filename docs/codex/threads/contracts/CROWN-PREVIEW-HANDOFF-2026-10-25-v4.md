# Crown Brief grade feedback — implementation handoff v4

2026-10-25. Owner: **PN Implementation**. **APPROVED; handed off through the internal TODO.**

[User approval](CROWN-GRADE-FEEDBACK-APPROVAL-2026-10-25-v1.md) · [exact design and copy](CROWN-GRADE-FEEDBACK-DESIGN-2026-10-25-v1.md) · [matching findings](CROWN-GRADE-FEEDBACK-FINDINGS-2026-10-25-v1.md) · [queue](../../TODO.md)

This supersedes [v3](CROWN-PREVIEW-HANDOFF-2026-10-25-v3.md) only for approval/queue status. Its GF1 evidence and negative fixtures remain applicable. Implement the approved presentation package; preserve rewards. Existing Crown cash Contracts and separate challenge rewards are outside this Brief-specific change.

## Implementation tasks and acceptance

| ID | Status | Required change and acceptance |
|---|---|---|
| GF2 | **handed off — approved** | Add a pure selected-card projection using the same frozen terms, legal card planner and award evaluator as settlement. Validate four distinct current tokens; show raw Scope/four Cores, Work completion, Core balance, limiting factor and highest/lowest ties. Explain the minimum of completion/balance, not their product. Preserve exact floors, over-target values and cap behavior. First hand: provisional score value, one hand remaining, no award yet and actual standing unchanged. Final hand: on-completion award and cap-limited credit. Completed result reads the trusted committed event and says **Brief complete**, including partial Work completion. |
| GF3 | **handed off — approved** | On the final hand only, enumerate legal quartets from the current visible cards through the shared pure planner (at most35 in this pilot). If at least one valid choice exists and every choice requests zero, show: **With these cards, every four-card selection earns 0.00 Reputation.** Suppress for first hand, missing/unsupported/stale/incoherent state or no legal choices. Cap-clipped credit and financial blockers are distinct from a zero score. Refresh on candidate/redraw/state changes; do not select cards or alter play/redraw behavior. |
| GF4 | **handed off — approved** | Derive a quiet reminder from validated ordered Crown Brief completion records: publisher `crown_quill`, kind `crown_quill_brief_completion_v1`, applicable definition and frozen terms. Requested zero increments; requested positive resets even if credited zero. Other publisher/products neither increment nor reset. At count2 display **Last 2 Crown Briefs: 0.00 Reputation earned. Check Work completion and Core balance before your next Brief.** Update the actual count thereafter. Use result Details and existing Crown Brief Studio/offer information. No modal, repeated toast/sound or new durable streak field. At R100 suppress proactive advice, prioritize the cap explanation and retain factual Details. Missing/incomplete/invalid/duplicate/out-of-order history is unavailable; a validated complete empty ledger is zero. |
| GF5 | **approved — invariant** | Preserve the [approved pilot](BALANCED-CRAFT-APPROVAL-2026-10-25-v1.md): two four-card hands, Scope9/Core4, full balance through spread2 fading to zero at6, up to10 Crown Reputation, zero cash/advance/Promotion/Investment. Preserve R100 cap, current exact formulas, Search/hand costs, ordinary redraws, existing offers and other publishers. No pity, consolation, guaranteed R20 cadence, draw changes or forced Research. |
| GF6 | **handed off — approved implementation and verification** | Integrate against current canonical source and current folder/theme/animation controls. Prove query/history display preserves cycle, sequence, finance, standing, used Features, redraw budget, world and RNG. Commit revalidates rather than trusting a displayed quote. Test actual ledger consumption, once-only settlement, old/current Studio restore and cold Continue; native and exported UI at supported sizes with keyboard/focus/Details, animation and financial locks intact. Report human comprehension separately from automated acceptance. |

## Dependencies and adoption sequence

1. Inspect current HEAD, dirty source and implementation queue. Source at handoff: `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, substantial pre-existing edits. HEAD alone does not identify the working runtime. Reconcile against the current campaign-latency, checkpoint, Contract Search and UI changes; preserve their proofs and other thread edits.
2. Use the [sealed Crown runtime packet](handoffs/crown-search-brief-20261025-v1/HANDOFF.md) and [CSB adoption gates](CROWN-SEARCH-BRIEF-HANDOFF-2026-10-25-v1.md) for the underlying Brief path. Feedback implementation is authorized now. Normal Crown catalog exposure retains the existing explicit activation/migration/acceptance gates; do not infer broader activation from this presentation approval. If the underlying path remains private, stage and verify this feedback there and report the exposure dependency separately.
3. Reuse production evaluators and trusted relationship reconstruction. The Python reference is a fixture oracle, not an independent gameplay implementation to copy. Check overlapping `scripts/persistence/studio_checkpoint.gd` and validated history access before adoption.
4. Cache only complete relevant input identity: offer/definition/terms, hand, candidates/selection, scores, standing/cap, sequence and coherent presented state. Invalidate on changes, redraw, restore, new offer and animation transitions. Avoid repeated35-option work every frame; preserve native responsiveness and current validation guarantees.
5. Record exact adopted source, changed files, maintained checks, fresh-process replay/restore, UI/export results and remaining gates. Mark implemented and verified only at demonstrated scope. No new balance approval is needed for these unchanged reward terms; unresolved broader pacing remains a separate design review.

## Matching evidence and mandatory negative cases

The [finding](CROWN-GRADE-FEEDBACK-FINDINGS-2026-10-25-v1.md) pins private source `f7de61169758dcd874972c59e584c7b6a9a36f1fedc4f24b2398f6a2edfdf60f`, mechanics `9dd1e4551338d38894dace6eb98bc635c38b7e6ec47427b4078cf0ccfe8b0bd6`, exact commands and assumptions. It covers36 recorded selected projections,18 completed results,1,260 current-card evaluations,48 constructed cases and603 arithmetic checks. These are offline evidence, not native implementation acceptance. No gameplay patch or new simulator version is included in v4.

- Puzzle4522 Brief2: provisional+2.50 becomes final0 despite Scope9; all35 final choices request0. Reminder appears after the second consecutive zero, then updates to3.
- Puzzle4522 Brief1: all first-hand current choices have provisional0; **no final-hand warning** before the second draw.
- Action/Simulation zero-positive-zero histories: **no consecutive-two reminder**.
- R99.50 full grade: requested10, credited0.50. R100 full grade: requested10, credited0; cap explanation and streak reset. A genuine zero streak at R100 retains Details but no proactive improvement advice.
- Missing or malformed history, duplicate identities, stale projections, selection changes and redraw invalidation must not invent a result or streak. Query repetition must not mutate world/RNG. Preserve negative fixtures and retained failures in implementation receipts.

## Open items outside this queue

Final balance, reliable progression cadence, human comprehension and broader publisher catalog/support/commission decisions remain separate. This handoff changes feedback only. Queueing does not dispatch a chat, merge a variant, commit, push or approve a release.
