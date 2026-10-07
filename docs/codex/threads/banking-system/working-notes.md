# Banking System working notes

Started 2026-10-06 (America/Los_Angeles). These notes stage this thread's design discussion; the [economy and banking design](../../design/economy-banking.md) remains the authoritative system summary. No new gameplay rule is approved by creating this file.

## Existing baseline

- **LOCKED:** Exact-cent cash accounting, $500 rent at each completed calendar month, typed obligation history, and one monthly credit update. Bank navigation is passive.
- **ACTIVE/TRIAL:** Current credit range, clean-profit gain, and typed penalty values are prototype defaults.
- **SUPERSEDED initial package:** The at-most-$500, one-settlement candidate below was replaced by the user's two-settlement gate and player-selected principal of at least $500 plus selected term. The [economy design](../../design/economy-banking.md) holds the current rules. Loans are not available in runtime.

## Initial questions (superseded by later decisions)

- Interest rate and due-cycle convention are now locked in the [economy design](../../design/economy-banking.md); the player selects term.
- Capacity calculation and two-settlement gate are locked there.
- Issuance, repayment, early payoff and Bank screen requirements are recorded there and in [HANDOFF.md](HANDOFF.md); loan code is absent.
- Focused acceptance cases are in the [draft shared-list contribution](TODO-UPDATE-DRAFT-v1.md).

Record future discussion here in dated entries or new versioned files. Label observations separately from approved rules, and prepare a scoped handoff for the internal TODO only when the user requests it.

## 2026-10-06 selectable-contract clarification

The user reiterated that amount and term were already decided and questioned the assistant's extra ruling. The $2,500 ceiling, $100 steps, 6/12/18-month menu and level bills are analysis options only. They are not prerequisites to the shared TODO contribution. The implementation brief must make valid inputs and exact payment math reviewable before gameplay changes. [Decision record](2026-10-06-selectable-loan-decision-v1.md); [source draft](TODO-UPDATE-DRAFT-v1.md). The user supplied the explicit shared-list prompt later on 2026-10-06; B3–B5 are now [queued](../../TODO.md).

The user then explicitly declined implementing that extra proposal and asked to move on. Treat it as historical analysis only. The accepted player-selected amount/term requirement was contributed to the shared TODO as B3–B5 at the user's later request.

## 2026-10-06 candidate package

The [state note](2026-10-06-state-v1.md) and [first-loan proposal](2026-10-06-first-loan-proposal-v1.md) supply a concrete but unapproved $500 offer, exact payment math, capacity screen, and first-game pressure check. The [handoff](HANDOFF.md) holds proposed tasks for later review. No rule was promoted to LOCKED and no shared TODO entry was made.
