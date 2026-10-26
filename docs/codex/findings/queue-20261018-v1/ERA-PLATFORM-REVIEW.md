# Store foundation follow-ons — implementation-thread design review, 2026-10-18

**Review COMPLETE; all proposed new behavior remains OPEN. No era/platform gameplay or catalog rollout.** Scope: [era brief](../../threads/feature-store/NEXT-DECISION-v2-era-unlocks.md) and [platform proposal](../../../../patch-notes/design-logs/feature-pools/proposal-011-platform-eligibility-foundation.md). `main` at `0132c4d`, dirty shared source; [integrated source manifest](integrated-v1/source.json). Current Handoff015 gates and Handoff012 prices/cards are independent.

## Current source

`RunState.register_release` already records each unique committed release and freezes `review.scope` and `review.required_scope`; its SideStreet entitlement uses actual played Scope >= actual required Scope on first registration. That provides authoritative facts for a future separate era entitlement. Do not use current owned-pool Scope, current Genre targets, a raw release count, or an old SideStreet offer as a substitute. Historical grants may have different provenance. No approved target-platform/capability registry or selector exists in the current design authority; current untagged cards retain their availability.

## Recommended era model

For a later separately approved era, qualify a distinct successfully committed player release when its frozen played Scope is at least its positive frozen required Scope. Equality qualifies; one below does not. Failed/cancelled launches and duplicate registration never count. Keep a versioned receipt keyed by release ID and qualification rule version, distinct from Contracts. Whether another Review/quality condition is desirable is a separate numerical decision.

Recommend showing future-era nodes as locked with both the calendar condition and qualifying-release condition visible. Explain missing owned parents, incomplete era qualification and affordability separately; being visible does not enable purchase. The known calendar boundaries remain1984/1990/2000/2010/2020/2026 (cycles96/240/480/720/960/1104). A player who waits but has no qualifying releases stays locked. Sufficient qualifying releases before the date remain locked until the date. Once earned, an entitlement remains permanent. No count, per-node assignment or first era pack is selected by this review.

Migration recommendation: reconstruct only from validated frozen release facts when both Scope values are present and their meaning is known. Missing historical facts remain explicitly unqualified/unknown rather than invented; preserve existing owned Features and accepted Research. Never revoke current first-era supply. Decide the exact legacy policy in the eventual handoff before any such gate becomes playable.

## Recommended platform contract

Use a versioned platform definition with stable ID and explicit capability set. Select the target during Pre-Development, then freeze the platform ID, capability revision and compatible owned Feature IDs with the project at its ordinary begin command. Editing a target in setup is free and changes only the preview; rejected begin leaves cash, time and RNG unchanged. Later research or registry changes affect future projects only. This proposal does not name a platform or select capabilities.

Each Feature declares its own required capability IDs. Eligibility is `all(card.required_capabilities in project.capabilities)` for tagged cards; untagged current cards remain compatible. Parents, lane and era never implicitly supply a child's platform tags. Validate unknown IDs and malformed requirements before offering a project; do not silently drop requirements. Ownership and research legality stay separate from compatibility, draw probability and committed play. Existing Contracts retain their Primitive eligibility until separately ruled.

Recommend a visible warning when a phase has no compatible finite Features, naming the missing capabilities and available renewable Pass fallback. Preserve the existing single-class fallback and the launch requirement for implemented finite Features; do not invent a compatible Feature, bypass the launch guard, or promise a playable release. Whether to prohibit such a project at setup is a separate user-experience ruling; the warning-only model is the smallest proposal.

## Minimal later verification packet

Use synthetic platform/card definitions only: two capability sets; compatible/incompatible/untagged cards; a directly tagged child with untagged parent; target changes before begin; no compatible Feature with Pass fallback; newly researched card excluded from an already frozen project. Include actual-required-Scope below/equal/above cases, duplicate/failed release, pre-date qualification, date-only waiting, existing ownership/queue migration, rejected atomic commands, cold Studio Continue and exact replay. Test player and AI against the same legal option set, plus keyboard/readability at both supported sizes.

Before implementation, the owning design threads must choose exact platform definitions, save/version migration, fallback/launch setup policy, first era counts and named content. No prices, fees, old97-node rollout, candidate tags or balance approval are inferred. This review supplies a concrete next decision packet and closes the review task without activating unspecified gameplay.
