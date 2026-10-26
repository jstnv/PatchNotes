# Market adoption — compiled export acceptance

Date: 2026-10-22 (America/Los_Angeles). Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; shared dirty source and `.codex-godot-temp` preserved. **Clean build, compiled-package campaigns, native presentation and automated cold Continue PASS at the boundaries below. Direct release executable Continue through physical input remains BLOCKED.** No Bank rule change, commit, push or release-readiness claim.

## Current build and source

The accepted build is [export-v6](export-v6/build-manifest.json), a clean positive-allowlist copy imported and exported with Godot `4.7.1.stable.official.a13da4feb`. Both [clean import](export-v6/clean-import.command.json) and [release export](export-v6/export-release.command.json) exited 0 with empty error lists. Two existing card-resource UID warnings fell back to their valid text asset paths; they remain in the export log.

The [readback audit](export-v6-evidence-audit.json) independently rehashes all output artifacts, reruns actual PCK payload validation, and confirms **all 301 included source files still match the canonical project bytes**. Build-only application name/template paths are recorded in the build manifest.

| Artifact | Bytes | SHA256 |
| --- | ---: | --- |
| `Patch Notes Demo.exe` | 109112320 | `7c3e92d9c175dc8754947c93f2ad6d9514091e51cf542407b7595e2bbbd20257` |
| `Patch Notes Demo.pck` | 4371548 | `9b5c42d8e3a9e8064250c389ef21d1a0b5aa34c64561c5f35283d7f2638e70cb` |
| `Tiny5-OFL.txt` | 4389 | `6fe7d64407c69d187748206265977654747d3e2fe9e38e45a62cd03ec4770df6` |

The [PCK audit](export-v6/pack-manifest-verified.json) passes **331 entries**, all embedded payload MD5s valid, no missing runtime files and no unexpected files. Debug scripts, findings, Python, archives, design logs and `.codex-godot-temp` are excluded. Compiled scripts/remaps and the authoritative market query are present and included in runtime identity.

- Editor mechanics identity: `5783246fcb2ecd6612eccf8e06cde72490db3ebb2944b8592e0943bfdaf94536`.
- Compiled mechanics identity: `d259a6545d3802f5a2493f96547d9e10ad26984f4342270724232a3764fbec72`.
- Compiled content identity: `f522bf2f8166cba5fa68cb9936c04ef0b64d46560d5e68cca9681733e1fa7f0b`.

Editor and compiled source identities deliberately differ. No saved source marker was rewritten to force a current editor checkpoint into the compiled package.

## Compiled-package behavior

These runs use the **Godot editor executable with `--main-pack` pointing to the actual exported PCK**, and external task-owned harness scripts. Gameplay classes, scenes and assets load from the compiled package. The harness scripts are not shipped in the PCK. This proves package behavior under the editor runtime; it does not substitute for physical input into the release executable.

| Run | Result | Actual Godot CPU / wall seconds |
| --- | --- | ---: |
| [Compiled identity](pack-identity-v6-run.json) | Correct compiled/content identities, exit 0 | 0.593750 / 0.755569 |
| [Legal Action/War campaign](pack-campaign-v6.json) | 1071/1071; 54 commands, 3 releases, cycle 21 | 24.656250 / 29.414245 |
| [Fresh-process exact replay](pack-replay-v6.json) | 1100/1100; every result/state/RNG step matches | 14.359375 / 16.950239 |
| [Native market presentation](native-pack-market-v6.json) | 32/32; both supported logical sizes | 5.812500 / 9.531338 |
| [Original old-save Store adapter](pack-old-store-v6.json) | Valid, restored, original generation unchanged | 1.750000 / 1.862307 |
| [Native old-save Continue](native-pack-old-continue-v6.json) | 14/14; both supported logical sizes | 4.781250 / 5.047827 |

Every runner exited 0 with an empty script-error list. Existing six-instance ObjectDB shutdown warnings are retained in the relevant identity/Store/native logs. CPU observations include harness work and do not establish a frame-time or population budget.

### Editor versus compiled outcomes

The [explicit parity comparison](editor-compiled-parity-v6.json) matches the corrected editor Action/War campaign against the compiled campaign:

- Exact recipe, release records, project records, earning/Fan observations and coverage counters.
- Exact complete captured player checkpoint, including player RNG and authority.
- Exact complete captured world authority after excluding **only `world.source_identity`**, the deliberate build identity difference. Rival state and RNG are included.

All four input reports/checkpoints are hashed in that record. Timings and top-level digests containing build identity are excluded from outcome comparison. This is bounded parity for one 54-command, three-release legal route, alongside the compiled route's own full fresh-process replay. It is not a claim that every possible editor/export route is equivalent.

## Current and migrated native Continue

`presentation.gd` publishes the actual compiled campaign's Studio pair, instantiates the ordinary Gameplay scene and calls its normal Continue path. The only Store subclass override allocates a test-specific writer TCP port; persistence and validation methods are inherited. Both 1152×648 and 1280×720 logical sizes reach Studio, retain the current month identity, and display Pre-Development, the saved Review's **Core tab**, and monthly sales explanations.

The six native captures record logical layout rectangles and actual PNG dimensions. At the 1152×648 logical setting, the captured raster is 1280×720 due to window scaling; the 1280×720 logical setting also produces 1280×720 PNGs. They must not be described as six differently sized native-pixel images. Both UI state comparisons preserve every captured player mechanic/RNG field, excluding only the existing `seen_tutorial_topics` UI metadata changed by opening help topics. Automated view bounds and button-access checks pass.

The root implementation pass visually inspected **all six compiled market captures and both old-save Studio captures**. New target/factor explanations are readable. In the 1152×648 logical sales view, the Tree's first row is partly under its pinned header at the captured scroll position; the new factor breakdown remains fully visible, and lower scroll-container content is outside the current viewport. This presentation observation is retained without a runtime change. Screenshot inspection does not establish human comprehension or physical-input acceptance.

For migration, `export_store.gd` uses the normal `CheckpointCoordinator` and normal Store with the actual [original roster fixture](../queue-20261018-v2/roster-closeout.json). It does not edit source markers or gameplay values. Fixture SHA256 is `103585b637b05012cb8a851df24ba51c4a053501c96f614667c440d0273f894d`. This reuses an existing original fixture; **it was not freshly generated by running the old release executable during this pass**. Other old-save families likewise retain their original recorded provenance in the separate migration matrix.

The initial Store generation remains **generation 1**, SHA256 `d4b2594faabbea55f70872bb85c4411a95f281d7c542eb1418443fc1ecf7fed7`, before and after restore. Independent audit readback confirms both the original fixture and current generation file still have those exact bytes. The restored state is cycle 1, cash 547500 cents, Fans 0.

In a subsequent native process using the same isolated profile, `export_continue.gd` instantiates Main Menu and calls ordinary Continue at both supported logical sizes. **14/14 checks** verify Studio arrival, full restored player authority/RNG (only tutorial-seen metadata excluded), exact whole rival world/RNG, unchanged generation number and unchanged original generation bytes. Both Studio captures are retained. This is cold-process, compiled-package Continue under an automated harness; input was not physically clicked in the release executable.

## Direct executable attempt and remaining boundary

The actual current release executable was launched as PID16416 with its adjacent v6 PCK and an isolated profile, recorded in [release-current-v6-process.json](release-current-v6-process.json). Its [startup log](release-current-v6.log) reaches OpenGL initialization and loads 40 cards.

The root implementation pass reports that Computer Use could not activate the game window. Its recovery observation captured an unrelated WizTree window; **no input was sent to that window or to the game**. The bounded supervisor terminated its own process after600 seconds; `release-current-v6-run.json` records600.162s, exit1 and no logged script errors. Startup or automatic termination is not passing Continue evidence. **Direct release executable physical-input Continue remains BLOCKED**; audible/device, clean-machine and human understanding acceptance remain separate.

## Retained earlier builds

- Export v2 passed its 331-entry package audit before the final source-fingerprint and current-checkpoint decoding fixes. It is superseded for current-source acceptance. Its generated executable and clean source/cache copies were removed during disk recovery; logs/manifests remain.
- Export v3 failed with `ERR_FILE_CANT_WRITE` and `Save PCK: Failed to export project files` while C: was full. The v4 attempt in the same disk-exhaustion period produced no verified current build. Neither is a passing export.
- Direct canonical export v5 returned process exit 0 but logged `ERROR: Condition "split.size() < 9" is true. Continuing.` from the filesystem cache. Its [command record](export-v5/export-pack.command.json) retains that error; it was rejected despite nominal exit 0.
- Clean export v6 was then built and independently audited successfully as above. Earlier failed/incomplete attempts remain evidence and were not relabeled as passes.

## Changed-source record

[changed-source-manifest-20261022.json](changed-source-manifest-20261022.json) compares current source against this task's exact `before-source.json`: **30 files differ — 22 modified, 8 added, none removed**. Each entry contains its repository path, original/current SHA256 and current byte size. Scope is `scripts/**/*.gd` including debug checks, `data/**/*.json`, and `queries/**/*.gd`. It is a task-baseline delta, not the complete dirty worktree or a diff against HEAD. Bank-preservation verification is recorded separately in [REVIEW.md](REVIEW.md).

`audit_export_v6.py` reproduces artifact hashes, actual PCK inspection, all 301 included-source comparisons, report assertions, original-save/generation hashes, PNG dimensions, editor/compiled parity and the changed-source manifest. It makes no canonical gameplay edits.
