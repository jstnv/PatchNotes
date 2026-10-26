# Publisher support renewal and chronological persistence — 2026-10-23 v1

Status: PROPOSED private experiment. User authorized autonomous work on support renewal and second-deal persistence. No approval of P4 terms, canonical edits, activation, commits or pushes.

## Hypothesis and design choice

The old candidate accepts repeat support but rejects saved history with more than one deal. Its grouped reconstruction can also use a later commission to justify earlier capacity. A deterministic chronological history of verified commission outcomes and support assessments can validate exact capacity at acceptance and freeze a qualifying result for renewal. Proposal v4 is the selected experiment, not an approved gameplay rule: previous assessment must be resolved; a new successful supported assessment or full same-publisher commission after prior acceptance qualifies, including at Investment100. No backlog, debt or standing loss is introduced.

Alternatives: retain numeric +10 renewal (disables cap-level renewal); clamp numeric threshold (permits unearned cap retries); use qualifying results (recommended, requires historical validation). Keep existing candidate funding, marketing, review, unit, age and recoup values unchanged. Freeze previous support quote ID and qualification event ID in version2 terms. Reconstruct event order from validated committed cycle and stable release ordinal: support assessments at a cycle settle before release registration at that cycle. Native P1 adoption should use its committed ledger ordinal instead of introducing a competing authority.

## Source boundary and baseline

Shared main HEAD0132c4dab398a2a94dbeae3caa68a36505fbfa4f is dirty. Existing P2/P3 remains queued. Fork `simulators/publisher-progression-support-market-v1` with `simulator_variant.py create` into `simulators/publisher-support-renewal-v1`; preserve original baseline/ancestry. Historical parent mechanics b53d9a31b1f54155324e3ec942d86baedd7facae9adf519fd644690326fc8b07, manifest4e7a533335d8d0f1b17f3508414c2e49088a4ca88de9376a1b76f4d0aa46e469. This predates canonical P1 and uses the old starter pool, not current pacing. Never transplant its project wholesale. Record exact captured identities and current canonical drift in each bundle.

## Predeclared cases, policies and limits

1. Run the unchanged historical reduced second-support case through the isolated runner, then replay it. Expect 15 accepted commands but an empty ending checkpoint. This is the red regression.
2. After the private change, regenerate Sports/Fantasy seed1112, no traits, through the exact existing R20 prefix (three releases, 300 commands), Maps/long Game4 commission (180 commands, four releases), then support/control Game5+6 from identical new Studio state/RNG (180 commands each, six releases). Reuse detached visible Feature-first policies and schedules5/7/6 then2/2/2. No source identity edits, cash/score injections or old checkpoint reuse across mechanics.
3. From the supported branch, second support with1/1/1 hands, target7,40 commands. Require a nonempty valid checkpoint, then cold continuation with Game8 2/2/2, target8,80 commands to assess the second game. Retain miss and no-renewal outcome. Fresh replay of representative repeat and continuation cases.
4. Recovery path, if legal branch exists: after missed second support, full Game9 commission5/7/6 (100 commands), then Game10 support2/2/2 plus Game11 2/2/2 observation (120 commands). A miss/rejection is retained; do not search schedules or seeds to force success.
5. Focused constructed checks separately cover cap success, cap miss, no backlog, unassessed prior support, same-cycle/pre-start cutoff, early capacity forgery, qualification reuse/swapped publisher/missing funding/changed rights, and exact saved roundtrip. Constructed cases do not prove legal cap reachability or current pacing.

At most14 runner run/replay invocations, each import/execution bounded360s; at most four focused checker invocations/revisions after baseline, each180s. New outputs only, 20GiB free-space floor, stop at declared target/rejection/bound. Keep incomplete/timeouts/parse errors. No independent seed search, universal balance claim, native/export/device acceptance or P1 integration in this pass.

## Measurements and deliverables

Record exact commands, original/candidate/current hashes, starting state/RNG, legal command counts, release/cycle/fees, quoted capacity/qualification, all funding/assessment/rights histories, checkpoint presence and cold equality. Require raw=publisher+Studio accounting and earlier records preserved. Baseline behavior first, source-root fix second, fresh replays and corruption checks before conclusions. Write findings, proposed review handoff, and a minimal DESIGN-review TODO entry if evidence is ready; keep approved P2/P3 separate.
