# G1a archive candidate intake — 2026-10-11

**DESIGN review only; do not adopt the v2 packet into canonical gameplay.** The frozen-archive direction is LOCKED, but cohort values and migration remain OPEN. This source review also identifies an archive/live-ID collision path that needs correction and focused verification before adoption. No runtime failure was reproduced during this intake.

## Source, scope and files reviewed

- Branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`; dirty checkout, 476 status entries when this intake began. Re-read the new TODO entry and inspected branch/HEAD/status and TODO diff statistics. Existing edits and `.codex-godot-temp` were preserved.
- Read [v2 HANDOFF](../threads/ai-competitors/handoffs/g1a-archive-candidate-v2/HANDOFF.md), its `handoff.json`, `source-review.patch`, manifests/integrity records, [candidate decision](../threads/ai-competitors/2026-10-11-g1a-archive-candidate-decision-v1.md), [finding](../threads/ai-competitors/2026-10-11-g1a-archive-finding-v1.md), and [LOCKED frozen-history decision](../threads/ai-competitors/2026-10-09-incumbent-history-decision-v1.md).
- Inspected only the five-file delta and nearby bootstrap/checkpoint/project-ID/batch call paths. Did not read the whole candidate tree, execute Godot, rerun simulations/replays, modify the private candidate, update shared docs, commit or push. This intake authors only this review record.

## Packet and evidence checks actually performed

The recorded base identity is `4162c70c12bf3d6af7587e5879759b54b127280c4ff224f4970ed7f8c2b895df`; v2 candidate is `ca0769c9f37e65681c94115e5867937e82a31c0b8102675517f534b1cb18eb67`.

- Recomputed SHA-256 for all 13 files named in `handoff-integrity.json`: all match, including both source archives and `delta-files.zip`.
- Recomputed base, candidate and packet-time canonical identities from their 608-entry manifest dictionaries using the tool's exact sorted-JSON identity formula: all match the handoff. This checks the manifests and sealed artifacts; it is not a full current canonical-tree hash audit.
- Checked each of the five edited private source files against its `after_sha256`, each corresponding canonical file against `before_sha256`, and each exact delta ZIP entry against `after_sha256`: all 15 comparisons match. Thus the reviewed five canonical paths still match the packet's base at this read; no broader no-drift claim is made.
- Parsed retained run/replay/experiment JSON. V2 opening run has four completed cases: controls22/22 commands, incumbents20/21, each one live release at cycle11. V2 continuation completes22 further commands to two live releases at cycle22. The two retained v2 replays are `ok=true`, with20/22 steps and21/23 verified telemetry samples.
- The negative v2 run is correctly retained as `ok=false`: both1980-title and missing-parent cases are `invalid_initial_state`, zero commands, non-replayable. V3 old-envelope continuation likewise remains `invalid_initial_state`, zero commands. These are not successful migration tests.

Exact report paths, relative to `docs/codex/threads/ai-competitors/sims/`:

- `g1a-archive-candidate-2026-10-11-v2/run-report.json`
- `g1a-archive-negative-2026-10-11-v2/run-report.json` and `experiment-report.json`
- `g1a-archive-continue-2026-10-11-v2/run-report.json`
- `g1a-archive-replay-4417-2026-10-11-v2/replay-report.json`
- `g1a-archive-replay-continue-2026-10-11-v2/replay-report.json`
- `g1a-archive-migrate-old-2026-10-11-v3/run-report.json` and `experiment-report.json`

The continued v2 run's frozen bundle identity is `2f5e53e1e5e5a037fe1e82686e8d89ceb10f41a527573ab6fd79cd59fa3b5917`, different from the candidate snapshot because the helper copies a byte-identical policy to its supplied-policy path, as the finding discloses. Do not conflate frozen bundle identity, candidate identity and mechanics/checkpoint compatibility.

## Exact proposed delta and what it establishes

Five modified files: `scripts/run_state.gd` adds separate archive/opening fields; `scripts/persistence/checkpoint_schema.gd` types them; `scripts/persistence/studio_checkpoint.gd` adds capture/hydration, validation and an `incumbentarchive1` content revision; `scripts/simulation/run_factory.gd` bootstraps historically owned Features and archive records; `scripts/simulation/campaign_batch.gd` exposes them in outcomes. No UI, shared-world scheduler or rival decision policy is supplied.

Keeping archived titles outside `released_games`/`release_metadata` avoids feeding them into the ordinary live sales/release-count paths. The retained cases support legal post-start commands and same-revision Studio continuation for this fixture. They do not prove full cohort coherence, every malformed archive case, native scene parity, shared-world persistence or existing-player-save compatibility.

## Correctness blocker: reserve the archive ID namespace

The private [bootstrap accepts any nonempty, within-archive-unique title ID](../threads/ai-competitors/simulators/g1a-incumbent-archive-v2/project/scripts/simulation/run_factory.gd:53). Its ID validation does not reserve the ordinary live-release namespace. The unchanged [Begin Project code generates `<studio_id>:project:<serial>`](../threads/ai-competitors/simulators/g1a-incumbent-archive-v2/project/scripts/simulation/begin_project.gd:27). After a matching live release exists, [checkpoint validation rejects historical/live ID overlap](../threads/ai-competitors/simulators/g1a-incumbent-archive-v2/project/scripts/persistence/studio_checkpoint.gd:173).

Consequently, a syntactically accepted historical ID such as `<studio_id>:project:1` can conflict with the first subsequent live title and invalidate later Studio capture. This is a **source-inspected correctness blocker**, not a reproduced runtime incident. The two tested placeholder archive IDs do not exercise it.

**Corrective acceptance:** choose a disjoint typed archive namespace or reject every future live-ID form during bootstrap and restored-state validation. Test first and later serial collisions, duplicate archive IDs, and an existing live-ID collision; rejection must happen before commands or changed cash/RNG. For a valid archive, run at least two legal launches and fresh-process Studio restores, preserving distinct IDs and exact archive bytes with no archive-origin sales/Fans. Do not weaken source, RNG or integrity fences to make this pass.

A related input-validation edge also needs a focused negative case: `_apply_incumbent` accepts an empty `historical_titles` array while always creating a nonempty opening snapshot, but [checkpoint validation rejects that combination](../threads/ai-competitors/simulators/g1a-incumbent-archive-v2/project/scripts/persistence/studio_checkpoint.gd:155). `CampaignSession.initialize` does not run that checkpoint validator. Define whether an empty archive is allowed, then reject it at bootstrap or construct the corresponding consistently valid state. This observation is also static, not a new executed case.

## Explicit design and acceptance blockers

1. **Cohort authority:** actual incumbent identities/count, starting cash/Fans, traits, completed Features, historical titles/years/Reviews, familiarity and other opening provenance remain OPEN. The $5,850/20-Fan Action fixture and its finite test policy are examples. V2 derives resources from ordinary traits and requires empty familiarity/research provenance; it does not implement arbitrary authored endowments or prove a general opening Review advantage.
2. **Trusted migration:** v2 adds required checkpoint fields and changes the global content revision without a demonstrated old-save migration. Existing accepted legacy-rule checks do not themselves fill those fields. V3's source-mismatched simulator envelope is rejected before its proposed decoder defaults execute, so its negative run proves neither successful migration nor isolated migration validation. Choose a trusted player-save migration with exact allowed predecessor revisions and preserved bytes/history, or a separately scoped archive representation that avoids this player schema change; verify through the intended entry point while retaining simulator source/RNG/integrity checks.
3. **Integrated acceptance:** visible historical labeling/archive access, actual multiple-rival persistence, shared calendar/market/news semantics, and integrated live/headless/checkpoint coverage are untested here. The finding explicitly reports no maintained native scene verifier. G2/G4/G5 decisions stay separate.

## Recommendation

Keep the packet in **DESIGN review**, with no canonical adoption until the archive namespace/initial-state validation, explicit cohort authority and trusted migration requirements are resolved and verified. Request a corrected versioned private packet with those focused negative and continuation cases, then reconcile its sealed delta against the current canonical source in one implementation slot. Preserve the existing v1/v2/v3 attempts and their honest evidence boundaries. This review grants no new balance approval, task closure or release-readiness claim.
