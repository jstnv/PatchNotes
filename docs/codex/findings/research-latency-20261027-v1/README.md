# Research responsiveness verification — 2026-10-27

**REGRESSION REPRODUCED; NOT FIXED.** Latest source25dc0a... still has a late-game synchronous Research hitch despite passing cache/save tests. Two fresh native runs: queue607/505ms, Research2497/2229ms. Headless split: total824ms, rival calendar647ms, Store refresh86ms. Native idle rendering also has253ms maximum frame gaps, so no native60FPS/CPU-only guarantee is made.

[Exact source, probe/input hashes, commands and outcome data](verification.json) · [session and follow-up](../../logs/2026-10-27-research-latency-verification-v1.md). The native repeat probe is retained as copied before execution. Original genuine four-release/c96 fixture has declared historical synthetic solvency funding; it is unchanged, privately restored, and never pointed at player saves. Rules/policies/history/validation/RNG are unchanged.

No500ms+ action screen remains FAILED. Cycle192 stage and additional repetitions stop after the first miss; not covered. Durable generations validate and frames continue during the worker, but that does not eliminate synchronous action work. The197 cache/parser assertions passing is narrower evidence. No gameplay fix or new executable was made. Future work should isolate rival observation/policy/command and Store refresh hotspots, then verify exact outcome/RNG parity and actual late-save button latency.
