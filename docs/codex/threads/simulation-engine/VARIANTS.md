# Independent simulator versions for design threads

User-authorized workflow, 2026-10-11. Each design thread may prototype its scoped addition in its own candidate simulator, run experiments alongside other threads, and submit adoption to the implementation thread through the internal TODO. A Git commit is not required. Preserve the distinction between an approved design, an ACTIVE/TRIAL value and an OPEN candidate.

The authoritative integrated runtime remains `patch-notes/`. Each candidate contains a full editable `project/` copy plus its original baseline archive, manifests, owner, identity and version ancestry. Candidate changes do not automatically update the shared game. Explicit narrower instructions for a particular task, such as a documentation-only pass, still apply until that task authorizes a prototype.

## 1. Create a thread-owned version

From the repository root, with the Python/Godot setup in [USAGE.md](USAGE.md):

```powershell
python tools/simulator_variant.py create --id store-research-v1 --owner feature-store --output docs/codex/threads/feature-store/simulators/research-v1
```

Change only that version's `project/` files to implement the scoped design. Do not change `variant.json`, `integrity.json`, the baseline archive or their manifests. Write the hypothesis, design authority/status, changed rules and acceptance criteria in the owning thread's decision record. Keep unrelated mechanics unchanged so the experiment has an interpretable scope.

Create a new revision from an existing candidate when needed:

```powershell
python tools/simulator_variant.py create --id store-research-v2 --owner feature-store --from-variant docs/codex/threads/feature-store/simulators/research-v1 --output docs/codex/threads/feature-store/simulators/research-v2
```

The fork retains its parent's current source identity and ancestry while preserving the original canonical baseline. It does not silently rebase onto newer shared gameplay. Separate threads should own separate version directories; do not edit one another's candidate while it is being captured.

## 2. Run concurrently

```powershell
python tools/simulate.py run --variant docs/codex/threads/feature-store/simulators/research-v1 --config docs/codex/threads/feature-store/study-v1.json --output docs/codex/threads/feature-store/sims/research-v1-run-01 --timeout 240
```

Use an explicit experiment configuration from the run guide and a **new output folder** for every invocation. Run output must be outside the candidate directory. Other threads may invoke their own commands at the same time; there is no global simulator queue or shared campaign state. Every run receives a frozen source copy, private `.godot` cache and separate `user://`/environment profile. Finished runs remain frozen even if the editable candidate later changes. These ordinary simulations do not use the native checkpoint test port.

Threads share CPU, memory and disk bandwidth; concurrency does not establish unlimited throughput or an approved AI population limit. Keep command/release/time bounds explicit and retain timeouts or blocked routes. Full native scene test harnesses have their own coordination requirements; the concurrent interface here is `simulate.py run/replay`.

Candidate code and policies are trusted local executable code. Ordinary project/profile isolation is not an operating-system sandbox. Never point code at the canonical project, another candidate's mutable files, player saves or external services.

The run records candidate identity, original baseline, current canonical identity, baseline drift and exact changed paths. A changed gameplay source rejects incompatible old Studio envelopes; create a legal fresh prefix for that version. Never edit checkpoint identity fields to defeat compatibility checks. Studio-only Continue remains the shared boundary.

## 3. Check and retain evidence

Run the affected maintained verifiers against the candidate, inspect bounded numerical outcomes, then replay each representative case using the retained run bundle:

```powershell
python tools/simulate.py replay --bundle docs/codex/threads/feature-store/sims/research-v1-run-01 --case declared-case-id --output docs/codex/threads/feature-store/sims/research-v1-replay-01 --timeout 240
```

Replay uses that experiment's frozen candidate source, including its telemetry when requested. Retain failures alongside successes. The existing paired reporter compares arms within one rules revision; it intentionally rejects different mechanics identities. Candidate-versus-canonical numerical studies therefore need an explicit cross-version analysis with both baselines and rule differences recorded, not bypassed identity checks or a false parity claim.

The current reliability layer includes bounded seeded campaign invariants, broader native/headless routes and failure reduction; [the run guide](USAGE.md) describes their scope. Passing them is evidence for reviewed cases, not proof that every new design is balanced or globally correct.

## 4. Freeze a concrete adoption handoff

```powershell
python tools/simulator_variant.py handoff --variant docs/codex/threads/feature-store/simulators/research-v1 --design-record docs/codex/threads/feature-store/decision-v1.md --summary "Describe the precise addition and intended behavior" --acceptance "State a measurable acceptance criterion" --evidence docs/codex/threads/feature-store/sims/research-v1-run-01 --output docs/codex/threads/feature-store/handoffs/research-v1
```

Repeat `--acceptance` and `--evidence` as needed. The decision file must already exist. The tool records a copy/hash; its contents still require design review. Evidence must belong to the same version and current candidate bytes. If the candidate changed after a run, preserve the old run and test the new revision before submitting it.

The packet includes:

- Original and candidate source archives plus exact source manifests.
- A readable patch and an added/modified/deleted file manifest with exact replacement bytes.
- Design decision, concrete summary, acceptance criteria and hashed evidence references with actual success/failure status.
- Canonical changes since the original baseline and overlapping conflicts requiring reconciliation.
- A human-readable `HANDOFF.md` and integrity manifest. Nothing is applied automatically.

Keep the referenced run/replay folders; the handoff retains references and hashes rather than duplicating every evidence bundle. Handoffs are sealed records: make a new packet after further changes.

## 5. Update the internal TODO

Re-read `docs/codex/TODO.md`, then make a minimal entry that preserves other threads' additions. Example structure:

> **[System] — [QUEUED approved implementation / DESIGN review needed].** Adopt candidate `[version ID]` from `[HANDOFF link]`. Design authority: `[decision link and status]`. Scope: `[intended changes]`. Required checks: `[acceptance criteria]`. Evidence: `[run/replay/failure links]`. Remaining OPEN decisions and current canonical conflicts: `[list or none]`.

The implementation thread then:

1. Verifies the retained handoff/source/evidence hashes and design authority.
2. Reviews the exact delta against current canonical source, preserving other work and resolving drift.
3. Integrates approved changes in the single coordinated canonical gameplay slot.
4. Runs affected mechanics, native/headless parity and checkpoint checks, recording numerical differences expected from the approved rule change.
5. Updates design/state/TODO and a dated session record with the adopted revision and actual verification limits.

A TODO entry hands work over locally; it does not send a message to another chat, merge source, approve OPEN numbers, commit or push. Existing candidate versions and evidence remain available for historical reproduction.
