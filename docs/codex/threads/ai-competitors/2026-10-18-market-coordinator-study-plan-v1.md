# Named pre-market Coordinator/Store migration study — predeclared plan, 2026-10-18

## Question and scope

Can the exact old `f8f130c6a3e6b7d27710e11a56b445ea6c73d9dbc26ca26a8501ca2cf7ca32de` Studio/world source be read through `StudioCheckpointStore.inspect()`, hydrated through `CheckpointCoordinator.load_current()`, and advanced to a new atomic generation without changing the original committed generation? Can an interrupted write and a corrupt current generation preserve the explicit backup recovery boundary? This is a private simulator candidate only. The v18 whole-pair adapter and its trial market terms remain unchanged; no canonical gameplay or shared TODO edit is authorized by this study.

## Hypothesis and comparison

Use the original legal seed-4417 old-world fixtures at cycles 7, 8 and 10 from the retained old-source run. The control is the exact old envelope and v18 adapter direct restore; the candidate routes the same input through the normal Coordinator/Store validator, Continue, committed save, cold Continue, and backup recovery. Compare every pre-migration encoded player/world field after stripping only new schema fields and source recapture markers, plus released Reviews, earned units/cents, Fans, cash, active hands and RNG. A player-only old checkpoint, older world sources, Founder worlds and current presentation sources are outside this bounded test; do not forge identity or expand the allowlist.

## Cases, bounds and stopping rules

1. Create the named `market-migration-coordinator-20261018-v19` child of v18. Modify only its private `project/` copy. Copy the unchanged old cycle-7, 8 and 10 fixture files into an isolated profile and verify their hashes against the v18 finding.
2. For each old pair, construct a valid old `CheckpointCodec` envelope at generation 1 in the isolated Store path, then inspect/load through Coordinator with the real world catalog. Pure Continue must not publish a generation or alter its bytes. One legal zero-work productive player cycle and matching rival advance must publish generation 2 atomically. A fresh process must load it and preserve committed world cycle, market snapshot, owner histories, finance/Fanbase and RNG. Use only the existing explicit finite trial rival policy.
3. For the cycle-10 pair, inject a `before_rename` Store failure during the first post-Continue committed save. Confirm the old generation remains current, in-memory action remains once, further mutation blocks until retry, then retry publishes exactly one new generation. Separately create two valid generations, corrupt the newest one, and verify ordinary load/save refuses it, exposes the prior valid backup, and explicit `recover_backup()` publishes a fresh generation while preserving the corrupt bytes.
4. Reject a forged/unknown old source and a malformed old sale without changing the old file. The retained v18 direct migration checks and a representative legal player replay remain comparison evidence; rerun focused checks after private integration.

Seed `4417`, two legal trial rivals, no Traits, at most three old pairs, one post-Continue productive cycle per pair, two rival releases from the old fixture, 50 player commands for the runner control, at most 240 seconds per Godot process. Use a unique private test port and run Store processes serially with other checkpoint users. Stop on old-source hash mismatch, validator bypass, altered original bytes, changed pre-migration state/RNG/accounting, failed atomic publication or rollback, source drift, or cold restore mismatch. Retain every failed/incomplete output and use a new version/output for each code revision. No UI/computer control, player saves, canonical gameplay, commit or push.

## Evidence and adoption boundary

Record branch/HEAD/dirty status, original and candidate identities, exact commands, process exits/errors, envelope/file hashes, generation numbers, decoded state comparisons and negative results. A passing private Store route is not a production migration: player-only earned sales, the other named world/Founder source families, current canonical drift, graphical/exported Continue, numeric market policy and balance remain OPEN. Only after those are reconciled may the design thread make a source-pinned handoff and minimal TODO entry.
