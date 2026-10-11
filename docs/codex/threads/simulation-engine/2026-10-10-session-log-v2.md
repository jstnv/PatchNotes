# Architecture audit session — 2026-10-10

## Scope and checkout

User explicitly authorized a documentation-only Simulation Engine architecture pass using HANDOFF/REVIEW-v1. Read CURRENT_STATE, TODO, shared README, core/release/economy/Store/Fanbase/publisher design and current AI handoff/staged/world/scope records. Inspected source, branch, HEAD, dirty status and diff. `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`; initial ordinary status328 entries, tracked diff75 files/2,006 additions/522 deletions. Existing implementation, `.codex-godot-temp` and user saves preserved. No agents dispatched.

## Deliverables / changed files

Only this Simulation Engine folder was written:

- `2026-10-10-architecture-v1.md`: ownership/dependency audit; proposed module graph; state/command/event/RNG/policy contracts; layered parity plan; risks, OPEN gates, staged milestones, benchmark methodology and one first extraction recommendation.
- `README.md`: index/status for completed audit and candidate next seam.
- `source-pin-2026-10-10-v1/manifest.json`: SHA256 of545 runtime/source/design/AI-authority files.
- `source-pin-2026-10-10-v1/status.txt`, `tracked.diff`: observed expanded worktree status and tracked source/design patch. Expanded status produced Windows long-path warnings for old findings shader caches; not a full cache inventory.
- `source-pin-2026-10-10-v1/runtime-source.zip`: source-only archive including untracked runtime scripts; not a distributable build. SHA256 `3edf2ee26f9282ebfe95803e0e49162b4fb3a1cbbe8deae026d83393a80a84fe`.
- `source-pin-2026-10-10-v1/verification.json`: current-source integrity and document-link checks.
- This session log.

## Source findings

RefCounted run/project/finance/sales/Fan/Review helpers provide a substantial base, while phase Controls still own selection identity, pool state, deal/replace planning, finalization and UI allocation. Central productive commit preflights economic consequences but assumes callback atomicity; it does not undo arbitrary partial callback mutation. Release registration currently happens inside Studio setup. RNG is run-owned but randomized construction and fallback IDs mean seeds alone cannot reproduce complete state. Checkpoint coordinator owns Studio-only/deferred-flush/departure guards; active-phase simulation snapshots must be separate from Continue.

Current hand-local15% Balanced redistribution and percentage playtests were audited from live source. No generic retrigger mechanic was located in runtime scripts/card fields; document its absence and test actual duplicate-callback/familiarity/renewable-instance semantics rather than inventing an effect. AI policy numbers, world tick ordering, entrants/news/performance and migration remain OPEN as specified by current decisions.

## Exact checks and limitations

- `git branch --show-current`, `git rev-parse HEAD`, `git status --porcelain`, `git diff --stat`; expanded `git status --porcelain=v1 --untracked-files=all` and `git diff HEAD -- patch-notes tools/release_gate.py docs/codex/design` saved as audit evidence.
- `rg` method/class/call-site searches and targeted `Get-Content` reads; corrected initially guessed predevelopment/RNG paths using `rg --files`. No missing authority required Drive access.
- Bundled Python3 stdlib (`pathlib`, `hashlib`, `json`, `zipfile`, `subprocess`) captured source/status/diff/archive; a second read-only hash pass checked all545 pinned files: **zero drift/missing files**, TODO unchanged. This is source-integrity verification, not gameplay parity.
- Local Markdown target check on architecture document: **8 links checked, zero missing**. README/log links checked after log creation.
- `git diff --check -- docs/codex/threads/simulation-engine`: no whitespace errors. Untracked architecture was additionally checked via `git diff --no-index --check -- NUL <file>`; expected diff exit1 with no whitespace diagnostics. Git emitted LF normalization warnings only.
- No Godot invocation, gameplay test, simulation, benchmark, desktop control, implementation, TODO update, commit or push in this pass. Prior test counts are not reused as engine verification.

## Recommended next gate

Separately authorize only the shared validated Design/Alpha final hand-production arithmetic extraction. Keep legality, pool/RNG, costs, phase transitions, saving and presentation at existing call sites until later parity gates. Review the draft contract and current-source oracle fixtures first. This audit is complete at documentation scope; all architecture/module names remain CANDIDATE.
