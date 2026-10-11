"""Assemble the retained study results and verify replay/source evidence."""
from pathlib import Path
import hashlib
import importlib.util
import json
import re
import sys

sys.dont_write_bytecode=True
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location("cult_final_simulate",ROOT/"tools/simulate.py")
sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
read=sim.read_json
study=read(HERE/"audit-solo-interaction.json")
assert study["ok"] and len(study["cases"])==14
before=read(HERE/"source-before.json")
after={name:sim.sha(path) for name,path in sim.source_files(ROOT/"patch-notes").items()}
assert before==after
sim.write_json(HERE/"source-after.json",after)
replays=[]
for name in ["replay-solo-cult-4417","replay-solo-control-1104","replay-interaction-cult-buzz-4417","replay-interaction-cult-lease-1104"]:
    directory=HERE/name
    result=read(directory/"replay-report.json")
    run=read(directory/"run-report.json")
    assert run["ok"] and result["ok"] and result["telemetry_verified"] and len(result["steps"])==111 and result["telemetry_samples"]==112
    replays.append({"bundle":name,"ok":True,"commands":len(result["steps"]),"telemetry_samples":result["telemetry_samples"],"final_state":result["final_state"],"report_sha256":sim.sha(directory/"replay-report.json"),"command":read(directory/"replay.command.json")})
provenance=read(HERE/"provenance.json")
assert provenance["policy_sha256"]==sim.sha(HERE/"policy.gd") and provenance["plan_sha256"]==sim.sha(HERE/"PLAN.md")
summary={"ok":True,"cases":14,"study_commands":sum(v["commands"] for v in study["cases"].values()),"study_telemetry_samples":14*112,"releases":70,"primary_cycle":50,"supplemental_cycle":52,"final_studio_cycle":53,"audit_checks":study["checks"],"audit_failures":study["failures"],"canonical_source_unchanged":True,"predeclared_policy_and_plan_unchanged":True,"source_file_count":len(after),"source_identity":hashlib.sha256(json.dumps(after,sort_keys=True).encode()).hexdigest(),"replays":replays}
sim.write_json(HERE/"completion-audit.json",summary)

def cash(cents): return f"${cents/100:,.2f}"
def delta(cents): return ("−" if cents<0 else "+")+cash(abs(cents))
labels={"control":"No trait","cult":"Cult","buzz":"Buzz","family":"Family","lease":"Lease","cult-buzz":"Cult + Buzz","cult-lease":"Cult + Lease"}
table=["| Seed | Build | Cycle50 cash / Fans | Game4 settled at50 | Cycle52 cash / Fans | Game4 settled at52 | Cash low |", "|---|---|---:|---:|---:|---:|---:|"]
for seed in [4417,1104]:
    for arm in labels:
        item=study["cases"][f"post-{seed}-{arm}"];a=item["boundaries"]["50"];b=item["boundaries"]["52"]
        table.append(f"| {seed} | {labels[arm]} | {cash(a['cash_cents'])} / {a['fans']} | {cash(a['game4_sales']['settled_cents'])} | {cash(b['cash_cents'])} / {b['fans']} | {cash(b['game4_sales']['settled_cents'])} | {cash(item['minimum_transaction_cash_cents'])} |")
contrasts=["| Seed | Boundary | Combination | Cash vs Cult | Cash vs other component | Cash interaction* |", "|---|---|---|---:|---:|---:|"]
for seed in [4417,1104]:
    for cycle in ["50","52"]:
        def value(arm): return study["cases"][f"post-{seed}-{arm}"]["boundaries"][cycle]["cash_cents"]
        for combination,component in [("cult-buzz","buzz"),("cult-lease","lease")]:
            contrasts.append(f"| {seed} | {cycle} | {labels[combination]} | {delta(value(combination)-value('cult'))} | {delta(value(combination)-value(component))} | {delta(value(combination)-value('cult')-value(component)+value('control'))} |")
commands=[]
for folder in ["solo-run","interaction-run",*[x["bundle"] for x in replays]]:
    directory=HERE/folder
    for path in sorted(directory.glob("*.command.json")):
        commands.append({"bundle":folder,"file":path.name,**read(path)})
sim.write_json(HERE/"commands.json",commands)
finding=f"""# Cult20 post-adoption comparison — 2026-10-11

**COMPLETE bounded READ-ONLY; no new gameplay change or balance approval.** All14 fresh legal version8 routes completed the declared five releases/111 commands at cycle53. The primary cycle50 boundary includes Game4's first actual cash settlement; cycle52 adds later settled earnings. Cult20 retained a cash/Fan advantage in both seeds. Neither Cult combination blocked or accrued arrears. Retain the approved20/1 trial; wider balance and player feel remain OPEN.

## Source and verification

Dirty `main`, HEAD `{provenance['git']['head']}`. Full canonical source identity `{summary['source_identity']}`; mechanics identity `62cfd4f1686a6cc6302616d98aab421f2db511971fc5655cf5b6d9e743f612c4`. All{len(after)} runtime source files match before/after, and both isolated snapshots match the predeclared source. Policy SHA256 `{provenance['policy_sha256']}`.

The [plan](PLAN.md) was recorded before execution and followed without seed, hand-budget or stopping-rule changes. The study began only after the implementation thread confirmed new version8 and genuine version7 Continue acceptance. [Solo bundle](solo-run/run-report.json), [interaction bundle](interaction-run/run-report.json), [364-check audit](audit-solo-interaction.json), [source/replay completion audit](completion-audit.json) and [all exact process commands/timings](commands.json) preserve the evidence.

Coverage:14 routes,1,554 commands,1,568 command telemetry samples and70 launches, including14 minimal fifth launches used to return to Studio. All14 first-three-game Review sequences qualify as strong→weak→recovery:6.1/0.6/5.6 for4417 and6.2/1.0/7.2 for1104. Four fresh-process replay bundles verify444 recorded commands and448 telemetry samples exactly. There are zero rejected, incomplete or timed-out cases; no failure reduction was needed. These are headless numerical results, not new visible/native or human acceptance.

## Actual common-boundary outcomes

Cash is actual portfolio cash after settlement and due expenses. Game4 settled columns are that title's cumulative actual cash, separately reconciled with the portfolio ledger. At50 the title has earned its first half-month;52 includes the rest of Month1 and the first earning cycle of age Month2. No projected units or revenue are counted as settled cash.

{chr(10).join(table)}

Relative to no traits, Cult is **+$194.77/+4 Fans** at50 and **+$208.74/+4 Fans** at52 for4417; **+$173.77/+6 Fans** at50 and **+$187.76/+5 Fans** at52 for1104. Game4 itself contributes only+$7.00/+$6.99 of the primary cash difference; prior actual portfolio settlements and the $50 startup-point cost remain part of total cash. These endpoint advantages do not improve the earlier cash low: Cult bottoms at$790 versus control$840.

## Component contrasts

{chr(10).join(contrasts)}

*Cash interaction = combination − Cult − other component + no-trait control, at the same calendar boundary. Each comparison uses its own legal trait start; equal seeds are not equal initial state. Normalized request tapes, initial RNG and final RNG match within each seed across all seven builds, and Reviews/timing match. Only declared Studio/project identity strings are normalized. Cult+Buzz is subadditive in4417 and slightly superadditive in1104; this small screen does not establish a stable synergy advantage. Cult+Lease's cash delta is additive here: its extra$100 startup conversion minus25/26 months of extra$15 rent gives−$275/−$290 versus Cult.

All ordinary builds pay$13,000 rent through52; Lease builds pay$13,390. Every due is paid, maximum overdue balance is zero, and no borrowing, payroll, Store/research or campaign action occurs. The single declared first Contract pays$1,941.66 for4417 and$1,733.33 for1104, identical across same-seed builds. Total productive Feature spending is$5,140/$5,300 by seed; the fifth project's Design/Alpha continuation accounts for$590/$650 of that and is included at52. Seed1104's fifth Beta hand earns an additional$1,000 at53; it is excluded from both comparison columns. Game5 sales are unsettled at the ending Studio.

Credit at52 is627 for4417 except Lease-only624; all1104 builds reach630. The difference is a recorded month13 profit threshold:4417 control has+$12.02 operating profit and earns+3 credit, Lease alone has−$2.98 and earns0, while Cult+Lease has+$18.00 and earns+3. Thus the sampled combination shows no hidden arrears/blocker and offsets this one Lease-only credit shortfall. Minimum transaction cash ranges$740–$1,040; Cult+Buzz is lowest at$740 and Cult+Lease reaches$755. This does not prove safety for other policies or slower launches.

## Method and remaining limits

The unchanged simulator runner stops on a Studio release target, so the predeclared minimal fifth project returns every route to Studio53. The analysis takes the recorded50/52 boundaries; it neither estimates an absent boundary nor grants free waiting. Detached public per-title observation sidecars live under each private run profile and are hashed in the audit. Their sequence, cash and Fans match official telemetry; actual settlements reconcile with closed monthly finance rows, first-cycle integer revenue arithmetic, and final authoritative sale records. Standard replays independently reproduce authoritative states and official telemetry; they do not separately regenerate the policy-written sidecars.

Only Action/Fantasy, two seeds, one deterministic policy and two combinations were measured. Deliberately weak releases and minimal Game5 are test choices, not player-frequency estimates. The study ends before Game5 income settles and cannot establish long-run compounding, other Genres, alternate Store/Bank choices, human feel or final pricing. Existing20/1, Fanbase rates, Buzz, Family and Lease rules remain unchanged. The current bounded question is answered; commission a wider study only for a specific new question.

## Commands

Python: `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`; Godot: `C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe`.

Run `tools/simulate.py run --config docs/codex/findings/cult-post-adoption-v1/solo.json --output docs/codex/findings/cult-post-adoption-v1/solo-run --godot <above> --timeout 600`, then the analogous `interaction.json`/`interaction-run` command. Exact argument arrays are retained in the run bundles and [commands.json](commands.json). Four `simulate.py replay` calls use cases `post-4417-cult`, `post-1104-control`, `post-4417-cult-buzz`, `post-1104-cult-lease`, their corresponding source bundle, new `replay-*` outputs and `--timeout 300`. The read-only audit command is `python docs/codex/findings/cult-post-adoption-v1/audit.py solo interaction`; `finish.py` verifies four replay reports and final source consistency.
"""
(HERE/"FINDING.md").write_text(finding,encoding="utf-8")
(HERE/"HANDOFF.md").write_text("""# Cult20 post-adoption review handoff — 2026-10-11

**COMPLETE bounded READ-ONLY. No gameplay adoption delta or further implementation task.**

The approved version8 Cult20 trial passed the queued follow-up:14 fresh legal routes,1,554 commands, five releases each and actual Game4 settlement at common cycles50/52. All364 study-audit checks and four fresh-process replays (444 commands/448 telemetry samples) pass. Canonical source remains unchanged throughout this study.

[Finding, result table and limits](FINDING.md) · [Predeclared plan](PLAN.md) · [Source/replay proof](completion-audit.json) · [Detailed study audit](audit-solo-interaction.json).

Cult retained+$194.77/+4 Fans and+$173.77/+6 Fans versus same-seed controls at50. At52 the differences were+$208.74/+4 Fans and+$187.76/+5 Fans. Cult+Buzz/Cult+Lease had no arrears or blocked actions; the lowest observed cash was$740. One4417 Lease-only month missed a+3 profit-credit award, which Cult+Lease retained; this is bounded evidence, not a universal rescue promise.

Recommendation: retain the existing20-Fan/one-point ACTIVE/TRIAL rule. Mark this study's TODO item COMPLETE at the bounded scope. No new seed, trait price, Fanbase rate, UI change, commit, push or further broad grid is proposed. Human feel, wider Genres/policies, later settled Game5 and final balance remain OPEN. The implementation thread owns any shared-record reconciliation.
""",encoding="utf-8")
(HERE/"SESSION.md").write_text(f"""# Session — 2026-10-11

- Scope: approved post-adoption read-only Cult comparison, after root confirmed version8 creation and old-save acceptance.
- Branch/HEAD: dirty main `{provenance['git']['head']}`. Existing edits and `.codex-godot-temp` preserved. No canonical files, shared TODO/design/state records, commit, push or computer control.
- Files created only in this evidence folder: PLAN.md, policy.gd, prepare.py, solo.json, interaction.json, audit.py, finish.py, source/provenance manifests, audit reports, FINDING.md, HANDOFF.md, SESSION.md, two isolated run bundles and four isolated replay bundles.
- Exact commands/status/timing: commands.json and each bundle's *.command.json; source identity`{summary['source_identity']}`.
- Results:14/14 completed routes,1,554 commands,70 releases including14 minimal fifth projects;364 read-only audit checks;4/4 strict fresh-process replays,444 commands/448 telemetry samples. All{len(after)} canonical runtime files unchanged; predeclared plan and policy hashes unchanged. No rejected, incomplete, timed-out or rerolled cases.
- No blockers. Final balance, wider policy/Genre and human play feel remain OPEN. Shared TODO closeout belongs to root. Existing certificate-store environment diagnostics remain in original process logs and are excluded by the maintained runner's explicit filter.
""",encoding="utf-8")
for filename in ["FINDING.md","HANDOFF.md","SESSION.md"]:
    path=HERE/filename
    words=path.read_text(encoding="utf-8")
    # Repair prose spacing without touching commands or source identities.
    parts=words.split("`")
    for index in range(0,len(parts),2):
        part=re.sub(r"\b([A-Za-z]+)(?=[0-9])",r"\1 ",parts[index])
        part=re.sub(r"(?<=[A-Za-z])(?=\$|−\$|\+\$|\+[0-9])"," ",part)
        part=re.sub(r"([:;])(?=[0-9])",r"\1 ",part)
        parts[index]=re.sub(r"([A-Za-z]),(?=[0-9])",r"\1, ",part)
    path.write_text("`".join(parts),encoding="utf-8")
print(json.dumps({k:v for k,v in summary.items() if k!="replays"}))
