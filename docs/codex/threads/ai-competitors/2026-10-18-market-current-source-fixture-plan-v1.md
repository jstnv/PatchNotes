# Current-source world fixture plan — 2026-10-18

Status: predeclared, audit-only. This does not approve active market values or change canonical gameplay.

## Question and hypothesis

Can the current exact gameplay source produce an unmodified legal Studio/world pair, including optional Founder v2 ownership and a former-player Studio, which its own checkpoint codecs validate and restore? The expected result is a current-source `source_identity` and current `content_revision`, with all Studio, rival, former-player, finance, hand and RNG fields preserved on cold restore. Older presentation-source files remain distinct historical inputs; their source markers must never be relabeled.

## Cases and controls

1. Source freeze: create one `ai-competitors` audit-only variant from current canonical `patch-notes/`. Run a single seed `4417`, no-Traits, Action/Fantasy legal two-release fixture through `tools/simulate.py run --variant` to freeze/import source and record provenance. The existing finite fixture policy uses two legal hands per phase and visible order; it does not grant resources.
2. Current whole-world case: run existing `verify_legacy_world.gd` inside that frozen project, with a separate isolated profile and output file. Its seed `4417` starts a legal player/rival world; explicit tested Founder formation/consented corporate transactions and safe Studio handoff use public APIs; one legal productive cycle lets the former Studio advance under `Trial.policies` with `Trial.ZERO_STEPS`. Capture the real `StudioCheckpoint` and `RivalWorldCheckpoint` output without editing either marker.
3. Current-source cold read: run existing `verify_world_restore_file.gd` in a fresh process/profile against the saved pair; compare payloads except the documented recaptured source marker and demand unknown-source rejection. Historical comparison is read-only against retained `f8f…`, `200a…`, `fd7…`, `0679…` and `3e0d…` evidence and source gates; no old file is passed as a current-source fixture.

## Measurements, limits and stops

Record branch/HEAD, variant baseline/candidate/current source identities and drift, Godot version/hash, exact commands/ports/profiles, run exits/log errors, pair hash, world source, player revision, Founder version/operator/former Studio, counts of rivals/releases/earned sales, codec validation, cold recapture and unknown-source rejection. The simulator case is bounded at 100 commands and two releases. The native fixture uses its existing 90-second internal timer and an external 240-second process limit; at most one current Founder handoff and one post-handoff player cycle. Every process gets a new output directory, isolated profile and unique free test port; no player save, canonical file, `.codex-godot-temp`, shared mutable variant or other thread's output is touched.

Stop on snapshot drift, source marker mismatch, failed legal action, failed codec validation/cold restore, changed old payload data, any engine error, timeout or rejected run. Retain failures and mark the relevant case NOT RUN rather than changing the seed, source marker or budget. Even success is a fixture/provenance result, not normal `CheckpointCoordinator` atomic generation migration, numeric market approval or a canonical adoption handoff.
