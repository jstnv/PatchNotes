# Market browser and overnight queue execution

Started2026-10-22; evidence finalized2026-10-23. **COMPLETE at this pass's approved, feasible scopes.** Shared dirty `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; existing edits and `.codex-godot-temp` preserved. No commit/push or release-readiness claim. The newly approved October23 Publisher P1 task is a separate subsequent implementation; see the current TODO.

## Implemented

- Studio **Market** lists actual player and AI releases through the authoritative index, newest first, with owner filters, stable IDs, frozen Review/Core/Genre/Theme/date and actual units/earned/paid revenue. Historical archives and forecasts are excluded; dormant titles remain. Browsing is passive.
- Market, Finances and Bank retain the existing shared top HUD/chart. Finance's transparent full-viewport blocker still intercepts underlying actions; shading and its existing panel start below the header.
- Market owns Esc before child GUI routing. A visible tooltip no longer consumes the first cancel. Studio focus returns without opening Pause.
- [Simulator repairs](SIMULATOR.md): exclude only unsaved market transaction scratch from detached replay projections; correct current/legacy comparison identities; repair historical fixtures and stale Store/navigation assumptions. No scoring, finance, Fanbase, market coefficient or AI-policy rule changed.
- [Publisher intake](PUBLISHER-INTAKE.md) and [AI Store intake](AI-STORE-INTAKE.md) were completed as reviews. Private candidate code was not adopted by this pass.

## Source and acceptance boundaries

Final canonical mechanics identity: `652f14adf47d7b305e40503e6f624ce1acfe8813fe72d31e249e8572930de14f`, pinned in [final3 source](final3/source.json). The final compiled-PCK identity is intentionally different: `30aceef1a405ac3c3b3db2cd03b35bae45d3d8959d0aacd23a0aacf5a0267453`. Replay hashes source or compiled inputs respectively; this does not permit arbitrary cross-build saves.

| Check | Verified result and limit |
| --- | --- |
| Full maintained gate | [Gate5](gate5/gate-result.json):173 suites, import, clean335-entry package audit, headless and graphical EXE startup, unchanged source set. This precedes the final Esc delta. |
| Exact final delta | [Normalized source comparison](gate5-final-delta-v2.json): only Market, its verifier and the exact-known-predecessor list changed after Gate5. [Eight affected runs](final3/results.json) pass, including headless104/native104 Market assertions at both sizes, Pause64, Founder/world, Finance118, Bank and HUD checks. [Red regression](cancel-red/results.json) failed exactly both cancel assertions before the fix. |
| Final new-game campaign | [Record](campaign-delta-record-process.json) and [fresh replay](campaign-delta-replay-process.json):108 legal commands, six player/twelve AI releases, cycle42, replay7359 assertions, no script/runtime errors. [Whole gameplay comparison](campaign-delta-no-rule-change.json) is exact except source provenance. Two hands per phase; this route does not buy Store/Bank/Contract actions. |
| Final export | [Current-source incremental build](final-build-warm/result.json) retains only hash-verified unchanged Gate5 asset imports after two fresh imports exhausted host memory. All335 payload MD5s validate. [Actual payload delta](packaged-runtime-delta.json): only the two intended runtime `.gdc` files changed; the other333 entries are byte-identical. Both EXE startup modes pass. This is not a new clean-import/full173-suite claim on the final delta. |
| Compiled runtime proof | [Packaged check v3](packaged-identity-v3.json) verifies the compiled identity independently derived from PCK payloads, final `_input` callback and unchanged default worker setting. [Actual predecessor preparation](native-final-input-prepared.json) preserves every player/world field except accepted source provenance through the real codec/store. |
| Native final EXE | Actual Continue,18-game Market, AI detail, visible-tooltip single Esc, Finance/Bank shared header and normal exit0. [Market](native-final-market-all.png), [AI tooltip/detail](native-final-tooltip.png), [Esc return](native-final-escape.png), [Finances](native-final-finances.png), [Bank](native-final-bank.png). Earlier same-pass build additionally verified AI filter12/18 and legal zero-capacity quote rejection. |
| Earlier focused boundaries | [Continuation/batch/reducer/four stress routes](i/results.json), [historical economics/migration/full-world cold replay](n/results.json), [actual old-world restore](final/results.json), [streamed trace equality](streamed-trace-parity.json), [90 tools tests](tool-tests.log) and [30 final affected tools tests](tool-focused-final.log) pass at their pinned revisions. |

Final EXE SHA256 `7c3e92d9c175dc8754947c93f2ad6d9514091e51cf542407b7595e2bbbd20257`; PCK `2633a4787c1e03d73044497916151e482e778d7a420ee8be30e695825b81966d`. [Actual process/profile](native-final-input-process.json) and [normal exit](native-final-input-exit.json).

## Retained failures and remaining work

Early diagnostic scans and failed gates are retained, not counted as passes. Host commit exhaustion interrupted export, later trace serialization and two final fresh imports. Evidence serialization is now bounded by route with all parsed values exact; export uses Dummy text only for packaging, while font import/runtime retain normal text. The unsuccessful import-worker trial was removed and did not change shipped settings. The final incremental build's font/audio/scene payloads exactly match the clean Gate5 build.

Native capture also returned black or mismatched pixels and later reported Direct3D allocation failure/timeouts. No input was sent to mismatched Codex pixels. Reconnection/fresh observations recovered the target; all three isolated EXE processes exited0. Completed Git/Godot host crash notifications were dismissed. These observations do not establish clean-machine/device acceptance.

Diagnostic corrections are retained: the v1 source-delta audit failed to normalize Windows paths; v2 is authoritative. The first packaged probe incorrectly expected the canonical-source identity in compiled code, and v2 used an invalid static introspection call; v3 corrects both. An initial non-isolated settings probe failed at unwritable user logs; its isolated rerun confirmed the setting. These are harness/environment failures, not passing gameplay evidence.

Remaining: human Bank quote comprehension, audible mix/device latency, asset approval and clean-machine acceptance; inaccessible Bank age2+/older-education/newer-Bank combinations; OPEN AI planner/population/news/leaderboards, publisher P2–P4, Store rollout, Founder career, courses/final balance; explicitly deferred studies. The separate October23 P1 approval supersedes the earlier P1 adoption gate and is now queued. No Bank rule was changed to force a route.
