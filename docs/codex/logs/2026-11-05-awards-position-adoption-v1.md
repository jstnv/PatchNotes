# Awards nominee placement adoption — 2026-11-05

On `main` at `2ad3cf2b2bb63d324a970b10864b0f69843dcb1a`, the user requested completion of the queued UI handoff. The current shared awards implementation and verifier matched the isolated candidate's baseline before adoption. Existing edits, real saves and `.codex-godot-temp` were preserved.

The nominee cards and podium move together to sit above the fixed Next button; ties, constrained scrolling, opening/final pages, award state and existing animation remain. Runtime: `scripts/ui/annual_awards_ceremony.gd` SHA-256 `DA942F7CC45476BB84C38EB7CBD9BE62CB6365241716C90FB8551C41A8F8F981`. Updated `verify_annual_awards_ui.gd` and added `verify_awards_nominee_position.gd`.

All checks ran in the isolated project/profile under `sims/awards-adoption-20261105/`. The before-state position verifier failed **3/9** expected positioning checks (gaps 114, 162 and 234 pixels). After adoption, native positioning passed **9/9** at 900×600, 1152×648 and 1280×720 with a 12-pixel gap; tie and intro assertions passed. The full native awards UI verifier passed **332/332**; both final stderr files were empty. The 1280×720 capture was visually inspected. No exported/device acceptance or release claim is made.
