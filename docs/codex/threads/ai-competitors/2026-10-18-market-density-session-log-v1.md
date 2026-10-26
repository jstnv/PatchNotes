# AI Competitors market density session — 2026-10-18

## Checkout and scope

`main` at `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; shared worktree dirty before and after. The authoritative `patch-notes/` project, existing edits, player saves and `.codex-godot-temp` were preserved. No computer control, commit, push or canonical gameplay implementation. This session selected the delegated ACTIVE/TRIAL active-market design, tested a private v31 simulator, sealed an adoption packet and updated internal item 22.

## Files produced or updated by this session

- New [predeclared plan](2026-10-18-market-density-trial-plan-v1.md), [decision](2026-10-18-market-density-trial-decision-v1.md), [finding](2026-10-18-market-density-trial-finding-v1.md), [handoff](handoffs/market-density-trial-20261018-v1/HANDOFF.md) and [companion](handoffs/market-density-trial-20261018-v1-evidence.md).
- New thread-owned [v30](simulators/market-density-20261018-v30/variant.json) and corrected [v31](simulators/market-density-20261018-v31/variant.json) private versions, [focused verifier wrapper](run_market_density_verifier_v1.py), and unique isolated run/output profiles under `sims/market-density-*`. V31 only corrects the v30 synthetic verifier ordering; market gameplay is unchanged between them.
- Minimal status/rule additions in `docs/codex/DECISIONS.md`, `CURRENT_STATE.md`, `TODO.md` item 22, `design/genre-specialties.md`, `design/game-lifespan.md`, and this thread's `README.md` and `working-notes.md`. Other concurrent changes in those and unrelated files were preserved.

## Checks and results

The [finding](2026-10-18-market-density-trial-finding-v1.md#exact-commands-and-retained-evidence) has the exact `simulate.py run/replay` and isolated verifier commands, Godot/Python paths, seed, ports, 240-second limits, source identities and evidence links. Godot 4.7.1 console SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`.

| Check | Result |
|---|---|
| Current neutral player fresh run | PASS 18/18 commands, one release. |
| Private v31 player and fresh replay | PASS 18/18 and 18 exact accepted replay steps. |
| Private v31 actual two-rival world | PASS 122/122, one real Action publication raises later legal player's frozen targets to `[42,28,42,28]`; exact Theme-only factor, units/cents and rollback checks pass. |
| Private v31 cold Studio Continue | PASS 8/8. |
| Private v31 original old Store/world fixtures and cold repeat | PASS 73/73 and 51/51; two original fixture SHA-256 values preserved. |
| V30 focused world | FAIL 1/122 from nonlexical synthetic fixture order; corrected/repeated in v31. |
| Current-source rival activation control | TIMEOUT after cycle 13 at 240 seconds; INCOMPLETE. |
| Handoff generation | First call rejected replay bundle as evidence because the handoff tool accepts a current-candidate **run**, not a replay. Second call with the v31 run succeeded: 24 changed paths, four overlaps, `baseline_drift=true`, one sealed successful run reference. The separate replay, world and migration evidence remain linked in the finding/companion. |
| Documentation | `git diff --check` on touched tracked docs PASS; new record trailing-whitespace and local-link checks PASS. |

Low disk headroom initially prevented an independent new variant. NTFS transparent compression was applied only to approximately thirty older AI market `git-provenance.json` evidence files with `compact.exe /c /a /i`; their contents, paths and SHA-256 identities were not changed. No evidence, save or project file was deleted or moved. New outputs use unique folders and profiles.

## Remaining gates

The packet's old baseline overlaps current world codec, checkpoint schema, Studio checkpoint and RunState. Integrate against current Store/Contract/roster/synergy source in the implementation slot. Verify active Genre-only and pair sales, completed player Review under pressure, strong player-to-rival response, exact current-source Store migration/backup and Gameplay/exported Continue, visible explanations and CPU/save limits. Investigate the retained current-world timeout. Final coefficients, campaign challenge, entrant/AI choices, following-month high-Review news and the eventual leaderboard remain OPEN. No private simulator pass grants final balance approval or release readiness.
