# One fresh Studio with every catalog Feature — finding, 2026-10-26

**Finding:** Complete Feature ownership solved the earlier under-Scope/Core problem in this one synthetic Adventure route, but did **not** produce a high Review. The corrected case released at **5.5/10** with **65/30 Scope**, Core **40/32/56/61** against Adventure standards **33/26/20/53**, and **11 remaining Bugs**. A high-quality production rating of **9.539** was multiplied by `1 - 11/30` and then received this run's inferred `-0.5` Review variance, yielding **5.5**. Unlocking Features alone is insufficient; Beta QA and available cash are the next constraints.

## Authority and test boundary

- [Predeclared one-case plan](2026-10-26-all-features-fresh-studio-one-case-plan-v1.md) and [protocol correction](2026-10-26-all-features-fresh-studio-one-case-amendment-v2.md). `main` HEAD `087df09d653858b72c6e2dc344352237433dd3ac`, dirty shared checkout. Private v2 original canonical base `882eaae93f3261756b191fddbef0d998d9dafec6d01f0388fef28aa7f86b77e9`, baseline drift **false** at capture, candidate `0d5e3ead0b50cbade9063bf164194270f4ace9884146ecb2a6b135229d8f241f`, runtime source identity `569454df9ab755535f6f5bd8cb039f13df651234c9cbb1fc928e0ecb9da86060`.
- One Adventure-specialty fresh Studio, Adventure/Fantasy project, no traits, seed `4417`, no artificial cash/Fans/Core/Review grant. Private `RunFactory` grants all **42** current catalog definitions (27 starting + 15 Store entries) as owned for only `all-features-adventure-4417`. This bypasses Store acquisition and era timing, so it is a stress condition, **not a legal ordinary new-save start**. The ledger's current Store play-price semantics remain in force.
- Policy uses the private whole-supply/full-Scope trial selector from [v3](simulators/whole-supply-gates-20261026-v3/variant.json), with synergy and Beta choice enabled. It searches legal supply through redraw/Pass, refuses under-Scope Alpha exit/launch, and uses the trial two-hand Beta exit. One release, 180-command ceiling, 240-second process timeout. No seed or budget substitution.
- Earlier bare Adventure `4417` case used two Design and two Alpha hands and released at **17/30 Scope, 0.8 Review**. Its starting ownership differs; equal seeds do not make the two states or RNG trajectories paired.

## Results and failure retained

| Case | Review | Scope | Cores G/S/T/D | Bugs | Cycles | Cash/dues at launch | Status |
| --- | ---: | ---: | --- | ---: | ---: | --- | --- |
| v1 protocol error: synergy/Beta selector off | 4.7 | 65/30 | 36/31/55/62 | 13 | 16 | $0 / $90 overdue | Completed; retained, excluded from declared competent-policy conclusion |
| v2 corrected policy | **5.5** | **65/30** | **40/32/56/61** | **11** | **16** | **$0 / $90 overdue** | Completed, 26/26 commands accepted |

The v1 private policy accidentally passed `enabled=false`, which also disabled the Beta QA selector. [Its frozen result](sims/all-features-fresh-studio-one-case-20261026-v1/cases/all-features-adventure-4417/result.json) remains evidence of that narrower route. A child v2 changed **only** the selector argument to `true`; [v2 run report](sims/all-features-fresh-studio-one-case-20261026-v2/run-report.json), [case result](sims/all-features-fresh-studio-one-case-20261026-v2/cases/all-features-adventure-4417/result.json), [telemetry](sims/all-features-fresh-studio-one-case-20261026-v2/cases/all-features-adventure-4417/telemetry.json) and [fresh-process replay](sims/all-features-fresh-studio-one-case-replay-20261026-v2/replay-report.json) are retained. Initial state digest matched between v1/v2 (`341ad711…649`), though their policy/source identities differ. Replay passed all **26** accepted commands and final state `6e8dbe66…d03`. The experiment log had no `SCRIPT ERROR` or `ERROR:` markers; it did report a six-ObjectDB-instance leak warning at exit.

The corrected trace has seven Design plays and six Alpha plays, then two Beta plays. It began with **$5,700**, entered Beta with **$410**, and launched at **$0** and **$90 overdue**. The policy did not prove every one of the 42 owned Features was played: it exhausts its legally available phase supply and the retained trace counts hands, while affordability and draw legality constrain card use. It did prove this route exceeded required Scope and every frozen Core standard. Scope above 30 gives no further Review multiplier once completion reaches 1.0.

At the same Core mix and variance, the Review formula implies approximately **9.0 with zero Bugs**, **8.1 with three**, and **7.1 with six**. These are arithmetic sensitivities, not simulated alternate runs or approved targets. A rival aiming for 8+ under this production state would need to finish near three or fewer Bugs, and to afford enough legal QA time to get there. The current two-hand Beta exit is the immediate design bottleneck; the normal new-Studio bankroll is also exhausted by this oversized full-catalog project.

## Exact commands

```powershell
$py = 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$godot = 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
& $py tools/simulator_variant.py create --id all-features-fresh-studio-20261026-v1 --owner ai-competitors --output docs/codex/threads/ai-competitors/simulators/all-features-fresh-studio-20261026-v1
& $py tools/simulate.py run --variant docs/codex/threads/ai-competitors/simulators/all-features-fresh-studio-20261026-v1 --config docs/codex/threads/ai-competitors/all-features-fresh-studio-one-case-20261026-v1.json --output docs/codex/threads/ai-competitors/sims/all-features-fresh-studio-one-case-20261026-v1 --godot $godot --timeout 240
& $py tools/simulator_variant.py create --id all-features-fresh-studio-20261026-v2 --owner ai-competitors --from-variant docs/codex/threads/ai-competitors/simulators/all-features-fresh-studio-20261026-v1 --output docs/codex/threads/ai-competitors/simulators/all-features-fresh-studio-20261026-v2
& $py tools/simulate.py run --variant docs/codex/threads/ai-competitors/simulators/all-features-fresh-studio-20261026-v2 --config docs/codex/threads/ai-competitors/all-features-fresh-studio-one-case-20261026-v1.json --output docs/codex/threads/ai-competitors/sims/all-features-fresh-studio-one-case-20261026-v2 --godot $godot --timeout 240
& $py tools/simulate.py replay --bundle docs/codex/threads/ai-competitors/sims/all-features-fresh-studio-one-case-20261026-v2 --case all-features-adventure-4417 --output docs/codex/threads/ai-competitors/sims/all-features-fresh-studio-one-case-replay-20261026-v2 --godot $godot --timeout 240
```

## Recommendation and limits

Keep **LOCKED** full-Scope/Feature-exhaustion direction and the current **ACTIVE/TRIAL** Review math separate from this experiment. **OPEN:** a cash-aware Beta QA opportunity budget, ability to pay monthly dues during an oversized project, selection of QA over marketing, ordinary Store acquisition, other Genres/seeds, 1977 historical starts, and CPU/population behavior. This one-case test supports studying a longer affordable Beta policy before adding any Core boost or lowering Genre standards. It does not approve a balance value or require a TODO implementation handoff.
