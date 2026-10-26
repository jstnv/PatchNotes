# Persistent sales revenue HUD — 2026-10-18

Direct user request: a compact corner bar graph that keeps tracking released games in the market, inspired by Game Dev Tycoon. Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, shared dirty worktree. Read CURRENT_STATE, TODO, README, relevant lifespan design and source/diffs before editing. Existing changes and `.codex-godot-temp` preserved. No unrelated queue work, commit or push.

## Implemented behavior

- Top-right panel appears after the first release and persists across gameplay phases while titles remain on market. Space is reserved in the header/phase layout, outside cards, score fields and action buttons. Hidden on the title screen and before any release.
- Last 12 **calendar months**, oldest to newest, with a shared vertical scale. The amber current-month bar animates upward when productive cycles earn more sales; completed months are cyan. Current-month revenue, all-time earned revenue and the number of on-market titles accompany the plot. Exact cents and earned/paid distinction are available in tooltips.
- Metric: existing `sales_net_earned_cents`, summed across the player's released games, **after store share and before Studio expenses**. This is sales revenue, not operating profit or immediately spendable cash. Launch forecasts do not become earned income. No idle real-time earnings are introduced.
- No hard expiration exists under current rules: zero-unit titles remain on market, retain a zero bar and can revive through campaigns. The indicator therefore remains visible for dormant titles. Existing sales coefficients and settlement dates remain authoritative.
- Deferred signal-driven refresh coalesces calendar/sales notifications; duplicate events do not add revenue. Display animation stops at its target and freezes during pause. Continue reconstructs history from the existing ledger; new Studio binding clears it and disconnects the prior run.

Reference boundary: Greenheart's [official GDT mod API events](https://github.com/greenheartgames/gdt-modAPI/wiki/Gdt) expose release, sales-calculated and week-proceeded events. The adopted reference is persistent market-sales feedback driven by game time. The proprietary graph's exact interpolation/formula was not verified or copied; this implementation uses Patch Notes' calendar and existing sales ledger.

## Changed files

- `patch-notes/scripts/ui/sales_revenue_model.gd` (+UID): detached calendar series from authoritative finance and release metadata.
- `patch-notes/scripts/ui/sales_revenue_hud.gd` (+UID): compact labels, tooltips, rolling bar renderer, signal binding and pause-aware visual interpolation.
- `patch-notes/scripts/ui/gameplay_hud.gd`: bind the view, control visibility and reserve its corner. Prior soundtrack changes preserved.
- `patch-notes/scripts/market/rival_world_checkpoint.gd`: append exact pre-HUD source `fd7e8a3bfe749b1c121b7515e150c35ea926f80f5511b2ba86d8ee5dceb8c867` to existing presentation compatibility. Source identity includes UI; this narrow allowlist preserves otherwise unchanged saves. All validation still runs and unknown identities reject.
- `patch-notes/scripts/debug/verify_sales_revenue_hud.gd`, `capture_sales_hud.gd` (+UIDs): behavior and native-render checks. Findings runner/audit, lifespan presentation record, CURRENT_STATE, TODO and this log updated.

No sales/scoring/RNG/calendar/finance/card/AI rules, audio assets or checkpoint schema changed. Studio-only Continue remains intact.

## Verification and evidence

Godot **4.7.1**, frozen copies with separate APPDATA/LOCALAPPDATA/TEMP and writer ports. No player profile used. External timeout240s; verifier timeout120s, capture timeout90s.

| Check | Result |
|---|---|
| Pre-edit `verify_legacy_world` | PASS, 30/30; actual prior-source world/Founder-v2 checkpoint produced |
| Fresh imports | PASS |
| `verify_sales_revenue_hud` | **461/461** |
| Existing `verify_gameplay_hud_overlay` | PASS |
| Existing `verify_sales_earning_and_settlement` | PASS, 0 failures |
| Existing `verify_game_lifespan_sales` | PASS, 0 failures |
| `capture_sales_hud`, final render-v2 | **150/150**, ten native-size captures |
| Scoped source/UID/whitespace audit | PASS |

The behavior fixture uses explicitly funded Studios and constructed valid release boundaries, then real productive actions. It is not a complete player campaign. Two releases on opposite half-month alignments run through32 cycles; every displayed monthly bar and lifetime/settled total reconciles independently against per-title report slices. Tests include partial unpaid revenue, duplicate signals, the12-month rolling window, zero-sales tails, actual campaign revival, pause, unchanged state/RNG during animation, exact checkpoint hydration/rebinding and prior-source world/Founder restoration. Unknown source remains rejected.

Final native rendering covers Studio, Design, Alpha, Beta and Contract at **1152×648 and1280×720**, with selected cards in development. All ten screenshots inspected: graph/header/cards/actions/footer remain separate and graph labels fit. Settings navigation preserves the series. Initial render-v1 checked both logical layouts but Settings startup reset physical capture size to1280×720; render-v2 resizes after startup and asserts each PNG's actual dimensions. Only the capture script changed between those runs.

- [Behavior commands/exits](../findings/sales-hud-20261018-v1/check-v1/results.json) · [assertions and monthly observations](../findings/sales-hud-20261018-v1/check-v1/verify_sales_revenue_hud.json)
- [Final render commands/exits](../findings/sales-hud-20261018-v1/render-v2/results.json) · [source manifest](../findings/sales-hud-20261018-v1/render-v2/source.json) · [canonical/source/hash audit](../findings/sales-hud-20261018-v1/audit.json)
- [Studio1152](../findings/sales-hud-20261018-v1/render-v2/studio-1152x648.png) · [Beta1152](../findings/sales-hud-20261018-v1/render-v2/beta-1152x648.png) · [Contract1280](../findings/sales-hud-20261018-v1/render-v2/contract-1280x720.png)

All final processes exit0 with no script/runtime errors. Existing missing-artwork warnings and six ObjectDB leaked instances on exit remain; the same six-instance warning occurs in the pre-edit legacy producer. No refreshed export, cold executable interaction, device/audio or human usability acceptance is claimed.

Reproduce with bundled Python: `docs/codex/findings/sales-hud-20261018-v1/run.py <fresh-directory> verify_sales_revenue_hud verify_gameplay_hud_overlay verify_sales_earning_and_settlement verify_game_lifespan_sales capture_sales_hud`. The stored pre-edit producer enables the old-source check. `audit.py` pins the actual behavior/render runs and permits only four verified engine-generated UID sidecars after import. Use `git -c core.whitespace=cr-at-eol diff --check` for existing CRLF files. Remaining relevant acceptance: human readability/feel and refreshed export; no implementation blocker found.
