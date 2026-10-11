# Starwave matched Game 4 continuation v13: predeclaration

2026-10-09 (America/Los_Angeles). **Read-only proposed evidence**, not a change to the approved $0/$2,240/0-Promotion Starwave pilot.

## Fixed source and inputs

Use the complete native-v3 Starwave source pin from [source-manifest-v3](../../../findings/starwave-implementation-v1/source-manifest-v3.json), main HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`, original manifest SHA-256 `8922fd57eac43ec6ec04160bce01ca8f9712d4c05d396e7ebff721741953e8db`. The [recovery record](../../../findings/starwave-implementation-v1/source-pin-recovery-v3.json) verified the full pin. Copy the same selected runtime files as v12 into a **new** disposable project, verify their hashes before and after every process, and install only analysis scripts there. Do not execute Godot against the repository, the original pin or the v12 disposable copy.

Use exactly three genuine successful [v12](../sim-v12/README.md) before-Starwave checkpoint payloads. Each v12 attempt has `native_valid=true`, `driver_failure=false`, an earned Starwave offer, three prior completed Contracts and three releases at cycle 54. Pin these exact input bytes:

| Cohort | Seed | Checkpoint payload SHA-256 | Cash at cycle 54 |
|---|---:|---|---:|
| Action | 1104 | `61f1c69c203c9e671e18fc749abac267b368ec3ac91e6b14139affa2db25d335` | $16,847.67 |
| Puzzle | 4417 | `8c7c42f0edc205eefda55959d7e67f66fd1da0208e4160abf60a4ba972f91381` | $15,632.65 |
| Racing | 1104 | `dde276dc491b4d5aff1b395f3db86776fae4839e5b98a28cef5ef3c6ce09559c` | $17,761.06 |

Before either arm, validate and hydrate the same payload independently; compare its re-captured typed state with the input. Do not reuse a mutated RunState between arms. Capture the initial RNG, finance, owned pool, Fans and pending Promotion. Abort a cohort as a source/input failure if hashes, hydration or initial state differ.

## Exactly two legal arms per cohort

1. **Starwave:** accept the earned pending offer in the native Studio chooser; commit three actual optimizer-selected four-card hands with the current finite Feature/renewable Pass and run RNG rules; dismiss the real completion result. Record every draw, selected ID, Scope/Core, exact completion numerator, receipt and cycle. Then start Game 4.
2. **Skip Starwave:** leave the pending offer untouched and start Game 4 immediately from a second hydration of the same payload. No three-cycle placeholder, artificial cash receipt, debt, offer, Promotion or work is added.

Both arms use the same inherited v12 synergy/mixed/QA route policy and the same project Genre as the Studio specialty. Game 4 uses deterministic route seed `cohort_seed + 1,500,000`; Game 5 uses `cohort_seed + 2,000,000`. The inherited native route fixes the Review variance roll through its existing verifier hook in both arms; no release result is directly written. Use the same card selection, redraw, priority and launch choices wherever legal. No optional new Store, Bank, hire or campaign action after the checkpoint; already scheduled rent, payroll, Bank and sales continue normally.

## Calendar endpoints and validity

Game 4 should launch at cycle 75 with Starwave and cycle 72 without it, if both legal routes complete under this policy. Record actual cycles; never force a launch or pad a timeline. Take exact state snapshots at common completed cycles **75, 77 and 79** in both arms, including cash, original overdue obligations, credit, earned/settled portfolio sales, Game 4 release data, Game 5 project progress, pending/consumed Promotion and finance journal. Continue through legal Game 5 actions only as far as needed to capture cycle 79; do not infer missing later state from a blocked or failed route. At cycle 75 the skip arm has more Game 5 work completed by design; report that difference beside cash.

Each arm is a valid matched continuation only if it starts from identical captured checkpoint bytes, uses legal native actions, reaches all three endpoints, has a valid finance ledger, and records no engine errors or source drift. Preserve every failed attempt with its first stop reason, last legal state, command/log and source hashes. A one-arm success is not a paired estimate. Compare the two arms within each cohort at each common cycle; do not pool different specialty cash levels or mistake Starwave's receipt for free profit. Report direct cash, settled sales, debt and work progress separately. No advance sensitivity or final balance recommendation follows automatically.

## 2026-10-09 protocol clarification after adapter failures

The initial v13 attempt had a GDScript parse error, preserved in `action-1104-starwave/`. Repair v2 reached a legal Action Game 4 launch at cycle 75, then its partial Game 5 adapter rejected initial priority commit because it omitted the native-v3 route's required priority setup. That output is an incomplete adapter attempt, not a balance result. Repair v3 must copy the exact [native-v3 Game 5 entry](../../../findings/starwave-implementation-v1/native-v3/native-route.json) sequence: seed Design deal/finalization RNGs at `cohort_seed + 2,000,003` and `+ 2,000,004`; if initial priority planning is active, set `_priorities(project)` before committing the draft; then play native `_production_hand` actions without a later manual priority change. Continue the same hand policy only until common cycle 79. This makes explicit the actual seed offsets and priority path intended by the original native route. Run one full Action/Starwave arm as a gate before the other five arms; preserve and diagnose another failure before expanding.

Repair v3 still called `commit_draft()` when initial priority planning was already complete in the Game 5 predevelopment action. It stopped at cycle 76 with a valid Game 4 launch and finance, and is excluded from comparison. Repair v4 restores the native conditional: both `set_priority_distribution()` and `commit_draft()` run only when `is_initial_priority_planning()` is true. This is an adapter correction, not an alternate gameplay policy or a change to endpoints.
