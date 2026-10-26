# SideStreet P2/P3 canonical adoption — 2026-10-24

**IMPLEMENTED locally at the approved bounded trial scope. Final interaction acceptance is PARTIAL:** native source and exported-PCK flows pass; the direct release EXE Continue/playthrough is **BLOCKED** by another running game's production save writer. That game was preserved. This is not final balance approval or release readiness.

Authority: [approved trial](../../threads/contracts/SIDESTREET-P2-P3-TRIAL-APPROVAL-2026-10-23-v1.md), [current v3 adoption](../../threads/contracts/SIDESTREET-P2-P3-ADOPTION-2026-10-23-v3.md) and [v2 tasks A–E](../../threads/contracts/SIDESTREET-P2-P3-ADOPTION-2026-10-23-v2.md). [Execution ledger](../../logs/2026-10-23-sidestreet-p2-p3-plan-v1.md) · [dated session log](../../logs/2026-10-24-sidestreet-p2-p3-adoption-v1.md) · [review](REVIEW.md).

## Source and preservation

Shared dirty `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`. The original12 packet before hashes matched current source exactly. All13 packet seals and both complete source archives were checked; the sealed packet and private studies remain unchanged. Existing edits and `.codex-godot-temp` were preserved. No commit or push.

- Editor mechanics: `a6766632c3c57c6abf5df0b4c981390c7f0dece678c6665d843bb84de8076cbe`.
- Compiled-PCK mechanics: `1be636f8f92822d4d693179a1bf9b5ed693a92ee2269133674d73ed22bacd113`.
- Final PCK SHA256: `b98fd9b92f4dd0fd9d64d12b581688690512f59c998a1e5311941c747bd14fb3`.
- Windows release EXE SHA256: `7c3e92d9c175dc8754947c93f2ad6d9514091e51cf542407b7595e2bbbd20257`.

[Exact source inventory](final-source.json), [44-path delta against the preserved pre-task source](source-delta.json), [build inputs/artifacts](build-manifest.json), [359-entry PCK audit](pack-manifest-verified.json), [verification](verification.json), [final audit](final-audit.json), and [external evidence manifest](external-artifacts.json). Raw caches, isolated profiles, tapes, failed attempts and the build stay outside the synced checkout at `C:/Users/64jus/AppData/Local/Temp/pn-sidestreet-canonical-20261023-v5/`. Earlier v1–v4 attempts remain at their original source identities. No checkpoint was relabeled to a new mechanics identity.

## Implemented behavior

**Reputation Brief:** separate two-hand/four-card SideStreet work, Scope10/Core3 each,64-unit completion denominator, no advance/cash/Promotion/Investment. Scope≤10 with no successful redraw retains the full promise;11 gives half;12+ or any successful redraw gives zero. Award is at most10 Reputation, using the lower completion/promise fraction through P1. Opportunities follow releases without missed-offer backlog; Briefs do not count as legacy completed cash Contracts.

**Commission:** SideStreet R20 opens optional normal name/Genre/Theme setup without spending standing. The confirmed quote freezes the actual prepared positive required Scope, identities, setup, acceptance cycle, Review6.0 target, maximum$6,000 fee and publisher rights. One active commission, no cancellation after Begin. Fee uses the lower Scope/Review fraction, floored to cents; only full delivery requests +15 Reputation/+15 Investment, with independent100 caps. Partial/zero completions still retain one named receipt and P1 event. Later projects can quote again.

**Rights and finance:** raw units, title sales/history and Fans remain; publisher-owned sales contribute zero Studio earnings, settlement or Bank sales inputs. Post-launch Studio campaigns are unavailable for that title. The fee is a separate publisher receipt and can service ordinary arrears. Promotion consumption and normal rent/payroll/Bank rules remain intact. No base scoring or Review formula changes.

**Transactions and persistence:** prospective Brief/P1/cycle planning, exact privately committed finance cash, full prepared-project fences and detached launch/view preparation replace late/assert-only effects. Project/Run/fee/rights/standing/RNG commit before observers. Named frozen-P1 migrations add empty sources without retrospective awards and validate exact old world/source pairs. Pending commissioned rivals have an explicit project-linked DTO; player Continue remains Studio-only. Jointly forged Scope/terms and missing, renamed, duplicated or orphan finance/award/rights sources reject.

**Presentation:** distinct Brief selection/progress/result, publisher standing/readiness, normal setup/quote/keyboard confirmation, full/partial/$0 breakdown, ownership-aware Finance/Review/Market/monthly reports and two guide topics. Card token mapping now excludes tooltip PopupPanels from physical CardViews across Design/Alpha/Beta/Contract; animation/scoring policy is unchanged.

## Verification

| Check | Actual result and boundary |
| --- | --- |
| Maintained regression | **36 affected suites PASS** in two frozen runs:28 passing checks plus eight UI/Market/rival/codec/store checks. The first runner incorrectly requested nonexistent `verify_rival_world`; the actual `verify_rival_world_foundation` passes in the second run. This is not a full174-suite gate. |
| Fresh legal campaigns | Nine cases,466 accepted commands,16 newly produced releases across branches; same declared Sports1112 foundation, original research prices/hand policies/bounds. Independent analysis **224/0**. |
| Exact fresh replay | Six PASS: prefix, full first, second, repeat-to-cap, recovery and separate readiness witness;383 replayed commands. |
| Source/quote/cap audits | Ten PASS, including zero fee, idempotence, altered quote/readiness, missing/duplicate/renamed receipts/events, rights and both caps. |
| Focused transactions |25/0; detached release/late guard, one-shot cash guard, ordinary Begin, exact observed Brief row/altered quote, old P1 dormant-source rejection. |
| Real Brief/Begin boundaries |17/0; finishing-source failure before hand/cash/calendar/RNG, exact retry, six prepared-project alterations, player save rejection, active-rival DTO/Scope corruption. |
| P1 preservation |38/0 in editor and38/0 in actual compiled PCK: retained editor/compiled/Founder/active-rival data and dormant forged sources. |
| Populated world/ownership |19/0 in editor and19/0 compiled: actual share/cash transaction, active commission, rejected active-project operator handoff, completed commission, safe control transfer and return, exact per-Studio fee/standing/rights/finance/RNG, cold world restoration. Test-only policy adapter does not activate rival commission AI. |
| Native UI versus headless |115 exact state/ordered-notification boundaries per full route at1152×648 and1280×720, both source and compiled PCK. Actual engine mouse/keyboard callbacks, one activation, cancellation, frozen terms, tooltip-child injection, full release, later owned release/raw commission sales and Continue. A fifth1152 compiled route retains the pre-quote disk generation before normal pruning. |
| Real disk/native cold Continue |20 fresh-process PASS; before quote, full/later sales, partial/$0, both sizes for compiled partial/$0, active rival and post-handoff Founder worlds, actual previous P1 editor/compiled and pre-P1 Founder generations. Eight real store writers also reject corrupted replacement and preserve the last valid generation. |
| Clean export | Clean import/export PASS; all359 PCK entry hashes/allowlist inputs verified. Actual EXE headless and graphical startup PASS. Current Windows preset is `Patch Notes v0.01`; canonical preset was not edited. |
| Actual release EXE interaction | **BLOCKED after real Main Menu Continue click.** Recovery says another Patch Notes process owns the slot; isolated generation bytes remain exact and this EXE exits0. The other game was not closed. [Capture](writer-busy-exe.png). |

Cold UI comparison explicitly accounts for existing presentation actions: the expected queued publisher notice is displayed/consumed, and the exact appropriate Studio guidance tip is marked visited. All remaining typed player/world fields and RNG compare exactly; original generation bytes remain unchanged. Initial strict comparisons and diagnostic differences are retained. Migration alone still preserves every old field before presentation.

### Actual campaign outcomes

| Case | Scope | Review | Fee | Standing outcome |
| --- | --- | --- | --- | --- |
| Maps-only retained miss |26/30|6.4|$5,199.60|No R/I |
| First full portfolio commission |30/30|7.8|$6,000|+15R/+15I |
| Cold second commission |30/30|8.6|$6,000|+15R/+15I |
| Original seven-commission bound | Includes29/30 miss | Actual per-title grades retained | Actual proportional fees | R100/I90 |
| Separate unchanged-policy recovery |29/30|5.7|$5,100|No R/I; R100/I90 |
| Separate predeclared10/10/10 witness |30/30|9.2|$6,000|Requested15/15, credited0R/10I; both100 |
| Predeclared weak Action release |11/30|0.3|$0|One zero-credit event/receipt; no R/I |

The matched owned/commission pair has identical actual Review/production, raw sales, Fans and final RNG; the full fee exactly accounts for the cash/arrears difference. The researched trio and longer hand budget are evidence routes, not prerequisites or pacing recommendations. [Declaration](LEGAL-PLAN.md).

## Captures

[Brief1152](brief-1152.png) · [compiled quote1152](compiled-quote-1152.png) · [full result1280](compiled-result-1280.png) · [partial1280](partial-1280.png) · [zero1280](zero-1280.png) · [Market1152](market-1152.png). Text and action bounds were inspected. More supported-size captures remain in the external manifest.

## Retained failures and limits

The execution ledger retains baseline RED, guard/migration fixes, CardFan tooltip/type failures and source regenerations; original private misses were never replaced. Native harness repairs include initial deal grouping, window-relative input/focus and a freed confirmation button after a successful key activation. The launch oracle now explicitly verifies the approved coherent notification change while preserving exact arithmetic/state/RNG comparisons. Legacy verifier fixtures were updated only for the sixth separate Brief definition and the actual pre-pilot shape.

Export attempts retained missing simulation-only presets, a stale preset-name assumption and an unsupported release-template script launch. Final compiled tests load the **actual audited PCK with the editor engine**; they are not claimed as direct release-EXE playthroughs. Passing logs may contain existing missing-artwork, incomplete-selection preview or cleanup warnings; no performance, memory, audio-device or clean-machine conclusion follows.

Remaining: close the other game safely, then complete the direct release EXE Brief/commission/later-sales/Continue interaction at supported sizes. Human comprehension/audible/device/license acceptance and final balance remain separate. P4 support/renewal, broader publisher tiers and default AI commission policy remain OPEN/PROPOSED; no candidate support values were adopted.
