# Symmetric card frame integration — 2026-10-09

Implemented locally on dirty `main` at `41c87c76fb4d3c06a5332d93f0e7b0997007475d`. No commit or push. User authority: integrate the attached kit, preserve scoring and capture native/displayed cards. This request authorizes the bounded rendered screenshots; the broader overnight Computer Use/exported-playthrough hold remains in place. No Computer Use or user save interaction was used.

## Source and presentation

Read the supplied ZIP's README and revision-3 layout manifest before inspecting the existing CardView/data bindings. Original bytes and hashes are retained in [kit-manifest.json](kit-manifest.json); only the complete frame, background, two lifecycle icons, Tiny5 font/license and source README/manifest were imported. Separate frame/band assets are not rendered or imported.

Card-local bounds are 240×336. Draw order is background, existing artwork, complete frame at (0,0), selected lifecycle icon, Godot labels. The existing selection outline remains an optional overlay. Nearest filtering, integer local coordinates, and non-antialiased/non-subpixel Tiny5 import are explicit. Existing fan rotation, 75% display scale and animation are retained.

| Field | x, y, width, height |
|---|---|
| Primary value / type | 10,12,40,30 / 10,46,40,16 |
| Name | 70,18,100,34 |
| Secondary value / type | 190,12,40,30 / 190,46,40,16 |
| Lifecycle slot / icon | 10,296,42,32 / 19,300,24,24 |
| Department | 70,300,100,24 |
| Scope | 188,296,42,32 |

Both score pairs use existing CardData fields. Missing secondary text is cleared even when recycling a previously two-score view; the frame stays symmetrical. Beta retains its V-value and hidden Scope, with QA operation or Beta category in the footer and lifecycle in the icon/tooltip. Scope uses `S<number>`; score labels use `GFX`, `TECH`, `MKTG` where needed. All text is rendered by Godot.

Measured font fitting allows two name lines and one Department/type line. The original three-pixel label line spacing was explicitly removed to prevent a two-line name growing its 34-pixel rectangle. Full wording remains in the card tooltip. All 51 current ledger/Store card definitions fit without ellipsis; minimum name font is 11, Department font is 14. Unbounded future labels have a tested ellipsis fallback. Numeric fields are verified for all current cards; arbitrary future oversized numeric values are not covered.

## Verification

Godot `4.7.1.stable`, isolated profiles, no scoring/data/transaction changes. [Machine-readable summary](verification-summary.json) confirms current source hashes still match all eight final checks and export inputs. Individual folders retain exact commands, output, source hashes and driver hashes.

| Check | Result |
|---|---|
| `verify_card_frame-v2` | PASS: 1,708 assertions; 51 cards; zero failures or truncated catalog fields |
| `verify_design_phase-v2` | PASS |
| `verify_alpha_phase-v2` | PASS |
| `verify_beta_card_data-v2` | PASS |
| `verify_beta_base_hand_resolution-v2` | PASS |
| `verify_card_motion-v2` | PASS; existing 140 BPM / four-bounce specialization timing |
| `verify_contract_presentation-v2` | PASS |
| `verify_pool_organization-v2` | PASS |
| `capture-v3` | PASS: real GL Compatibility viewport capture; native and two supported window sizes |
| `export-v1` | PASS: clean import/export, 225-entry PCK audit, every payload MD5 checked, excluded material absent |
| `export_check.py` | PASS: clean font settings retained, original OFL copied/hash checked, uninstrumented headless EXE main-menu startup exit0/no runtime errors |

The maintained new verifier also covers draw order, exact bounds after layout, correct kit icon paths, secondary recycling, selection, Beta semantics, font metrics, long future wording and unchanged CardData signatures. Existing focused suites cover authoritative phase/selection/resolution behavior. The broader previous 104-suite gate predates this UI change and is not presented as a fresh full rerun.

Run focused checks with the bundled Python and `run.py <fresh-label> <verify_name>.gd`; rendering uses `run.py <fresh-label> capture.gd render`. `run.py import <fresh-label>` uses a fresh isolated editor profile. The exporter is `docs/codex/findings/export-queue-v3/export.py` with `OUT` set to this finding's export folder; its clean copy now preserves font import settings and ships `Tiny5-OFL.txt` beside the EXE. Build paths/hashes are in [build-manifest.json](export-v1/build-manifest.json); accepted startup is recorded separately in [startup.command.json](export-v1/startup.command.json).

### Preserved preparatory failures

`import-v1.log` records default editor-settings path errors; isolated `import-v2` succeeds. `frame-v1` rejected a missing test lease environment value before testing. `frame-v2/v3` exposed 20 name-rectangle failures from inherited line spacing; the scene/measurement fix resolved them. `verify_card_frame-final` stopped in the Python runner before Godot because its runpy path was relative; the corrected runner is source-pinned in the accepted runs. Earlier capture-v1 requested 1152 but DemoSettings reset it to 1280; capture-v3 asserts and records the actual sizes. These are retained, not counted as passing evidence. The exact host root-certificate-store warning is filtered separately from runtime errors.

## Screenshots and limits

These are actual Godot CardView/AlphaScene renders using a deterministic presentation fixture, not a human playthrough or an earned gameplay route. The fixture supplies seven fixed candidate cards and an explicit temporary RunState; no save/Continue acceptance is inferred. Screenshot dimensions and live fan transforms are recorded in [captures.json](capture-v3/captures.json).

- [Native gallery, 240×336 cards at scale1](capture-v3/native-gallery.png)
- [Native two-score finite Levels](capture-v3/native-levels.png)
- [Native one-score finite Text with existing artwork](capture-v3/native-text.png)
- [Native renewable Technology Pass](capture-v3/native-technology_pass.png)
- [Native long Character Backstories](capture-v3/native-character_backstories.png)
- [Displayed fan / selected card at 1152×648](capture-v3/displayed-selected-1152.png)
- [Displayed fan / selected card at 1280×720](capture-v3/displayed-selected-1280.png)

Visually inspected final native gallery and both selected in-game sizes. All current text fits its own rectangle. Score types remain small at the existing 75% fan scale, and neighboring cards can cover secondary fields until selection brings the card forward; both selected screenshots expose both scores. Existing missing card artwork still uses the kit background. No new artwork, fan-layout redesign or broader exported interaction is claimed.
