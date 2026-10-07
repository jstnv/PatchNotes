# Handoff: incremental weak-release loss verification v1

**Status:** COMPLETE locally as read-only verification, 2026-10-06: [already satisfied on branch](../2026-10-06-incremental-loss-verification-v1.md), 202 constructed domain checks and the existing native verifier pass. No correction task was needed. The original bounded acceptance below is preserved; the 15% coefficient remains unapproved.

**Decision:** [Incremental loss ruling](../2026-10-06-incremental-loss-decision-v1.md). A below-5.0 title can lose further fans in a later month only on its newly estimated reach. Its prior exposure cannot be charged twice. Concurrent losses use one pre-boundary fan snapshot and total losses cannot exceed it. Exactly 5.0 remains neutral. The reach estimate, rate, rounding, and cross-title overlap remain open.

**Source revision:** Inspect `codex/fanbase-on-main` at `bd450a9e4e8d83ece1478cdf5a16526432e36cce`, or record a newer exact SHA. At the cited revision, `patch-notes/scripts/fanbase/studio_fanbase.gd` already stores cumulative `loss_exposure_accounted`, subtracts its prior target, uses one `starting` count, and caps summed losses. `patch-notes/scripts/debug/verify_studio_fanbase.gd` includes a concurrent-loss cap check. This is branch evidence, not a claim that current main implements fans.

**Dependencies:** Existing branch fan ledger and legal monthly sales/settlement flow; the [audience definition](../2026-10-06-buyer-definition-decision-v1.md). Preserve all unrelated checkout edits. Do not alter review/sales/lifespan formulas for this audit.

**Acceptance checks:** On the cited branch or a newer recorded SHA, exercise one weak title over at least two earning months with rising estimated reach, then a month without additional reach; reconcile the cumulative target, each monthly incremental loss, and ending fans. Repeat a month callback/reconstruction and confirm no second charge. Exercise two weak titles at the same boundary with potential losses exceeding starting fans; confirm one shared starting snapshot, aggregate cap, and no loss funded by same-boundary gains. Confirm Review 5.0 stays neutral. Record exact inputs, source SHA, results, and any gap in this thread's own versioned evidence file.

**Output:** If all checks pass, report “already satisfied on branch” with the trace and create no duplicate gameplay task. If a check fails, prepare a narrow correction handoff with the failing case and expected result; numerical tuning stays separate. No TODO contribution until the user prompts it.
