# Starwave first-offer bounded pilot — user approval

2026-10-08 (America/Los_Angeles). **APPROVED ACTIVE/TRIAL design for one playable Starwave offer; not a final balance lock or implementation verification.** The user replied “Sure thing. I approve” to the exact [SW3 proposal](FINDINGS-v13-starwave-proposal.md) and this thread's recommendation: three hands, Scope 14, each Core 7, maximum $2,240 direct cash paid on completion, $0 acceptance advance and 0 Starwave Promotion. The prior [SW1](FINDINGS-v11-starwave-foundation-cards.md)/[SW2](FINDINGS-v12-starwave-earned-rewards.md) studies support a bounded trial, not a universal balance claim.

## Approved trial rule

- Preserve the existing Starwave profile gate: two distinct releases and three distinct committed Contracts. Issue one persistent, non-expiring first-unlock offer when eligible. Pending offers may coexist; only one Contract may be active. Accepting/browsing/dismissing results costs zero cycles.
- At acceptance, freeze the currently owned eligible Primitive Feature IDs, Core Pass eligibility, offer identity and these numerical terms. Later Store ownership does not enter this Contract. There is no abandonment or minimum-completion gate.
- Play three successful four-card hands. Each committed hand uses one productive cycle. Draw seven candidates, select four, retain the three unselected candidates, and draw four replacements before both hand 2 and hand 3. Preserve finite Feature exhaustion, renewable Passes, priorities, synergies, run-owned `contract_deal` RNG and shared redraw rules. Failed or rejected actions change no state.
- Let `H_i` be each resolved Core score in half-units. Let `n = 4×min(Scope,14) + Σ_i min(H_i,14)` for Graphics, Sound, Technology and Design. Clamp `n` to `[0,112]`. Completion is exactly `n/112`; Scope 14 and each Core 7 give full completion.
- Acceptance pays **$0**. Hands 1 and 2 pay **$0**. A committed completing hand 3 pays `floor(224000×n/112)` cents once at the direct-effect stage, before that cycle's sales settlement and bills. Zero completion pays $0; full completion pays $2,240. The completed Contract counts once even when payout is $0. No recoupment, hand-two installment or extra cash transfer.
- Starwave earns **0 Promotion** in this pilot. Do not consume, cap, replace or change Promotion already banked by Crown/Neon; those awards continue through their existing next-successful-launch rule.

## Boundary and evidence

The [current publisher authority](../../design/publishers-contracts.md) records this as ACTIVE/TRIAL. Ironclad, SideStreet, Crown and Neon terms and two-hand behavior stay unchanged. Revenue share, exclusivity, publisher control, campaigns, Store familiarity and final publisher balance remain outside this pilot. Player-selected Neon focus remains OPEN.

[SW1](FINDINGS-v11-starwave-foundation-cards.md) found one legal solvent post-Neon profile checkpoint, 354 native/model parity assertions and 12 completing analysis-only three-hand arms; [SW2](FINDINGS-v12-starwave-earned-rewards.md) mapped 60 scored candidate outcomes to 25 native economic continuations with 87,279 independent checks. The approved formula earned $2,040–$2,240 in those 12 arms and covered the three-cycle cash cost on that route. Other specialty/ownership pools, a low-cash advance rescue case and player preference remain untested. These limits do not turn the trial into a final numerical lock.

Current gameplay has a Starwave profile but no offer or third-hand runtime. `ContractState.REQUIRED_HANDS`, Contract screen text and typed checkpoint validation still assume two hands. The [implementation handoff](HANDOFF-STARWAVE-v1.md) is now actionable for the main implementing thread, subject to one coordinated gameplay slot and its stated gates. This design thread changes no gameplay code, tests, assets or configuration and makes no commit/push claim.
