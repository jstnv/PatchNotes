# Remaining queue review and development text repair — 2026-10-17

## Scope and source

User request: inspect the internal TODO and complete remaining work that needs no user input. Read CURRENT_STATE, TODO, repository workflow, release-engineering guidance and the relevant remaining design boundaries. The approved foundations and bounded Bank/publisher acceptance were already complete. The actionable defect was the development-panel encoding issue recorded by that acceptance pass.

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, shared dirty worktree. [Edit record](edit.json) preserves the initial status, exact before/after hashes and five replacements. Existing changes and `.codex-godot-temp` were preserved. No commit or push.

The only gameplay runtime change removes five corrupt `Â` prefixes in `patch-notes/scripts/ui/phase_workspace.gd`: selected-card separators, phase heading, Beta known/fixed and launch-readiness separators, and the Balanced Production ±15% explanation. All other bytes in this file are identical to the retained pre-edit copy. No scoring, timing, save-format, balance or candidate-adoption changes.

## Verification

- Clean isolated Godot import: PASS, engine `4.7.1.stable.official.a13da4feb`; [engine hash](engine.json).
- Five existing focused suites: PASS — Gameplay HUD/priority overlay, Design phase, Alpha phase, Beta base hand resolution, and three-Core foundation. [Commands/results](results.json).
- Two additional graphical runs of the existing HUD verifier: PASS at 1152×648 and 1280×720, with ten inspected captures below. Selection and phase captions, Beta known/fixed/launch readiness, and the complete Balanced Production explanation fit and show the intended symbols.
- [Text audit](text-audit.json): five prefix removals are the entire code delta; 328 runtime text files contain none of the checked corruption markers. This marker scan is not a linguistic review of every string.
- [Source stability](source-stability.json): 653 copied source/input files retain their canonical hashes through verification.
- Clean Windows export and [package audit](build-v3/pack-manifest-verified.json): PASS, 297 entries, every payload MD5 verified, no missing runtime files or unexpected analysis/debug content. [Manifest and EXE/PCK hashes](build-v3/build-manifest.json). Relative to the previously accepted v4 export, the only changed runtime input is `scripts/ui/phase_workspace.gd`; the other 266 runtime input hashes match.

Isolated exported headless startup: PASS, exit0 with no recorded error markers; [command and profile](build-v3/headless-startup.command.json). No audible or new exported interaction acceptance is claimed.

The initial runner named a nonexistent `verify_beta_phase.gd`; its failed invocation is retained. The continuation used the existing `verify_beta_base_hand_resolution.gd`, preserved earlier passes, and rechecked every pinned source hash. No production defect or test assertion failed in that invocation. [Runner](run_checks.py), [render adapter](capture_workspace.gd), [final build runner](build_v3.py).

The graphical evidence uses constructed states from the existing HUD verifier, including synthetic evenly scored preview cards; it is not a new legal campaign or exported publisher playthrough. Audio used Dummy. Existing placeholder-artwork warnings and six-ObjectDB-instance exit warnings remain in HUD runs. The earlier Bank/publisher interaction evidence retains its exact binary boundary; this pass does not relabel it as interaction with this new export.

## Export reliability repair

The first export is **FAILED**, retained under `build/`: Godot returned zero despite safe-save/temp-file errors and packed a zero-byte `project.binary`. The old package inspector checked its MD5 but missed the empty payload; exported startup then failed and timed out. Its old package PASS is invalid as a usable-build claim.

Repaired the shared helpers used by `tools/release_gate.py`, `docs/codex/findings/export-queue-v3/export.py` and `inspect.py`: build/cache directories live under the requested output, each build has its own writable TMP/TEMP/TMPDIR, all Godot ERROR lines (apart from the established certificate-store diagnostic) reject the command, and package inspection requires an ECFG project-settings header. No security setting was disabled. New `tools/tests/test_export_validation.py` covers real private temp writes, zero-exit error rejection, successful-command handling, valid-header acceptance and valid-MD5 empty/wrong-signature rejection. These six tests plus seven existing release-gate tests pass in [the 13-test run](export-tests-v2.log). The initial unit invocation also encountered inaccessible default sandbox temp storage; its failed log is retained.

The corrected v2 export passed package/startup using a caller-provided workspace. The final v3 build removes that caller override and verifies the shared helper's own output-directory isolation. The old failed build is not the delivered artifact. [Final helper hashes and rejection audit](final-audit.json).

## Captures

| Surface | 1152×648 | 1280×720 |
|---|---|---|
| Design selection and heading | [capture](1152-design.png) | [capture](1280-design.png) |
| Design Balanced Production help | [capture](1152-design-balanced.png) | [capture](1280-design-balanced.png) |
| Alpha selection and heading | [capture](1152-alpha.png) | [capture](1280-alpha.png) |
| Alpha Balanced Production help | [capture](1152-alpha-balanced.png) | [capture](1280-alpha-balanced.png) |
| Beta selection, heading and readiness | [capture](1152-beta.png) | [capture](1280-beta.png) |

## Remaining queue disposition

No additional approved implementation is left unstarted by this review. Existing OPEN/DEFERRED decisions are preserved:

| Work | What prevents completion now |
|---|---|
| AI Store/Core planning, detailed policies/entrants/news and representative population limits | Design-owned policy, budget, threshold and population decisions remain OPEN. Private prototypes are not canonical approval. |
| Store era/platform progression and authored content | Release eligibility/display semantics, milestones, platform requirements, catalog terms and rollout remain OPEN. |
| Founder career/formation/ownership UI | Optional foundation APIs are implemented; the playable loop, mandates and economic terms are not approved for adoption. |
| Employee courses/final wages; final Fanbase, Traits and publisher tuning | Explicit unresolved effects, amounts or final tuning. Mature Fanbase study and Store human testing remain deferred. |
| Bank B7 | Human quote comprehension is NOT RUN; the older-education/newer-Bank elective-payoff combination remains inaccessible through the examined legal automatic-service routes. Age1 recovery is complete, not proof of every overdue age. |
| Audio/release assets and external platform checks | Audible mix, loop feel/device latency, asset approval, clean-machine testing and human tuning require the relevant human/device/content input. Steam remains deferred. |

Do not replay completed broad studies to fill these decision gaps or infer release readiness from this repair.
