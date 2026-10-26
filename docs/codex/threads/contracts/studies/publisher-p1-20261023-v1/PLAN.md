# P1 private prototype experiment and implementation plan

2026-10-23. Spec: [P1 foundation](../../PUBLISHER-P1-FOUNDATION-SPEC-2026-10-23-v1.md). Use the existing isolated simulator workflow; no canonical changes, commits, push or cross-thread dispatch.

Hypothesis: a dormant typed publisher ledger can preserve existing gameplay exactly, reject invented awards, and initialize valid predecessor saves to zero without losing any preexisting Studio data.

Cases: legal fresh Action/4417 and Sports/1112 Studios, empty traits, explicit stable IDs, current startup cash/grants, ordinary two-release campaigns. Policy is existing finite fixture, features_first, Fantasy, two hands per Design/Alpha/Beta, 100 commands per case. No grants or state/RNG/source substitutions. Baseline first; same recipes under the new source generate fresh states. Cross-version comparison explicitly removes only additive publisher ledger and content-revision metadata from native checkpoints and compares full remaining state/RNG. Ordinary paired tool is not used across differing sources.

Budgets: two cases per run, max two releases/100 commands each; at most six run/replay invocations including retained failed attempts, 240 seconds per import/run process; focused verifier processes capped at120 seconds and at most12 invocations. No seed, action budget or policy change to obtain a passing route. Stop on unexplained gameplay drift, unsafe save compatibility, repeated compile failure after three repairs, or less than20GiB disk free. Retain all incomplete/error outputs. Reduce a failure before expanding coverage.

Measurements: actual commands/termination, source identities and exact delta, final native state/RNG, nonempty Studio checkpoint, event retry/collision/cap results, exact old-payload field preservation and fresh-process restore. Fixture credits are synthetic, never reported as legal gameplay. Native disk durability, historical world versions, exports and human acceptance remain separate.

Steps:

1. Capture source/status, run baseline and replay one representative route.
2. Create `publisher-relationships-foundation-v1` owned by Contracts from current canonical; preserve baseline archive and metadata.
3. Implement pure ledger/rule resolver and focused fixture verifier only inside its project. Integrate RunState, creation identity, checkpoint/schema and narrow migration.
4. Run focused checks, retain initial errors, then run legal candidate campaigns and exact replay. Execute native old-payload migration and new-payload hydrate in fresh processes under private profiles. Keep source compatibility guards intact.
5. Audit results and unchanged canonical hashes. Seal a versioned handoff matching tested bytes, write findings and session log, update thread indexes. Re-read shared TODO before a minimal DESIGN review entry for unresolved adoption.

Pre-run amendment: the first focused publisher regression exposed a constructed historical fixture retaining the new ledger. Inspect its exact old shape; preserve the failure and fix only the fixture in a new candidate revision. Source review also identifies combined-world source fencing as a likely migration blocker. Before fixing, generate one legal Action/4417 Studio with the current two incumbent rivals, advance one ordinary productive cycle and capture the complete world at Studio. Use a separate process to reproduce restore rejection on v1, then test exact predecessor pair migration, unchanged player/rival/ownership fields, one subsequent cycle and isolated disk rejection preservation on v2. This is a bounded persistence fixture (one then two cycles), not an additional balance campaign; retain the original command/release budgets and twelve focused-process ceiling.

Budget amendment before v2 verification: allow at most14 focused invocations (previously12). The retained external world-probe parse failure consumed one invocation, and full-world cold continuation needs its own fresh process. No campaign seed, policy or command/release ceiling changes. World probe v1 retains the parse failure; v2 fixes its explicit Dictionary type; v3 additionally uses the actual Store `status` result field before first reaching the disk assertions. V1 candidate whole-world restoration now reproduces the predicted source rejection. V2 will admit only the captured canonical predecessor paired with its original content revision on every Studio and preserve strict simulator-envelope compatibility.
