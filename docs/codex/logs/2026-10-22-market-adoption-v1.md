# Market trial implementation and acceptance — 2026-10-22

Continues the October18–19 implementation interrupted by disk exhaustion. User direction: leave Bank rules unchanged and finish other executable TODO work without further input. Local queue and v31 decision/implementation companion are authority; no new tuning was selected.

## Repository and scope

- Branch `main`; HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`. Existing shared dirty work and `.codex-godot-temp` preserved. No commit or push.
- Editor mechanics identity `5783246fcb2ecd6612eccf8e06cde72490db3ebb2944b8592e0943bfdaf94536`; compiled identity `d259a6545d3802f5a2493f96547d9e10ad26984f4342270724232a3764fbec72`. They identify different input formats and are deliberately distinct.
- [Changed-source manifest](../findings/market-adoption-20261018-v1/changed-source-manifest-20261022.json):30 script/query changes versus this task's retained baseline,22 modified/eight added/no removals. This is not the whole dirty checkout or a diff against HEAD.
- Added market transaction and named migration/frozen legacy validators; integrated RunState, world, project/Review, sales/Fanbase, checkpoint schema/coordinator, compiled-source fingerprints, Pre-Development/Review/monthly sales/HUD/guide explanations. Three focused debug fixtures/verifiers were added or clarified. Full exact paths/hashes are in the manifest.
- Updated TODO item22, CURRENT_STATE, lifespan design and AI thread index. Task-owned findings, runners, logs and screenshots are under [market-adoption-20261018-v1](../findings/market-adoption-20261018-v1/README.md).

## Implementation

One actual-release month snapshot feeds both player and rivals after a successful productive transaction. Projects freeze approved population/strong-Core standards; sales freeze exclusive Genre-only/Theme-only/pair factors per earning age month. Existing exact integer unit/cash/Fan ledgers and Studio-only Continue remain authoritative. Named old sources migrate prospectively, keeping original generations and previously earned results intact. New validation reconstructs saved factors/targets from owner release facts and restricts historical exemptions to recorded migration provenance.

The review found two implementation issues before final acceptance: forged but arithmetically consistent history needed stronger owner provenance checks, and exported fingerprints needed actual compiled scripts/remaps. Both were corrected and tested on the final source. Current checkpoint decoding also avoids redundant historical catalog hashing while keeping strict validation.

Bank preservation was independently checked: seven Bank/finance/UI files and six RunState Bank/loan methods match the retained baseline. Changed market income can affect future balances; Bank terms and progression guards did not change.

## Checks and exact results

| Check | Result |
| --- | --- |
| Current transaction verifier |122/122 |
| Eight actual original-save families,16 fresh processes |260/260; original bytes and cold generations retained |
| Corruption/provenance |31/31 |
| Publisher / roster focused checks |52/52 and239/239 |
| Five new-game campaign records / fresh replays |5,820/5,820 and5,964/5,964;267 exact commands,14 releases,111 cycles |
| Original/restored two-cycle branch continuation |37/37; exact receipts, durable state and RNG |
| Maintained20-cycle actual rival/Store verifier |120/120; four rival releases;155.592s wall/118.984s CPU |
| Editor graphical Continue/explanations |32/32; both logical supported sizes |
| Clean current export | import/export exit0;331 PCK entries/checksums/allowlist pass |
| Compiled PCK record / exact replay |1,071/1,071 and1,100/1,100 |
| Compiled current graphical Continue/explanations |32/32 |
| Compiled actual old-save graphical cold Continue |14/14; both sizes, original generation/player/world/RNG preserved |

Commands are retained in each `*-run.json`/`*.command.json`. Core runners are `run.py`, `run_rss.py`, `run_migrations.py`, `build_current.py` and `run_export.py`; use new labels/output profiles for reproductions. [Campaigns](../findings/market-adoption-20261018-v1/CAMPAIGNS.md), [migration](../findings/market-adoption-20261018-v1/MIGRATION.md), [review](../findings/market-adoption-20261018-v1/REVIEW.md), [timeout investigation](../findings/market-adoption-20261018-v1/TIMEOUT-REVIEW.md) and [export](../findings/market-adoption-20261018-v1/EXPORT.md) contain exact inputs, hashes, counts and limits. Source-scoped `git -c core.whitespace=cr-at-eol diff --check` passed.

Measured campaign working set175–206MB and compact checkpoint sizes51,656–190,465bytes are bounded observations. CPU includes verification, hashing, restore and serialization; no population budget is established. Existing UID fallback and ObjectDB shutdown warnings remain recorded. The original240-second timeout is retained; the current maintained route completes, but no sole historical cause is proven.

## Retained failures and acceptance boundaries

- Earlier record tapes serialized raw CardData objects incorrectly. Corrected harness freezes results before encoding; all fresh replay comparisons now pass. Empty disk-interrupted outputs remain retained, not counted.
- Four maintained restore comparisons initially included an unsaved transaction candidate. A paired continuation proved it is scratch only; a narrow debug-only comparison now excludes it and explicitly checks the saved world market. No gameplay/RNG change was made for this clarification.
- Disk exhaustion interrupted earlier builds/tests. Only this pass's disposable build files/cache and obsolete/failed PCKs were removed; hashes/logs/manifests and original fixtures remain. V5 direct export reported a filesystem-cache scan error and was rejected. V6 clean import/export passes.
- Current compiled-PCK graphical tests run in the editor engine with an external test harness. The actual release EXE launches, but Windows activation failed and the recovery capture showed an unrelated application. No mouse/key input was sent. Direct release-EXE mouse Continue stays **BLOCKED**, distinct from automated graphical acceptance. Original old-save fixtures were reused; this pass did not freshly produce them through an old EXE.
- All six editor and six compiled market captures plus both old-save Studio captures were inspected. New explanations are readable; small-size lower content uses existing scroll containers, and the sales table's top row can be partially under its pinned header at the captured scroll position.
- Human comprehension, listening, clean-machine release acceptance, all historical permutations, final balance, population limits and release readiness remain unclaimed.

## Follow-up

The October19 fixed-coefficient market-exposure work order is complete at its predeclared bounded scope: Eight six-release records and eight exact fresh replays pass across 864 legal commands, 48 player releases and 336 productive cycles (58,372 record and 58,872 replay assertions). See the [read-only finding](../findings/market-exposure-20261022-v1/README.md) and [separate session log](2026-10-22-market-exposure-v1.md) for attribution, timing deviations and limits. The [remaining queue audit](../findings/market-adoption-20261018-v1/QUEUE-REVIEW.md) found no additional unstarted approved task; [final integrity check](../findings/market-adoption-20261018-v1/final-integrity-20261022.json) confirms all 301 export inputs still match and Bank files remain unchanged. Leaderboard rules, new rival policy, Store planning, entrants, news and final coefficients remain OPEN.
