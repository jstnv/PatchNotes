# Current-source exported interaction — 2026-10-10

Actual Windows exported-game interaction using the Computer Use skill, ordinary mouse/keyboard input, and four isolated profiles. No gameplay edits, save injection, debug unlocks, altered rules, commit or push. Shared dirty `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`. This evidence supplements the [108-suite noninteractive gate](../release-gate-noninteractive-20261010-v1/README.md); it does not establish release readiness or final balance.

## Reproduction and source

`build_playable.py` builds the main profile; the three child directories contain their corresponding builders and export manifests. Run with the configured Python runtime. Each export uses Godot 4.7.1, has 237 package entries, passes headless startup, and has no included gameplay-source drift from the gate or current checkout. Only exported project configuration changes the application name/custom user directory. Exact inputs and hashes: `export/build-manifest.json`, `export/playable-summary.json`, and the matching files in `creation-control/`, `cult-minimum/`, `education/`.

Main EXE SHA256: `7c3e92d9c175dc8754947c93f2ad6d9514091e51cf542407b7595e2bbbd20257`.
Main PCK SHA256: `0bf369cda72cbbffa064830e250e34c1764041fedf5c496e3fb21dc8926b0bcf`.

Profiles under `%APPDATA%`: `Patch Notes Acceptance 20261010 v2`, `Patch Notes Acceptance 20261010 creation control`, `Patch Notes Acceptance 20261010 cult minimum`, `Patch Notes Acceptance 20261010 education`. User saves and existing project work were preserved. All four acceptance windows were quit after testing. Checkpoint copies under `checkpoints/` are evidence, never fed back into the application.

Run `python docs/codex/findings/export-interaction-20261010-v2/audit.py`: **3,304 checks PASS**, 66 captures, ten checkpoint groups, nine retained runtime logs. The audit verifies payload hashes, exact transaction chains/sequences/closing balances, expected cycles/Fans/cash, artifacts and included source. See `audit-result.json`. Initial audit harness field names were corrected to the serialized `*_cents` keys before the passing run; no game defect was implicated.

## Observed acceptance matrix

| Route | Result | Evidence / exact boundary |
|---|---|---|
| Cult creation | PASS | 1280×720 main and 1152×648 separate Cult-only creation: one point, $5,650, 40 Fans. Separate no-trait control: $5,700, zero Fans. Genre/Traits/Overview attention flow observed. Captures 01–02, 53–57. |
| Cult frozen launch / changing month / Continue | PASS | First release Review 2.6, frozen 40 Fans → 10 Awareness; 119 launch Awareness. Actual settlement changes Fans 40→26. Cold Continue retains c9/$6,162.65/26 Fans, trait and history; no reseed. Captures 06–13. Later Review 7.3 yields growth 26→102→124→139→149. ACTIVE/TRIAL remains unchanged. |
| Store research | PASS bounded route | Recorded Sounds: $850 irreversible down payment at c9, no time; $850 Research advances to c10 and grants ownership once. Captures 15–16. This is not a human comprehension study. |
| Bank exported normal route | PASS | Eligibility after two settled sales months; $500/12-month loan at c10, zero-cycle acceptance, cold Continue; first full-month installment at c12 $46.67 ($41.67 principal/$5 interest); payoff $458.33, persisted closed after next Studio and cold Continue. Captures 14,17–24,30–31. |
| Crown A1/A2 | PASS bounded route | Review 7.3 unlock; $150 advance at c24, two hands, $1,770 completion at c26; total $1,920 and 12 Promotion. Captures 32–34. |
| Neon A3 | PASS visible route; aggregate audit not repeated here | Launch Awareness 128 unlocks independently of Crown Promotion. Frozen Graphics focus shown across two hands, $0 advance, $1,560 completion at c28, 20 Promotion. Captures 35–37. No claim that Crown caused Neon unlock. |
| Promotion A4 | PASS bounded consumption/restore | 32 keyed points survive Starwave rollback/Continue, then next successful release has Awareness 169 = base100 + Fan37 + Promotion32. Both keys consumed, bank empty after fresh Continue; no repeated receipt. Captures 41,46,48–52. Deliberately low-Scope release Review0 has zero sales; positive-sales uplift and a second post-consumption launch were not observed. |
| Starwave B1/B2 | PASS | Gate after two releases/three distinct completed Contracts. $0 acceptance/hands1–2; third hand alone $2,240 at c31; Scope20/Core12,10,21,15 gives numerator112/112. Zero Promotion; prior32 retained. Captures 37–46. |
| Starwave B3 | PASS bounded restore | Completed receipt/offer remain after subsequent legal launch and cold Continue at c33/$14,632.53; no reissued offer or payment. Captures 50–52. Monthly settlement/rent occurred; no active payroll/Bank obligation on this route. Immediate post-result restart was not separately performed. |
| Starwave B4 | PASS rollback behavior; protocol variation | Quit after uncommitted hand1 c29, Continue restores c28/$11,843.38/124 Fans/32 Promotion, reaccepts identical opening draw. Rollback was performed before completion in the same disposable profile; completed evidence was subsequently preserved, not reset. Captures 38–43. |
| Education payoff | PASS bounded route | College Dropout creation $5,800 includes $300 unused-point refund, no $5,000 debt cash deposit. Cancel payoff unchanged; confirm $5,000 principal/$0 interest at c0 leaves $800. Finance correctly separates principal from expense. Fresh Continue retains closed account. Captures 58–63,66. |
| Settings | PASS bounded UI persistence | 1152/1280 Apply/Keep and fresh restart exercised; Music/SFX mute flags persist. Captures 20–21,64–65. No audible assessment. |
| Full presentation matrix | PARTIAL | Creation at both sizes; Crown/Neon at1152, Starwave at1152/1280, finance/Bank at both. Not every browser/chooser/hand/result screen repeated at both sizes with keyboard navigation. |
| Late/partial debt, migration, Graduate | NOT RUN in this exported pass | Prior native evidence remains separate. Current visible overdue recovery, first education due/month13 and historical preview migration are not closed here. |
| Task12 audible / Store human understanding | NOT ASSESSED | Computer Use supplied no listening feed or human responses. UI persistence and agent navigation cannot establish these outcomes. |

The full Contracts acceptance script remains PARTIAL because its complete presentation/continuation matrix exceeds these bounded observations. T9's specific Cult route is complete. No new balance values or AI decisions are approved.

## Legal route record

Main studio `Cult Acceptance V2`, Action specialty, Cult only. First project `Cult Launch One`, Action/Fantasy, priorities25 each: Design [Design Pass, Split Screen, Design Pass, Design Pass]; [Menu System, Keyboard & Mouse, Scrolling, Technology Pass]; [4-Color Palette, Sprites, Text, Controller]. Alpha [Maps, Sound Effects, General Combat, Enemies]; [Power-Ups, Multiple Endings, Levels, Exploration]. Beta Marketing [Posters, Press Interview, Posters, Posters]. Confirmed under-Scope26/30 launch: Review2.6, Production4.08, bugs8, Awareness119, Month1 units385. Release at c7/$2,920/40 Fans.

Ironclad: $400 advance; hands [Maps, Multiple Endings, 8-Bit Sound, Enemies], [Controller, Exploration, General Combat, 4-Color Palette]. 100%, $2,000 completion, c9/$6,162.65/26 Fans. Cold Continue. Recorded Sounds queue/Research, then Bank route above.

Second project `Second Wind`, Action/Fantasy: Design [Recorded Sounds, Split Screen, Menu System, Text]; [Controller, Scrolling, Keyboard & Mouse, 8-Bit Sound]; [Graphics Pass, Graphics Pass, Sprites, 4-Color Palette]; four Sound Passes; four Design Passes. Ordinary available redraws used to replace spare passes. Alpha [Maps, Controls, Multiple Endings, General Combat]; [Graphics Pass, Sound Pass, Levels, Power-Ups]; [Exploration, Enemies, Technology Pass, Sound Effects]. Beta [Debug, Search, Debug, Search]; Marketing [Press Release, Sign Flippers, Posters, Press Release]; [Sign Flippers, Press Interview, Posters, Posters]; QA [Search, Debug, Debug, Debug]; mixed [Press Release, Sign Flippers, Sign Flippers, Search]. Available redraws removed Insider cards. At c24: Scope31, bugs0, Review7.3, Awareness128=100+6 Fan+22 Marketing, Month1 units855, cash$1,671.08. Cold Continue confirms paid-off Bank.

Crown hands [Multiple Endings, Enemies, Sound Pass, Controls], [Graphics Pass, Sound Effects, Split Screen, Menu System]: final Scope11, Core4/4/16/9. Neon [Power-Ups, Split Screen, 8-Bit Sound, 4-Color Palette], [General Combat, Sound Effects, Multiple Endings, Sprites]: final Scope14, Core9/8/8/13. At c28 cash$11,843.38/Fans124/Promotion32.

Starwave first hand [Split Screen, Sound Effects, Levels, Scrolling] → intentional unsaved quit and Continue, then same hand; second [Multiple Endings, General Combat, 8-Bit Sound, Enemies]; third [Controller, Power-Ups, Sound Pass, Sprites]. No hand1/2 Contract cash; intervening sales/rent separately accounted. At c31 cash$14,695.26/Fans139/Promotion32.

Third project `Promotion Receipt`: one legal Design hand [Split Screen, Keyboard & Mouse, Menu System, Recorded Sounds], no Alpha/Beta work; explicit under-Scope confirmations. Scope8, Review0, bugs4; frozen Fans149→37 Awareness plus32 Promotion yields169. Studio c33/$14,632.53/Fans149, Promotion consumed. Cold Continue and completed Starwave browser checked.

## Diagnostics and limits

Nine retained runtime logs have **zero ERROR/SCRIPT ERROR** entries. They contain163 missing optional card-artwork warnings and58 rejected incomplete Alpha-selection warnings. Rejected selections were corrected in UI; no duplicate productive action was observed. Log rotation means this is a claim about retained logs, not every historical process. Captures are numbered in observed order; their file times and build manifests accompany the checkpoint evidence. No subjective readability, sound quality, human comprehension or final balance approval follows from automated interaction.
