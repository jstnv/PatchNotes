# December demo, checkpoints and release gates

LOCKED product authority§62; current Tasks10–14. Godot4.7.1, standalone Windows x86_64 EXE/PCK demo. Steam/depot/SDK/achievements/cloud save deferred. Working Patch Notes Demo/JooceBox Studios labels await final packaging review.

## Studio checkpoint contract (implemented locally; acceptance partial)

One automatic Continue slot, committed Studio only: initial creation, return after release/completed Contract dismissal, every committed Studio action including zero-cycle starter purchase. Passive/canceled/failed actions do not replace it. Before departure to development/Contract ensure last committed Studio checkpoint is durable; save failure blocks departure. No mid-phase/hand/active-Contract checkpoint or offline earnings.

Unexpected exit/in-app quit outside Studio discards all work since checkpoint, including Contract advance/unfinished outcomes. Quit explains loss; New Run warns before replacement. Loading restores state without callbacks, repeated payouts/settlements/refills/creation grants.

Atomic versioned current generation with previous valid backup; validate schema/references/hash before restore. Preserve corrupt/incompatible bytes and offer explicit safe recovery/new-run path; no silent migration. Lossless integer/RNG encoding and stable run/project/release/offer identities, no executable scene/Variant object deserialization. Deterministic run-owned RNG required; run-owned streams now replace phase-local randomization in active runs.

2026-10-08 bounded compatibility exception: review2 accepts the exact immediately preceding finance5/bank1/employees1/traits5/sales1/contracts3/research1 revision when all data hashes and schemas match. No stored field changes: historical Review standards/scores and sales remain frozen. Continue is read-only; the next normal committed checkpoint records the current revision. Unknown/older data revisions still fail compatibility and preserve bytes. [Verification](../logs/2026-10-08-genre-rating-implementation-v1.md).

[Archived Task10 full specification](../archive/studio-checkpoint-spec-v1.txt) preserves envelope, field map, atomic protocol, fixtures, A01–A12 and bounded implementation order. Its old six-card-only start/starter-spending/no-finance fields are superseded. Mandatory current additions: specialty/owned union, Task31 traits/once-only financing identity, finance schema5 original bill/late/payment provenance, immutable actual monthly rent, Bank schedule schema1, employee roster schema1/payroll contracts and canonical traits v3/project-owned Lean savings, credit policy/history/processed month, all per-title age/organic/active Awareness/campaign/earned/settled records and payout IDs. [Task29 addendum](../../../patch-notes/analysis/task29_finance_save_contract_v1.txt), [Task33 addendum](../../../patch-notes/analysis/task33_finance_save_contract_v1.txt). Reconcile exact current fields before coding; do not claim old field audit applies to HEAD.

## Packaging, settings and startup state

Task11 historical clean-profile templates/export,161-entry manifest and actual Windows D3D12 launch passed; exported interactive two-game path remains unverified. Re-export current runtime with verified official matching templates/version/hash, runtime include/exclude manifest and final artifact hashes. Exclude analysis/logs/debug captures/docs while preserving actual runtime resources. No clean-machine/release-readiness claim from editor/headless checks.

Task12 settings/input/display/audio-bus framework now committed in4f5aa30 and source-verified: mouse/keyboard, visible focus/confirm/back, default1280×720, minimum1152×648;900×600 unsupported until fixed. Reversible windowed/borderless mode, timed confirm/revert, Reset Defaults, separate settings persistence, Master/Music/SFX volume/mute. Approved music/SFX, cues/license/credits and audible playback remain BLOCKED; no approved set located. Do not ship placeholders to satisfy the gate. Fresh settings suite passes; historical render/relaunch checks are historical evidence.

Task13 dependency paragraph still says schema/manifest missing, but Task10 spec and historical Task11 manifest exist. Current typed checkpoint/Continue runtime and refreshed package verification are implemented locally. Remaining blockers are A01–A12 acceptance breadth, approved audio and exported interactive smoke. Split bounded startup/recovery/gate coding around these dependencies. Runtime missing/invalid data must show retry/quit/local diagnostic without damaging valid checkpoint; no remote telemetry.

## Required verification before release

Focused tests plus all maintained verifiers with error-marker scan, clean-profile current package/resource inspection, exported initial Studio/release/two-game and Continue smoke. Corrupt/incompatible checkpoints, torn-write/backup recovery, missing ledger, deterministic next choices, payout/settlement-once and concurrent-title reload. All essential actions/input/layout at supported resolutions; display revert/settings relaunch; approved audible music/SFX/mute and credits. Tests listed here are acceptance requirements, not claimed passed.

Keep art/audio inventory and human external balance/platform playtests distinct from automated scene checks. See [audit](../findings/migration-audit-2026-10-06.md), [TODO](../TODO.md).

[Current checkpoint/Contracts verification and remaining gates](../findings/2026-10-07-checkpoint-contracts-implementation-v1.md): 42-field audit, combined83-suite gate and two seven-process restart sequences.

## Research checkpoint extension — 2026-10-08

Local content revision now includes research1/traits4. Capture/hydration maps the ordered acquisition history, stable entry IDs, admission cycle, nominal/discounted installment payments, completion ownership and Resourceful window claims. Validation reconciles catalog prices and finance sources, rejects orphan/malformed payment histories and unproven trait claims. Seven separate processes verify admission, constructed partial progress and completion without repeated payments. [Execution](../logs/2026-10-08-feature-research-resourceful-v1.md). Existing incompatible saves are preserved through recovery; no silent migration, exported interaction or broader Task10 closure is implied.
