# Annual Awards presentation repair — 2026-11-01

User request: repair the character-stacked saving screen and slow ceremony after the second release, animate every nominee bar from a common baseline to its actual frozen score, and use Graphics/Sound/Technology/Design units.

## Source and ownership

Working branch `main`, HEAD `5fb0cfdf561c36cf27ffe09f1ad810b9fd5a579b`; existing dirty Engine Phase3A/3B and audio work preserved. No player saves, balance data, awards rules/rewards, calendar rules, production Continue boundary, commit, push or export changed by this repair. Private candidates live under ignored `private-project/`; `ANCESTRY.json` records the immutable published baseline. Both `.codex-godot-temp` directories were retained.

The genuine pre-repair Phase3A fixture is `current-world/fixture.json.first-year.json` (48 cycles, six player releases, eight rivals); `current-world/fixture.json` is its 96-cycle/twelve-release continuation. Their runtime is `89b2459915e55f7d203780d6fc0d4b73218c3e44997b3a3111e33267f31080e1`; the unchanged-source generating run passes128 checks. The other exact admitted predecessor is the published `ee16630a62508df8170e15b6dbc39a874a24d977792a42e0f3b56bd8bf10254f` fixture in the checksum closeout. No invented old-save source stamps were used for compatibility acceptance.

The post-hardening diagnostic loaded runtime `eca974619cf3a32382284b2f0f45bfe225bc6bf9cc29dd38dc282671a8aded51`; its before-run byte manifest is recorded by `native-hardened-final/report.json` and `source-manifest.json`. Native full-flow, motion and most predicate checks were fenced at runtime `9f6304b6f7ac23e9b3c0c8ab4d20fe8ee9a6752b105edb1c62d4ff647961ba10`; the only subsequent production delta is the reviewed early frozen-engine presence guard. Final cold/negative/native checks cover that hardening separately.

## Repair

- Bounded shared FolderUI saving surface: label1px/24 lines becomes656px/one line at1280. This is layout repair, not a timer delay.
- Real score-proportional bars share a baseline and maximum per award. Rank order2/1/3, actual winners, ties, sparse nominees, fixed Next and exact large integer endpoints remain. Visible-only nominal1.4-second counter/fill progression starts at zero on its first visible frame; a delayed frame cannot consume the whole reveal. Relative anchors preserve resize and immediate-completion layout. Native images show zero/intermediate/final at1152×648 and1280×720.
- Category-specific score and final-results units replace generic Core. Score/rank/title labels use existing FolderHeading typography.
- Parsed-envelope cache remains bounded to three proofs; memory bound rises8→32MiB so three representative7,767,248-byte generations coexist. Exact envelope, parser/script context, types, checksums, disk readback and semantic validation remain required. Oversized values fall back to normal validation.
- Five producer insertions now use plain String keys (`offset`, `policy`, `market_origin`, `legacy`, `annual_awards`). The old StringName keys missed the unchanged strict serializer parse-proof subset. Producer, trusted copy and strict parser now agree exactly in types/values (124,625 nodes in the measured pair).
- One process-local native player/world pair is retained only after successful publication. Encoding is reused only when complete native bytes, executable source and content revision agree except for validated annual stage/complete. The whole ledger is re-encoded; any actor/RNG/finance/history/ranking/reward/policy/source/content mutation falls back to full encoding. Attach/load/rebind and synchronous publication clear the memo.
- Semantic positive proofs normalize only independently checked annual stage/complete (canonical types,0–9 range, final-only completion and completed-prefix ordering). Every other field, catalog, source, script and rules revision remains in the exact proof key. Misses/rejections retain full validation. No failed predicate is cached.
- Two source-pinned predecessor admissions retain all validation, require modern annual/Pass Budget fields and require frozen engine identity/capacity BEFORE legacy schema decoding. Unknown sources and stripped ledgers/fields reject. Whole-world cold Continue comparisons are exact apart from the executing-source stamp.

## Verification

Every accepted PASS listed below has exit0, no ERROR/SCRIPT ERROR/FAIL, and a stable full project source fence. Explicitly rejected source-fence runs are labeled separately. Each run has a private APPDATA/LOCALAPPDATA/profile and dedicated test port where supported. Counts are not summed as unique scenarios.

| Output folder | Result and scope |
| --- | --- |
| `progress-final` |57/0, native/encoded two-year ordering and malformed progress types |
| `memo-final-v2` |19/0, exact memo/full encoding plus player/rival RNG, cash, ID, offset, policy, frozen owner/reward/rank, source/content misses |
| `validation-final-v2` |27/0, legal progress proof; protected mutation fallback agrees with full validator; catalog miss |
| `geometry-final-v2` |13/0, three real-size cache entries23,301,744 bytes; hidden/visible reveal, category units, resize and nonanimated first layout |
| `wire-final` |PASS,124,625 nodes, unchanged strict parser/type equality |
| `verify_checkpoint_codec` |46/0; Godot and result record PASS; original wrapper printing then failed cp1252 Unicode and is retained. Wrapper now uses UTF-8. |
| `verify_checkpoint_store` |18/0, publication failures, retry, corruption, backup and lease |
| `verify_annual_awards_rules` |49/0 |
| `verify_annual_awards_ui` |263/0 |
| `award-world-required-final` |7/0, global awards world remains mandatory |
| `engine-skill-continue-final` |0 failures, current combined Phase3B owned-node world Continue |
| `compatibility-hardened-phase3a`, `compatibility-hardened-ee` |10/0 each, genuine whole old player/world and cold Continue exact, unknown source and stripped ledger reject |
| `engine-projection-green-phase3a`, `engine-projection-green-ee` |10/0 each, missing ID, capacity, or both reject cleanly for both exact predecessor sources |
| `background-final` |29/0,96-cycle worker coalescing/newer state, paused save, fault/Retry, identical notification, teardown and fresh Continue;49.522ms kickoff,141.498ms maximum observed frame gap (machine/fixture bound) |
| `native-motion-final` |34/0, actual windowed zero/intermediate/final bars at both sizes; personally inspected images |
| `native-integration-final` |56/0, all ten actual Gameplay pages, input exclusion, duplicate Next, durable stages, Continue, write failure/Retry, preferences, Exit, exact unchanged owner/results, teardown |
| `native-hardened-final` |Behavior9/0, but NOT accepted as final combined proof: unrelated Engine auto-configuration edits changed five files during the source fence. Label656px/one line, fills0→65.17/59.00px and durable waits8,796/4,345/4,892ms are retained observations. See fence-delta.json. |

Commands use `run_check.py --script <res://script or absolute external script> --output <new folder> --fence [--fixture <pair>] [--native] --timeout <bound>`. The exact argv and manifests are stored in each result folder. `run_private.py --project <isolated project>` was used for candidate RED/GREEN before canonical adoption. Source-fence failure during concurrent Engine3B work was not accepted as combined verification.

## Timing and limits

`before-native/report.json`: synchronous click109/137/94ms; durable pages19,226/32,684/34,949ms. The text counter did briefly run; the fixed100px bars and consumed reveal made presentation appear static.

`native-integration-final/report.json`: initial full save14,437ms; first Next8,663ms; later stages2/3/5–9 take3,801–4,216ms (wait measured after synchronous click callback), Retry4,156ms, Exit4,299ms. The separate private native diagnostic includes click callbacks and records later waits4,859/4,670ms. This is a substantial measured reduction, not an instant-save or universal performance guarantee. Initial full-world validation, larger/older histories beyond bounded caches, other hardware, exported builds, human pacing and final balance remain separate. Final-source diagnostic includes click callbacks: first Next8,796ms; next4,345/4,892ms. Initial0 Graphics/0 Sound rise to18 Graphics/10 Sound after300ms; actual fills start0 then grow65.17/59.00px.

## Retained failures and rejected hypotheses

- `regression-red`, `geometry-red-final`, `wire-red`, `memo-red`, `validation-red`: meaningful missing-cache/bar/layout/wire/reuse failures before their corresponding repairs. `geometry-green`, `wire-green`, `memo-green`, `validation-green` establish isolated green transitions.
- `regression-green` returned zero behavior failures but its source fence changed during Engine3B; it is not accepted as final combined evidence. Work moved to a private published snapshot until the Engine owner finished.
- `normal-priority-native`: raising worker priority did not materially improve delays and was reverted. `native-pipeline`/`pipeline-profile`/`wire-diagnosis` retain the measured investigation.
- `native-motion`: two endpoint assertions used wall-clock waits while deliberately capped animation delta needed more visible frames. Replaced with a bounded wait for completion; final motion34/0.
- `memo-final`, `validation-final`: expanded tests initially addressed native and encoded RNG with the same shape; both errored and were interrupted. Corrected native dictionary and encoded map-array paths pass in v2. `geometry-final` omitted its fixture; corrected v2 passes. First engine-projection test chose an idle actor and was interrupted; v2 picks an actual active actor.
- `engine-projection-red-v2`: reviewer-discovered admission gap accepted missing capacity/both fields and hit a typed-Nil error for ID-only. The early raw-field requirement closes all three on both predecessors; final scoped review has no remaining Critical/Important findings.

No release/readiness, new economy balance, full-career parity, zero-hitch guarantee or exported EXE result is claimed.

## Concurrent Engine auto-configuration pass

After the hardened cold/negative checks passed, another user-authorized Engine turn changed engine_feature_actions.gd, engine_feature_state.gd, studio_checkpoint.gd, run_state.gd and feature_store.gd during `native-hardened-final`. Its9/0 behavior result is retained but its fence is false. `engine-skill-hardened-final` then encountered transient missing-variable parse errors in that actively edited Feature Store and also has a false fence. These are not final combined PASS results. The earlier source-fenced native56/0, motion34/0, Engine Continue and hardened cold/negative results retain their narrower scope. Final shared-build verification waits for that owner to settle; the awards owner does not edit its in-progress Engine files.

The Engine pass also introduced a per-worker immutable catalog identity and a separate three-generation exact semantic Store proof. Read-only reconciliation found no concrete production bypass: detached definitions are cloned/replaced at attachment, each writer has a fresh Validator, and cold readers/coordinators are excluded. Same-Validator live-catalog mutation is outside that contract; `validation_current_model.gd` prepares fresh-worker catalog-change and live-to-detached isolation/rebind checks. Additional Store DTO copies are count/input bounded, separate from the32MiB parsed-cache accounting. Optional explicit binding/method restrictions remain API hardening, not a verified production failure. Final combined tests are not yet run on this moving source.

## Final combined closeout

Runtime `6b3fa06073593241c439c080903dcada00360f952fe2b084ff591656080d6563`, branch main/HEAD5fb0cfdf…579b. The approved Engine auto-configuration model and its additional Store proof were preserved and reviewed; no Core/Scope/economy/reward/calendar values were added by this repair.

Accepted current-production checks: `combined-validation`34/0 (including fresh-worker catalog change and live/detached/rebind isolation), `combined-memo`19/0, `combined-compat-phase3a` and `combined-compat-ee`10/0 each, `combined-stretch-native`34/0 with project1152×648 base stretched to1280×720 and1906×932, and `combined-integration-native`56/0 including ten pages, Continue, failed write/Retry, exact finances/RNG/results, Exit and teardown. All exit0 with no error/failure lines.

The strict all-files fences are intentionally retained as false: the concurrent owner continued editing unrelated `scripts/debug/verify_*` files. Separate `production-fence.json` receipts preserve every changed filename and prove every production input plus actual test dependencies unchanged. This matches the existing runtime fingerprint's deliberate exclusion of debug verifiers; `assess_fence.py` does not alter original result records. No production change is waived. `combined-source-pin.json` records this exact scope. Earlier transient Engine parse errors and moving-production fences are not retroactively accepted.

Current windowed waits (after click callback): initial full-world save17,589ms, first Next4,948ms, later Next4,889–5,222ms, Retry5,261ms and Exit5,234ms. Other chat QA processes were active; these are observed local timings, not an isolated-device benchmark. The earlier pinned3.80–4.22s warmed-page result and original32.68/34.95s waits remain separately recorded. Initial save cost is still about14–18s across the observed runs. No zero-lag, performance-parity or release-ready claim.

The ceremony's final combined gate is closed at this production source. Broader Engine verifier maintenance continues independently. Optional writer API binding hardening, broad late-career performance, human pacing, other devices and fresh EXE/ZIP remain distinct.
