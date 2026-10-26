# Cardinal Store trees and parent changes — 2026-10-18

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; shared dirty worktree and `.codex-godot-temp` preserved. Direct user request implemented locally. No commit, push or export.

## Changes

- Inner cardinal root axes and grid-based outward cones; Gameplay/Audio swapped to lower-left/upper-right. Visual/Audio trees open away from the upward Tools crown. Every fork keeps one child aligned and the other adjacent. Category camera jumps now wait for actual scrollbar layout.
- Six approved parent changes in FeatureStoreCatalog: Multiple Endings→Branching Dialogue, Secrets→Exploration, 8-Bit Music→Music, 8-Bit Sound→Sound Effects, Scrolling→Text, Sprites→4-Color Palette. No scoring/card values, prices, specialty rosters or underlying FIFO/payment changes.
- Studio checkpoint branches2 and exact prior-world compatibility preserve actual old ownership, paid queues, finance/RNG and Founder data.
- Runtime files: `scripts/ui/feature_store_map.gd`, `scripts/cards/feature_store_catalog.gd`, `scripts/persistence/studio_checkpoint.gd`, `scripts/market/rival_world_checkpoint.gd`. Added parent/render verifiers with UIDs; updated six existing Store/Primitive/research/navigation/guidance expectations for the new contract. [Complete task file list/diff](../findings/store-cones-20261018-v1/README.md).

## Exact evidence and follow-up

[Source-pinned results, commands, source audit, preserved early failures and screenshots](../findings/store-cones-20261018-v1/README.md). New parent225/225, earlier branches177/177, two-parent65/65, FIFO26/26, Store66/66, navigation78/78, checkpoint93/93, specialty245/245, Alpha pack174/174, guidance38/38, native288/288 (24 captures), world30/30 and prior-world8/8 pass. Final 727 source/asset inputs match the tested project, runtime `f4303f0101e1971026080ec0b0acf3c817e96675fa190758d7c8651b8969a412`.

The user added a pause-track follow-up while checks ran; its [separate log](2026-10-18-pause-track-continuity-v1.md) records the audio-only hardening and WASAPI boundary. Handoff017 remains queued; no specialty rollout was folded into this request. Full release gate, export, balance and human map acceptance were not rerun.
