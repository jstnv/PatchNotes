# Overnight implementation and verification — 2026-10-11

Base: dirty `main` at `41c87c76fb4d3c06a5332d93f0e7b0997007475d`. Existing work and `.codex-godot-temp` were preserved. This folder records the overnight queue pass; earlier accumulated implementation has its own logs and evidence. The later user request explicitly authorizes committing and pushing accumulated work.

## Queue outcomes

- **Feature Pools008 COMPLETE locally:** [Store implementation](STORE-008.md). Approved copy changes explain future-project Feature supply, no guaranteed draw/play, and every applicable quote/finance blocker. No economy or card-rule changes. Focused results:52 headless,60 rendered and62 existing Store checks pass. Eight rendered frames cover1152×648 and1280×720. Human comprehension remains deferred.
- **Private AI G1a correctness correction COMPLETE:** [result](G1A-RESULT.md) and [sealed adoption-review packet](g1a-corrected-handoff-v2/HANDOFF.md). Empty archives and reserved live-project IDs reject; failed bootstrap is atomic.29 focused and112 audit checks pass;83 fresh replay commands and85 telemetry samples match; a21-command Studio continuation reaches release3. Canonical AI adoption, cohort values, trusted save migration and broader policies remain OPEN.
- **Fanbase design intake COMPLETE at review scope:** [review](FANBASE-REVIEW.md). Two legal nonzero-audience Review4.9 witnesses confirm once-only losses of2/161 and1/83. Recommend retaining the current trial. No new numerical rule was approved or implemented; feel review, held taper and deferred mature-growth study remain separate.

## Verification repairs

The retained failed gate attempts led to test/harness corrections, without a gameplay change:

1. `release-gate-v1`: the historical Alpha oracle predates the approved StudioTraits version8 migration. [Exact comparison](alpha-oracle-difference.json) found342 differences, all the version7→8 field, while current live/headless traces matched. The historical digest helper validates version8/non-Cult preconditions and normalizes only a deep copy for that historical hash. Raw captures and runtime checks retain version8. Design/Alpha/Beta command suites pass afterward.
2. `release-gate-v2`: simulator verifiers require their own evidence-output path. The maintained release gate now supplies a separate directory for every verifier and clears inherited mode/capture overrides. The verifier and gameplay behavior are unchanged.
3. `release-gate-v3`: the redraw test sampled wall-clock time although motion follows the audio clock. Its center/exit slice now uses the injectable clock and verifies each transition exactly once at both supported sizes. The rest of the test retains native asynchronous execution. [Focused rerun](card-motion-v1/command.json) passes116 checks with no errors.

4. `release-gate-v4`: the full development replay had the same version7→8 metadata mismatch. [Complete trace comparison](development-oracle-difference.json) found432 differences, all that field, and exact equality between current live/headless traces. It now calls the same guarded digest helper for its `state` boundaries. Historical oracle fixtures remain unchanged. The focused rerun passes1,128 assertions with unchanged source and no errors.

**Final maintained gate v5: automated PASS,133/133 suites**, clean import/export,275-entry PCK audit, headless and graphical60-frame startup; [machine result](release-gate-v5/gate-result.json). Source and wrapper hashes remain unchanged across the run. The gate intentionally returns nonzero while `release_ready=false`; `automated_pass=true`, with no failure or blocked field. Each attempt retains source hashes, exact commands, isolated profiles and logs. Test-only coordinator wrappers use the real TCP writer lease on47733; production62741 is untouched. This is not production-port or exported Continue acceptance. Some suites retain ObjectDB shutdown warnings; the gate's classified error scan and all assertions pass.

All70 Python tooling tests pass (`python -m unittest discover -s tools/tests -v`; [command](python-tests.command.json), [output](python-tests.log)).

## Fresh-start system run

The final gate passes four declared fresh-start routes, each through four releases: Action seed4417, Cult Action90210, Graduate RPG1104 and Puzzle77. The baseline also repeats deterministically. Together the routes cover344 recorded commands and16 releases; the baseline includes seven Studio restores, Contract completion, hiring/payroll, Store research admission/completion, a Bank loan/installments/payoff and stale-command rejection. These runs exercise legal headless commands and financial state; they are not human playtests. Current live/headless suites separately match94 and138 boundaries across their declared routes. See `release-gate-v5/verify_campaign_*.log` and its verifier artifacts for completion results.

## Exported and human acceptance

`exported-build-v1/`: clean import/export,275-entry PCK content/hash audit and isolated60-frame headless startup pass. A separate native launch reached a window but the automation could not target it; no gameplay interaction was completed. The source export EXE SHA256 is `7c3e92d9c175dc8754947c93f2ad6d9514091e51cf542407b7595e2bbbd20257`; PCK is `6f0ca065be81be7e36f1cc5e69d26f17e611477c8bbd6c8a9a5f146cb1bbf550`.

`desktop-build-v1/` changes only the exported application/user-directory settings for an isolated interactive attempt. Its275-entry package audit passes; PCK SHA256 is `5bd0c170c3f7e9add0e4e0b6ae70461fa17b807c883ea4668c3e871177a6a171`. The Temp-path desktop launch returned Windows access denied. The subsequent launch of a byte-identical workspace copy was stopped by the user's physical Escape key. **Computer control stopped immediately. No new exported gameplay, audible acceptance or human Store-comprehension result is claimed.** The older partial exported routes retain their original source limitations.

Buildable Windows executables/PCKs, import caches and disposable profiles remain local and are ignored. Code, private simulator snapshots, command/results, captures, traces and review packets are retained as repository evidence. Source-pinned evidence has byte-preserving Git attributes; it must not be reformatted merely to remove historical whitespace. This preserves records without approving candidate values or declaring release readiness.

The final v5 export has EXE SHA256 `7c3e92d9c175dc8754947c93f2ad6d9514091e51cf542407b7595e2bbbd20257` and PCK SHA256 `2964fa52f592dd85f8130b89ccb41140b129958b1f0807ad78a7a0c51c5435db`. Its two startup checks pass; it does not add an interactive route.

## Git delivery checks

The original inventory contained105,568 untracked files/8.69GB, including rebuilt executables and profiles. Git exclusions preserve those generated files locally. Simulator source snapshots and original evidence remain included. [Byte-preservation audit](git-source-byte-preservation.json) verifies that changing only Git attributes in the canonical project and five archived project copies leaves their610/572/580/580/580/580 source hashes unchanged. These attributes are outside simulator source inventories and prevent checkout newline conversion from changing those hashes.

The staged-content scan initially matched two `AKIA`-like substrings inside megabyte-size, valid-base64 replay payloads; neither is a bounded credential token. The scanner now requires token boundaries. No payload or sealed evidence was edited. [Delivery audit](git-delivery-audit.json) records the staged scan and any representative byte differences; later staging refreshes documents/results written during the gate. Some compact test checkpoint/profile evidence already selected for publication is retained, alongside its matching logs; the new ignore rules prevent adding further disposable profiles.

[Scoped whitespace audit](git-whitespace-audit.json) reports eight existing cosmetic whitespace cases in a verbatim font license, historical fixture and maintained source. They are retained with the tested/source-pinned bytes, rather than silently rewriting them during publication. This is not recorded as a passing whitespace check. Immutable historical traces and snapshots retain their original whitespace too.

Final delivery scan:9,921 unique changed blobs checked, zero bounded credential-pattern matches. [Staged-source audit](git-index-source-audit.json) verifies exact bytes for all610 canonical source inputs and all five archived project inventories, with zero mismatches. Seven scene entries needed explicit content-hash staging after Git retained cached normalized entries; the earlier failed comparison is retained. No scene content was changed. The final staging refresh adds these audit records and publication documentation.
