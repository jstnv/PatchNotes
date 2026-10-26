# Publisher implementation intake reconciliation

2026-10-23 (America/Los_Angeles). Read-only source/status review; next scope **PROPOSED**.

## Verified state

User requested checking what PN Implementation finished and selecting the next publisher step. Read CURRENT_STATE, TODO, README, publisher design authority, implementation intake/log, Contracts decision packet and overnight handoff. Inspected branch, HEAD, status and diff. Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; before these notes, 112 tracked modified paths and 1,314 untracked status entries. Existing edits and `.codex-godot-temp` preserved.

[TODO](../../TODO.md) records P1-P4 **DESIGN intake review COMPLETE; adoption OPEN**. [Implementation assessment](../../findings/overnight-market-20261022-v1/PUBLISHER-INTAKE.md) explicitly says no private publisher code was adopted. Current `ContractDefinitions.built_in_ids()` lists the existing five work offers. Targeted inspection of RunState, StudioCheckpoint and Contracts source finds no proposed relationship/deal ledger. The existing `PUBLISHER_INVESTMENT_CENTS` is Ironclad's payout budget, not relationship Investment capacity.

PN Implementation also corrected the shared comparator's executed market-query identity. Its [retained comparison](../../findings/overnight-market-20261022-v1/support-comparison-final/comparison.md) now accepts the immutable support pair. The old decision packet's comparator-blocked statement is historical on this point. No frozen bundle was changed in this review. The broader Market/build work is documented in [CURRENT_STATE](../../CURRENT_STATE.md) and its [session log](../../logs/2026-10-22-market-and-overnight-v1.md); those test results were not rerun here.

The PN Implementation chat was inspected read-only: idle, latest turn marked interrupted, with final documentation updates present. Its completion scope is therefore taken from the saved source and scoped intake, not inferred from chat status.

## Reconcile with our overnight evidence

The intake requests legal failed milestones and expiry routes. Our later [overnight finding](PUBLISHER-OVERNIGHT-FINDINGS-2026-10-22-v1.md) already supplies two both-target misses, full-commission recovery and positive post-expiry earnings; reuse those bounded results. Review-only/unit-only misses and positive earnings across exact ages 23/24/25 remain open. Three second-support routes still fail checkpoint export in the frozen private candidate. Its observer atomicity, playable quote and ownership-aware finance gaps remain open.

[Renewal v4](PUBLISHER-RENEWAL-AND-FAILURE-PROPOSAL-2026-10-22-v4.md) is a proposed replacement for the old numeric renewal gate, including qualification at capacity 100. It has not been implemented or approved. Successful arithmetic and campaign evidence do not change that status.

## Recommended next slice

Prepare a narrow **P1 relationship-foundation adoption handoff** before P2-P4 gameplay:

- Separate Reputation and Investment records by stable Studio and publisher identity; Founder/operator changes do not transfer relationships.
- Typed, versioned committed events with exactly-once identity and deterministic reconstruction. Existing cash Contracts/results award no automatic or retroactive standing.
- Explicit predecessor migration to empty/zero relationships, strict validation, Studio-only save/Continue and unsaved rollback.
- Acceptance: independent Studio/publisher records; duplicate/reentrant requests; rejection with no partial mutation; exact cold restore; known-old-save migration; malformed/forged history rejection preserving the previous valid save; unchanged existing Contract payouts/challenges and RNG.

Status **PROPOSED**, not queued or approved by this review. Keep gates, award sizes, fees, support terms and rollout separately proposed. Subsequent order: relationship-bearing offer integration, commissioned games, then support/renewal. The selected independent-client cash Brief remains a separate first-new-contract commitment; P1 does not silently replace it with SideStreet P2.

In this design thread, the next deliverable can be the P1 schema/API/migration specification and a current-source private candidate with focused persistence evidence. PN Implementation owns canonical adoption after the corresponding ruling and handoff. No additional broad balance sweep is needed to prepare this structural slice.

## Commands and source pins

Read-only commands: `git branch --show-current`, `git rev-parse HEAD`, `git status --short`, `git status --porcelain` grouped by status, `git diff --stat`, `git diff -- tools/compare_simulations.py`; targeted `Get-Content` and `rg` on the cited documents and canonical Contracts/RunState/StudioCheckpoint; SHA256 via `Get-FileHash`.

| Canonical file | SHA256 |
| --- | --- |
| `patch-notes/scripts/contracts/contract_definitions.gd` | `fe44f875af7670beee5039cbcd2d3746c89d5345eb6e9427ab96aa5015e81e94` |
| `patch-notes/scripts/run_state.gd` | `af4a6e2eeda2015337bf3f0f666a5136719edd4154b141416bef8f5e50b8a464` |
| `patch-notes/scripts/persistence/studio_checkpoint.gd` | `38d534d5e620f838836bd7722c61ddf79e68bd663794f960a04469b617b49ba6` |

Source/status reconciliation: complete. New gameplay tests/simulations: **NOT RUN**, unnecessary for this documentation review. Changed only this session log and the thread README. Shared TODO, implementation authority, gameplay, candidate code and player saves unchanged. No commit, push, dispatch or release-readiness claim.
