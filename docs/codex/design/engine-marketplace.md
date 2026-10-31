# Engine System and Marketplace — implementation intake

**2026-10-31 status: user-approved implementation direction; implementation IN PROGRESS.** The pasted Engine System brief authorizes a reusable engine model, two opening listings, specialization integration, licenses, royalties, Scope capacity, save compatibility and Studio Management UI. The user resolved the three integration rules below on 2026-10-31.

## Selected starting definitions

| Engine | Creator in both certified 1980 openings | Specialty | Max Scope | License | Royalty | Dominant Core | Specialization bonus |
|---|---|---|---:|---:|---:|---|---:|
| Action Engine | `incumbent-action` / Arcade Foundry | Action | 25 | $7,500 | 20% | Graphics, Technology | +0.1 each |
| Puzzle Engine | `incumbent-puzzle` / Prism Logic | Puzzle | 25 | $7,500 | 20% | Technology, Design | +0.1 each |

Puzzle's dominant categories follow the current approved Genre target table: Technology 40, Design 59. Both owners are real persistent rival `RunState`s in `certified/rival-opening-5607-v1.json` and `rival-opening-5613-v1.json`. The catalog at `scripts/engines/engine_marketplace.gd` is fixed data; the current world checks creator ID and specialty before a purchase.

## Implemented integration boundaries

- `RunState` stores owned/licensed IDs and the selected engine; each `ProjectState` freezes an engine ID at project creation and each release stores that ID in a separate typed map. The fixed starting catalog supplies terms. Old projects/releases use the legacy default.
- Engine bonuses enter the existing Design/Alpha Specialization calculation only after four-card primary-stat qualification. The base multiplier is 1.5; category-specific engine and earned employee additions are summed before existing whole-score rounding. Balanced Production remains separate. Printed Feature Core feeding Pass Budget remains unchanged.
- `RivalWorld.license_engine` checks the actual creator and both finance plans before committing the buyer debit, creator credit and entitlement. Duplicate licenses and forged owner entitlements reject; the paired world/player checkpoint saves both ledgers.
- Licensed release sales deduct 20% from cumulative Studio net earned/settled cents in the existing sales/finance plan. `RivalWorld` credits each creator the incremental cumulative settled amount after all rival actions, stores the creator's per-release receipt, and refuses duplicate credit. Publisher-owned commission releases have no Studio sales royalty; support releases use their Studio net after platform and publisher rights.
- The Studio Management Engines page shows creator name/specialty, capacity, bonuses, fee, royalty, purchase and future-project selection. No Engine Skill Tree nodes or upgrades are included.

## Remaining acceptance

Godot 4.4 and native layout/controls are unverified; local headless checks used Godot 4.7.1. Support-share and publisher-owned commission arithmetic passed focused checks; full publisher-deal careers and cross-owner failure recovery remain unverified. The current `RivalWorld` reports a required checkpoint recovery if a creator finance credit fails after rival actions; this edge is not claimed as a complete atomic rollback. Existing fixed-seven Design/Alpha trace fixtures and rival dashboard-label assertions require updates for already changed Pass Budget/folder behavior. See the dated implementation log for exact checks.

## Selected integration rules

1. **Royalty base — SELECTED:** 20% of the existing studio net sales **after** the platform share. Round in integer cents on a cumulative base; pay only the new entitlement minus already paid royalties.
2. **Capacity — SELECTED:** Action and Puzzle engines hard-cap played Scope at 25 even though the existing project requirement remains 30. A game using either engine therefore finishes under the requirement until a higher-capacity engine exists; preserve the existing under-Scope warning/review formula.
3. **Default — SELECTED:** existing and new player Studios retain a built-in legacy engine with current behavior before any marketplace license. It has no new bonus, fee, royalty or 25-Scope cap. Do not retroactively convert old projects/releases.

Current Godot executable available in this workspace is 4.7.1; 4.4 verification remains separate.


## 2026-10-31 Feature implementation boundary

[Engine Features Phase1](engine-features.md) adds per-engine permanent implementation, fixed legacy-access snapshots and configuration. Existing Marketplace license prices, creators, royalties, bonuses and caps are preserved; no new marketplace or proposed starting-library terms are adopted.

## 2026-10-31 Browser and project setup selection — IMPLEMENTED locally

Engines is a full-width FolderUI page: scrollable engine buttons at left; inspected engine terms and license/select action at right. Inspecting a listing is free and does not select it. Licensing retains the existing exact transfer and entitlement rules; selecting afterward is explicit. Unlicensed listings remain outside the setup pickers.

Game setup and Contract detail use a shared owned/licensed picker showing engine capacity and configured printed supply. Choosing updates the Studio default immediately; cancelling the setup retains that explicit choice. The project engine/configured pool freezes at Begin; accepted Contract eligible pools freeze at acceptance. Contract scoring/capacity rules do not gain new Engine modifiers. Changing a setup while Begin awaits background saving aborts that pending request; the player reviews and presses Begin again. Engine changes invalidate confirmed publisher/support quotes. A pending Contract acceptance also rejects if its engine changes during saving.

Focused native browser/picker, delayed-save, marketplace accounting and real world Continue checks pass under4.7.1; genuine preceding d729 world restoration and current cold round trip pass. Exact source pin and retained baseline fixture failures are in the [session log](../logs/2026-10-31-engine-browser-selection-v1.md). This closes this browser/picker request, not the broader publisher careers, cross-owner failure recovery, device,4.4 startup/export or balance gates. Proposed libraries/creation/Skill Tree remain inactive.

## 2026-10-31 acceptance reconciliation

Rent/hub follow-up closes the inherited predevelopment/Contract menu fixtures, actual shared navigation/Back and native1152/1280 surfaces. Marketplace transfers/royalty receipts, real world Continue, entitlement/specialization/capacity and both certified openings pass current automatic checks. New and saved rent paths retain their separate declared values. Focused new-feature runtime checks also pass4.4; the copied clean editor import still has progress-task and debug-script dependency/API errors and is not a clean-project pass. Full publisher/support Engine careers, cross-owner failure-recovery policy, broader balance and device/export gates remain OPEN. [Exact receipts and limits](../logs/2026-10-31-rent-hub-queue-completion-v1.md).
