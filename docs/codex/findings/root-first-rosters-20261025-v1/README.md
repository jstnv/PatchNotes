# Root-first starting pools and transparent Store toolbar —2026-10-25

**IMPLEMENTED locally and packaged separately.** New Studios use connected founding-roster v3; existing Studios keep exact saved ownership. Research/queue/Debug/Close, budget advice, zoom and Core legend sit above the map with transparent fills. Hover/focus/disabled cues remain; detail, Debug and dropdown surfaces remain readable. The existing first-release Summary/Contracts fix and current shared Theme are included.

Main / HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`,170 inherited tracked modifications at start. Shared changes and `.codex-godot-temp` preserved. No commit/push or unrelated queued Contract Search/QA-employee adoption. [Exact task delta](scoped-delta.patch) · [file hashes](source-delta.json) · [verification](verification.json) · [external raw evidence](external-artifacts.json) · [plan/session](../../logs/2026-10-25-root-first-rosters-plan-v1.md).

## Starting pools

The user explicitly chose replacements instead of granting all missing parents. Fixed per-Genre patches preserve the existing27 Primitive grant boundary and independently close every named parent in the full current Store graph. Earlier branch nodes already present are deduplicated; later Store High Scores/Branching Dialogue are not silently granted with their undefined play costs. Valid owned connected branches remain. All genres start with Sound Effects; Adventure/Role-Playing/Puzzle replace8-Bit Sound with its root and may acquire the child normally. Every starter still grants zero familiarity.

Exact IDs/removals/additions/Scope/Core totals: [independent audit](independent-roster-audit.json), [maintained v3 fixture](../../../../patch-notes/scripts/debug/fixtures/studio_specialties_v3.json), [design/version boundary](../../design/genre-specialties.md#new-founding-rosters-v3--root-first-replacements2026-10-25). Counts now range15–18 and printed Scope21–27. This structural replacement changes aggregate starting supply, without retuning individual card values, Genre rating targets, prices, Research, traits or scoring. **Final balance remains OPEN.**

Historical v1/v2 preview/membership remain frozen. Only current checkpoint metadata accepts new version3; historical validators are not broadened to accept forged v3. Hydration assigns saved ownership and RNG without rerunning founding grants. Two named actual predecessor identities admit prior editor/Studio Fix worlds under existing strict field/content checks; unknown/mixed sources reject.

## Store presentation

`feature_store.gd` provides a map host plus a transparent sibling toolbar. Local duplicated button styles clear only their fills, preserving the shared Theme. Empty toolbar space and labels allow map gestures. `feature_store_map.gd` rejects actual toolbar-button positions before its `_input` gesture handling, preserving GUI clicks/wheel handling. Map fit/focus retains toolbar clearance; panning can show nodes/connections behind controls. No queue, purchase, cycle, bill, cash, familiarity, card or RNG transaction was altered.

Native full HUD: [1280×720](captures/store-1280x720.png), [900×600](captures/store-900x600.png), [Debug](captures/debug-1280x720.png). [Actual EXE overlay capture](captures/store-overlay-1280.png) shows graph content behind the transparent controls. Full-HUD screenshots include a constructed six-release display fixture; they are layout evidence, not a played six-release campaign.

## Verified

| Check | Result |
|---|---|
| Pre-change regression | Root-first RED retained; final overlay test fails48 expected geometry/fill assertions against predecessor |
| Maintained focused matrix | **16/16 PASS**, identical immutable current runtime, canonical unchanged; [result](receipts/final-matrix/result.json) and exact command records alongside |
| Current root pools | **318/318 PASS**, all8 exact fixtures/full parent closure, no familiarity/regrant, saved state/RNG and optional child price/timing |
| Historical roster versions | **212/212 PASS**, frozen1/2, exact round trips and invalid-version rejection |
| Live/headless campaign | **106 matched boundaries**,0 failures; historical Design/Alpha/Beta extraction golden traces remain explicit v2 fixtures and pass |
| Eight new genre campaigns | **8 releases /144 legal commands**, seed4417, finite fixture policy2/2/2 hands; every action/result/state/RNG replay exact. This is bounded functionality, not balance coverage. [Result](receipts/eight-genre-campaigns/result.json) |
| Native transparent controls | **87/87 editor and87/87 actual EXE**,900×600/1280×720/1920×1080; zoom/Debug/Close pointer routes and unchanged complete state/RNG |
| Native full HUD | **153/153 PASS**,1152×648/1280×720/1920×1080/900×600; chart, real queue, Debug, keyboard/Esc, prerequisite details and map/navigation fit |
| Actual previous EXE saves | **16 exact old saves PASS** in editor and new EXE: fresh and one legal optional purchase for every genre |
| Old/current world saves | Exact player/world/RNG restoration in new EXE; actual old Studio Fix EXE world and current editor world both pass, unknown/mixed source rejection retained |
| Clean package | **410 entries**, every payload hash/exclusion, six PE icon frames, exact current editor save, headless/native EXE startup and ZIP integrity PASS |
| Fresh code review | No actionable findings in scoped runtime delta |

Canonical editor runtime `900512cd4167008a122720e252e6d2a1afd5215e0186b3f196279e4f7c9aeb87`; actual EXE runtime `91681dc365c033cede4a383c90299b2193f4c79886f8023ade9de30b1bc45e9c`. Build-local version/embedded-data/editor compatibility overrides are pinned in [manifest](build-manifest.json). Build and maintained runner both confirm canonical source unchanged. Scoped whitespace check passes with CRLF recognized (`core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol`).

## Separate updated download

- [ZIP](<C:/Users/64jus/Downloads/Patch Notes Design Folder/Builds/Patch Notes v0.02 - Root First.zip>) —44,249,247bytes; SHA256 `68e04b78084edc429d0cdf89176ea7fa03720138d83ea342fad9a4b3519177ab`.
- [EXE](<C:/Users/64jus/Downloads/Patch Notes Design Folder/Builds/Patch Notes v0.02 - Root First/Patch Notes v0.02 - Root First.exe>) —116,987,200bytes; SHA256 `8cb4a1d7f40fb4ab9ac324c30b716817efbfa44ad233243c7038a6e279fd8967`.

Old builds are preserved; save/settings folder remains Patch Notes. Existing Studios keep their original pools; create a new Studio to use v3.

## Retained failures and limits

Initial root fixture ordering used StringName ordering instead of lexical JSON order; corrected verifier fixture without changing runtime. One old purchase fixture chose Simple Story, now owned in Action v3; changed its optional test purchase to unowned Dialogue at the existing same price/Scope. Historical command digests explicitly construct v2 instead of rewriting goldens. The initial overlay harness forgot to open/refresh its standalone Store; the corrected pre-change rerun fails exactly48 expected assertions, then passes87 after implementation. The first native-HUD harness stripped its capture environment; a second version sets only that capture path inside the isolated verifier and retains nine native PNGs. One new roster verifier emits six ObjectDB cleanup-instance warnings at exit; all assertions/commands pass, and no memory/performance claim is made.

Bulk raw projects/imports/profiles/tapes remain outside OneDrive, pinned by [manifest](external-artifacts.json). Human comprehension, broader device/audible acceptance and final balance remain OPEN. Studio-only Continue is unchanged. No whole-release readiness claim follows.
