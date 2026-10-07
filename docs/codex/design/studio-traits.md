# Studio Traits

Authority: cumulative §56 amended by§63 and current Tasks22,31. Source [StudioTraits](../../../patch-notes/scripts/studio_traits.gd), MainMenu and RunState creation snapshot.

## Locked choice / current first pass

Exactly one manually selected mutually exclusive company background: Family Funding, Cult Following or Publisher Connections. Separate required permanent Genre specialty. Working secondary framework4 points, at most2 positive/1 negative preview; $50/unspent point capped$300. Current Task31 authorizes choices persisted in RunState/capture and explicit inactive effects; all4 remain unspent and grant one$200 financing receipt above$5,500 base. Current new-player total$5,700, legacy no-trait$5,500. No secondary price/refund/Student Loan bill is active.

Preview choices: Resourceful, Lean Production, Studio Buzz, Student Loan, Expensive Lease, Unknown Name. Selection is not gameplay benefit approval. Duplicate/invalid/reconfirmed choices must not mint cash or overwrite committed identity. Current snapshot is in-memory; “persist” does not mean disk save/load.

## Rationale and candidate history

Background choice supplies deliberate company identity; stacking/random assignment would erase the tradeoff. Earlier Family+$300, Cult+200 fans, Publisher+15% first Ironclad and matching Genre+10 Awareness were trial values, not locks. Publisher boost can be clipped to zero by fixed Ironclad cap; funding mechanism stays open.

Task22’s narrow high-Review rebaseline recommended Buzz+3 at1 point and matching+3 only as candidates; tested+3/+5/+7 at1/2/3 prices versus cash conversion. Specialty selection/roster is free and required; any hypothetical point price is for an additional Awareness effect. Cult+25/50/75/100 vs200 depends heavily on unapproved fan attrition/visibility. Family+$300 retained only as reference.

Student Loan working design retains+2 points,$10/month for96 boundaries/eight years, interest-free arrears distinct from bank debt. Original dues stop after96; repayment does not mint points twice. Current preview grants neither refund nor bills. Generic typed Student Loan penalty hook does not implement this obligation.

## Open decisions and dependencies

Background effects, secondary numerical costs/bonuses/refunds/caps/durations, Cult fan rules, Publisher Connections funding, rent/credit modifiers and eventual effect-enabled UI/confirmation remain unresolved. No shortened96-month schedule or replacement point economy is inferred from trials. Bank loan post-settlement$500 direction is a different system.

Use actual rent/settled portfolio opportunity costs and compare neutral startup ledgers$5,500 and current preview$5,700 explicitly (Task34). Pre-rent/capped-starter trait rankings are historical; strong routes differ. [Evidence](../findings/current-balance-evidence.md), [Fanbase](fanbase.md), [banking](economy-banking.md) and [TODO](../TODO.md). Fresh trait-selection verifier passes. Older §56 “no inert UI until values settle” is superseded only for the explicitly authorized Task31 preview pass, not for unapproved effects.
