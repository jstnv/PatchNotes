# Publisher progression pilot: access and preparation finding v1

2026-10-19 (America/Los_Angeles). **PROPOSED private trial; no gameplay approval or adoption.** Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty shared checkout preserved. Current-source runs froze project identity `648daa7202785cd0fb451918ad39ef674e8c42669f998f147ee6b8c0706f3532`; runner SHA-256 `65bdf6c5eb4a47af829283a0b07d4b78ad45e8a95139607b96a613d6ffbf9193`, Godot 4.7.1 executable SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`. Exact per-run Godot commands, input hashes, results and failures are retained in the linked bundles. The [pre-run plan](PUBLISHER-PILOT-PLAN-2026-10-18-v1.md) fixes hypotheses, seeds, policies, release/command/time bounds and stops; [v2](PUBLISHER-PILOT-PLAN-2026-10-18-v2.md), [v3](PUBLISHER-PILOT-PLAN-2026-10-18-v3.md) and [v4](PUBLISHER-PILOT-PLAN-2026-10-18-v4.md) declare each access repair before rerun.

## Current-source results

All routes start from a fresh legal Sports/1104 no-trait Studio with the listed starter purchases and Sports/Fantasy development. `tools/simulate.py run --config <listed config> --output <new bundle> --godot <recorded executable> --timeout 240` was used; each bundle's `inputs/requested.json` and `experiment.command.json` retain its exact inputs and child process command.

| Bundle | Declared change | Actual result |
| --- | --- | --- |
| [baseline v1](sims/publisher-pilot-current-baseline-20261018-v1/run-report.json) | Six v11 witnesses, first development hands 3/4/4; max 130 commands, two releases | Six rejected SideStreet acceptance actions after first release Scope 28 against required 30. No new Brief. |
| [access v2](sims/publisher-pilot-current-access-20261018-v2/run-report.json) | First Design hands 4 | One rejection, first release Scope 28. |
| [access v3](sims/publisher-pilot-current-access-20261018-v3/run-report.json) | Add Split Screen starter | One rejection, first release Scope 28. Sports already owned Split Screen, so the purchase policy skipped it. |
| [access v4](sims/publisher-pilot-current-access-20261018-v4/) | First Alpha hands 5 | **Incomplete before case execution:** disk full; no outcome. |
| [access v5](sims/publisher-pilot-current-access-20261019-v5/) | Same Alpha-5 input | **Runner setup failure:** missing `--godot`; no case. |
| [access v6](sims/publisher-pilot-current-access-20261019-v6/) | Same Alpha-5 input, explicit Godot | **Interrupted during isolated source import** when C: reached 0 free bytes; no case or conclusion. |

No seed, budget or rejected case was silently changed or omitted. Baseline v1's 48 MB `git-provenance.json` was removed during failed disk recovery; its source manifest, patch, run report and case outputs remain, but that provenance file is no longer in the bundle. This evidence loss must be considered before any replay or adoption claim.

## Private candidate state and limits

[Variant v1](simulators/publisher-progression-v1/variant.json) owns a preserved original baseline (`base_identity` and `creation_identity` both `798e8be69bf595922096064807a0164e6be7911bec8f4595b99d19c40e9a68e3`) and a candidate two-hand SideStreet Relationship Brief/Reputation implementation only. Initial focused import, definitions and new Brief checks passed, including candidate-created Studio checkpoint roundtrips. Boundary assertions added afterward were **not rerun**. A read-only audit found current canonical `-market1` Studio checkpoints cannot migrate into the private revision; the variant only recognizes pre-market revisions. The [five-case full/half/miss/redraw/partial config](publisher-brief-private-pilot-v1.json) and [policy](publisher_brief_pilot_policy_v1.gd) are prepared but **not compiled/run** together. The empty earlier `PUBLISHER-BRIEF-PRIVATE-PILOT-NOTE-2026-10-18-v1.md` is not evidence.

The $0 Brief advance/cash/Promotion, 10-point Reputation cap, issuance cadence, commission and support formulas remain **PROPOSED**. The user-selected independent-client cash brief still has first-new-type priority; testing a publisher Brief privately does not revise that order. No private commission or support prototype exists. No canonical gameplay, shared TODO, implementation authority, commit or push changed here.

## Recommendation

Free sufficient disk space before another isolated run; this attempt consumed over 100 MB during source preparation. Repair and verify current-canonical-save migration in variant v1, rerun the focused checks, then use a newly named output folder for the predeclared Alpha-5 access case. Only after a legal SideStreet route exists should the five candidate Brief cases and exact replays run. Commission and support need separate versioned candidate descendants with legal same-revision prefixes and a within-revision support/no-support checkpoint pair. Keep all terms proposed until a later user design decision and adoption handoff.
