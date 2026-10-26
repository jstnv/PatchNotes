# First new Contract type — source feasibility v1

2026-10-18 (America/Los_Angeles). **Read-only source review; no simulation, new rule approval, or gameplay edit.** Repository `main` at `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, with preexisting uncommitted changes. The file hashes below identify the inspected working source rather than claiming HEAD alone contains it.

## Setup and assumptions

- Question: which first new Contract type can demonstrate the approved extensible foundation while preserving the five publisher flows and deferring final balance?
- Inspected the current definition, challenge, offer/settlement, chooser, checkpoint and Studio-only Continue code. No generated starting state, seed, policy, command limit or release limit applies because no headless experiment ran.
- Current rules and the [2026-10-18 implementation evidence](../../findings/queue-20261018-v1/README.md) are the baseline. A proposal does not alter them.

| Working source | SHA256 |
|---|---|
| `patch-notes/scripts/contracts/contract_definitions.gd` | `fe44f875af7670beee5039cbcd2d3746c89d5345eb6e9427ab96aa5015e81e94` |
| `patch-notes/scripts/contracts/contract_challenges.gd` | `6be5f579db1cc556522ffd00d772fccd3ee1282a9eef0d423448af6bf54114a9` |
| `patch-notes/scripts/run_state.gd` | `eb18befdf9cf621e073b509b24a3aa792e34ff4b510acdea19310110969b5925` |
| `patch-notes/scripts/persistence/studio_checkpoint.gd` | `b86c5c1b832227481f11f0fd2b292b493a32af80b4eeee8e4bb32b0a279215dd` |
| `patch-notes/scripts/persistence/checkpoint_schema.gd` | `581ede912e685b52addce53a5824e822d7e58a89b6e137b6e334e446adccddcd` |
| `patch-notes/scripts/persistence/checkpoint_coordinator.gd` | `0ed77e3b1bee498ee63a70e81bc370036e256cb888e7138ac046ce077dc8d374` |
| `patch-notes/scripts/phases/studio_phase.gd` | `fde82e339b30265fcba366f071fa13395e99a97ee22ca811f86ca0d1f32b486c` |
| `patch-notes/scripts/phases/contract_phase.gd` | `a5be5cfc7a865e15dfc2e5c84583d764e0bd1cdaba2e29801c364b0b2b6266a2` |

## Findings

1. `ContractDefinitions.built_in_ids()` contains exactly the five publishers, and `is_valid_definition()` requires a `publisher_id`. One-hand definitions are numerically valid, but no one-hand live flow was verified here. A truly independent client needs an explicit source/kind model; assigning a fake publisher ID would misstate player-facing identity.
2. `RunState` stores Ironclad, SideStreet entitlements and other publisher offers in three distinct paths. `get_active_contract()`, ownership, chooser, acceptance, final settlement and `get_completed_contract_count()` traverse those paths directly. A new offer family cannot be added by a definition entry alone.
3. `get_completed_contract_count()` controls Starwave qualification; checkpoint validation independently reconstructs its prior completed-Contract count. Counting an independent brief there would change a publisher gate. Preserve the current gate until separately approved.
4. Studio chooser and acceptance UI branch among Ironclad, SideStreet and publisher quotes. A client brief needs truthful offer copy and routing rather than publisher-browser labels.
5. Checkpoints enumerate current offer containers and validate known Contract IDs/receipts. Active Contracts are not saved. A new type needs a typed, versioned offer/result record, exact once-only finance validation, an explicit old-save policy and the same Studio-only Continue boundary.
6. A next-release commission would require a commitment spanning project creation and launch, unlike today's Contract hands. Deadline, cancellation, failed launch and migration behavior are not currently defined.

## Recommendation and limits

Recommend a **single, optional independent cash brief** as the first design candidate: one ordinary Contract hand, a persistent offer after a release, completion payment, and no implied publisher standing. This is a proposal for the player promise and a narrow new offer family, not an approved payout, target, challenge, unlock, or implementation. [Comparison and open rulings](NEW-TYPE-PROPOSAL-2026-10-18-v1.md).

No simulation was run because the first choice is the contract's purpose and lifecycle. Once those rules are selected, a separate source-pinned plan can test legal one-hand routes and economics with declared seeds, policies, limits and stopping conditions. The review establishes code seams, not feasibility of any amount or score target.
