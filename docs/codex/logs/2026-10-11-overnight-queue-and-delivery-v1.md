# Overnight queue and Git delivery — 2026-10-11

Started on dirty `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`, with extensive earlier implementation/design/evidence changes. Read CURRENT_STATE, TODO, relevant handoffs/source and README. Preserved existing work and `.codex-godot-temp`. User authorizes ready queue execution, headless-first verification, fresh-start system testing, and subsequently committing/pushing all accumulated work. No new design values are inferred from that publication request.

## Work and files

- Store008: `patch-notes/scripts/ui/feature_store.gd`, `feature_store_map.gd`; new `scripts/debug/verify_feature_store_copy.gd` and UID; exact-price assertion in `verify_feature_store.gd`. Quote-based copy/fit only. Updated Feature Store design and minimal shared TODO status.
- AI G1a: separate `findings/overnight-20261011-v1/g1a-archive-validation-v1` candidate; bootstrap/restore validation and its private verifier only. Source-pinned corrected packet, replay, continuation and independent audit. No canonical AI changes.
- Fanbase: review/audit record and TODO link; no numerical implementation delta.
- Verification repairs: `tools/release_gate.py`; historical digest helper in `verify_design_phase.gd` used by the Design/Alpha/Beta command and full development replay verifiers; audio-clock redraw slice in `verify_card_motion.gd`.
- Delivery hygiene: root `.gitignore` excludes import caches, scratch work, generated test profiles and exported Windows binaries under docs; root/canonical/five archived-project `.gitattributes` preserve byte-hashed source, evidence and candidate snapshots. All six project source inventories remain byte-identical; the attribute files are outside them. Nothing is deleted from disk. Earlier ignored design logs retain their existing local-only status.
- Complete evidence index: [overnight README](../findings/overnight-20261011-v1/README.md). Earlier accumulated gameplay/tooling/design work is included in the requested Git delivery, with its original session logs retained.

## Exact checks and limits

Godot4.7.1, existing local console executable. `focused.py` records each exact invocation: clean import; Store52 headless/60 rendered/62 existing checks; card motion116. Python `-m unittest discover -s tools/tests -v`:70 tests, exit0. Private G1a29 unit/112 audit checks; two seeded two-release runs; fresh replays83 commands/85 telemetry samples; unmodified Studio continuation21 commands to release3.

Maintained command: `python tools/release_gate.py --godot <local Godot4.7.1 console> --output docs/codex/findings/overnight-20261011-v1/release-gate-v5 --isolate-checkpoint-writer`. The README explains retained v1–v4 failures and fixes. **133/133 suites, clean import/export,275-entry PCK audit and both startup modes pass.** Source/wrapper hashes are unchanged. The machine result has `automated_pass=true`, `release_ready=false`; the gate deliberately returns nonzero for open acceptance. Fresh-start stress routes cover four Genres/trait configurations,344 commands/16 releases; native parity checks cover232 boundaries. No all-possible-state parity, performance or release-readiness claim.

Clean source export:275 PCK entries and startup pass. The isolated desktop attempt did not complete a playable route; the user stopped Computer Use with physical Escape, and all computer control ceased. Exported interaction and audible acceptance remain OPEN. Human Store comprehension remains deferred. Canonical AI cohort/migration/policy choices and other DESIGN gates remain OPEN.

## Publication

The user explicitly requested pushing all uncommitted work after this pass. A fresh `git fetch origin` confirmed `main` and `origin/main` both at the starting HEAD (0 ahead/0 behind). Staging includes accumulated source, design records, private candidates and evidence; generated caches/profiles/export executables stay local. Commit/push outcome is verified separately before reporting success; this pre-commit log does not assert publication has already occurred.
