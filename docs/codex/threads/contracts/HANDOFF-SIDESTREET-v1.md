# SideStreet strategy — design review handoff v1

2026-10-11 (America/Los_Angeles). **Status: proposed / DESIGN review needed.** No gameplay adoption candidate, simulator variant or approved numerical delta exists. This packet makes the decision and next evidence requirement reviewable for the implementation thread; it does not dispatch another chat or authorize canonical changes.

## Decision authority and exact delta

The current [Contracts design authority](../../design/publishers-contracts.md) retains Ironclad and SideStreet as implemented/locked rules and Crown/Neon/Starwave as bounded ACTIVE/TRIAL rules. The user authorized this headless investigation, not a SideStreet, Crown, Starwave or access-gate retune. **Current proposed code/config/asset delta: none.** Continue existing behavior unless a later explicit design decision selects a change.

## Evidence and decision requested

[Predeclared study and retained failures](FINDINGS-v21-sidestreet-take-skip.md) used a frozen dirty `main` HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`, mechanics identity `13980fdeb9efabaeb070c8dddddcd8137982e3e073aa43ab87f7fdd1a57c4c4f`, one exact eligible Studio checkpoint, and two fresh-process exact replays. Take earned $1,125 SideStreet, then $1,276.36/7 Promotion from Crown; Skip earned $1,759.09/10 Promotion from Crown. Take was $642.27 cash ahead at shared cycle52, launched Game3 two cycles later, and had a pending Starwave offer after Game3; Skip did not. Neither arm blocked or accrued arrears. The 4417 seed failed the Crown access gate and was retained. The result is one route, with no post-Game3 sales settlement or Starwave acceptance.

**Open user design decision:** keep the current take/skip choice without more work, or commission a broader legal-route and post-settlement comparison. The bounded result does not support a payout, Promotion, cap or access-gate change. Recommended present action: retain current rules and commission the broader study only if the strategic tradeoff is important to tune.

## Conditional next study and acceptance criteria

If broader review is selected, this design thread can prepare a new predeclared version and run it headlessly before any implementation request:

1. Find at least one additional **legal** eligible checkpoint under a declared different seed or specialty, preserving access misses and all rejected/bounded routes. Verify Studio phase, exact checkpoint/RNG/source identity and both pending offers before pairing.
2. From each common checkpoint compare SideStreet take then the same Crown/Neon offer against leaving SideStreet pending, with otherwise equal observable policy. Record direct receipts, Contract score/Promotion, Starwave access, exact cash, overdue, credit, later work and launch date.
3. Continue each arm through Game3's first two actual settlements and use matched calendar cycles plus release milestones. Reconcile portfolio settled sales, publisher receipts and rent/credit; do not compare different-cycle endpoint cash as equivalent.
4. Use the isolated runner, retain failed/incomplete/timed-out cases, run the paired source/state/RNG check, and replay representative cases in fresh processes. Pin exact source revision, policy hash, legal prefix, commands, budget and Godot identity.
5. Return a versioned finding for explicit user ruling. Only an approved exact rule delta may become a **QUEUED implementation** handoff. The implementation thread must then reconcile canonical drift and verify source/focused behavior, maintaining one overlapping gameplay implementation at a time.

No current task is **handed off** for gameplay and no rule is **implemented and verified** by this study. The existing local implementations retain their separately documented statuses.
