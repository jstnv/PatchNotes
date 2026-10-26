# Simulator and maintained-check repairs — 2026-10-22

Source/HEAD and shared-worktree boundary are in [README](README.md). No scoring, card, price, finance-service, Fanbase, market coefficient or AI policy rule was changed.

## Durable campaign projection

Market adoption added `RunState._market_committed_candidate`, temporary data passed from a successful player transaction into `RivalWorld`. Studio checkpoints intentionally reconstruct it empty, while the saved `world.market` owns the durable snapshot. `CampaignSession.replay_state()` previously froze the scratch into campaign state and nested hand/Contract references. Valid Continue then appeared different; checkpoint reducers and stress replays could also fail after a restore.

The campaign projection now removes only that scratch key from the detached Run projection and its per-call object cache. Raw `Replay.freeze`, actual RunState, the live provider, committed transaction, every gameplay field and RNG remain intact. Nested references use the same projection. The independent pre-optimization verifier checks the precise exception, and native financial comparators omit that same intentionally unsaved scratch after hydration. [Initial failures](scan/verify_campaign_stress.command.json), [continuation/reducer/stress/projection successes](i/results.json), and [final unchanged real campaign data](campaign-no-rule-delta.json) are retained. Existing frozen variants keep their own code; source fences still reject cross-revision tapes.

## Source identity in comparison reports

`compare_simulations.py` omitted the executed `queries/market_release_index.gd`, while current `DevelopmentReplay.source_identity()` includes it. The new regression [failed before correction](comparator-red.log). Current bundles now include that exact query; pre-market bundles with an inspection query but an older frozen Replay definition retain their original source set. Other presentation queries, UIDs and debug scripts remain outside the mechanics identity. Every file still participates in the outer frozen-manifest consistency checks.

[Final affected tests](tool-focused-final.log) pass. The immutable Contracts support bundle now produces a [verified comparison](support-comparison-final/comparison.md), preserving its old candidate source identity and +$6.81/+3-Fan observation at cycle79. The original bundle was not edited or promoted to approved gameplay.

## Historical oracle and fixture corrections

- Alpha/Beta/Design/full-development extraction oracles predate market metadata. Their detached historical adapter now first requires an empty project market vector and neutral transaction scratch, then excludes only those newly added fields. Original locked digests remain unchanged; raw current traces remain available. [Four corrected extraction suites](f/results.json).
- BeginProject now separately requires exact current live/headless equality and the independently specified neutral Puzzle vector/provenance, then compares the historical result after removing those new fields. [Six fixtures](j/results.json). The separate predevelopment test now gives its constructed legacy-finance fixture a stable owner ID, required by market standards.
- The market-index cold test previously replayed a recorded shared-world player tape in a player-only session. Its fresh replay now constructs the actual incumbents, compares every player result/state, advances their real policy after each productive boundary, and checks the complete world digest. [151 producer and 4 cold checks, 36 recorded steps](n/results.json).
- The old queue migration test bypassed the named pre-market migration. It now validates the original source/schema through that real upgrade, checks exact upgraded roundtrip, strips only explicit new provenance to compare every old field, and still rejects unknown inputs. Original fixture data is not rewritten.
- The gate now supplies a checksum-pinned copy of the existing pre-parent-change owned/paid-queue DTOs to `verify_gameplay_tree`. Nine historical records and original producer/source hashes are retained in `tools/fixtures/gameplay_parents_pre_change_v1.*`; these are constructed migration fixtures, not legal campaigns.
- Starter economy checks follow legal prerequisite order and the current Owned Pool/Debug presentation. In the Sports fixture 26 currently eligible cards total Scope38, cost $3,750 and retain $1,750 with zero cycles; Local Leaderboards still requires High Scores. The test does not bypass the approved parent to recover its old 27-card expectation.
- Mouse navigation checks inspect physical map cards after waiting for resized scroll ranges; they no longer call the removed category shortcut buttons. [Focused result](mouse-final2/results.json). The year-label fixture uses the supported player-only constructed entry, tests the actual shared header, and leaves real AI-world stress to separate evidence.

The non-fail-fast [diagnostic scan](scan/results.json) had an initial output-directory harness error, then ran while scoped fixes were applied; its source check is false. It is retained for diagnosis, never counted as an all-source gate pass. Earlier callable/indentation/verifier mistakes and superseded failed stages are also retained. The final full gate must run against an unchanged source set.

## Memory-bounded evidence serialization

Gate3 passed all173 suites but export ran out of host commit memory. Gate4 reached54 suites before the full development replay's whole-array JSON serialization also emitted allocation errors. Neither failed gate is passing acceptance. Export now uses Dummy text only for serialization; font import and runtime text rendering retain their normal drivers. A separate export retry exited0 without errors.

`verify_development_replay.gd` now writes its complete JSON array one route at a time instead of allocating a second pretty-printed copy of the entire run. It retains every route, trace value, oracle and assertion and additionally checks that the output file opens. [Focused verifier](memory-trace/results.json) passes without errors. [Independent parsed-value comparison](streamed-trace-parity.json) confirms all12 live and12 headless routes are exactly equal to Gate3's successful original captures. The smaller files differ only in whitespace. This is a verifier output change, not a campaign state or rules change.
