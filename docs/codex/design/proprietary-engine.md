# Proprietary Engine foundation — Phase 3A

**2026-11-02 current capacity / Skill Tree launch — IMPLEMENTED locally.** The direct user brief supersedes the20-Scope starting terms below: every newly paid$100 proprietary engine starts at25, Generation I completes at30 and Generation II at35. Four free foundation technologies still grant no Feature cards. The owned-engine detail exposes Feature Implementation Tree and Skill Tree before the longer description; creation remains on overview/separate creation page. Version3 upgrades validated saved1/2 engine capacities by5 without resetting purchased nodes, partial challenges, milestones, receipts, supplies or financial/history/RNG state. Existing started projects keep their frozen limits. Public/legacy/licensed terms are unchanged. [Current Skill Tree authority](engine-skill-tree.md) · [acceptance](../logs/2026-11-02-engine-progression-launch-v1.md). Historical Phase3A20-Scope text below is superseded for current paid engines.

**2026-11-01 Feature workflow update:** The $100 creation receipt, 20 initial Scope, foundation technologies and Phase 3B Skill Tree behavior below remain current. Engine creation now lives on the top-level Engines overview and a separate creation page. An individual owned engine detail shows its Feature Implementation Tree, Skill Tree, Scope, library and queue; it has no creation control. Paid Feature completion now updates that engine's future draw pool in the same productive cycle. The Phase 1 staging/commit/respec text below is superseded by [Engine Feature implementation](engine-features.md); historical configuration records remain in saves.

**Phase 3B update:** The inert foundation below is the historical starting state. Generation I/II progression is now ACTIVE/TRIAL in the [Skill Tree design](engine-skill-tree.md); this document remains the Phase 3A creation and ownership record.

**2026-11-01 status: IMPLEMENTED locally; focused checks pass.** A player Studio can create multiple named proprietary engines from Studio Management → Engines. Each costs $100 once, starts at 20 maximum Scope, has zero engine royalties and no Feature cards. Public Action remains the new-Studio default. The 30-Scope project requirement is unchanged.

## Creation and ownership

`RunState.get_proprietary_engine_creation_quote` validates a trimmed 1–80 character name, affordability, current Studio state and a unique owner-scoped serial ID. `create_proprietary_engine` rechecks the quote, plans the exact $100 `other_expense` finance receipt, then commits cash, ownership, the Feature registry and the proprietary record together. Creation spends no productive cycle. IDs use `<studio-id>:proprietary:<serial>`; serials are monotone and engines cannot be deleted in Phase 3A. A new Studio receives no automatic proprietary engine.

The `proprietary-creation-v1` Feature record is owned, editable, empty and capped at 20 Scope. Existing Feature definitions and the Phase1 implementation/configuration journals remain authoritative. Feature implementation is per engine; Studio familiarity is shared and keeps its 80% effective discount cap. Staging is free, additions commit in one cycle, and removed Features use the existing 10% respec rule. A new project freezes the selected engine, capacity and committed supply; later changes do not rewrite it. Proprietary releases do not enter the licensed/public royalty debit path.

## Inert technology foundation

Each created engine has an independent `proprietary_engines` record with its owner, name, creation cycle and finance receipt. `technology_nodes` initially contains `text`, `4_color_palette`, `keyboard_and_mouse` and `8_bit_sound` as **technology foundations**, separate from same-named Feature cards. `challenge_progress`, `branch_progress`, `scope_milestones`, `pass_efficiency`, `pass_effectiveness` and `bug_prevention` are empty. Phase3A validation requires these future-effect fields to remain empty. No challenge evaluation, node purchase, Scope expansion or gameplay bonus is active.

## UI and saves

The Engines page has a name field, affordability-gated Create Engine button, ownership/capacity/royalty/foundation details and a Configure Features route to the existing Store. Created engines join the same selection list and predevelopment picker as other accessible engines. An optional typed `proprietary_engines` checkpoint field is written only when at least one engine exists; old saves hydrate it as empty. Validation binds each record to owner entitlement, Feature record, ordered serial and exactly one $100 finance receipt. Public and rival terms, saved license payments, release IDs and historical royalties are unchanged.

[Phase 3A implementation and exact checks](../logs/2026-11-01-proprietary-engine-phase3a-v1.md). The separate [Phase 3B Skill Tree](engine-skill-tree.md) now implements trial node/challenge rules and effects; this foundation record does not approve final balance values.
