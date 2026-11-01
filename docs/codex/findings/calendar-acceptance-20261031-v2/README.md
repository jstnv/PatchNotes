# Calendar acceptance and fixture closeout — 2026-10-31

Status: available Windows/Godot4.7.1 calendar implementation and acceptance COMPLETE; source-reviewed, with remaining version/human gates below. User explicitly authorized fixing remaining fixtures, completing calendar acceptance and pushing the repository without input. Branch `main`, intake HEAD `2d5c8df152cd40eb827117270f13fed20af69498`. The immediately preceding runtime is5717e5e2573ea90a83ac8fe2bc87bbd3c6c10da3fe67524603ae57d3286cf54a. Final runtime: `ef14cc34682dbe4ab3e739ea13396da9979c3a8efb9c057c7c8cfa25d78980f6`; all final production file hashes are in `final-source.json`.

## Changes

- Compare summary-panel content, not the one-time publisher-unlock notification elsewhere in Studio. Preserve checks for unchanged cash, cycles and project identity.
- Construct public-engine releases with their actual engine ID/capacity, assert valid Core/Scope additions, reconcile HUD Studio proceeds after cumulative royalties, and select the actual per-release monthly Fan-loss event. Use four-cycle settlement/stale-preview boundaries and guard failed restores.
- Research/year fixtures explicitly register an owned editable control, satisfy the first-release gate and pay for prerequisites. They do not grant expansions to the fixed public engine or exercise proprietary creation economics.
- Full Continue fixture uses the actual asynchronous creation signal, month-of-year and encoded quarter-clock cases, a reliable teardown barrier, and frame-yielded staged loading. A transient background-hydration label need not render every time. Native screenshots explicitly request a draw rather than waiting indefinitely for an optional frame signal. This is test instrumentation; loading/scoring/timing rules are unchanged.
- Fixed one genuine readonly report bug: Studio proceeds now deduct the same cumulative engine royalty already deducted by finance, after publisher/support ownership resolution. Raw post-platform sales remain unchanged; this adds no cash mutation, royalty charge, balance value or gameplay formula. A four-cycle failing test preceded the fix; Public Engine now includes the regression.
- Admit only the exact5717e5… preceding source with its current rules/content pair and full provenance/profile validation. A genuine pre-edit capture verifies unchanged players, active rivals, history, cash, dates, engine access and RNG; unknown sources still reject.

[Exact follow-up source files](CHANGED_FILES.md). Earlier implementation and full underlying file inventory: [calendar](../calendar-four-cycle-20261031-v1/README.md), [Public Engine](../public-engine-phase2a-20261031-v1/).

## Verified receipts

| Receipt | Actual result |
| --- | --- |
| `final-maintained/results.json` | All12 maintained verifier names pass, zero errors: Clock, summary/Studio entry, SalesHUD, Fanbase checkpoint, SideStreet Scope/year, Public Engine, Engine/world Continue, finance integration, monthly report, publisher support, Bank finance and StudioFanbase. Public Engine93/0; Clock296/0. |
| `native-continue-draw` |646/0; actual native loading/Continue at1152×648/1280×720, exact state/RNG/disk bytes, calendar dates, corruption, writer collision, retry, teardown, both restore APIs and New Run after Cancel. Four native captures. Dummy audio verifies transport continuity, not listening. |
| `full-continue-v2` |689/0 headless; prior setup variant retained. Current native fixture also covers the complete recovery/teardown path. |
| `native-calendar-v3` |92/0; week3/4/month/year dates, real48 actions/12 rents, cash/RNG and typed durable/cold save. Ten captures; cycle0/1152 and cycle48/1280 inspected visually. |
| `full-year-world` |290/0; one legal48-cycle production year,12 releases,8 actual rivals in1981,12 player credit closes, monthly Market proofs and complete paired cold save. No synthetic funding added to that declared recipe. |
| `preceding-cold-v2` |19/0; genuine5717e5… players at8/9 and all8 active rivals preserve every captured field, repeated Continue is idempotent, paired re-save/cold restore passes, unknown source rejects. Active actor captures use their project ID, not the player Studio-only capture context. |
| `export-build-v3-result.json` + `normal-export-startup` |Unmodified-game entrypoint Windows debug export builds with zero errors and starts successfully. Installed templates are supplied through the private export preset only. |
| `export-runtime` |56/0 in an actual Windows template/PCK with the same game sources and a private test entry scene: no editor/debug scripts,48-cycle year,12 rents, no RNG, current cold save, certified8-rival boot and paired cold restore. Executable/PCK SHA256 pins recorded. |
| `compat44-clock` / `compat44-native-calendar-v2` |296/0 Clock and92/0 native date/finance/save checks under actual Godot4.4 using an independent project/cache. |
| Source review |Independent readonly review: no Critical/Important findings; report ownership/rounding and exact preceding source admission verified. |

The twelve maintained verifiers and actual native/export/current/previous-save receipts are separate scopes; do not sum overlapping checks as unique coverage. Final CRLF-aware diff check passes. Original protected temporary directories and inherited work remain intact.

## Retained failures, rationale and limits

Keep `red-summary`, `red-fixtures`, `red-public-report`, initial green attempts and diagnostic logs. The public report initially overstated Studio proceeds in all four quarters. Scope addition above27 was correctly rejected by gameplay, so fixtures must assert and respect capacity. The old Fan assertion selected the preceding month rather than the weak title's current close. The old teardown waited for a label that a cached/background restore can skip and then leaked its Game/lease into the following test.

All harness failures are retained: the first report patch used a nonexistent helper; a typed conditional array and a Fan-row key were corrected; native probe initially expected a coordinator in the supported player-only scene path; the native loader's screenshot wait was unbounded;4.4 needed its explicitly referenced JSON fixtures mounted beside the isolated copy. Private export initially lacked a preset, an absolute profile and installed template paths. Official4.7 templates forbid CLI path/script overrides, so packaged behavior uses a clearly declared private entry scene rather than weakening template settings. A Python assertion around a None-returning fence was corrected and relevant probes rerun. These do not represent passing tests in their original failed folders.

Godot4.4's broader Public/AI-world probe retains a failure because frozen opening certificates explicitly name Godot4.7.1; `rival_opening_loader.gd` correctly rejects a different engine version. No version guard, frozen certificate, historical rule, candidate capital, cohort value or engine library was relaxed. Current4.7.1 and packaged certificates pass. Cross-version world certification, clean4.4 editor/import, physical devices, human listening/comprehension and broad balance/late-save performance remain separate; no unsupported parity or release-readiness claim. Historical1977 certificates are immutable inputs, not regenerated histories for a pacing change. Full-year future actions and old/cutover saves are verified.

## Reproduce and publish

`run_acceptance.py` provides isolated absolute profiles, an allocated test lease port, optional native windows and configurable Godot executable, with raw source fences and retained stdout. `queue-rent-hub-20261031-v1/run_checks.py` runs maintained verifier names into a new output. Private export projects/profiles/binaries and copied4.4 caches are ignored. Actual game sources remain canonical and unchanged by those builds; only test entrypoint/configuration differ for instrumented export.

User-selected integration: commit the completed canonical Public Engine/calendar/fixture work plus bounded records and evidence, then non-force push to `origin/main`. Stage explicit paths only; exclude all profiles, project copies, binaries and protected temporary directories. Confirm remote object ID before claiming synchronization. [Session log](../../logs/2026-10-31-calendar-acceptance-push-v2.md).

Final publication audit: removed one extra blank line at the end of `verify_public_action_engine.gd`; `final-format-check` reran that verifier successfully (93 checks, zero failures/errors). Only that debug-script byte hash changes in the final source fence; the authoritative runtime identity above and all gameplay sources remain unchanged. The initial local staging check caught this formatting issue after the implementation commit; the cumulative source/record whitespace check is clean after the correction. Raw evidence-log whitespace remains verbatim. `publication-manifest.json` records the original 687-path implementation-commit selection and file sizes at staging.
