# Visual and performance audit intake — 2026-11-04

User requested alternating visual/animation-clipping and performance checks until 4:30 PM America/Los_Angeles, with no routine input. Started at approximately 06:21 PST on `main`, HEAD `2ad3cf2b2bb63d324a970b10864b0f69843dcb1a`; retained existing uncommitted Production visualizer and Fanbase performance changes, other edits and `.codex-godot-temp`.

C: had roughly 403 MB free. Avoided launching Godot, importing, creating large profiles or snapshots, and did not touch real saves. This is a storage blocker for fresh interactive and performance verification; no claim of a completed whole-game audit.

Read-only inspection of the previously captured actual Design-hand screenshot at `.codex-godot-temp/production-visualizer-hand-native-20261104/Godot/app_userdata/Patch Notes/production-visualizer-live.png` shows the persistent contextual tip covering the rightmost card titles at 1280×720. `patch-notes/scripts/ui/contextual_tip.gd` currently allows narrow-width overlap. This is an observed prior-capture obstruction, not a new live reproduction; assess a layout fix and pointer interaction when adequate space permits.

Read-only performance review of the existing owner-proof trace suggests another candidate: retain exact typed validation keys while evicting or dropping decoded values under the existing byte cap. The existing decoder already has a no-native fallback, but strict sequence/content/context, active-mode and concurrent eviction behavior require independent testing. This is a hypothesis only; it has not been implemented or benchmarked. The 48 MiB cache candidate remains unadopted pending its stated safety and memory gates.

Created a 30-minute same-chat follow-up through the user's 4:30 PM deadline, with a free-space gate before heavy tests, alternating useful visual and performance work where possible, and no commit or push authorization inferred. Initial automation creation without a thread destination was rejected as invalid; the explicit same-thread creation succeeded. Preserve these limits in later results.
