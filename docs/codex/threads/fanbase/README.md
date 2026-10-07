# Fanbase design thread

This is the dedicated local record for this Fanbase design thread. Other design threads use their own folders. Add new dated, versioned files here; do not append to another thread's log. The shared [documentation index](../../README.md) links here, and the [authoritative Fanbase design](../../design/fanbase.md) holds approved system rules.

## Find the work

- [Context and current questions, v2](2026-10-06-context-v2.md)
- [Local evidence summary, v1](2026-10-06-evidence-v1.md)
- [Drive handoffs and local queue reconciliation, v1](2026-10-06-drive-handoffs-v1.md)
- [Rent-era legal route fan-rule shadow, v1](2026-10-06-current-route-shadow-v1.md)
- [Implementation handoffs](handoffs/README.md): the main implementing thread should read this index first, then only the handoffs marked ready.

## Boundaries

This thread records decisions, evidence, open questions, and handoffs. It does not edit gameplay or the internal [TODO](../../TODO.md), merge, or push. Update TODO only when the user explicitly prompts it. Use local evidence first; consult Drive only if essential authority is missing or demonstrably stale. Keep **LOCKED**, **ACTIVE/TRIAL**, **OBSERVED**, **OPEN**, and **SUPERSEDED** separate. Branch behavior and test results do not, by themselves, approve numerical tuning.

When the user approves a rule, record the decision and rationale in a new versioned file here and reconcile it into the authoritative design document. Cross-system decisions belong in [DECISIONS.md](../../DECISIONS.md). Give the main implementing thread a versioned handoff with source revision, exact behavior, dependencies, acceptance checks, and status. Do not duplicate work already present on its Fanbase branch.
