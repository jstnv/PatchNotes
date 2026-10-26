# Founder Legacy foundation implementation session

**Date:** 2026-10-17 (America/Los_Angeles). **Branch/HEAD:** `main` / `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`. The checkout was dirty before and after this work, with concurrent AI Competitors and unrelated source/docs edits. No commit, push, release claim or canonical gameplay adoption was made.

## Work and exact files

The user authorized a foundation implementation and deferred balancing. To preserve the active overlapping AI Competitors implementation, this thread created [private version `founder-foundation-v1b`](simulators/founder-foundation-v1b/) from base identity `bf55f6242734a85c384566137c9eca97a3251d2d9d422e57cf57c9504eedcb3f`. An initial snapshot to `founder-foundation-v1` failed because the shared source changed during capture; that incomplete directory is retained as failed evidence and is not the candidate. The completed candidate changed only its `project/` copy:

- `scripts/legacy/ownership_book.gd` and its generated UID: typed equal-share books, >50% control, acyclic corporate ownership, pure primary/secondary plans and exact consideration legs.
- `scripts/legacy/founder_profile.gd` and UID: career history, one active operator, safe departure/activation, once-only milestones and nonspendable financing summaries.
- `scripts/legacy/legacy_codec.gd` and UID: exact decimal-string checkpoint encoding/decoding for shares, cents and cycles.
- `scripts/debug/verify_founder_foundation.gd` and UID: synthetic focused verification.

The [candidate decision](2026-10-17-foundation-candidate-decision-v1.md), [sealed handoff](handoffs/foundation-v1b/HANDOFF.md), this log, the thread README, and the minimal shared `docs/codex/TODO.md` entry were updated. The sealed candidate identity is `3a4f963ec2a7b2ff26480b3d362ecb2e6b61fc8b9f8c54ee88d05888809f4ac3`; the handoff reports canonical drift and zero overlapping changed paths at packaging.

## Checks and results

- Godot 4.7.1 headless focused verifier, after isolated project import and isolated `APPDATA`/`LOCALAPPDATA`: [log](checks/foundation-v1b-focused.log), **27 checks, 0 failures**. The first unprofiled Godot invocation crashed before script execution because its default profile was inaccessible; the isolated profile resolved this. An intermediate naive JSON round trip failed two checks because number types were not preserved; the explicit codec fixed them before final evidence.
- `simulate.py run --variant ... --config docs/codex/threads/simulation-engine/examples/finite-fixture.json --output .../foundation-v1b-campaign-03 --timeout 240`: [report](sims/foundation-v1b-campaign-03/run-report.json), **completed**, seed 4417, 36 commands, 14 cycles, two releases. This is unchanged single-Studio card-flow regression only.
- `simulate.py replay --bundle .../foundation-v1b-campaign-03 --case action-4417 --output .../foundation-v1b-replay-03 --timeout 240`: [replay report](sims/foundation-v1b-replay-03/replay-report.json), **passed**, final state digest `b7bef12630cc4b93c13b0ee23634e0173bf3ee170567882c0f67e9fc723d6d8f`.
- `simulator_variant.py handoff` created [packet](handoffs/foundation-v1b/HANDOFF.md): **8 added files**, baseline drift true, zero overlapping changed paths, one pinned successful run bundle.

## Boundaries and next work

This is a tested **candidate foundation**, not an in-game legacy loop. `RivalWorld` in the concurrently edited canonical source still has a fixed `player: RunState` and no founder/operator checkpoint. Ownership plans do not settle money and cannot be applied without an atomic world-finance transaction. The next integration slice must reconcile AI World source, seller consent, buyer cash/due validation, studio finance journals, whole-world persistence/rollback and a safe founder-to-AI handoff. Valuation, startup financing, CEO mandates, offers, subsidiaries and milestone presentation remain later slices; numerical balancing remains deferred by the user. No Drive calls were needed.
