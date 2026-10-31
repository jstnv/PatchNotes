# Pictured low-Review save predates the 27-Scope grant — 2026-10-30

**Finding:** Read-only inspection found the local Studio `a` checkpoint whose four rival releases match the screenshot exactly. Its saved rival world identifies predecessor mechanics `33f44f0c61446daf6f464bee3c04f689a437d4b08704d2c3dbc65874778a1f27`, not the later 27-Scope source `c4436b020d6580b0ddc79f40e18f085e43c742965e2bcfdce75104fe386255d1`. The game may have been fully relaunched afterward, as the user reports; restoring this saved world correctly preserves its original rival ownership. This resolves the screenshot's provenance without assuming the user continued an older *different* Studio or ran an old executable.

The two matching local checkpoint generations for Studio `a` were last written **09:22:49** (cycle2) and **09:29:11** (cycle20) America/Los_Angeles on October30. The new `rival_starting_pool.gd` file was written **09:37:43** and the changed `rival_trial.gd` **09:38:59**. Thus this particular Studio was saved before the 27-Scope creation code existed locally. The cycle20 checkpoint SHA-256 at read time was `638d20c62f04631e61b879ad73673443e96fbf8f19a2dfbc83c0be3f222b2976`. No save was copied into the repository, modified, used as a simulator start, or replayed.

| Rival release in the matching save | Cycle | Review | Played Scope | Remaining Bugs | Core `[G,S,T,D]` |
| --- | ---: | ---: | ---: | ---: | --- |
| Arcade Foundry 1 | 8 | 0.9 | 12/30 | 2 | `[15,11,15,13]` |
| Wayfinder Works 1 | 8 | 1.3 | 14/30 | 0 | `[20,10,11,17]` |
| Arcade Foundry 2 | 14 | 1.0 | 12/30 | 0 | `[15,7,7,9]` |
| Wayfinder Works 2 | 16 | 0.9 | 14/30 | 0 | `[16,6,13,23]` |

Arcade owned12 Feature IDs and Wayfinder13, including retired Audio IDs and the original extras. Those are the predecessor roster, not the fixed fresh 27-Scope membership (19/20 IDs) in `rival_starting_pool.gd`. The zero-Bug second releases show that QA alone would not cure the low Reviews: their Scope and Core production are too small. The current [fresh-source five-case check](2026-10-30-fresh-27-low-review-reproduction-finding-v1.md) separately confirms both new rivals receive27 Scope and score2.2–5.0 in its cases. That is an improvement, but still below the user's challenge target.

**Reproduction boundary:** The read-only command parsed each JSON envelope's `payload_utf8`, inspected `rival_world.source_identity`, `rival_world.studios[].run.run.owned_features`, and the frozen `release_metadata[].value.review` fields; it decoded stored IEEE-754 Review values without invoking Godot or loading the save as a simulation checkpoint. PowerShell `Get-Item` supplied the two checkpoint and source-file write times. The saved source identity and exact four release rows match the screenshot; no private player save bytes are retained as an artifact. The current source's old-world Continue rule deliberately keeps old ownership/projects instead of regranting cards.

**Next check:** A newly created Studio after the 27-Scope code is loaded should show the fixed 27-Scope rival roster; simply relaunching and continuing Studio `a` cannot upgrade these rivals. If a genuinely new post-update Studio again produces the pictured four low releases, inspect its saved source/roster identity before changing balance. The broader 27-Scope quality gap remains documented in the [factor finding](2026-10-30-live-rival-review-gap-finding-v1.md). No canonical gameplay, TODO, player save, commit or push was changed here.
