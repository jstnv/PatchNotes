# M3b — Contracts, remaining Studio actions and checkpoint continuation

2026-10-11. **IMPLEMENTED locally, bounded verification.** Authorized by the user's “go ahead.” Dirty `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`. Existing work and `.codex-godot-temp` preserved. No TODO edit, commit, push, export or computer control.

## Changes

Paths below are relative to `patch-notes/`.

| File | Responsibility |
|---|---|
| `scripts/simulation/contract_session.gd` | Scene-free initial deal, priorities, redraw, ordered four-card hand, retained candidates and refill. Versioned commands carry offer ID, accepted sequence, hand count and Run cycle; candidate tokens reject stale/repeated selections. |
| `scripts/phases/contract_phase.gd` | Native Contract presentation delegates those mechanics to the shared module. Views, input, animation and completion dialog remain here. |
| `scripts/simulation/studio_actions.gd` | Exact-quote adapters for Bank borrowing/payoff, education payoff, Specialist hiring and acceptance of all five current publishers. Detached observations expose existing quotes and offers. |
| `scripts/simulation/campaign_session.gd` | Contract lifecycle and dismissal, financial commands, Studio-only simulation checkpoint export/restore, canonical state projection across Continue. |
| `scripts/run_state.gd` | Optional redraw publication callback: replacements publish only after a successful budget debit and before `redraws_changed`. Existing callers retain the default behavior. |
| `scripts/debug/campaign_replay_cli.gd` | Can start from either an explicit fresh-Studio recipe or a source-pinned simulation checkpoint. |
| `scripts/debug/verify_contract_extraction.gd`, `verify_campaign_continuation.gd` | Original/live/headless Contract comparison, direct financial transaction comparisons, continuation, rollback and malformed-state checks. |

No card scoring, Contract terms, hiring/wage values, finance arithmetic, Fanbase rules, Store rules or data ledgers changed. ContractState and RunState remain the scoring, cash, calendar and Promotion authority. Employee training still occurs through existing Design-hand mechanics. No course command or unresolved course value was introduced.

### Commands and boundaries

Existing M3a commands remain. New campaign commands:

- `bank_borrow`, `bank_payoff`, `education_payoff`: `{quote: exact_existing_quote}`; zero cycles, available through Finances in Studio, development and Contracts under existing Run guards.
- `hire`: `{quote: exact_existing_quote}`; Studio only, existing Specialist transaction.
- `accept_contract`: `{kind: ironclad}`, `{kind: sidestreet, offer_id}`, or `{kind: publisher, quote}`. Acceptance retains existing advance and zero-cycle rules; no redraw refill.
- `contract`: `{request: ContractSession.command(...)}` for `begin`, `priorities`, `redraw` or `play`. Candidate selections are ordered token arrays. Existing `contract_deal` RNG draw order is retained.
- `dismiss_contract`: completed Contract only; returns to Studio and refreshes redraws once. Completion alone does not permit saving. No abandonment action.

Contract hands keep their existing two- or three-hand limit, finite-card exhaustion, unselected-card order, Scope/Core calculation, payout and Promotion behavior. Completed hands do not draw unused replacements. Commands reject stale identities/counters, invalid tokens and reentry. Accepted outer campaign events retain deterministic event IDs and before/after snapshots of all nine RNG streams.

One pre-existing bug was repaired: a denied redraw could publish replacement cards and consume RNG despite `consume_redraw` refusing the debit. The new callback publishes only after debit acceptance. A checkpoint-blocked redraw now rejects with cards, tokens, budget and RNG unchanged. This enforces the existing checkpoint rule; it does not add a free action or alter a price.

### Studio checkpoint continuation

`export_checkpoint()` accepts only an idle Studio session. The inner payload is the existing `StudioCheckpoint` DTO. The outer simulation envelope adds a canonical string schema version, source hash, exact Godot version/RNG algorithm, accepted-command sequence and integrity digest. Accepted-command sequence is distinct from the player save generation number.

`restore_checkpoint(envelope, catalog, snapshots)` requires an uninitialized session and validates the wrapper and existing Studio codec. It does not call initial-Studio initialization, refresh redraws, reseed streams, repeat a release, award money or consume Promotion. The terminal signed-64-bit sequence can restore; further commands reject without wrapping.

Completed project presentation objects are excluded from Studio and active-Contract canonical state. Studio and Contract commands have an empty development project identity. The old completed object remains accessible to local presentation/tests, but Continue deliberately discards it. Restored next-project serial, supply and all nine RNG states remain authoritative.

The simulation wrapper is a local test artifact, not a replacement player save file or a new mid-project Continue feature. Player checkpoint storage, writer lease, migrations and the Studio-only Continue boundary are unchanged. CLI usage:

```text
Godot --headless --path patch-notes --script res://scripts/debug/campaign_replay_cli.gd -- --checkpoint=<studio-envelope.json> --tape=<campaign-tape.json> --output=<report.json>
```

Use exactly one of `--recipe` and `--checkpoint`. Definitions and direct state references remain trusted; this is not a hostile-input sandbox or arbitrary-state import interface.

## Verified evidence

Source archive, before/after manifests, exact eight-script turn patch, commands and audit: [m3b-v1](m3b-v1/). [Machine-readable acceptance](m3b-v1/acceptance.json). Individual runs are under `docs/codex/findings/card-presentation-v2/m3b-*`.

| Check | Result and scope |
|---|---|
| Import/parse | Passed after fixing explicit GDScript types; generated UIDs recorded separately from behavior runs. |
| Original/live/headless Contracts | **10 fixtures, 52 matched states**: Ironclad, SideStreet, Crown & Quill, Neon Circuit and Starwave, seeds 51/8191. Compares entire Run, Contract, candidate order, all RNG streams and recorded cash/finance/redraw/Contract/employee signal order. Includes priorities, two-slot redraw in click order, retained cards and every required hand. |
| Contract failure checks | Completed/invalid-token commands, blocked redraw, failed refill preparation and synchronous redraw reentry reject without extra effects. |
| Financial adapters | **9 comparisons** against direct Run transactions, including successful and rejected borrowing, hiring, education payoff and Bank payoff; exact state and signal order match. Education payoff uses explicitly constructed funding, not a balance route. |
| Legal campaign continuation | **37-command prefix, 23-command suffix**: first release, hiring/payroll, pending/completed research, Ironclad, Bank, next project and launch. Restored suffix matches uninterrupted results/state after every command. Includes active-development Bank payoff, 14 reentry checks and malformed/overflow envelope checks. |
| Contract checkpoint continuations | All five publishers accept, deal, change priorities, redraw, complete and dismiss identically after restoring Studio. Completed receipts/Promotion restore exactly. Unsaved Contract acceptance rolls back to the previous Studio snapshot. Publisher qualification is a constructed fixture, not evidence of an earned full campaign. |
| Separate processes | **6 fresh Godot processes, 59 suffix commands**: five Contract continuations (7/7/7/7/8 commands) plus the 23-command campaign continuation. Source/runtime/RNG fences and every recorded outcome/state digest pass. |
| Maintained regressions | Existing 81-command/three-project campaign and 432-step development replay checks pass. Contract/SideStreet/Starwave, publisher offers/cash/Promotion, retained candidates, shared redraw/priorities, ledger, Bank, education, employees and checkpoint suites pass. |
| Native Contract presentation | Both 1152×648 and 1600×900 headless scene fixtures finish animated hands exactly once, show completion correctly and dismiss passively. This is not visual or audible human acceptance. |

Total: **23 focused suites plus 6 fresh-process replay runs**, all exit zero, no unexpected error records, stable source and harness hashes. The audit verifies TODO/data hashes and unchanged HEAD. Existing missing-artwork warnings and two-instance ObjectDB exit warnings remain in some maintained/headless processes; memory-leak freedom and long-running throughput are not certified.

Failed attempts are retained: import type-inference errors; an initial Contract fixture omitted the real Ironclad prerequisite for SideStreet; an initial loan fixture requested credit before two settled sales months. These were fixed in the fixtures/types without changing gameplay eligibility. JSON schema-number integrity and terminal-sequence restore issues were found and fixed during review before accepted disk replays. The first failed parse process was stopped after a subsequent edit, so its source-stability result is false; it is excluded from accepted evidence.

## Remaining work

1. Continuous native Gameplay versus headless campaign comparison across repeated development, Store, Contract, finance and Studio transitions. Current evidence joins bounded component comparisons and headless continuations; it is not that end-to-end proof.
2. A reusable batch scenario runner and interchangeable test/competitor policy adapters, with command budgets and persisted failure tapes. Policy strengths, action priorities, rival cadence and balance remain OPEN unless separately approved.
3. Measure throughput and memory over repeated long campaigns before setting AI simulation scale. These functional runs are not a benchmark.

Live initial Contract dealing is automatic, while headless `begin` is an explicit accepted command; protocol counters therefore differ between those adapters, while gameplay state/RNG comparisons exclude that bookkeeping. Live replacement-view construction after a hand retains the original presentation failure boundary. Arbitrary external mutation inside trusted callbacks is not covered by transaction parity.
