# Current verified state

As of 2026-10-06 (America/Los_Angeles). Source: main at 2b5717d0de737f77f1b1bc8c1a02da0db9f53942 (“Hidden avg cycle”), following 4f5aa30 (“Bank update”) and e054791 (“Bank”). No fresh remote verification, commit or push in this migration.

## Playable loop

Studio creation chooses a name, one company background preview and a required permanent Genre specialty, granting its Primitive Feature roster. Studio → Pre-Development (title, project Genre, Theme) → Design → Alpha → Beta → Review/launch → Studio; Contracts provide an alternate Studio activity. Successful development departure costs one run cycle; phase transitions and launch cost zero. Two productive cycles equal one calendar month; January 1980 is the origin. Exact-cent RunState transactions advance all released titles together.

Design/Alpha use seven candidates, four selected cards, finite Features, renewable Passes, priority/synergy resolution and shared redraws. Beta implements QA, Marketing, competitor/forecast actions, host playtests, finalization and launch snapshots. Review and Genre Fit, immutable release history, tutorial/guidance, card animations, retained candidates and sorting are present.

## Studio, economy and progression

Studio exposes the Store, next-game setup, summaries/detailed Review, per-title monthly units/revenue, eligible campaigns, publisher profiles, Ironclad/SideStreet Contracts and HUD Cash → Finances → Bank. Passive navigation is free.

Base capital is $5,500; current player trait-selection flow separately adds a once-only $200 unused-point financing receipt ($5,700 total). Legacy no-trait fixtures use $5,500. Rent is $500 every completed calendar month. Finance journals distinguish earned net sales, settled cash, operating profit, financing, original bills and partial/late recovery. Typed age-based credit starts at 600; numerical gains/penalties are configurable prototype defaults. Loans are unavailable.

Month 1 earns over two productive cycles after launch; monthly settlement pays the existing 70% net entitlement once. Month 2+ and $100/one-cycle campaigns are playable accepted working coefficients, held fixed during other economy work, not final tuning. Monthly portfolio reporting exists. Runtime fan accrual/storage/loss is absent; launch fan contribution is zero.

Ironclad and qualifying-release-linked SideStreet cash offers/history are implemented. All five publisher unlock profiles exist; Crown/Neon/Starwave offers and Promotion banking/consumption are absent. Employees, courses and payroll are absent. Background/secondary choices persist in RunState as explicitly inactive previews. Required Genre specialties and automatic rosters are active. Store ownership, parents, familiarity discounts and later one-cycle purchases work; proposed multi-era catalogs, numerical gates, new cards and later-card play fees remain design work.

**Design approval, 2026-10-06:** the user selected the [Employees trial package](threads/employees-challenges/2026-10-06-trial-package-decision-v1.md): one Production Specialist after Game 1, $100/zero-cycle hire, temporary $10 monthly wage, first-full-month payday, optional bundled planning and rent → payroll → bank recovery. The [separate implementation task](threads/employees-challenges/2026-10-06-production-specialist-implementation-v1.md) is QUEUED; this is not implemented gameplay. Future course timing is approved, but course effects/amounts and final wages remain OPEN. The preceding bounded comparison used isolated main `553d1a4`; this approval update changes documentation only.

## Current verification and gaps

The pending alpha_phase.gd/run_state.gd free-Alpha-exit repair is preserved. Its migration-discovered flaky test is now resolved locally: controlled native no-income and $1000 Insider-income hands prove blocked production versus genuine bill recovery separately (149 checks). The repair's runtime code was unchanged by this follow-up.

Fresh Godot 4.7.1 editor import passed; 12/13 focused suites passed on the first run. [Audit](findings/migration-audit-2026-10-06.md) records exact results and source hashes. No full-suite or visible exported two-game smoke run in this migration.

Subsequent 2026-10-06 user UI work is local/uncommitted: Run Campaign moved to the summary header; Beta sorts by type with a Sort label; replacement fans reapply their chosen sort after card entrances. Import, all64 maintained suites (13,425 PASS markers), rendered UI checks at1152×648/1280×720 and diff-check passed. [Session log](logs/2026-10-06-campaign-pool-ui-v1.md) separates this later full gate from the migration's historical partial result. No current export or human interaction acceptance claimed.

Major release gaps: durable Studio checkpoints/Continue, deterministic restore/RNG integration, startup recovery/package gate, exported interactive smoke and approved audio/credits/playback. Settings/display/input/audio-bus framework exists. Broader human balance validation remains open. Start relevant work from [TODO](TODO.md) and [system designs](README.md); numerical design gaps are not blanket permission to implement.
