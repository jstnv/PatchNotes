"""Record only inspected, source-fenced acceptance outputs; never change gameplay."""
import hashlib
import json
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
SOURCE = "dabfdcc4484b44727f7cc0f772811346c13655c617ee0564562a110d723ef692"
LOG = "2026-10-31-pass-budget-career-acceptance-v1.md"

def read(path):
    return json.loads(path.read_text(encoding="utf-8"))

def write(path, text):
    previous = path.read_bytes() if path.exists() else b""
    newline = "\r\n" if b"\r\n" in previous else "\n"
    path.write_bytes(text.replace("\r\n", "\n").replace("\n", newline).encode("utf-8"))

names = [
    "green-clock-final-v9", "green-legacy-provenance-v9", "genuine-5b-save-v9",
    "genuine-late-save-v9", "world-budget-final-v9b", "actual-new-continue-v9",
    "native-gallery-v9", "native-budget-final-v9", "final-dto-replay-v9",
    "cohort-final-5607-v9", "cohort-replay-5607-v9", "live-career-300-v9",
]
index = []
for name in names:
    result = read(HERE / name / "result.json")
    report = read(HERE / name / "report.json")
    assert result["ok"] and result["source_unchanged"] and not result["engine_errors"], name
    assert not report.get("failures", []) and not report.get("issues", []), name
    if "source" in report:
        assert report["source"] == SOURCE, name
    index.append({"directory": name, "result": "PASS", "checks": report.get("checks"),
                  "report_sha256": hashlib.sha256((HERE / name / "report.json").read_bytes()).hexdigest(),
                  "log_sha256": result["log_sha256"], "source_unchanged": True})
matrix = read(HERE / "maintained-final-v9/results.json")
assert len(matrix) == 10 and all(item["ok"] for item in matrix)
forward = read(HERE / "normal-careers-final-v6/report.json")
assert not forward["failures"] and len(forward["rows"]) == 6
assert all(len(row["releases"]) == 8 and not row["stop"] for row in forward["rows"])
live = read(HERE / "live-career-300-v9/report.json")
assert len(live["releases"]) == 8 and live["cycle"] == 249 and not live["stop"]
bounded = read(HERE / "live-career-v9b/report.json")
assert live["commands"][:len(bounded["commands"])] == bounded["commands"]
comparison = read(HERE / "canonical-final-comparison.json")
assert comparison["differences"] == []
head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
branch = subprocess.check_output(["git", "branch", "--show-current"], cwd=ROOT, text=True).strip()
assert head == "3a61522f18db7a2bae892cb8c5be1fee68cd4100" and branch == "main"
write(HERE / "verified-index.json", json.dumps({"runtime_source": SOURCE, "branch": branch,
      "HEAD": head, "verified": index, "maintained": matrix}, indent=2) + "\n")

rows = read(HERE / "normal-career-summary.json")
table = "\n".join(f"| {row['recipe']['specialty']} | {row['recipe']['seed']} | 8 | {row['cycle']} | {row['contracts']} | {row['Passes']} |"
                  for row in rows)
log = f"""# Pass Budget career acceptance — 2026-10-31

## State and authority

User: finish remaining Pass Budget career checks, repair issues, update TODO without input. Main/HEAD `{head}`; dirty shared work preserved. Final runtime source `{SOURCE}`, Godot4.7.1 stable, RNG `godot-4.7.1-rng-v1`. No commit, push, public build or ZIP. Both `.codex-godot-temp` folders remain. All canonical project source bytes match final simulator-v9 in `canonical-final-comparison.json`; both certified1977 input files match task-start hashes byte-for-byte.

Read current state/TODO, provenance README, Pass Budget design/implementation records, source and diffs. Task-start source `ac5b36c205824b47262a192e83fc7b8c724314088a1fa7578279a774b1920e07` is retained in before-source.zip/before-manifest.json. Concurrent Engine edits invalidated an early canonical cohort fence; isolated versioned simulators retained each attempt. Twenty-one scoped GDScript paths are listed in merge-preview/index.json: fourteen runtime files and seven verifier fixtures. Three-way reconciliation preserved the newer Engine implementation; no rent, price, roster, capital, Review or card-stat changes were adopted.

## Repairs

- Persist explicit project rule version and exact Design/Alpha printed/spent counters for active rivals, restore before phase construction, expose quota to policies, and reject invalid versions/origins/printed totals/spend/reservations. New projects use2/K8 independently per phase. Unversioned existing active rival projects finish under version0 legacy unlimited rules with an admitted source origin and no invented past counts; the next project uses version1. This deliberate one-project migration also handles preceding partial implementations whose saved spend was unrecoverable. Player Continue remains Studio-only.
- Rival hand selection obeys the shared budget. Exhausted Alpha exits when legally allowed instead of pursuing an unattainable quality target. Whole-supply checks require an affordable complete four-card hand; a stranded lone Feature cannot indefinitely prevent exit. Full-Scope gates and quality/funding values remain.
- Passive `rival_wait` settles real sales/bills even in arrears. RunState permits only the existing1977 founder profile, own Studio source, zero direct cash, no campaign and no productive callback. Checkpoints enforce those receipts. Debts/interest/rent remain; player production retains its arrears gate.
- Stable simulator IDs now rekey Engine entitlement ownership along with the other Studio-owned state, fixing genuine Continue rejection. No license or money is granted.
- Historical fixed-seven fixtures explicitly use legacy version0. Current2/K8 has separate native/career coverage. Frozen scoring digest files are unchanged: asserted dormant Engine/calendar fields and unused later Store metadata are translated only in detached historical comparisons. Current raw live/headless traces retain everything. Priority assertions use current20–40 default bounds; the finite test policy chooses legal short-pool hands.

## Verified careers

Normal no-trait starts:12 Scope/$5,700, paid Research, ordinary Bank/Contract recovery, no grants. Explicit test policy: Features first, up to2/2/2 phase hands, legal exits, Research toward12+4 per release capped30, six-rent production reserve. This is a test policy, not an adopted AI/balance strategy.

| Genre | Seed | Releases | Cycles | Recovery Contracts | Actual Pass activations |
|---|---|---:|---:|---:|---:|
{table}

Forward run on integrated v6/source4a2cc02…:3,200 checks;2,730 commands,178 successful Design/Alpha hands,67 Passes and2,442 printed Feature Core; all six reach30 owned Scope. Final-v9 replay:4,756 checks compare recorded persistent-state/RNG projections after every command, exact complete Studio DTO/Engine state at48 release-boundary Continues, and1,972 rejected active-player checkpoint attempts. The compact per-command projection covers FIELDS/SUPPORT_FIELDS, Engine entitlements, Contract instances, Project/hand DTOs and RNG; it is not a save format or the entire raw object graph. The complete Studio DTO comparisons additionally cover the newer Engine portfolio/royalty maps.

Actual live Market route (same normal start/policy, twelve-zero-step scheduler, eight real frozen1977 owners): **8 releases at cycle249**,335 checks,61 recovery Contracts,30 owned Scope, $1,957.54 cash, nine exact player/world JSON continuations and249 successful world ticks. All eight owners, Market/history/policy/budget/RNG are compared at each saved boundary. The original240-cycle study reached seven releases at241 and remains BOUNDED; the300-cycle extension preserves all516 original commands and state hashes exactly. No gameplay value changed to finish it.

## Other final-source verification

| Artifact directory | Result / actual coverage |
|---|---|
| maintained-final-v9 | PASS10 verifiers: Design/Alpha/Beta commands with original digests/full live-headless traces; Design/Alpha phases; budget; empty Alpha finalization; candidate retention; alignment; finance ledger |
| green-clock-final-v9 | PASS14 budget/observation/exit/stranded-Feature/passive-debt/player-gate regressions |
| world-budget-final-v9b | PASS169 real24-cycle world, JSON cold/next choices/RNG, legacy-to-new-project transition, counter/source/corruption rejection |
| genuine-5b-save-v9 / genuine-late-save-v9 | PASS28/24 actual preceding5b durable save and genuine cycle97/2e5049 world; old gameplay fields retained, explicit version/origin metadata, exact migrated roundtrip |
| green-legacy-provenance-v9 | PASS16 genuine BF active-project save generated under exact archived BF runtime; original gameplay fields preserved, explicit current schema revision, source provenance retained |
| native-budget-final-v9 | PASS162 full native/shared-command Project/Run/hand/token/counter/RNG comparisons, real short pools/exits, three Genres at1152×648/1280×720 |
| native-gallery-v9 | PASS8 native Pass badge/tooltip-content checks; both gallery captures inspected. Earlier standalone phase captures before layout/entrance settled are retained but excluded from visual acceptance |
| actual-new-continue-v9 | PASS10 actual title/new-Studio/loading/durable save/tutorial invitation/Continue, eight-owner state exact and Studio-only attach |
| cohort-final-5607-v9 / cohort-replay-5607-v9 | Eight real1977 founders,72 ticks,32 legal releases; full object/RNG/event replay PASS2,088 checks over1,032 owner commands |

Seed5613's integrated-v6 cohort also completes72 ticks/32 releases. Its source boundary is recorded separately; v6→v9 changes concern admitted save provenance, not hand/scoring/finance policy. Every counted final runner has exit0, no engine errors and an unchanged source fence; exact commands and script/runner/log hashes are in result.json and verified-index.json.

## Review, retained failures and limits

One fresh-context read-only whole-change review found omitted exact legacy-origin groups. Those groups are now admitted narrowly. The authentic BF case already used the pre-calendar adapter, revealing a second detail: that adapter stamped its own673… identity instead of the validated generation source. RED v8 has two provenance failures; final-v9 retains BF provenance and passes16. Original bytes/headers were never relabelled.

Retained: missing-counter/exit REDs; passive arrears deadlock; Engine-owner Continue rejection; concurrent-source fence failures; import/profile/parse harness errors; old-priority and historical-hash mismatches; null inactive-world row and native begin-command harness mistakes. The former all-state600-second career run and every-Studio-action900-second replay timed out; their partial output is not counted as success. Final bounded projection/complete-DTO verification passes. The idle clock fixture's ordinary player correctly stops in arrears at25; final cold coverage is explicitly24 cycles. The seven-release240-cycle live route remains alongside its completed extension.

**OPEN:** Godot4.4 is not installed/tested; do not weaken frozen engine/source pins to simulate compatibility. No current EXE/ZIP acceptance, human/device/listening, no-lag/performance, final balance, optimal8/4 build exposure or guaranteed8.0 Review claim. Neutral-policy Reviews were0.0–2.8 and required36–57 recovery Contracts; the live route needed61. Functional solvency under this explicit policy does not settle pacing, challenge, diverse strategies or broad economy balance. Player12 Scope/30 required Scope,2/K8, existing$500 rent, Bank rules and certified history remain; separately selected$300 rent and other candidate changes were not adopted.
"""
write(ROOT / "docs/codex/logs" / LOG, log)
write(HERE / "README.md", f"""# Pass Budget career acceptance — 2026-10-31

Functional/career acceptance COMPLETE locally on Godot4.7.1.2/K8 remains ACTIVE/TRIAL. [Dated assessment](../../logs/{LOG}) contains source, exact scope, policy, outcomes and remaining gates. [Verified output index](verified-index.json) records only passing final source-fenced runs; failures remain in their original directories.

- Final runtime `{SOURCE}`; main/HEAD `{head}`. All canonical project bytes match simulator-v9. Original certified opening bytes are preserved.
- Seven normal12-Scope careers reach eight releases: six neutral-market cases plus one actual eight-rival Market career at249 cycles. No cash/Feature grants. The240-cycle live bound is retained, with an identical516-command prefix in the300-cycle extension.
- Final six-case replay4756 checks; complete Studio DTOs and active-player Continue rejection; live-world335; maintained10; current cold169; genuine old saves28+24; authentic BF16; regression14; native162+8; actual game entry10; founder replay2088.
- Before-source.zip and before-manifest.json retain the dirty task baseline. merge-preview and pre-adoption-canonical-scoped.zip document preservation/reconciliation. Historical-bf-copy-manifest.json and bf-active-generation prove the real old-source fixture; no save was relabelled. Each simulator version retains its tool-created ancestry/integrity and exact run outputs.
- Reproduce with the exact argv in each result.json into NEW output directories/private profiles. Import a new candidate before parallel Godot work. Absolute profile paths are required. Normal-career-summary.json/live-career-summary.json describe the declared test policy; these are evidence, not balance or policy adoption.
- Compact command hashes are scoped projections, not full raw states/save formats; release-boundary complete DTO equality supplements the newer Engine fields. The2088-check founder replay and native hand comparisons retain full objects/RNG.
- Godot4.4, public package/device acceptance, optimal build exposure, performance and final balance remain OPEN. Long timeout attempts, bounded funding stops and failed harness/source fences are retained and excluded from PASS counts.
""")
write(HERE / "REVIEW.md", """# Read-only final review disposition — 2026-10-31

Fresh-context reviewer compared the task-start archive with scoped runtime changes and reported one important exact-source legacy-origin omission; no additional actionable defect was found in quota/counters, future reset, Engine identity, feasible-hand fallback, authenticated passive calendar or player arrears preservation. Exact existing origin groups were added. A genuine BF active-world fixture was generated by executing the byte-pinned archived BF runtime in a separate copy, preserving both .codex-godot-temp folders. This demonstrated that the pre-calendar adapter already restored that historical shape but assigned adapter673 provenance. The migration now retains the original generation source only after the old reader verifies its exact source/content pair. RED two provenance assertions → GREEN16; current strict and genuine5b/late saves also pass.

Historical digest mismatch was resolved by raw comparison with the original extraction capture: only asserted empty new Engine maps and unused later Store metadata remained. Original digest files were not regenerated. Final10 maintained verifiers pass. See dated log and verified-index.json for exact evidence/limits.
""")

design = ROOT / "docs/codex/design/pass-budget.md"
text = design.read_text(encoding="utf-8").replace("\r\n", "\n")
paragraphs = text.split("\n\n")
paragraphs[1] = f"**2026-10-31 status: ACTIVE/TRIAL2/K8 baseline, implemented locally; available-runtime career/functional acceptance COMPLETE.** The user selected2/K8 after the Action studies. Seven normal12-Scope eight-release careers, budget persistence/legacy migration, current native/shared-command checks and maintained historical traces are verified in Godot4.7.1. Godot4.4, current public-package/device checks and final balance remain OPEN. This does not approve a27-Scope player grant or guarantee8.0 Review. [Implementation](../logs/2026-10-31-pass-budget-implementation-v1.md) · [career repairs/evidence](../logs/{LOG})."
text = "\n\n".join(paragraphs)
text = text.replace("the isolated trial reconciles that for Alpha, while canonical integration remains OPEN", "canonical Alpha supports that and the short/empty-pool exits are verified")
needle = "## Verified intermediate counts"
section = f"""## Persistence and career boundaries

New projects use version1 and save exact phase-local printed/spent counters for active rivals; the next phase starts independently. Existing unversioned active rivals use explicit version0 legacy unlimited rules until that project ends because prior spend cannot be reconstructed reliably, including the preceding partial implementation. Keep their actual hands/tokens, scores, finance, history and RNG; never invent counters. Record only an admitted generation-source origin, reject invalid/missing current/versioned state, and start the next project under2/K8. Player Continue remains Studio-only.

Rival decisions obey quota and may exit an exhausted legally complete phase rather than chase unattainable Review. Whole supply requires a feasible complete four-card hand. A code-owned1977 rival-only passive calendar tick can settle sales/bills in arrears, with no work callback/direct income/debt forgiveness; ordinary player work retains its gate. Rosters, capital, full-Scope gates, goals and economic values are unchanged. The simulator's Engine owner rekey is an identity/persistence repair.

Career evidence: six neutral cases (Action/Puzzle/Simulation ×4417/5607),48 releases,2730 recorded commands,178 successful budget hands,67 actual Passes; exact final-source replay/complete-DTO checks. One normal start with all eight live rivals reaches eight releases at249 cycles/61 Contracts after a retained240-cycle bounded run. This is functional recovery under a declared2/2/2 test policy, not proof of broad pacing/quality. [Exact policies, source boundaries, failures and all checks](../logs/{LOG}).

"""
assert needle in text
text = text.replace(needle, section + needle, 1)
start = text.index("**OPEN before full acceptance:")
text = text[:start] + f"**Remaining OPEN:** Godot4.4 and current package/device validation, final balance/diverse career strategies, and exact optimized-build exposure. Maintained historical traces, current native card surfaces/hand parity, save/Continue, actual counters and declared normal-start career checks are closed within the source-pinned4.7.1 scope above. The recovery policy's low Reviews and heavy Contract workload do not establish satisfactory pacing or a guaranteed8.0. See [dated assessment](../logs/{LOG}).\n"
write(design, text)

decisions = ROOT / "docs/codex/DECISIONS.md"
text = decisions.read_text(encoding="utf-8").replace("\r\n", "\n")
entry = f"""## 2026-10-31 — Pass Budget prospective projects, persistence and passive rival clock

Under the user's authorized2/K8 career-check/repair request, new Design/Alpha projects share authoritative quota/counters across live/headless commands. Unversioned saved active rivals finish that project under explicit legacy version0 with an admitted generation origin and no fabricated past spend; subsequent projects use version1. Preserve all actual historical state and the Studio-only player Continue boundary. A1977-founder-only zero-delta/no-callback passive calendar may service real sales/debt in arrears; player productive gates, debt, funding, prices and roster values remain. Stable simulator identities also rekey Engine ownership. These are functional/persistence repairs;2/K8 and other values remain ACTIVE/TRIAL and no new balance/package is approved. [Source/evidence/limits](logs/{LOG}).

"""
write(decisions, text.replace("# Cross-system decisions\n\n", "# Cross-system decisions\n\n" + entry, 1))

state = ROOT / "docs/codex/CURRENT_STATE.md"
text = state.read_text(encoding="utf-8").replace("\r\n", "\n")
for line in text.splitlines():
    if line.startswith("**2026-10-31 Action Pass Budget —"):
        text = text.replace(line, f"**2026-10-31 Action Pass Budget — functional/career acceptance COMPLETE locally;2/K8 ACTIVE/TRIAL.** Seven normal12-Scope careers reach eight releases (six neutral cases, one actual eight-rival route at249 cycles); final4756-check replay/complete DTOs,10 maintained verifiers,169 current-world cold/corruption checks, genuine old saves,162 native hand comparisons, Pass surfaces and actual New/Continue pass. Fixed persisted counters/legacy provenance, Engine identity rekey, finite-hand rival exits and passive sales/bills deadlock without changing economic values. Godot4.4, current package/device/performance, optimal build exposure and final balance remain OPEN. [Exact source, policies, failures and limits](logs/{LOG}).")
text = text.replace("Maintained Design/Alpha fixed-seven traces and two predevelopment fixtures still fail amid the provisional Pass Budget; rival activation/cold checks only fail their stale dashboard label assertion.", "The Pass Budget hand/phase fixture blockers are resolved in the career acceptance record. Separate Engine predevelopment/status-text, royalty and device gates remain OPEN.")
write(state, text)

# Re-read TODO immediately before the minimal replacements; preserve other handoffs.
todo = ROOT / "docs/codex/TODO.md"
text = todo.read_text(encoding="utf-8").replace("\r\n", "\n")
for line in text.splitlines():
    if line.startswith("**2026-10-31 Pass Budget career acceptance —"):
        text = text.replace(line, f"**2026-10-31 Pass Budget career acceptance — COMPLETE locally at functional/automated scope.** Counter/provenance persistence, simulator Engine ownership, feasible rival hands/exits and passive arrears calendar are repaired. Seven normal12-Scope careers reach eight releases; the live eight-rival route ends at249 cycles, retaining its earlier240-cycle bound. Final4756 replay/complete-DTO checks,10 maintained verifiers, current/genuine-old cold saves, native surfaces/hand parity and actual New/Continue pass.2/K8 remains ACTIVE/TRIAL; Godot4.4, package/device/performance, optimized exposure and final balance remain OPEN. [Source, policies, retained failures and evidence](logs/{LOG}). No commit/push/build; preserve shared work and separate rent/Engine gates.")
    elif line.startswith("**2026-10-31 Action Pass Budget —"):
        text = text.replace(line, f"**2026-10-31 Action Pass Budget — IMPLEMENTED; career/functional checks COMPLETE on Godot4.7.1, values ACTIVE/TRIAL.** Shared2/K8, short pools, reservations, exact active-rival counters and one-project legacy migration are integrated. Maintained old-Pass traces, current native/model parity, save/Continue and declared normal-start careers now pass; player12 Scope, required30 Scope and existing economic values remain. Godot4.4, current public package/device checks, optimal build exposure and broad balance are OPEN. [Complete assessment](logs/{LOG}) · [design](design/pass-budget.md).")
text = text.replace("Reconcile maintained fixed-seven Pass Budget traces and stale rival-status text fixtures;", "Pass Budget hand/phase traces are resolved; reconcile separate Engine predevelopment/status fixtures;")
write(todo, text)
plan = HERE / "PLAN.md"
write(plan, plan.read_text(encoding="utf-8").replace("- [ ]", "- [x]"))
print(json.dumps({"recorded": LOG, "source": SOURCE, "verified_directories": len(index), "maintained": len(matrix)}))
