# Patch Notes repository workflow

Read docs/codex/CURRENT_STATE.md and docs/codex/TODO.md first. Then read only the relevant docs/codex/design/<system>.md, findings and recent logs. Inspect branch, HEAD, status and diff before edits or status claims.

The repository is the shared design and engineering memory. Chats are working environments; persist important decisions in design documents, cross-system decisions in DECISIONS.md, work state in TODO.md, and material high-level changes in CURRENT_STATE.md. Findings are evidence, not design approval. Keep LOCKED, ACTIVE/TRIAL, OPEN and SUPERSEDED rules distinct.

Use Drive only for missing/ambiguous authority, explicit synchronization or necessary historical evidence. Existing design-logs and old Drive instructions demanding full cumulative-history reads are superseded by this workflow. Read docs/codex/README.md for source provenance and update conventions.

Preserve existing worktree edits and .codex-godot-temp. Use one overlapping gameplay implementation at a time. Do not turn candidate values into approved gameplay. Verify implementation claims against source and focused behavior checks. Leave a concise dated local session log with branch/commit state, changed files, exact checks/results, blockers and follow-ups. Do not claim a commit, push or release readiness without evidence.
