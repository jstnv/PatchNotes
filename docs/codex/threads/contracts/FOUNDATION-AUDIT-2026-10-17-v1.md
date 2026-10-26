# Contracts foundation scope audit v1

2026-10-17 (America/Los_Angeles). **Read-only scope audit; no new foundation rule or gameplay implementation approved by this note.** The user asked to stop balance work and implement the Contracts foundation. Repository `main` HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f` has extensive concurrent uncommitted work. Contract runtime files inspected here have no local diff. Preserve that work and the single overlapping gameplay implementation slot.

## Already present in current source

- Five publisher profiles in `patch-notes/scripts/publishers/publisher_catalog.gd`; Ironclad, SideStreet, Crown, Neon and Starwave offer rules are represented in `patch-notes/scripts/run_state.gd` and current publisher/Contract classes.
- `patch-notes/scripts/contracts/contract_state.gd` holds immutable offer identity, eligible pool, hands, score/result, payout commit and trial terms. `publisher_trial_terms.gd` stores current Crown/Neon/Starwave terms and completion calculators. `simulation/contract_session.gd` supplies the shared command/draw/action boundary without presentation dependencies.
- Studio checkpoint mapping and once-only payout/Promotion behavior have prior local evidence. The current [TODO C5 entry](../../TODO.md) still marks the complete current-build exported presentation/Continue/rollback matrix **PARTIAL**, so the user's report that implementation is done should not be conflated with verified C5 closure without new evidence.

## Scope choice needed before code changes

1. **Extend the framework for later Contract types.** Candidate foundation: explicit versioned Contract definitions and effect/obligation identities that can represent future publisher deals without changing the five current offers or inventing revenue share, recoupment, exclusivity, reputation or control values. Acceptance would require exact parity for current offers, rejection atomicity, Studio-only checkpoint compatibility and replay across source changes. The schema, first future deal and migration policy are **OPEN**.
2. **Finish the existing publisher flow.** Complete the [C5 exported acceptance handoff](HANDOFF-C5-CROWN-ROUTE-v3.md), fix only defects found, and verify the current integrated build at both sizes, keyboard, Continue and rollback. This is an execution/verification scope and does not need new Contract balance rules.

The latest user instruction removes balance tuning from the next work. It does not specify which foundation direction or approve the previously OPEN commercial systems. Do not silently introduce new payouts, contract eligibility, revenue share, recoupment, exclusivity or control while resolving that choice. No TODO, central design authority, gameplay, tests, assets or configuration changed in this audit.
