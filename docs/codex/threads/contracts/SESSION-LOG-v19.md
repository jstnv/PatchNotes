# Contracts design session v19 — Starwave bounded-trial approval and handoff

2026-10-08 (America/Los_Angeles). The user explicitly approved the exact Starwave bounded pilot recommended after SW1–SW3: three hands, Scope14/each Core7, up to $2,240 completing-hand cash, $0 acceptance advance and 0 Starwave Promotion. This is ACTIVE/TRIAL design approval, not a final balance lock or implementation verification. Branch `main`, HEAD `91ce539978b87ac0a6efe3a1e028cae5f1360f19`; the shared worktree had extensive preexisting dirty gameplay and documentation. Read `CURRENT_STATE.md`, `TODO.md`, repository update conventions, current publisher design, SW3 and HANDOFF, and inspected branch/HEAD/status/diff before editing. No Drive authority was needed because the user ruling and local evidence were clear.

Changed files in this session:

- New [approval v4](APPROVAL-v4-starwave-bounded-pilot.md) records exact rule, user authority, evidence limits and non-implementation status.
- New [S1–S5 implementation handoff](HANDOFF-STARWAVE-v1.md) specifies offer/freeze, third-hand/scoring/cash, typed checkpoint/rollback, UI and integrated/exported acceptance with serial stop gates and current Task10/11 dependency.
- [Publishers/Contracts authority](../../design/publishers-contracts.md) and [cross-system decisions](../../DECISIONS.md) record the ACTIVE/TRIAL rule and distinguish old Starwave candidate language from the later ruling.
- User-authorized [shared TODO](../../TODO.md) now queues S1–S5 after the completed SW1–SW3 study; its Contracts status and publisher summary are reconciled. [README](README.md) and [HANDOFF](HANDOFF.md) now show approved versus queued versus implemented status.

Checks: `git diff --check` over the five edited tracked documents exited 0, with only Git LF→CRLF working-copy warnings. New-file trailing-whitespace and relative Markdown-link checks passed after this log was created. Exact-cent arithmetic for completion numerators `0/56/112` gives `0/112000/224000` cents as specified. `rg` confirmed current source still has only Starwave's profile and `ContractState.REQUIRED_HANDS := 2`, so this is an implementation queue, not a gameplay claim. No gameplay, maintained tests, assets, configuration or simulations were changed or run in this design session. No commit, push, merge or release claim.

Follow-up: the main implementing thread executes S1→S5 in one coordinated gameplay slot, preserving other publisher behavior and reporting source-hashed gate evidence. Existing C5 final repaired-export confirmation remains separate and gates Starwave exported acceptance. Low-cash advance rescue, other specialty pools, player preference and final publisher balance remain OPEN.
