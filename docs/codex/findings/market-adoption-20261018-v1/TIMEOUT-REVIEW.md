# Retained cycle-13 timeout review — 2026-10-22

## Scope and source

Read-only investigation followed by a narrowly authorized debug-verifier clarification. No gameplay, Bank, save schema, shared TODO, commit or push change. `main` remains at `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; gameplay identity is `5783246fcb2ecd6612eccf8e06cde72490db3ebb2944b8592e0943bfdaf94536`. The debug verifier is excluded from that identity by the existing source-pinning convention.

The exact original command and log are retained in `docs/codex/threads/ai-competitors/sims/market-density-current-world-20261018-v1/`. [Source hashes](timeout-source-audit.json) pin those inputs and compare the old project, adoption's `before-source.zip` and current files.

## What the historical evidence proves

The October18 control launched `verify_rival_trial_activation.gd` against the sealed current-control project, with a 240-second external deadline. Its command record reports `exit: timeout`, elapsed240.031 seconds and no parsed runtime error. The last log line is the successful cycle13/Beta observation with two actual rival publications.

That line prints **before** a separate world capture and an atomic Studio flush. The next line would print only after capture, flush and the next player/rival advance. Consequently the log does not locate a single stalled function and does not prove the rival choice loop itself hung. This harness executes twenty cycles synchronously; its SceneTree90-second timer cannot interrupt synchronous GDScript work. The external process deadline is the effective bound.

The old harness and adoption's before-source harness have identical SHA-256 `0c9242e51c13a88e8ad170969106f638a7d6cb4846430ce3d7baf01bc426a050`. The original `studio_checkpoint.gd`, coordinator and storage files also exactly match the adoption's archived before-source bytes. This is not a guessed reconstruction of the old verification workload.

## Source-supported cost explanation

The historical `StudioCheckpoint._validate` eagerly computes seven three-entry catalog revision sets and two nine-entry legacy revision sets:39 `_rules_revision` calls before decoding even a current payload. Its `_decode_payload` computes a further21 revision variants. Each variant walks the six-JSON data tree and hashes applicable files. These variant sets are not cached by those helpers. The current-revision fast path now uses the current revision and strict current schema directly; named old data still takes frozen historical validation.

Every harness cycle also captures the world separately, then asks the coordinator to capture and publish it again. `StudioCheckpointStore._publish` validates the previous generation, candidate, flushed temporary generation and retained generations during pruning. Each complete world validation restores owner state and checks provenance; world capture/read also computes the mechanical source identity. Thus repeated full validation and file hashing are a concrete amplification path. Growing release/Fanbase/history ledgers add work after publications.

**Inference:** repeated checkpoint validation/hash work is a credible contributor to the old deadline. No historical per-stage profile, stack sample or controlled old/new timing pair exists, so this report does not claim a proven sole root cause or attribute a numerical speedup to one change. Concurrent processes, filesystem cache and host load also differ.

## Same-harness current run and restore diagnosis

`timeout-current-v1` ran the byte-identical maintained harness on current gameplay through isolated `run.py`, with a300-second external deadline. It completed all20 cycles and four rival publications in197.504 seconds wall /123.609 seconds Godot process CPU. It did **not** time out, but exited1 with four persisted-session digest failures among118 checks. This is retained failed evidence, not a passing test.

The diagnostic `trial-restore-diagnostic-v1` captures the full before/after session projection. Both rivals differ only in `RunState._market_committed_candidate`, repeated through the session/run/hand aliases. Before Continue it contains the already-committed neutral snapshot; after Continue it is empty. The durable `world.market_snapshot`, RNG, hands, projects and all other serialized session fields are equal. This candidate is transaction scratch: a successful productive action overwrites it before world advancement; the world snapshot is the saved authority.

The explicit original-versus-restored branch proof `trial-restore-continuation-v2` passes37/37 in16.423 seconds wall /13.672 CPU. It asserts the exact saved market snapshot, confirms the original scratch equals that committed snapshot and the restored scratch is empty, then compares two further productive cycles. Both branches have identical rival action receipts/events, player and world checkpoint payloads, RNG and all full session fields; after the first next action even the unnormalized session projections agree. Independent JSON readback confirms both rivals' complete states match after cycles2 and3. V1's diagnostic used raw Dictionary equality for bound Callables and failed those object-identity comparisons; it is retained, and v2 uses the established replay-digest projection.

## Maintained verifier clarification

Only `scripts/debug/verify_rival_trial_activation.gd` changes. Persisted-session comparisons omit exactly `_market_committed_candidate` at its three known RunState aliases; all other session fields remain compared. Two additional assertions require exact nonempty saved `world.market_snapshot` equality at the Design and Beta Continue points. No runtime field is removed, persisted, normalized or otherwise changed by this test clarification.

The corrected maintained run `timeout-current-v2` passes **120/120**, exit0, all20 cycles and four real rival publications, with an empty parsed error list. It takes155.592 seconds wall /118.984 seconds Godot process CPU, below both the original240-second cap and the new runner's300-second safety bound. The original and corrected logs remain separate. This closes the bounded current-harness timeout check and clarifies the four nonpersistent-scratch comparisons; it does not turn the original historical timeout or the current-v1 failed assertions into passes.

An independent post-edit enumeration of138 non-debug mechanical inputs still hashes to `5783246fcb2ecd6612eccf8e06cde72490db3ebb2944b8592e0943bfdaf94536`. `git -c core.whitespace=cr-at-eol diff --check -- patch-notes/scripts/debug/verify_rival_trial_activation.gd docs/codex/findings/market-adoption-20261018-v1/TIMEOUT-REVIEW.md` passes.

## Limits

This twenty-cycle test deliberately advances a player calendar through the public productive transaction while testing real rival choices and atomic storage at every boundary. It is not a normal player campaign or a human playtest. The legal campaign records provide that separate coverage. Process CPU is actual Windows user+kernel time; elapsed time includes file IO and contention. These observations do not establish a stable population budget, higher-population scaling, long-campaign performance or final balance. The preexisting six-instance ObjectDB shutdown warning is retained.
