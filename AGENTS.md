# Patch Notes repository workflow

Read docs/codex/CURRENT_STATE.md and docs/codex/TODO.md first. Then read only the relevant docs/codex/design/<system>.md, findings and recent logs. Inspect branch, HEAD, status and diff before edits or status claims.

The repository is the shared design and engineering memory. Chats are working environments; persist important decisions in design documents, cross-system decisions in DECISIONS.md, work state in TODO.md, and material high-level changes in CURRENT_STATE.md. Findings are evidence, not design approval. Keep LOCKED, ACTIVE/TRIAL, OPEN and SUPERSEDED rules distinct.

Use Drive only for missing/ambiguous authority, explicit synchronization or necessary historical evidence. Existing design-logs and old Drive instructions demanding full cumulative-history reads are superseded by this workflow. Read docs/codex/README.md for source provenance and update conventions.

Preserve existing worktree edits and .codex-godot-temp. Use one overlapping gameplay implementation at a time. Do not turn candidate values into approved gameplay. Verify implementation claims against source and focused behavior checks. Leave a concise dated local session log with branch/commit state, changed files, exact checks/results, blockers and follow-ups. Do not claim a commit, push or release readiness without evidence.

## Design-thread simulator versions

User workflow, 2026-10-11: design threads may implement and test their scoped additions in independent candidate simulator versions. Use `tools/simulator_variant.py create` under that thread's folder, then edit only its `project/` copy. Preserve the recorded canonical baseline and ancestry; use a new version for a new revision. See `docs/codex/threads/simulation-engine/VARIANTS.md` for the commands and handoff contract. This permission covers isolated simulator prototypes; explicit narrower instructions for a particular task still apply.

Run each experiment with `tools/simulate.py run --variant <folder>` into a new output directory. Threads can run simultaneously with separate projects, import caches and profiles. Do not share editable variant directories or point candidate code at canonical files/player saves. Keep policies, seeds, bounds, design status and actual coverage explicit; candidate results do not approve gameplay values.

When the addition is ready for implementation review, create a source-pinned handoff with design decision, exact delta, evidence and acceptance criteria, then add a concise entry to the internal `docs/codex/TODO.md` pointing to it. Re-read TODO immediately before a minimal edit so other handoffs are preserved. The implementation thread owns reconciliation and adoption into the authoritative `patch-notes/` project; one overlapping canonical gameplay implementation at a time still applies. A variant, successful run or TODO entry does not auto-merge, commit, dispatch another chat, or establish final approval.
