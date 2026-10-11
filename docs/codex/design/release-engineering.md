# December demo, checkpoints and release gates

LOCKED product authority§62; current Tasks10–14. Godot4.7.1, standalone Windows x86_64 EXE/PCK demo. Steam/depot/SDK/achievements/cloud save deferred. Working Patch Notes Demo/JooceBox Studios labels await final packaging review.

## Studio checkpoint contract (implemented locally; acceptance partial)

One automatic Continue slot, committed Studio only: initial creation, return after release/completed Contract dismissal, every committed Studio action including zero-cycle starter purchase. Passive/canceled/failed actions do not replace it. Before departure to development/Contract ensure last committed Studio checkpoint is durable; save failure blocks departure. No mid-phase/hand/active-Contract checkpoint or offline earnings.

Unexpected exit/in-app quit outside Studio discards all work since checkpoint, including Contract advance/unfinished outcomes. Quit explains loss; New Run warns before replacement. Loading restores state without callbacks, repeated payouts/settlements/refills/creation grants.

Atomic versioned current generation with previous valid backup; validate schema/references/hash before restore. Preserve corrupt/incompatible bytes and offer explicit safe recovery/new-run path; no silent migration. Lossless integer/RNG encoding and stable run/project/release/offer identities, no executable scene/Variant object deserialization. Deterministic run-owned RNG required; run-owned streams now replace phase-local randomization in active runs.

2026-10-09 current compatibility: Education revision `19e79e7fdd6378fc80abfbade73f63943014e43ad88ef0441fe92ac217919127` supports the exact prior Fanbase/Starwave revision `c7f6f3165ea85f7afd5070042d053ce581f84338437640c3e4b6de787c1f5a5b`. Full prior finance replay changes only the revision, finance5→6 and an empty education field; saved v3–v5 previews stay inactive, and Continue leaves original bytes untouched until a new normal checkpoint. Eighteen fresh compatibility processes include seven genuine creation saves and one rich journal with Bank/payroll/Fans/Promotion. [Education verification](../logs/2026-10-09-education-implementation-v1.md). Unsupported older content remains incompatible and its original bytes/backup are preserved; no retrospective Fan reconstruction. [Fanbase verification](../logs/2026-10-09-fanbase-integration-v1.md), [Starwave verification](../logs/2026-10-09-starwave-implementation-v1.md). This supersedes the historical review2-only exception that accepted the immediately preceding identical-field format; that exception remains historical evidence in the [Genre implementation record](../logs/2026-10-08-genre-rating-implementation-v1.md).

[Archived Task10 full specification](../archive/studio-checkpoint-spec-v1.txt) preserves envelope, field map, atomic protocol, fixtures, A01–A12 and bounded implementation order. Its old six-card-only start/starter-spending/no-finance fields are superseded. Mandatory current additions: specialty/owned union, Task31 traits/once-only financing identity, finance schema6 original bill/late/payment and education provenance, immutable actual monthly rent, Bank schedule schema1, employee roster schema1/payroll contracts and versioned canonical traits (current6)/project-owned Lean savings, credit policy/history/processed month, all per-title age/organic/active Awareness/campaign/earned/settled records and payout IDs. [Task29 addendum](../../../patch-notes/analysis/task29_finance_save_contract_v1.txt), [Task33 addendum](../../../patch-notes/analysis/task33_finance_save_contract_v1.txt). Reconcile exact current fields before coding; do not claim old field audit applies to HEAD.

## Packaging, settings and startup state

Task11's exported two-game/Bank/Continue route and final repaired-export confirmation passed on the pinned pre-Fanbase source, with2,483 independent captured-state/finance checks and clean repaired interaction logs. [Dated evidence](../logs/2026-10-09-queue-execution-v1.md). New Fanbase/Starwave/Education graphical startup and actual exported interaction are deferred to an overnight task at the user's request; old export evidence does not verify newer gameplay. Re-export current runtime with verified official matching templates/version/hash, runtime include/exclude manifest and final artifact hashes. Exclude analysis/logs/debug captures/docs while preserving actual runtime resources. No clean-machine/release-readiness claim from editor/headless checks.

Task12 settings/input/display/audio-bus framework now committed in4f5aa30 and source-verified: mouse/keyboard, visible focus/confirm/back, default1280×720, minimum1152×648;900×600 unsupported until fixed. Reversible windowed/borderless mode, timed confirm/revert, Reset Defaults, separate settings persistence, Master/Music/SFX volume/mute. The user-selected Version A WAV soundtrack and requested original card tap/removal whoosh now have implemented cues, provenance and credits; see [presentation evidence](../findings/card-presentation-v2/README.md). Audible playback/mute, mix and device-latency acceptance remain OPEN. Fresh settings suite passes; historical render/relaunch checks are historical evidence.

Task13 startup Retry/Quit/local diagnostics and the one-command gate are implemented locally; Task10's native A01–A12 matrix is complete at its recorded source. [Matrix](../findings/queue-completion-v1/CHECKPOINT-MATRIX.md), [implementation](../logs/2026-10-08-queue-completion-v1.md). Audible music/SFX and exported acceptance of newer gameplay remain separate. The gate's `--defer-graphical-startup` mode records headless suite/import/export/package/startup success separately and leaves full automated and release-ready flags false until their remaining gates pass. Missing/invalid data recovery preserves valid checkpoints; no remote telemetry.

## Required verification before release

Focused tests plus all maintained verifiers with error-marker scan, clean-profile current package/resource inspection, exported initial Studio/release/two-game and Continue smoke. Corrupt/incompatible checkpoints, torn-write/backup recovery, missing ledger, deterministic next choices, payout/settlement-once and concurrent-title reload. All essential actions/input/layout at supported resolutions; display revert/settings relaunch; approved audible music/SFX/mute and credits. Tests listed here are acceptance requirements, not claimed passed.

Keep art/audio inventory and human external balance/platform playtests distinct from automated scene checks. See [audit](../findings/migration-audit-2026-10-06.md), [TODO](../TODO.md).

[Historical checkpoint/Contracts verification](../findings/2026-10-07-checkpoint-contracts-implementation-v1.md): 42-field audit, combined83-suite gate and two seven-process restart sequences. Current status is the later matrix and dated integration evidence above; C5 still needs exported next-launch Promotion consumption/restore.

## Research checkpoint extension — 2026-10-08

Local content revision now includes research1/traits4. Capture/hydration maps the ordered acquisition history, stable entry IDs, admission cycle, nominal/discounted installment payments, completion ownership and Resourceful window claims. Validation reconciles catalog prices and finance sources, rejects orphan/malformed payment histories and unproven trait claims. Seven separate processes verify admission, constructed partial progress and completion without repeated payments. [Execution](../logs/2026-10-08-feature-research-resourceful-v1.md). Existing incompatible saves are preserved through recovery; no silent migration, exported interaction or broader Task10 closure is implied.

## Optional isolated headless verifier lease — 2026-10-09

`tools/release_gate.py --isolate-checkpoint-writer` runs each maintained verifier through an inherited findings-owned wrapper. Fresh Coordinator stores retain their validator and isolated user directory, using the same real TCP lease/collision/release rules on47733. Existing verifier-owned leases stay under their verifier's control. The default mode still requires production62741 to be free; this option neither closes nor interacts with an existing game. Helper/original/wrapper hashes and instrumentation limits are recorded. Runtime and exported package files are unchanged by instrumentation.

Focused verification covered four native processes, including actual collision/release and the existing Genre-owned lease; held-production and held-test-port preflights both behaved as required. This mode does not test production62741 acquisition in wrapped Coordinator cases. Unmodified exported headless smoke reaches the Main Menu only; it does not prove save/Continue interaction. Continue to use the separately required overnight actual exported acceptance. [Tooling evidence](../findings/release-gate-writer-isolation-v1/result.json).


## Current integrated headless gate - 2026-10-09

Fanbase, Starwave and Education pass all104 maintained suites, clean import/release export,214-entry PCK audit and headless EXE Main Menu startup on the final frozen source. [Exact result, artifact hashes and instrumentation limits](../findings/release-gate-education-v4/README.md). This run used optional isolated test leases; the existing game was untouched. Full automated and release-ready flags remain false because graphical startup, actual newer exported interaction and approved audio remain outstanding. No Computer Use or overnight automation was started.

## Overnight control dispatch — 2026-10-09

The user has now authorized desktop acceptance. Fresh current-source export and225-entry PCK audits pass, but the supported desktop launcher returns `ShellExecuteW returned 5` (access denied). This supersedes the user-preference deferral above; exported interaction remains open due to the launch blocker. [Exact attempt and retained artifact manifest](../logs/2026-10-09-overnight-export-attempt-v1.md). No human playtest or release-readiness inference.

## Cult content boundary and credits compatibility — 2026-10-10

New checkpoint rules use traits7/cult1 and derive initial Fan history from validated saved traits. Both supported pre-Cult and pre-education shapes retain inactive Cult. Audio credits are excluded from new content hashes; legacy hashes are recomputed with either verified historical credit-file hash while retaining every gameplay JSON hash. This repairs rejection of exact education-preview fixtures following the soundtrack credits update. [Verification](../findings/cult-following-t8-v1/README.md); export/interactive acceptance remains separate.
