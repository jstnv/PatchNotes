# Four productive cycles per month — implementation plan

User-authorized Calendar Cycle Conversion,2026-10-31. Work inline in the authoritative shared checkout, preserving the uncommitted Public Action Phase2A implementation and both temporary Godot directories. No unrelated balance,engine,card,review,employee or publisher redesign.

## Authoritative clock contract

Module `res://scripts/calendar/calendar_clock.gd` (preload as Clock). Profile `{}` means explicit historical2-cycle timing. `fresh()` returns `{version:2,legacy_until:0}`. `upgrade(profile,current_cycle)` anchors conversion at current action cycle if legacy,otherwise returns the original profile. For a converted profile with anchor C,calendar quarter coordinate is2*k through C,then2*C+(k-C). Raw productive/project/review/event counters never rescale. New Studios get fresh4 timing; existing loaded Studios preserve date/half-month progress and adopt future quarter-month steps. Keep historical1977 raw72 offsets and frozen certificates.

Shared methods: `valid(profile)`, `fresh()`, `upgrade(profile,cycle)`, `position(cycle,profile={}) -> {month_index,quarter}` (zero-based), `month(cycle,profile={})` (absolute1-based run month), `month_of_year(cycle,profile={})`, `year(cycle,start_year=1980,profile={})`, `is_boundary(cycle,profile={})`, `month_start(cycle,profile={})`, `month_end(month_number,profile={})`, `first_full_month_end(cycle,profile={})`, `cycle_at(month_index,quarter=0,profile={})`, `quarters_between(first,last,profile={})`, `elapsed_months(first,last,profile={})`, `retarget_cycle(cycle,source_profile,target_profile)`, `shift(profile,offset)`, `action_month(cycle,productive,profile={})`, `label(cycle,start_year=1980,profile={})`. Use integer quotient/remainder to avoid unsafe multiplication of extreme counters.

RunState API `get_calendar_profile()` exposes the selected run clock. UI uses this profile and central helpers,not private conversions. Ledger/sales validators treat missing clock metadata strictly as legacy2. Finance additionally stores an action-journal cutover index so historical and newly accepted zero-cycle operations at the same rawC retain different timing. Immutable loan schedules retain their issuing clock; unissued future dues map through the active clock. Existing issued bills/payments never move.

Sales retains actual `total_earned_cycles` for development/history identity. Its release-age profile preserves earned old halves and completes partial months with quarter steps. Store the run profile for exact settlement/factor replay. Keep Month1 rounding order distinct from later months and retain old frozen factors/campaigns. Fanbase and report replay share the same contexts.

## Ownership and ordered work

- [x] Capture genuine old even/odd Studios with debt/payroll and a paired eight-rival world before source edits; retain baseline source/diff and failures.
- [x] RED/GREEN central clock:4/month,48/year,odd/even legacy cutovers,inverse dates,boundaries,unchanged cycles.
- [x] Root owns Clock,RunState,sales/Fanbase/support replay and typed Studio/world save integration.
- [x] Finance worker may own only scripts/finance; implement pure clock integration,immutable schedule contexts,history replay and new same-cycle operation correctness; report typed schema deltas to root.
- [x] World worker may own only market transaction/book/historical standard/rival world/opening/policy files; root owns rival_world_checkpoint and persistence. Version new snapshots/context and preserve old histories.
- [x] UI worker may own only named UI/date presentation plus Store era and release index date helpers; preserve existing Phase2A edits. Root owns gameplay formulas.
- [x] Migrate validated saves only after old provenance checks,align owner/player profiles,never recreate past settlements or re-simulate careers.
- [x] Focused monthly finance/sales/loans/education/payroll/Fans/Market/era tests; actual new/old cold saves and independent legal replay. Preserve action mechanics and source-pinned pre/post development outcomes.
- [x] Relevant maintained suites; independent review; truthful TODO/design/current state/dated session log and modified-file inventory.

No commit,push,public build,Drive synchronization or new automatic checks are implied. Gameplay action deadlines such as Support6/24 and contract2/3 hands remain fixed. Market's old12-cycle window is explicitly six months and becomes24 fresh cycles through calendar distance,without changing coefficients. Absolute finance month IDs stay separate from month-of-year display.

Completed at implementation/headless scope; see the dated log for retained fixture failures and unrun native/4.4/export/full-prelude gates. The genuine pre-change Bank quote declined; focused loan coverage is constructed, while genuine saves include education and payroll.
