# Publisher Reputation and Contract types — ownership boundary v1

2026-10-18 (America/Los_Angeles). **PROPOSED thread boundary and design questions; no reputation rule, amount, contract type, or implementation approved.** The user wants to begin work toward publisher-reputation Contract types and asked whether this belongs here or in a dedicated Publishers thread. The independent cash brief remains the selected *first type direction* under [the separate decision](NEW-TYPE-DIRECTION-2026-10-18-v1.md).

## Current evidence

- `main` HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; inspected working source includes uncommitted changes. Source identities: `publisher_catalog.gd` SHA256 `45bf1aca89ba8ce0dda279508963c6c233715b6a5027abe6b99717e70d7494e5`; `publisher_browser.gd` `81b08d5640936944634ba176af64f0e44eb4c0ee95c391b07e22c53b5656305f`; `run_state.gd` `eb18befdf9cf621e073b509b24a3aa792e34ff4b510acdea19310110969b5925`; `studio_checkpoint.gd` `b86c5c1b832227481f11f0fd2b292b493a32af80b4eeee8e4bb32b0a279215dd`.
- `PublisherCatalog` has five identities, names, personalities and offer descriptions. `RunState` stores unlock flags, offer/result history and Promotion, but no publisher-reputation value or reward event. `PublisherBrowser` displays unlock/availability, not a relationship score. The `FounderProfile.reputation_events` field belongs to the separate Founder system and is not publisher standing.
- The current [publisher/Contracts authority](../../design/publishers-contracts.md) marks wider publisher reputation, revenue share, recoupment, exclusivity and control OPEN. The older local implementation authority explicitly deferred Publisher Reputation and Studio Prestige. No current numerical reputation model should be inferred from those historical mentions.
- Contract outcome identity is already immutable by offer ID and its reward settles once at completion. A future reputation award still needs its own typed, persisted, once-only ownership and old-save policy; cash/Promotion proof does not establish that behavior automatically.

## Recommended ownership

| Owner | Design responsibility | Keeps out of its scope |
|---|---|---|
| **Contracts thread (this folder)** | Define each playable Contract type: offer source, accepted promise, hand or release obligations, success/grade evidence and the exact committed outcome a publisher may consume. The independent cash brief emits no Publisher Reputation by default. | A global/per-publisher reputation ledger, progression effects, unrelated publisher UI and numerical reputation policy. |
| **Dedicated Publishers design thread (recommended)** | Decide per-publisher versus global standing, initial state, event rules, caps/decay, losses, unlock/economic effects, visibility and checkpoint/migration policy. Own its own folder and handoff. | Rewriting Contract hand/scoring rules or this thread's files. |
| **Implementation thread** | Reconcile the two approved handoffs into canonical source in one coordinated gameplay slot; verify exactly-once cross-system settlement and old-save behavior. | Promoting trial numbers or a design candidate into authority. |

Do not create or edit another design thread's folder from here. This document is a seed for a dedicated Publishers thread when the user opens one. Shared `TODO.md` and design authority remain unchanged while these rules are OPEN.

## Candidate Contract-to-Publisher interface

For a future reputation-bearing Contract, propose a committed outcome keyed by immutable offer ID and publisher ID, with Contract definition/version, accepted terms, completion cycle and the grade or objective evidence needed to adjudicate reputation. A browse, acceptance, rejected hand, uncommitted preview, duplicate callback or old completed result must not generate a new award. The publisher system should own the reputation ledger and decide the award amount and effect. This is an interface proposal, not a new runtime event or payout rule.

**First reputation-oriented type candidate:** a publisher Relationship Brief that asks for a specific quality promise and yields a reputation outcome when completed. This would follow the independent cash brief. Whether it is one-time or repeatable, uses Contract hands or a next-release obligation, pays cash/Promotion, and penalizes misses is **OPEN**. Existing cash-first Contracts must not gain retroactive reputation merely because the system is introduced.

## Decisions to resolve before a reputation simulation or handoff

1. Is reputation **per publisher** (recommended for distinct relationships), global Studio Prestige, or both as separate ledgers? They must not be silently conflated.
2. Which events earn reputation: only new Relationship Briefs, future completions of existing publisher Contracts, game releases, or a selected combination? Define the old-save boundary.
3. Is an unmet promise zero gain, a loss, or a separate Contract-only missed bonus? Keep current cash/Promotion guarantees intact unless separately approved.
4. What can reputation do: unlock additional offers, change cash/advances, affect Promotion, or provide purely visible standing first? Exact thresholds, caps, decay and economic effects remain OPEN.
5. Which first reputation Contract promise is interesting and attainable under real legal cards/releases? After selection, predeclare source revision, legal starting states, policies, seeds, measures, command/release limits and failure conditions for bounded simulations.

No headless simulation ran for this boundary review because there is no selected reputation state, award rule or Contract promise to test. The next step is a Publishers design ruling and a Contract-type specification, then source-pinned experiments. A simulation result alone will not approve any reputation value.
