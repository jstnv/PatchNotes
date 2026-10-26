# Founder Legacy foundation candidate v1

**Date:** 2026-10-17 (America/Los_Angeles). **Status:** CANDIDATE IMPLEMENTATION in a private simulator version, not adopted into canonical gameplay. The user authorized implementation of the legacy foundation and explicitly set balance tuning aside. [SPEC-v2](SPEC-v2.md), [share-sales/control v2](2026-10-11-share-sales-and-control-v2.md) and [founder-role v1](2026-10-11-founder-role-transition-v1.md) remain design authority.

## Scoped decision

Start with pure, serializable corporate and founder primitives that can be integrated with the AI Competitors shared world after its active canonical implementation settles. The [version](simulators/founder-foundation-v1b/) has baseline identity `bf55f6242734a85c384566137c9eca97a3251d2d9d422e57cf57c9504eedcb3f`. The first snapshot attempt was rejected because source changed during capture; v1b is the completed, immutable baseline. Only its `project/` copy was edited.

- `scripts/legacy/ownership_book.gd` creates and validates equal-share cap tables, typed founder/corporate/outside holders, exact integer majority, acyclic corporate holdings, fresh transaction identities, consented secondary-transfer plans, and authorized primary-issuance plans. Plans return the resulting cap table and exact cents cash legs. They deliberately do **not** commit shares or cash. The future world transaction must settle all legs through Studio finance and publish them atomically.
- `scripts/legacy/founder_profile.gd` holds the one active manual operator pointer, operated periods, once-only milestones and nonspendable financing summaries. A voluntary departure and all operator changes require a safe boundary. It contains no personal wallet or company assets.
- `scripts/legacy/legacy_codec.gd` encodes shares, money and cycle integers as canonical decimal strings for lossless JSON-facing checkpoints. Its decoder rejects malformed or inexact values. The enclosing whole-world save/rollback contract remains a later integration dependency.
- `scripts/debug/verify_founder_foundation.gd` exercises these primitives with synthetic cases. It is not a played takeover, actual finance settlement or world-Continue test.

The core incorporation split, valuation coefficients, offer premiums, founder mandate term, startup underwriting and CPU/population targets remain **OPEN calibration**. Callers supply formation holders and pre-money/investment amounts; this candidate adds no balance defaults. A primary issue requires positive pre-money, a paid subscription and more than half of pre-issue votes. A secondary sale requires explicit seller consent and positive consideration; neither plan may be treated as a completed deal before cash settlement.

## Integration dependency

AI Competitors was concurrently building its shared-world source in the same checkout. The candidate therefore does not modify `patch-notes/`, the live `RunState`, Bank, ordinary Studio checkpoints, card commands or UI. Integration must bind books to the world studio IDs, validate seller authorization against an accepted live offer, preflight buyer funds and known dues, plan both sides of corporate finance plus external owner settlements, then commit the new ledgers and event exactly once. The legacy checkpoint must include these records and the sole manual-operator pointer. A former Studio can only become AI-run from its retained exact state at a safe handoff; this candidate does not yet perform that transition.

## Acceptance and limits

Focused checks cover 50% versus one-unit majority, other-holder sale, founder refusal, dilution/post-money math, duplicate/stale deal, cycle/self-ownership, safe departure, one manual team, once-only milestone, nonspendable financing history and codec round trips. The isolated two-release Studio campaign and exact replay are regression evidence for unchanged card play; they do not exercise corporate world integration. Before canonical adoption, reconcile the exact AI World and finance APIs, prove atomic share/cash settlement and fresh-process world save/rollback, then test founder-to-AI migration and return. No balancing study is requested in this foundation slice.
