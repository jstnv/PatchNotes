# Technology root row spacing — 2026-10-28

Direct user request: Menu System left, Keyboard & Mouse centered, Controller immediately right. Branch main, HEAD f3e0f2b5d35270c879327bc297b389748571feb4; inherited edits/concurrent design records and `.codex-godot-temp` preserved.

- `ui/feature_store_layout.gd`: Controller cell(2,-3)→(1,-3). Menu(-1,-3), Keyboard(0,-3), Controller(1,-3) now occupy neighboring212px grid cells.
- `ui/feature_store_map.gd`: Technology heading centers over Keyboard & Mouse while staying within the category region. Other category headings and all prerequisites/content remain unchanged.
- `market/rival_world_checkpoint.gd`: one exact c15b025cf78073ccbed099f6d6df522279ead2a413de4636b8b37bd3a6714409 predecessor with the same current content revision. Unknown and mixed player/rival pairs still reject.
- Maintained grid verifier now asserts equal neighboring gaps and heading alignment; cold restore checks the exact new presentation source pairing. New native probe uses actual Gameplay/Studio/Store in a private profile and writer, with rendered capture inspected.

Source baseline c15b025cf78073ccbed099f6d6df522279ead2a413de4636b8b37bd3a6714409→39413580c9c5addc58d5ed5e3b60de49be3e2a77c2ebc6fa4bb65c4c8a2add9d. Only three runtime files changed. [Manifests, byte snapshots, owned diffs and exact commands/results](../findings/tech-row-20261028-v1/verification.json).

RED spacing assertion retained (68checks/1failure); RED heading assertion retained (69/1). Final grid69/0, native3/0 and exact cold-world7/0 pass, with source unchanged throughout. Full card/name/header/route clearance and no layout RNG consumption checked. Final native screenshot inspected at1280×720. CRLF-aware owned diff check passes. No new gameplay/performance/release claim, commit, push or export; the prior Research latency failure remains OPEN and scheduled checks remain disabled.
