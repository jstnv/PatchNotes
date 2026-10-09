# Fanbase handoff index

The main implementing thread can start here from the shared [Codex documentation index](../../../README.md). Read the status and source revision before taking a handoff. This folder is owned by the Fanbase design thread; add new versioned files rather than appending to a shared log.

Latest approved definition: [Fans are an estimated audience; the branch's eligible-unit proxy remains a trial](../2026-10-06-buyer-definition-decision-v1.md). No rate is locked.
Latest approved loss structure: [incremental per-title exposure and shared-boundary cap](../2026-10-06-incremental-loss-decision-v1.md). The focused verification below confirms this structure is already satisfied on the cited branch.
Latest rounding ruling: [allow zero integer loss below a cumulative target of one; never force a one-Fan minimum](../2026-10-08-zero-minimum-loss-decision-v1.md). Other rounding details remain open; the isolated branch already behaves this way.
Latest loss scale ruling: [retain 15% as ACTIVE/TRIAL](../2026-10-08-loss-rate-trial-decision-v1.md) after the Review4.3 / 93-Fan capture. Final rate remains OPEN; branch behavior already matches.
Latest gain ruling: [retain the branch's linear shape as ACTIVE/TRIAL](../2026-10-06-linear-gain-trial-decision-v1.md); its numerical scale and cap remain open. No implementation handoff is needed for this selection.
Latest sales direction: [make frozen at-launch Fans contribute proportional Fan Awareness](../2026-10-06-proportional-fan-awareness-decision-v1.md), with no second fan multiplier on all Awareness or sales. The user selected a [quarter-per-Fan, 150-cap trial](../2026-10-06-quarter-awareness-trial-decision-v1.md); it is [implemented and captured on an isolated branch](../2026-10-07-quarter-trial-recovery-findings-v1.md), not merged into main or approved as final tuning.

| Status | Handoff | Scope |
|---|---|---|
| QUEUED in TODO 2026-10-09 — not dispatched | [Current-main Fanbase playable trial v1](2026-10-08-current-main-fanbase-trial-v1.md) | Reuse existing branch work on the integrated source, preserve selected trial values, verify checkpoint/finance/Fan parity. Requires coordinated implementation dispatch. |
| COMPLETE — read-only evidence recorded | [Current-branch route replay v2](2026-10-06-current-branch-replay-v2.md) | [Nearby legal route and gain comparison](../2026-10-06-current-branch-replay-v1.md) captured; do not repeat without a new question. |
| COMPLETE — already satisfied on branch | [Incremental loss verification v1](2026-10-06-incremental-loss-verification-v1.md) | [202 focused checks plus native verifier](../2026-10-06-incremental-loss-verification-v1.md) pass; no correction task needed. |
| COMPLETE for trial analysis; final tuning OPEN | [Proportional Fan Awareness analysis v1](2026-10-06-proportional-awareness-analysis-v1.md) | [Candidate ratio/cap screen](../2026-10-06-proportional-awareness-screen-v1.md) and [propagated legal route](../2026-10-07-quarter-trial-recovery-findings-v1.md) are recorded; moderate weak Reviews and longer compounding remain unobserved. |
| COMPLETE — isolated branch trial | [Quarter Fan Awareness trial v1](2026-10-06-quarter-awareness-trial-v1.md) | [Findings and checks](../2026-10-07-quarter-trial-recovery-findings-v1.md); source is `bd450a9` plus two uncommitted trial files. |
| COMPLETE — read-only capture | [Strong → weak → recovery capture v1](2026-10-06-strong-weak-recovery-capture-v1.md) | [Legal route, Fan ledger and conditional no-loss comparison](../2026-10-07-quarter-trial-recovery-findings-v1.md). |
| Attempts exhausted; target INCOMPLETE | [Near-neutral weak-release capture v1](2026-10-07-near-neutral-weak-capture-v1.md) | At most two declared legal continuations targeting Review in `[4.0, 5.0)` with existing Fans; no gameplay or tuning approval. |
| COMPLETE — bounded target reached, 2026-10-08 | [Near-neutral continuation v2](2026-10-07-near-neutral-continuation-v2.md) | [Exactly one4/4/4 capture](../../../findings/fanbase-near-neutral-v2/README.md): Review4.3,93 launch Fans, losses9 then0; two earning boundaries and finance reconcile. No further attempt or final tuning approval. |
| SUPERSEDED by v2 | [Legal player capture v1](2026-10-06-legal-player-capture-v1.md) | Broader capture request retained for history. |

The quarter-per-Fan mapping is approved only as a playable trial; other Fanbase tuning remains open. The existing `bd450a9` branch already contains monthly fans, launch Awareness, and a Fans HUD/history view; do not duplicate that work. Both ordered handoffs were added to the internal TODO at the user's 2026-10-06 request and completed at branch-local scope on 2026-10-07.

2026-10-07 outcome: the [near-neutral handoff](2026-10-07-near-neutral-weak-capture-v1.md) exhausted both permitted attempts; target remains INCOMPLETE. [Findings](../2026-10-07-near-neutral-findings-v1.md). No third attempt under this allowance.

2026-10-07 new scope: the user separately approved [one continuation](2026-10-07-near-neutral-continuation-v2.md). This v2 authorization is the only additional attempt; v1 remains closed.
