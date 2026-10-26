# Refreshed AI, checkpoint and Bank acceptance — 2026-10-17

## Result and source boundary

**PASS at the bounded scope below.** The requested rebuild, affected regression checks and exported continuation/rollback refresh are complete. Gameplay rules and balance values were not changed by this acceptance pass. The maintained test runner was repaired to connect its two fresh-process rival checks and give one finite calendar fixture sufficient time. This is not full release approval.

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, with existing shared edits preserved. Two immutable copies capture concurrent integration:

| Source | Pin | Files | Export PCK SHA256 |
| --- | --- | ---: | --- |
| A | [pin.json](pin.json), UTC 10:45:58 | 631 | `25b6f100d3624fd29c21570ad9c801f1b324a8cef43c4755c80377ab7cf870b3` |
| B, latest refresh | [latest/pin.json](latest/pin.json), UTC 11:14:19 | 637 | `ea7ad2fc9e83ab3270c36b7b4515e567227d4a12aec2710c58083216c1cf7cda` |

Both use Godot `4.7.1.stable.official.a13da4feb`. EXE SHA256 is `7c3e92d9c175dc8754947c93f2ad6d9514091e51cf542407b7595e2bbbd20257`. The [first build manifest](delivery/build-manifest.json) and [latest build manifest](latest/delivery/build-manifest.json) record exact included files, template hashes and executable locations. Both clean imports/exports and 287-entry package audits pass, including payload hashes and exclusion of debug/docs files. The export helper changes the application title to `Patch Notes Demo`.

Source B adds archive validation for empty archives and globally duplicated frozen release IDs, an integer conversion in roster cash display, verifier cleanup, and the maintained cold-Continue verifier/UIDs. The five affected suites, four-process world check and rebuilt exported UI refresh cover this delta. **The 139-suite union below is not an uninterrupted full gate on source B.** Runtime hashes at closeout match source B; any subsequent changes require their own assessment.

## Automated evidence

| Check | Result | Evidence |
| --- | --- | --- |
| Maintained verifiers on source A, resumed with verifier cleanup | 108 prior + 31 continued = 139 distinct suites pass, including the added cold-Continue consumer | [Continuation report](gate-continuation/result.json) |
| Source B clean import and affected suites | Rival trial 118/0; normal Gameplay 10/0; checkpoint codec 46/0; Bank integration 0 failures; cold Continue 9/0 | [Focused records](latest/focused/) |
| Source B real separate-process world save/rollback/restore/continuation | 55 assertions / 0 failures across four processes | [World results](latest/world-process-v2/world-process-results.json) |
| Test-runner dependency and profile isolation | 7 unit tests pass; real producer 10/0 + consumer 9/0 pass in separate processes using the same isolated save | [Unit log](gate-orchestration-tests-v2.log), [paired run](gate-pair/), [helper hashes](gate-pair/helpers.json) |
| Independent save/finance/source/capture audit | 2,349 checks / 0 failures; zero source drift | [audit.json](audit.json) |
| Actual exported interaction | 43 original captures; 16 logs with no runtime error markers; all 12 recorded process exits are zero | [Capture index](captures/index.jsonl), [process records](ui-processes.jsonl) |

The four-process world test saves at player cycle5 with active rival Beta projects, advances an uncommitted timeline to cycle7 with two rival releases, restores the exact cycle5 player/world/hand/RNG digest in a new process, rejects malformed clocks/IDs/archives, and commits the restored world at cycle9. Rival actions use the legal campaign policy. Player productive ticks in this probe are synthetic, so this is native persistence evidence rather than an ordinary exported campaign.

### Retained failures and warnings

- The first snapshot lacked the external frozen begin-project oracle. Its setup timeout is retained in `initial-missing-oracle.log`; [additional-verifier-inputs.json](additional-verifier-inputs.json) pins the 82 supporting files then copied into the snapshot. Runtime was unchanged.
- The original `gate/gate-result.json` remains failed: rival-trial assertions passed, but its verifier leaked resources. The corrected verifier adds three `coordinator.free()` calls; [exact diff](gate-continuation/verifier-cleanup.diff) and original logs are retained. The continued report records the successful rerun. Some native verifiers still report six ObjectDB instances at exit; these warnings are not zero-warning acceptance.
- The 96-cycle SideStreet scope/year fixture exceeded 240 seconds after real rival advancement was enabled. The original timeout is retained under `gate-continuation/attempts/`; the same finite fixture passes with a 1,200-second limit. Other limits remain 240 seconds. This is not a performance benchmark.
- The first custom world probe had a test-owned unparented coordinator; v2 frees it. The original logs remain. The first Python unit attempt encountered an inaccessible sandbox TEMP; the workspace-TEMP rerun passes. The initial independent audit used incorrect string/integer, zero-value synchronization-entry and image-format assumptions; its report remains in `audit-initial-schema-assumptions.json`. Correcting the auditor required no gameplay edits.
- Export logs warn about existing missing placeholder card artwork. All captures are original JPEG bytes; misleading initial `.png` extensions were corrected to `.jpg`, with original names retained in the index.

## Actual exported routes

All interaction used isolated profiles, the actual exported application and native mouse/keyboard input. Player saves and `.codex-godot-temp` were preserved. Audio used the Dummy driver.

| Route | Observed result | Source |
| --- | --- | --- |
| Fresh Action Studio, development hand, quit and cold Continue | Two trial rivals appear. Player advances to cycle2; Continue restores cycle0, 570,000 cents and both rivals. | A |
| Fresh Adventure Studio and cold Continue | Two rivals display at 1280×720 and 1152×648; cold Continue preserves roster, cycle0 and 570,000 cents. | B |
| Completed Neon checkpoint | Restores cycle17, 540,244 cents and 53 Fans; completed state/save bytes remain unchanged; no retroactive rivals. | A |
| Crown acceptance/first-hand rollback | Cycle59 checkpoint cash 1,455,368; accepts 15,000-cent advance, plays a hand and settles cycle60; quitting restores exact cycle59 cash/Fans and unchanged checkpoint bytes. | A |
| Completed Starwave + new Bank loan + monthly service | Restores cycle37 and 1,848,116 cents. Borrows 50,000 cents, then ordinary Store research reaches cycle40. Month20 settles sales61,539, rent50,000, payroll1,000 and Bank4,667 (principal4,167 + interest500), in rent → payroll → Bank payment order. Starwave's 224,000-cent once-only payout/history and zero Starwave Promotion remain unchanged. | A |
| Starwave Bank payoff and cold Continue | Pays remaining principal45,833 once at cycle40, ending at 1,496,351 cents. Cold Continue preserves closed loan and credit621; latest export repeats Continue and displays the closed Bank record. | A then B |
| Recovered active Dropout education + Bank payoff | At cycle52, cancel leaves checkpoint35 unchanged. Confirm pays24,998 cents once:109,801 →84,803; education principal/interest/history and credit remain unchanged. Cold Continue restores checkpoint36 with closed Bank loan. | A |
| Distressed partial rent/Bank/education | Cycle50 cash0; arrears33,998 =rent22,430 +Bank4,500 +education7,068. Original due dates and partial histories visible. Confirming unaffordable33,665-cent payoff is rejected without checkpoint mutation. | A |
| Historical inactive education preview | Cold Continue preserves cycle0/570,000 cents. Education view explicitly shows no active debt; no backdated rivals or extra funding. This is a controlled historical fixture, not a naturally recovered human save. | B |

The [profile origins](profile-origins.json) identify prior legal routes and copied checkpoints. The [audit](audit.json) checks envelope hashes, cash conservation, transaction continuity, bill/history reconciliation, exact payoff deltas, once-only publisher histories and unchanged rollback/rejection bytes. The Starwave pre-payoff cycle40 generation is retained in `checkpoints/starwave-cycle40/`. The older [publisher matrix](../queue-completion-20261011-v1/PUBLISHER-MATRIX-2026-10-17.md) remains the authority for previously completed both-size Contract presentation and Promotion routes.

## Runner repair and reproduction

Only test infrastructure changed canonically:

- `tools/release_gate.py`: the cold-Continue consumer requires its successful activation producer's explicit isolated profile; unsafe/missing/failed provenance is rejected. The finite SideStreet calendar fixture gets the targeted longer limit.
- `docs/codex/findings/checkpoint-runtime-v1/run_checks.py`: optional existing isolated profile, recorded in command evidence; default remains a fresh profile.
- `tools/tests/test_release_gate.py`: dependency/isolation rejection checks and targeted timeout coverage.

The stored command JSON files contain exact Godot invocations and profile paths. Initial gate invocation used `snapshot/tools/release_gate.py --godot <Godot executable> --output <this folder>/gate --defer-graphical-startup --isolate-checkpoint-writer`, followed by `--resume`. `finish_gate.py --resume` preserves the original failure and completes the remaining verifier set. `latest/verify_latest.py`, `latest/run_world_processes.py` and `verify_gate_pair.py` retain the final-source commands. `build.py` and `latest/build.py` retain both clean export recipes.

These runners intentionally preserve evidence; for a new run, create a new output folder and isolated profiles rather than rerunning into completed directories. `prepare.py` alone does not collect the external verifier inputs: copy the exact relative files listed in `additional-verifier-inputs.json` and verify their hashes before running the full gate. Set TEMP/TMP to a writable workspace directory for Python unit checks. The following read-only audit can be repeated against the retained outputs:

```powershell
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' docs/codex/findings/refreshed-acceptance-20261017-v1/audit.py
```

## Remaining acceptance

- AI: ordinary exported long-campaign rival releases through a later Studio save and cold Continue; cross-revision AI-world migration; detailed policy, Store/Core planner, entrants and following-month news. Native active-project/release persistence passes; it does not replace the remaining long UI route. Existing player-only save compatibility passes.
- Contracts C5/item23: exported failed-launch Promotion preservation remains NOT RUN (focused native evidence exists). The requested latest-source continuation/rollback refresh is complete, with the A/B delta boundary above.
- Banking B7: human quote comprehension, explicit older-education/newer-Bank payoff route, and exported elapsed overdue-age interaction remain OPEN. This pass refreshes the already demonstrated distress/recovery routes.
- Starwave: the combined monthly Bank boundary now passes; low-cash rescue, other specialty pools, human preference and final balance remain OPEN.
- Audible soundtrack/SFX, clean-machine acceptance and the residual native ObjectDB warnings remain separate. No commit, push or release-readiness claim.
