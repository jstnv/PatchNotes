# Contract entry layout — 2026-10-24

**Later closeout:** the fixed presentation is included in the accepted [P2/P3 actual EXE build](../sidestreet-p2-p3-20261024-exe-v1/README.md) and subsequent [P4 build/acceptance](../publisher-p4-20261024-v1/README.md). Pending statements below describe this correction's earlier checkpoint, not the current queue.

**IMPLEMENTED locally.** User-reported initial Contract hand layout corrected; gameplay, scoring, hand counts, RNG, music timing and the Studio-only Continue boundary are unchanged. Shared dirty `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; no commit, push or refreshed export.

## Cause and changes

Contract builds and deals before its parent containers settle. The fan starts at minimum height240 and card scale0.45; subsequent container sorts deliberately skip staggered entrance tweens. Their completion previously removed only the entry flag, so the initial hand retained that undersized scale until selection/sorting.

- `scripts/ui/card_fan.gd`: queue a container sort when each entrance finishes, retaining the remaining staggered entrances. Finished cards settle to the actual bounds. Card details now use a width-bounded440px, word-wrapped tooltip instead of a full-width unwrapped popup over the action/footer rows.
- `scripts/market/rival_world_checkpoint.gd`: the source fingerprint includes presentation. Accept only the two exact preceding P2/P3 editor/audited-PCK identities with **current** player/rival content revisions and all existing world validation. This is not a broad source bypass or old-rules migration.
- `scripts/debug/verify_card_fan_entry_layout.gd` and UID: maintained resize-during-entry and full-detail tooltip regression. Sorting unchanged bounds must not suddenly enlarge the initial hand.

Exact final mechanics identity: `d4065bc10fd797b32405c507044bc2349b339c2d2a5b2a5c414817d17bc398d9`. [Complete source](source.json), [only two runtime deltas](runtime-delta.json), [verification](verification.json), [raw artifact/fixture hashes](external-artifacts.json).

## Evidence

| Check | Result |
|---|---|
| Resize-during-entry | RED30/14 before correction; final38/0 including tooltip assertions |
| Missing bounded tooltip | RED32/2 before wrapping |
| Shared upper fan |1740/0; selection cap, readable scale, card corners, hit testing and sorting |
| Card motion | PASS; development/redraw/synergy and Contract presentation; native resolution applied once |
| Contract presentation and challenge matrix | PASS; controls/completion/focus and existing publisher rules |
| Rival world foundation / publisher relationships / codec |156/0,43/0,46/0 |
| Four actual old editor/PCK world generations |32/0; active commission and completed/operator Founder worlds restore every persisted field exactly; unknown source and joint/rival rules mismatches reject |
| Actual first Contract via legal first-release campaign | PASS at1152×648 and1280×720; scales0.625/0.76; tooltip456×185 stays inside both windows; animation/hover leaves whole Run/RNG exact |
| Scoped independent source review | No actionable findings; static only |

Eight maintained suites ran against final runtime bytes. The first final runner also requested three nonexistent suite names: its aggregate remains false with those names explicitly NOT RUN. The actual relevant world/relationship/codec suites above passed separately; the compatibility check is distinct from those maintained suites. Original failures, parse-error attempts and runner receipts are preserved, not overwritten. The earlier entrance-only eight-suite run passed at its separately pinned pre-tooltip/pre-whitelist source.

Native project bytes now match canonical exactly, including the generated verifier UID copied after execution. Its original `canonical_unchanged:false` reflects that missing debug UID at execution time; [finalize.py](finalize.py) verifies the exact reconciliation and does not rewrite the receipt. The five final runner suites predate that debug UID only.

## Captures and reproduction

[Initial hand,1152×648](entry-1152.png) · [Wrapped tooltip,1280×720](tooltip-1280.png). All four native entry/tooltip captures were visually inspected; original before captures remain in Temp.

Raw evidence root: `C:/Users/64jus/AppData/Local/Temp/pn-contract-layout-20261024-v1/`. `run_probe.py --output <new-dir>` creates an isolated snapshot/profile and renders both sizes; `run_script.py` runs external checks against an already frozen project. `finalize.py` fences source, fixtures and receipts. Exact commands are in the hashed `*.command.json` files.

Limits: existing missing-artwork warnings and six ObjectDB shutdown instances remain. No new release EXE interaction or user listening/device acceptance is claimed. Safely closing the user's game completed separately with eight saved generations preserved byte-for-byte; P2/P3 actual EXE acceptance is now pending, and approved P4 remains unimplemented behind that dependency. This latest user-reported correction took precedence.
