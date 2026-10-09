# Fanbase design session — zero-minimum loss ruling v2

2026-10-08, America/Los_Angeles. Shared checkout `main` at `91ce539978b87ac0a6efe3a1e028cae5f1360f19`, with concurrent TODO and other worktree changes preserved. The user accepted the proposed no-minimum-one-Fan loss behavior for just-below-5.0 Reviews. Recorded the [narrow decision](2026-10-08-zero-minimum-loss-decision-v1.md), linked it in this thread's README and reconciled it into the [authoritative Fanbase design](../../design/fanbase.md). No gameplay/source edit, TODO change, merge or push.

Source/evidence: isolated quarter-trial `StudioFanbase.plan` uses a cumulative floored target; [conditional screen](2026-10-08-near-neutral-rounding-screen-v1.md) distinguishes arithmetic from played Reviews3.6/3.5. The branch already allows zero loss below an integer target of one. The 15% coefficient, exposure proxy, other rounding details and final Fan Awareness tuning remain unapproved. The dispatched one-attempt [v2 capture](handoffs/2026-10-07-near-neutral-continuation-v2.md) remains separate.

Check: targeted `git diff --check` on edited design/thread files. Follow-up: discuss how simultaneous titles share an estimated audience before changing their gain/loss conversion or pricing Cult Following.
