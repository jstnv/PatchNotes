# Shared Patch Notes memory

Established 2026-10-06 (America/Los_Angeles). This tree serves design discussions and implementation/testing across all system chats.

## Routine context order

1. [CURRENT_STATE.md](CURRENT_STATE.md)
2. [TODO.md](TODO.md)
3. Relevant [design](design/) document; consult [DECISIONS.md](DECISIONS.md) for cross-system constraints.
4. Relevant [findings](findings/), then relevant [logs](logs/).
5. Google Drive only if local authority is missing, ambiguous, needs explicit synchronization or historical investigation.

Code establishes what runs; approved design establishes intended behavior. A mismatch belongs in TODO/findings until reconciled, never silently resolved by an old log. New user rulings override older conflicting decisions; record their source/date and supersession. Preserve explicit user scope.

## System documents

- [Studio Traits design thread working folder](threads/studio-traits/)
- [Core loop and Studio](design/core-and-studio.md)
- [AI studios and competitors](design/competitors.md)
- [Economy and banking](design/economy-banking.md)
- [Banking System design thread workspace](threads/banking-system/README.md)
- [Sales and game lifespan](design/game-lifespan.md)
- [Fanbase](design/fanbase.md)
- [Fanbase design thread workspace](threads/fanbase/README.md)
- [Feature Store design thread workspace](threads/feature-store/README.md)
- [Publishers and contracts](design/publishers-contracts.md)
- [Employees and courses](design/employees-courses.md)
- [Employees/Challenges design thread workspace](threads/employees-challenges/README.md)
- [Feature Store and progression](design/feature-store-progression.md)
- [Genre specialties](design/genre-specialties.md)
- [Studio Traits](design/studio-traits.md)
- [Release engineering and checkpoints](design/release-engineering.md)
- [Current Task34 advance trial brief](design/contract-advance-trial.md)

## Update contract

Design discussion: record important rules/rationale and their LOCKED / ACTIVE/TRIAL / OPEN status in the relevant system file; cross-system decisions in DECISIONS; new or changed work in TODO. Update CURRENT_STATE only for material state changes. A chat title or an analysis recommendation is not an approval.

Implementation: inspect current source/status/diff, use the relevant local approved design, verify behavior, save findings, update TODO/design/state as appropriate and write logs/YYYY-MM-DD-topic-vN.md. Log tasks, branch/HEAD/worktree, actual files changed, implementation choices, exact checks/results, blockers and next work. Keep large data/specifications out of logs; reference them. Never overwrite another session's evidence.

Completed analysis and completed gameplay are different statuses. Task IDs from Drive are stable; append follow-ups rather than renumbering. READY for a read-only experiment authorizes that experiment, not runtime implementation. Do not repeat a broad simulation without a new question/defect. Compare current economy proposals at matched calendar checkpoints, actual settlements and opportunity costs.

## Sources and migration boundary

The live [Drive task queue](https://docs.google.com/document/d/1n6o5g8Gj_sDTs5Ku6PLM37OWPPyLpDM_ASfNiD9MRkY/edit) was read on Oct 6 local time; metadata modified 2026-10-07 02:49:49 UTC. Its complete bounded task briefs and historical completions are preserved in [the queue snapshot](archive/drive-task-queue-2026-10-06.txt), for targeted lookup only.

Also read the current [cumulative authority](https://drive.google.com/file/d/1kmlzNwRbckS9OxucMd5WPYNOF2Dx6QT1/view) (modified Oct 6 UTC) and [design/progress archive](https://docs.google.com/document/d/1SlwomB3riLH9qm0maT-4Ixhg9YSbLwUD88abW3NvBwM/edit) (modified Sep 30 UTC). Current rules are summarized in system files rather than copying months of history. Relevant local findings were inspected under patch-notes/design-logs and the Downloads design folder.

Important: root .gitignore excludes patch-notes/design-logs. Those older logs are local evidence, not guaranteed available to a fresh checkout. Their useful current conclusions are now summarized in tracked findings. Source harnesses under patch-notes/analysis and maintained verifiers under patch-notes/scripts/debug remain deeper reproducibility references. No existing history was deleted or moved. See [classification and contradictions](archive/README.md).

This migration reads Drive but does not change it. Future explicit synchronization should preserve revision safety and record direction/date; avoid two silently divergent execution queues. Local files are the normal Codex execution authority after this setup.
