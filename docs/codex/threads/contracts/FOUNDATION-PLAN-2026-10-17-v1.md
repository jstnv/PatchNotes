# Extensible Contracts foundation v1

2026-10-17 (America/Los_Angeles). **User approved structural direction:** extend the existing publisher Contracts system for future Contract types; defer balance. This plan fixes the first bounded private simulator revision before editing it. It does not approve revenue share, recoupment, exclusivity, reputation, control, new offers or new numerical values.

## Source and hypothesis

Repository `main` HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty worktree; private variant [contracts-foundation-v1](simulators/contracts-foundation-v1/variant.json) owned by Contracts has original baseline identity `ab7b4324cb93c94d3a65c935b353917f94590bc8b5d59bbf5ab4a2c672140ed8`. Edit only its `project/` copy. Hypothesis: a code-owned versioned definition registry can centralize the five existing Contract identities, display targets, frozen trial terms and score profiles without changing any accepted action, payout cent, Promotion point, RNG/state digest or serialized checkpoint field.

## Structural delta

1. Add a closed, versioned `ContractDefinitions` registry under `scripts/contracts/`. Define the five current contract IDs and their static publisher/hand/target/score/reward metadata. Return detached copies; reject unknown IDs and malformed score requests. The registry is a template for future *approved* definitions, not runtime mod loading or a save constructor selector.
2. Route `PublisherTrialTerms` through that registry while preserving its public API and **exact** `terms()` dictionary for Crown, Neon and Starwave. Route `ContractState`'s current calculations and presentation targets through the registry with compatibility wrappers for existing static Ironclad/SideStreet calls. Keep dynamic Publisher Connections Ironclad advance, offer issuance, finance timing, card eligibility, hand count, Promotion and checkpoint format intact.
3. Do not change `RunState`, current offer gates, UI layout, player saves, central design authority or shared TODO in this candidate. A future new offer still requires its own design approval, RunState issuance and checkpoint validation/migration review.

## Controls, checks and stop conditions

Before modification, a direct Godot 4.7.1 `--headless --path <private project> --script verify_publisher_trial_cash.gd` attempt crashed at engine signal11 before any verifier output. Preserve that failed command/result; retry after isolated import/profile setup without treating it as gameplay evidence. Compare current and candidate definitions over zero, partial, full and malformed scopes/cores for all five current IDs, both Ironclad advance variants and Neon focus ties. Run affected focused suites in isolated candidate setup and at least one legal fresh-process `simulate.py run --variant` route plus exact replay. Keep rejected or timed-out cases. Compare compatible baseline/candidate routes by legal fresh starts and state/RNG digests; do not bypass source identity fences. Stop and report if existing results, checkpoint shape, source ancestry or legality drift. No numerical balancing, exported UI or final balance claim follows.
