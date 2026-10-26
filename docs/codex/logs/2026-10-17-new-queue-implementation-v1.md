# New internal queue execution — 2026-10-17

## Request and checkout

Complete new TODO work without expecting user input. Read current state/queue/provenance, relevant handoffs/design and exact source before changes. `main` at `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, with extensive pre-existing edits (601 status entries at intake). No resets, cleanup of `.codex-godot-temp`, player-save access, cross-thread message, commit or push. [Intake](../findings/new-queue-20261017-v1/intake.json) preserves the exact status. Work stayed in the single canonical implementation slot; the AI experiment uses a separately recorded private variant.

## Delivered

- Adopted the approved four-card Alpha Store pack and exact temporary terms. Corrected branch overlap and expanded-map navigation. Preserved old ledger entries, Primitive/Contract/specialty rules and already-active project supply.
- Added a pure neutral real-release query for player, rival and continuing former-player owners. Explicit failure/optional-Core semantics; no runtime balancing, monthly snapshot, sales mutation or UI.
- Adopted the Founder claim ledger with once-only atomic ownership settlement; added strict version/proof checks and repaired post-launch Studio operator transfer. Existing saveable population stays capped at eight rivals.
- Added exact prior-catalog and pre-ledger-source compatibility, demonstrated using a real old-source checkpoint. Unsupported identities still reject.
- Completed Handoffs013/014 reviews with explicit first-pack deferrals and recommended typed entitlement/frozen-project contracts. Reviewed Contract challenge integration without approving the candidate publisher maps, targets or $100/+4 bonus.
- Rebased the bounded AI Theme-variety experiment into a fresh thread-owned version, retaining provenance, failure records and OPEN numbers. Two repeated 20-cycle runs and player replay pass; active market effects remain a separate design experiment.
- Integrated the new cold artifact dependencies, historical fixture and headless UI mode into maintained tooling; included the new query directory in simulator/export/release provenance.

## Changed files

Exact canonical before/after hashes: [21-file delta](../findings/new-queue-20261017-v1/source-delta.json). These comprise:

- `patch-notes/data/feature_store_ledger.json`; `scripts/ui/feature_store.gd`, `feature_store_map.gd`.
- New `patch-notes/queries/market_release_index.gd`.
- `patch-notes/scripts/legacy/legacy_world.gd`; new `victory_ledger.gd` and its UID.
- `patch-notes/scripts/market/rival_world_checkpoint.gd`; `scripts/persistence/studio_checkpoint.gd`.
- New focused Alpha UI/mechanics, market index, old-source migration, Founder evaluator/cold/atomic-commit verifiers; updated existing Store/navigation/radial assertions. Candidate verifier UID sidecars are retained.

Tooling: `tools/simulate.py`, `tools/release_gate.py`, simulator/release-gate tests, `tools/fixtures/queue_migration_pre_alpha_v1.json` and its provenance; existing `docs/codex/findings/export-queue-v3/export.py` and `inspect.py` now include/audit the query root. New evidence scripts, frozen source/run/profile artifacts and reports are under [new-queue-20261017-v1](../findings/new-queue-20261017-v1/README.md). The isolated AI variant changes three private project files only; canonical AI policy is unchanged. [Documentation edit inventory](../findings/new-queue-20261017-v1/documentation-changes.json) lists shared queue/state/design/thread reconciliation files.

## Exact checks and results

Runtime: Godot4.7.1.stable.official.a13da4feb; Python3.12.14. Every native run has a private profile and checkpoint test port. Exact argv/source/logs are retained in each run folder.

1. `run_checks.py final-checks-v1 ...`:13 focused suites, all exit0/no recorded errors. Store copy52; card fit1,841/55 cards/zero abbreviated fields; migration8; Alpha174 + cold28; index151 + cold4/36 replay steps; Founder13; world30; Founder cold6; normal Gameplay10; Store navigation and Alpha-priority checks pass.
2. `visuals-v2`: radial collision checks and58 UI assertions pass at1152×648 and1280×720; ten captures, inspected representative views. Its historical navigation failure is superseded by final-checks-v1. Existing parent65/research/integration checks pass in alpha-v3; its old node-count failure was corrected later.
3. `victory-commit-v3`:17/17, including an actual consented purchase reaching ten subsidiaries in an explicitly constructed eleven-Studio in-memory world, observed atomic cash/share/claim publication and duplicate/proof rejection. Oversized checkpoint correctly rejects.
4. `final_campaign.py`: three ordinary fresh-start campaigns, six releases/108 commands; every command exactly replays in a fresh process. These do not claim all new cards were acquired or establish balance.
5. `python -m unittest tools.tests.test_release_gate tools.tests.test_simulate tools.tests.test_export_validation`:32 tests PASS; final output in `python-final-v2.log`. Initial nonexistent module invocation remains in `python-final.log`.
6. `gate_jobs.py` exercised eight actual maintained-gate jobs,459 assertions, each exit0/no errors. Its final strict source equality rejected six import-generated UID files. `finish_gate_jobs.py` verifies all original hashes unchanged and validates the only additions as `.gd.uid` sidecars; [summary](../findings/new-queue-20261017-v1/maintained-gate-jobs-v1/summary.json). No verifier failure was waived; the entire release gate was not rerun.
7. `build.py` / `finish_build.py`: clean import/export and headless EXE startup exit0;301 PCK entries, valid checksums/no missing or unexpected files. The first inspector's missing query-root allowance was corrected and audited. `closeout_audit.py` verifies all270 included source files still match canonical. EXE/PCK hashes are in the finding/build manifest. Dummy audio provides no audible evidence.
8. `run_variety.py`: private candidate capture, two separate20-cycle rival checks213/213 each, identical complete observations/state/RNG and four legal releases;18-command player replay exact. The first capture's provenance rejection is retained. Source internal timer is90 seconds, correcting the plan's mistaken45-second description; external240-second bound unchanged. Actual process times53.109/52.562 seconds. Prior old-source timeout is not relabeled.

Full source identity, expected differences, fresh save limits, retained failed versions and exact artifact links: [findings](../findings/new-queue-20261017-v1/README.md), [AI finding](../findings/new-queue-20261017-v1/AI-VARIETY.md), [design review](../findings/new-queue-20261017-v1/DESIGN-REVIEW.md).

Documentation verification: local evidence links resolve, final canonical hashes match the recorded source, and the focused diff check passes with Windows CR-at-EOL allowed. The repository-wide check retains an unrelated pre-existing whitespace-only line in the Banking acceptance record; it was left untouched. [Exact audit](../findings/new-queue-20261017-v1/documentation-check.json).

## Remaining gates

No new numerical lock. Alpha prices/fees remain ACTIVE/TRIAL; current card artwork uses approved fallback behavior pending final art. Old missing-Core migration is not established by the read-only query; the prior-source world fixture uses valid Core records. Founder wins remain structurally testable but unreachable under the saved-population cap; UI, annual awards/denominator/Innovation Path/comeback need their own decisions/handoffs. Active market pressure still needs its separate private transaction, project-standard, age-month-ledger and migration work before numerical selection/adoption. Genre/Theme content, Pass effects/terms, Contract bonus maps/targets/caps and detailed AI policy remain OPEN. Human understanding, audible/device latency, clean-machine acceptance, deferred balance studies and release readiness are not claimed.

The internal TODO is reconciled to completed work and the explicit remainder. Existing broad publisher/Bank interaction evidence retains its earlier exact-build boundary.
