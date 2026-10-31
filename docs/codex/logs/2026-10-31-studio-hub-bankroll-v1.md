# 2026-10-31 — Studio hub, contract recovery and bankroll feedback

**Status:** IMPLEMENTED locally; scoped functional/native/save acceptance COMPLETE. No public EXE/ZIP rebuild, commit or push. Separate Pass Budget career/balance acceptance remains OPEN.

## Branch, preservation and source

- Branch `main`; HEAD `3a61522f18db7a2bae892cb8c5be1fee68cd4100` before/after. The worktree already contained substantial authorized work. No reset, checkout, commit, push or cleanup was performed. Both `.codex-godot-temp` folders are preserved.
- [Pre-edit manifest and exact source archive](../findings/studio-bankroll-20261031-v1/) preserve the dirty baseline. Final runtime source: `5b253e0c999d11652782544266cdb222ad052cd01d49ab8969f9669b074a70c2`.
- [Acceptance index](../findings/studio-bankroll-20261031-v1/acceptance-index.json) pins all final reports; `after-manifest.json` records exact project files. `task-files.json` lists the19 runtime/scene files this pass touched. Shared Design/Alpha files retain the other chat's Pass Budget additions. Original CRLF conventions were restored without changing normalized code; `pre-newline-source.zip` retains the intermediate bytes.

## User-approved behavior

The Studio dashboard now has three centered vertical choices. **Market Info** contains Daily Chart (the existing Market browser), Publisher List and Rival Info. Rival Info shows actual post-start Market games/titles, Fans and cash for every owner; frozen pre-1980 archives are not counted as live releases. **Studio Management** retains Feature Store/Employees and adds Post Game Summaries, Bank and Studio Info. Specialty/traits move off the dashboard. Info scrolls. **Start Production** contains Produce New Game, always first, then Contracts. Existing unlock conditions remain.

New pages use the shared menu entrance, theme, Back/Escape and focus restoration. History Back returns to Management; launch **Continue to Studio** returns to the dashboard. Bank opens directly from Management and returns there. The existing Beta Launch Warning now uses the common chamfered confirmation. Shared confirmation sizing waits for wrapped text layout before fitting/recentering; it avoids the observed716px-tall first-popup artifact.

Design, Alpha, Beta and Contract hand controls coalesce cash/finance notifications into a deferred affordability refresh. A real Bank loan re-enables the selected Design hand without reselecting or consuming RNG. Future stock transactions should use the same RunState cash/finance signals.

**Contract hands are a recovery action:** active-offer hand commits may proceed with zero cash and blocking arrears. They still advance exactly one cycle, issue/service actual bills, settle sales, preserve redraw restoration and pay once. `contract_receipt` identifies a paid completion; free hands use `contract_hand`. RunState requires the active incomplete Contract and exact offer identity. Ordinary development/Research/expenses retain existing cash/arrears rules. Ledger monthly publisher-income accounting, Contract Search provenance and the current completed-Contract checkpoint validator accept the new kind; frozen predecessor codecs remain unchanged. No loan eligibility, rent, wages, interest or debt forgiveness changed.

The HUD displays **actual cash minus all overdue obligations**, including a negative amount. Actual spendable cash remains nonnegative authority. Zero/negative displayed bankroll gradually tints button backgrounds red over0.8s; steady font colors remain unchanged. Deferred HUD refreshes coalesce net changes. A centered value rises/settles above Cash, briefly holds, hops and falls into the button. At contact the displayed number changes, shakes horizontally and flashes red/green for the net direction. Changes during a flight update its net target. Binding/Continue and debug infinity reset silently; the effect never mutates cash/calendar/RNG or intercepts input. Exact signed formatting handles the supported int64 balance range without overflowing a cross-zero difference.

## Frozen opening compatibility

The two bundled1977 opening files remain **byte-for-byte identical** to the pre-task archive, with original source/generation provenance `2e5049b58267d27fbff11408109e37f43dea6b2cbd84fd570ffcc94acabe3015`. They were not relabeled or regenerated. The loader accepts this one exact preceding source only for the two fixed paths and their literal **raw-byte SHA256 pins**. It then checks original format, generation/source agreement, integrity, player eligibility, full current Codec validation and eight-owner January constraints. Unknown/malformed sources, changed bytes (including a UTF-8 BOM), paths and typed state corruption reject. Existing exact2e5 worlds use the narrow same-content predecessor entry; no unknown-source wildcard was added.

This supersedes the initial plan to regenerate unchanged historical material after UI edits. A concurrent Pass Budget implementation changed prospective production. Rebuilding old history under those rules would change the accepted historical input. Preserve original history and validate its exact compatibility instead. The attempted `cohort-5607-v1` remains retained and unadopted: it showed a cycle21 funding/Alpha stall and the source fence also failed during concurrent edits. It proves no successful current-source cohort or final balance. New historical inputs or broader source compatibility require their own pinned acceptance.

## Final checks

Godot4.7.1 stable, private profiles; one source manifest per run. All four final runs exit0 with zero engine errors, unchanged source and the exact final runtime identity above.

| Evidence directory under the finding folder | Result | Coverage |
| --- | --- | --- |
| `verified-behaviors-native` | PASS103 | Real contract hand tokens/arrears/settlement/codec, rejected-command RNG, actual loan/retained selection, money motion/debt styling, mouse folder navigation at1152×648/1280×720, focus/Back, shared entrance, launch destination and dialog size |
| `verified-frozen-opening` | PASS190 | Both frozen cohorts,24 historical titles, no archive sales pressure, no player RNG consumption, exact cold continuation, independent owner RNG, typed corruptions and exact-byte source pin/BOM checks |
| `verified-late-save` | PASS14 | Genuine preceding cycle97 player/world; all data exact except current world code-source header, actual live Rival Info totals/Fans/cash, passive projection preserves finance/history/RNG |
| `verified-entrypoints-native` | PASS10 | Actual Main Menu→new Studio loading/durable save/tutorial invitation, decline→Studio, Continue loading/Studio-only attach, exact owner/history/finance/policy/RNG;630 rendered frames |

**317 final checks pass.** Native captures in `verified-behaviors-native` were inspected: dashboard, all three folders, Rival Info, Studio Info and fitted Launch Warning. Earlier cash-motion captures show popup and overdue tint. Earlier standalone cash motion11 checks also pass; final103 includes those mechanics. No general no-lag/performance, Godot4.4, listening, subjective balance or public-release claim.

Exact final commands use:

```powershell
python docs/codex/threads/ai-competitors/run_quality_async_check_v1.py --project patch-notes --script docs/codex/findings/studio-bankroll-20261031-v1/verify_behaviors_v8.gd --output docs/codex/findings/studio-bankroll-20261031-v1/verified-behaviors-native --native --timeout 180
```

The other scripts are `verify_frozen_opening_v2.gd`, `verify_late_save_v2.gd` and `docs/codex/threads/ai-competitors/quality_entrypoint_check_v1.gd`; their report directories correspond to the table. Every `result.json` records exact argv, raw script/runner/log hashes and source fence. These existing output directories must never be overwritten by a rerun.

## Retained failures and review

- Initial RED9 checks exposed missing menus, dialog theme, debt exception and motion. First GREEN9 passed.
- Behaviors-v1 had a verifier type-inference parse failure; v2 exposed completed-Contract provenance plus an exact-float assertion. The current checkpoint validator was updated; the pose assertion uses approximate comparison.
- After that, a synthetic accounting release lacked Genre/Theme, correctly rejected by strict checkpoint capture. The fixture now configures a valid catalog identity; it remains explicitly synthetic accounting coverage, not a played balance career.
- V3/v4 encountered concurrent Pass Budget changes/compiler errors/source fence rejection. V5 native captures revealed the tutorial invitation obscuring underlying UI; v6 declines through the real tutorial callback and exercises actual mouse input. No screenshot from the obscured fixture is counted as menu acceptance.
- V7 demonstrated dialog reset sizing; production now settles/fits/recenters correctly and V8 verifies it. Late-save-v1 verifier had a Variant inference warning; v2 corrects its annotation. All failed outputs remain.
- Read-only code review found missing new-page entrance registration, launch/history return-route conflation and decoded-text versus raw-byte certificate hashing. All three were fixed and covered. The reviewer found no additional high-confidence finance or sizing lifecycle defect.
- Existing missing-artwork warnings occur in controlled card fixtures. Some strict/late standalone probes retain six ObjectDB exit warnings; no zero-warning claim.

## Follow-ups and limits

Separate Pass Budget normal-start/rival careers, save-budget counters, old fixed-seven verifier updates, native balance acceptance and Godot4.4 remain that implementation's OPEN work. This pass does not close them, retune founding cash, adopt the rent300 design or update AI quality/performance claims from the preceding build. Stock transactions must publish the existing authoritative financial signals. Public packaging/Git operations were not requested for this pass.

Final whitespace check: ordinary `git diff --check` flags the repository's preserved CRLF as trailing CR. The nonpersistent `git -c core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol diff --check` on all19 touched runtime/scene paths passes (exit0). Both outputs are retained. No Git configuration was changed.
