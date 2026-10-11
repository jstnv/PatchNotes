# Renewed overnight execution and exported campaign — 2026-10-11

## Scope and source

User renewed all-task, headless-first and Computer Use authorization. Started from clean `main` at `e8ace395fa56eda9d9393e14f65b905188ebd2dc`; HEAD stayed unchanged. Inspected CURRENT_STATE, TODO, source/diff and relevant release, Contracts, Fanbase, Store, employee and simulation records. The queue contained no further approved numerical/gameplay implementation waiting to be adopted. Explicit AI cohort/migration/policy choices remain OPEN; Banking's eligible-quote design study belongs to its design thread; mature Fan growth and human Store comprehension remain DEFERRED.

This pass repaired five presentation defects found during actual exported play. It did not change scoring, card eligibility, rewards, finance rules, AI policy, RNG or the Studio-only Continue boundary. Existing files and `patch-notes/.codex-godot-temp` were preserved. No commit or push was made in this pass. The preceding delivery was already committed separately.

## Repairs

|Change|Evidence|
|---|---|
|Corrected eight mojibake separator/multiplier display strings in Design|First-game/tips and Design checks; corrected export route|
|Restored old card focus before opening the Contract result, and kept Tab/Shift+Tab inside that result|Before-fix regression failed 12 assertions across 1152/1280/1600 widths; after-fix verifier passes. Actual compact SideStreet and Starwave results dismiss with Enter; SideStreet also passes Tab/Shift+Tab|
|Put Production Specialist explanation in a bounded scroll surface, keeping Hire/Back visible|Initial regression reproduced overflow; final UI check passes both supported sizes. Actual 1152×648 export shows complete usable dialog and hiring succeeds|
|Routed Specialist planned hands through the common hand presentation|Design/Alpha verifier confirms one gameplay mutation, correct replacements, four score events and cleared selection. Actual Game3 export now animates and clears selection normally|
|Changed the generic pending-contract button from “SideStreet Offer” to “Contracts” with accurate tooltip|Actual button had opened Starwave under the SideStreet label. Publisher/browser, Starwave UI and navigation checks pass after the two-string correction|

Canonical files: `scripts/phases/{design_phase,contract_phase,studio_phase}.gd`, `scripts/ui/{employee_panel,employee_planning_dialog,phase_workspace,hand_presentation}.gd`, and `scripts/debug/{verify_contract_presentation,verify_employee_ui,verify_employee_hands}.gd` under `patch-notes`.

## Automated verification

- [Maintained gate](release-gate-final/gate-result.json): **133/133 Godot suites pass**, clean import/export, 275-entry PCK/hash audit and isolated headless EXE startup. The command used `--defer-graphical-startup`, so `headless_automated_pass=true`, `automated_pass=false`, `release_ready=false` and exit 1 are intentional. Separate actual graphical startup and gameplay are recorded below; the gate JSON was not rewritten to imply acceptance.
- The full gate includes the employee motion repair. **Only two Studio offer display strings changed afterward.** [Three focused checks](studio-contract-label/result.json) pass on that final change. The subsequent delivery export passes clean import/export, package validation and headless startup, and was started and played through Computer Use.
- [Final-source fresh campaigns](campaign-delivery/run-report.json): four cycle-0 Studios, **16 releases / 320 accepted commands**, all complete at cycle31. Explicit bounded test policy: `bounded-campaign-stress/v1`; Action4417, Cult Action90210, College Dropout RPG1104, Puzzle77. Each has two Design, two Alpha and two Beta hands per project. These are test policies, not approved rival AI or optimal play.
- Four independent fresh-process exact replays pass, 80 commands each: [Action](replay-delivery-action-4417/run-report.json), [Cult](replay-delivery-cult-action-90210/run-report.json), [education](replay-delivery-education-rpg-1104/run-report.json), [Puzzle](replay-delivery-puzzle-77/run-report.json). Source, recipes, RNG, tapes, profiles and rejected/intermediate evidence are retained. This self-service policy does not itself borrow; Bank coverage comes from native suites and the actual exported route.
- [Read-only evidence audit](audit-result.json): **1,018 checks, zero failures**, including checkpoint payload hashes, 158 exact-cent finance transaction links, 36 fully paid obligations, unchanged delivery source, once-only rewards, research/hiring/loan identities and release Awareness. The first audit accidentally counted starting funding twice; [failed audit](audit-result-first-attempt.json) is retained. The corrected auditor starts at zero and independently verifies the recorded starting-funding transaction.
- Focused checks and reproduced failures are retained in `focus-before`, `presentation-after`, `employee-geometry-v2`, `employee-after-v2`, `employee-motion-after`, `beta-after` and `text-fix-checks`. One intermediate batch referenced nonexistent `verify_beta_phase`; the actual maintained Beta base-hand and finalization suites were then run successfully. No failed attempt is counted as a pass.

## Actual exported campaign

All progression below used ordinary visible game input, without save injection, debug unlocks or altered rules. Dedicated disposable profile: `%APPDATA%/Patch Notes Acceptance 20261011 v3`. The normal player's saves were untouched. **377 timestamped captures**: [index](captures/index.json). Saved evidence is in [checkpoints](checkpoints/), including retained runtime logs; the audit found no script/runtime errors in these logs. Placeholder-art warnings are not asset acceptance.

The run was **Overnight Current Trial**, permanent Action specialty, Cult Following only. New version8 Studio started with20 Fans, one point spent and three unspent points converted into $150; initial spendable cash $5,650. It began at1280×720, then used1152×648 through a confirmed in-game setting change, preserved across cold restarts.

|Milestone|Actual result|
|---|---|
|Game1, Current Trial One|Launch c15; Review6.7, Scope29/30, zero bugs, Awareness127 = 100+22 Marketing+5 Fan Awareness; 20 launch Fans, cash$790. Cold Continue preserved Studio15|
|Neon|Unlocked by Awareness. Two legal hands c16–17, 100%, $1,560 once and20 keyed Promotion; automatic Graphics focus remained fixed|
|Ironclad|$400 advance c17, two hands throughc19, 89.6% completion, $1,791.66 final payment. Original result's keyboard failure reproduced and repaired|
|Bank|After two settled sales months, accepted $500/12-month loan c19 at zero cycles; cold Continue preserved cash$12,167.52. First full-month due c22. Six installments c22–32 paid $250.02 principal and$23.75 interest. Explicit payoff$249.98 atc32 closed the loan; no future interest. Cold Continue preserved closure and history|
|Employee|Hired c19 for$100 at zero cycles. First paydayc22, $10 each month. Training and optional Game2 Alpha plan were durably recorded. Game3 Design plan on delivery export shows the repaired normal animation and exactly one recorded hand|
|Feature Store|Recorded Sounds admittedc19: $850 non-refundable deposit, not owned yet. One Research actionc20 charged current familiarity quote$765 and granted ownership; the Feature appeared in Game2/3. No draw guarantee or balance change inferred|
|Game2, Current Trial Two|Launchc32; Review6.3, Scope30/30, two bugs, Awareness159 = 100+5 Marketing+34 Fan Awareness+20 Promotion. 137 launch Fans. Crown's Review7 gate was missed; retained as a miss. SideStreet became available|
|SideStreet|Acceptedc32 at zero cycles; two hands throughc34, 93.8% display, exact$1,125 once. Fixed result Tab/Shift+Tab/Enter worked. Third distinct contract unlocked Starwave|
|Starwave|Acceptedc34, zero advance/cycles. Hand1c35 and hand2c36 paid no contract money; ordinary sales/rent/payroll still processed. Hand3c37 completed100% and paid exactly$2,240 with no Promotion. Enter returned to Studio; cold Continue preserved cash$18,481.16, 185Fans, four completed contracts and no duplicate payout|
|Positive promoted sales|Game2 had actually settled **$8,992.99** byc40; its original launch Awareness159 remained frozen. This extends prior zero-sales Promotion evidence|
|Game3, Current Trial Three|Bounded deliberately weak release to check Specialist presentation and Promotion reuse: two Design hands, no Alpha/Beta hands, ordinary low-Scope and launch warnings accepted. Launchc40 Review0.6, Scope11/30, four bugs, 198Fans, Awareness149 = 100+49 Fan Awareness. **No repeated Promotion**. This is not a balanced-play policy or a weak-release monthly-loss observation|
|Final saved state|Studio c40, three releases, cash**$18,678.51**, Fans198, zero arrears, paid loan closed. Game closed normally after preserving checkpoint copies|

Useful captures: [employee dialog repaired](captures/184-0.png), [SideStreet result focus](captures/310-0.png), [Starwave result](captures/342-0.png), [Specialist moving](captures/367-0.png), [Specialist finished](captures/368-0.png), [next-launch Awareness](captures/376-0.png).

## Source and build boundaries

The route spans incremental exports as discovered defects were fixed. `captures/index.json` identifies the executable used for every image. Initial/corrected exports supplied Game1 and early contracts; `repaired` supplied hiring/research/Game2; `final-build` supplied the fixed contract focus and SideStreet/Starwave; `delivery-build` supplied cold completed restore and Game3 Specialist/next-launch checks. **Do not describe the entire route as one final binary run.** No gameplay-rule or data change occurred between these exports.

- [Delivery source hashes](source-delivery.json); [full-gate source](release-gate-final/source.json); [audit](audit.py) verifies the exact post-gate one-file difference.
- [Delivery manifest](delivery-build/export/playable-summary.json): EXE SHA256 `7c3e92d9c175dc8754947c93f2ad6d9514091e51cf542407b7595e2bbbd20257`; PCK SHA256 **`a4c159347d6191d2e1def21edd11e9a68c303fedf5c7bfb32f863c17e684835d`**, 3,071,076 bytes;275 entries. The custom profile is a build-only override.
- Local launchable build: `delivery-build/playable/Patch Notes Demo.exe`. Binaries, copied simulator projects and profiles remain ignored build artifacts; evidence/script files stay in this folder. Earlier exports are preserved.

## Remaining queue and acceptance

|Item|Status after this pass|
|---|---|
|Approved implementation backlog|No additional approved rule package waiting. Five discovered presentation fixes implemented and verified|
|Task11 ordinary integrated Bank/two-game route|PASS at the recorded incremental export/source scope, including accepted-loan Continue, installments, payoff and closed-loan Continue|
|Current Cult20 creation/growth/frozen launch/Continue|PASS for this Action/Cult route. Existing version7/inactive save compatibility remains native/restart evidence; no new exported migration claim|
|Contracts C5 / item23|PARTIAL: current Neon, Ironclad, SideStreet, Starwave payout and positive-sales/next-launch Promotion observations pass. Crown wasn't legally unlocked. Full per-publisher both-size keyboard matrix and fresh current-source uncommitted Starwave rollback remain OPEN; earlier pinned rollback evidence remains valid only for its source|
|Education and distressed finance UI|Current native suites pass. Fresh exported late/partial debt, Graduate and inactive-preview migration scenarios were NOT RUN here; this solvent single-profile route cannot stand in for them|
|Audio/assets|Timing checks pass (3,503 soundtrack checks). Audible balance/feel, approved final asset/license set and clean-machine acceptance remain OPEN; screenshots do not establish listening|
|AI|Private studies already completed; canonical cohort, migration, planner/policy and later gates remain OPEN. No candidate was silently adopted|
|Design studies|Fanbase near-neutral/SideStreet findings remain review evidence. Banking-owned study remains owned there. Explicitly deferred human Store testing/mature growth were not resumed|

This is substantial integrated acceptance, not complete release readiness or a final balance approval. Fresh campaign policy runs test systems independently of scenes; graphical routes test presentation and input. Neither substitutes for the other's unrun cases.
