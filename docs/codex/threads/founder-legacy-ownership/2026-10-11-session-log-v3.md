# Founder Legacy & Corporate Ownership session log v3

**Date:** 2026-10-11 (America/Los_Angeles). **Scope:** document the user's share-sale and valuation-based competitor-offer direction.

## Repository state and changes

- Inspected `CURRENT_STATE.md` and `TODO.md` before relevant records, then `docs/codex/README.md`, founder specification/decisions/handoff and scoped Git state. Branch `main`; HEAD `0132c4da` at inspection. The founder folder was already untracked; shared `CURRENT_STATE.md`, `DECISIONS.md` and `TODO.md` had concurrent edits. This pass preserved them.
- Added `2026-10-11-share-sales-and-control-v1.md` and updated this thread's `README.md` index. The ruling distinguishes a completed share transaction from an offer or warning and pins competitor offer terms to a disclosed valuation basis.
- No production source, simulator variant, shared TODO/DECISIONS/CURRENT_STATE, other thread record, commit, push or Drive document was changed.

## Checks and follow-up

- Confirmed the new ruling file exists and read it back. `git diff --check -- docs/codex/threads/founder-legacy-ownership/README.md` exited 0; the file is currently untracked, so this command does not check its content.
- Two short clarification questions remain pending: whether a competitor offer can compel founder-share sale, and whether other willing shareholders' sales can cause founder control loss. Until answered, [SPEC-v2](SPEC-v2.md)'s explicit founder acceptance and valid other-holder transfers remain the selected design. After the answers, publish a superseding ruling and reconcile the selected specification/handoff if their behavior changes.
