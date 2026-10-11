"""Read retained campaign evidence; do not alter gameplay or run artifacts."""
from pathlib import Path
from collections import Counter
import hashlib
import json
import sys

HERE = Path(__file__).resolve().parent
MECHANICS = "62cfd4f1686a6cc6302616d98aab421f2db511971fc5655cf5b6d9e743f612c4"
EXPECTED_START = {"control":570000,"cult":565000,"buzz":565000,"family":590000,"cult-buzz":560000,"cult-lease":575000,"lease":580000}

def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))

def normalize(value, studio):
    if isinstance(value,str):
        return value.replace(studio,"STUDIO")
    if isinstance(value,list):
        return [normalize(x,studio) for x in value]
    if isinstance(value,dict):
        return {normalize(k,studio):normalize(v,studio) for k,v in value.items()}
    return value

def audit(gates):
    checks=[]
    cases={}
    bundles={}
    def check(condition,label):
        checks.append({"ok":bool(condition),"label":label})
    for gate in gates:
        bundle = HERE / (gate+"-run")
        report = read(bundle/"run-report.json")
        bundles[gate] = {"ok":report["ok"],"frozen_source_identity":report.get("frozen_source_identity"),"runner_sha256":report.get("runner_sha256"),"results":report.get("results",[])}
        check(report["ok"],gate+" runner completed")
        check(read(bundle/"workspace-source-manifest.json")==read(HERE/"source-before.json"),gate+" canonical snapshot matches predeclared source")
        for directory in sorted((bundle/"cases").iterdir()):
            if not (directory/"result.json").exists():
                check(False,str(directory)+" result missing")
                continue
            result=read(directory/"result.json")
            telemetry=read(directory/"telemetry.json")
            recipe=read(directory/"case.json")["initial"]["recipe"]
            case_id=result["case_id"]
            seed,arm=case_id.removeprefix("post-").split("-",1)
            samples=telemetry["samples"]
            captures=list((bundle/"profile").rglob("cult-post-observations-"+case_id+".json"))
            check(len(captures)==1,case_id+" unique detached observations")
            if len(captures)!=1: continue
            measured=read(captures[0])["observations"]
            by_sequence={int(s["sequence"]):s for s in samples}
            check(all(int(m["sequence"]) in by_sequence and all(int(m[k])==int(by_sequence[int(m["sequence"])][k]) for k in ["run_cycle","cash_cents","fans"]) for m in measured),case_id+" detached observation alignment")
            check(result["ok"] and result["status"]=="completed",case_id+" completed")
            check(result["source_identity"]==MECHANICS,case_id+" mechanics source")
            check(result["commands"]<=140 and result["final_release_count"]==5 and result["final_run_cycle"]==53,case_id+" bounds and final Studio horizon")
            check(result["outcome"]["in_studio"],case_id+" Studio-only ending checkpoint")
            check(int(samples[0]["cash_cents"])==EXPECTED_START[arm] and int(samples[0]["fans"])==(20 if "cult" in arm else 0),case_id+" genuine trait start")
            check(recipe["specialty"]=="action" and recipe["seed"]==seed,case_id+" recipe")
            check(len(samples)==result["commands"]+1 and all(s["accepted"] is not False for s in samples),case_id+" command telemetry coverage")
            outcome=result["outcome"]
            finance=outcome["finance"]
            rows=finance["rows"]
            rent=51500 if "lease" in arm else 50000
            check(finance["available"] and finance["monthly_rent_cents"]==rent,case_id+" active rent rate")
            check(sum(r["rent_due_cents"] for r in rows)==rent*26 and sum(r["rent_paid_cents"] for r in rows)==rent*26,case_id+" actual rent through cycle52")
            check(all(r["bank_loans"]==[] for r in [finance]) and sum(r["store_cents"]+r["campaign_cents"]+r["payroll_due_cents"] for r in rows)==0,case_id+" no undeclared economic actions")
            boundary={}
            for cycle in [49,50,52]:
                observations=[m for m in measured if m["run_cycle"]==cycle and len(m["releases"])>=4]
                check(bool(observations),case_id+" boundary "+str(cycle))
                if not observations: continue
                m=observations[-1]
                fourth=m["releases"][3]
                boundary[str(cycle)]={"sequence":m["sequence"],"cash_cents":m["cash_cents"],"fans":m["fans"],"game4_sales":fourth["sales"],"game4_review":fourth["metadata"]["review"],"portfolio_settled_cents":sum(r["sales"]["settled_cents"] for r in m["releases"]),"portfolio_entitlement_cents":sum(r["sales"]["entitlement_cents"] for r in m["releases"])}
                if cycle==49: check(fourth["sales"]["settled_cents"]==0,case_id+" fourth launch remains unsettled")
                else: check(fourth["sales"]["settled_cents"]>0 and fourth["sales"]["last_settlement_run_cycle"]==cycle,case_id+" actual fourth-game settlement at "+str(cycle))
                if cycle in [50,52]:
                    earned_rows=[row for row in rows if row["month"]<=cycle//2]
                    check(boundary[str(cycle)]["portfolio_settled_cents"]==sum(row["sales_settled_cents"] for row in earned_rows) and earned_rows[-1]["closing_cash_cents"]==m["cash_cents"],case_id+" detached settlements reconcile with monthly cash ledger at "+str(cycle))
                    history=[entry for entry in finance["credit"]["history"] if entry["cycle"]<=cycle]
                    boundary[str(cycle)]["credit_score"]=history[-1]["after"]
                if cycle==50:
                    actual=fourth["sales"]
                    check(actual["total_earned_cycles"]==1 and actual["earned_units"]==actual["total_units"]//2 and actual["settled_cents"]==(actual["total_units"]//2)*999*70//100,case_id+" independently reconcile Game4 first-cycle actual settlement")
                if cycle==52:
                    check(fourth["sales"]["settled_cents"]==outcome["releases"][3]["sales"]["settled_cents"],case_id+" supplemental settlement retained in final authoritative outcome")
            launches=[s for s in samples if s["command_type"]=="launch"]
            reviews=[s["releases"][-1]["review"] for s in launches]
            check(len(reviews)==5 and reviews[0]>5 and reviews[1]<5 and reviews[2]>5,case_id+" strong weak recovery qualification")
            check([s["run_cycle"] for s in launches]==[18,24,42,49,53],case_id+" declared calendar")
            minimum=min(int(s["transaction_cash_low_cents"]) for s in samples)
            cases[case_id]={"seed":int(seed),"arm":arm,"status":result["status"],"commands":result["commands"],"source_identity":result["source_identity"],"initial_rng":result["initial_rng"],"final_rng":result["final_rng"],"start_cash_cents":int(samples[0]["cash_cents"]),"final_cash_cents":outcome["cash_cents"],"final_fans":outcome["fans"],"minimum_transaction_cash_cents":minimum,"maximum_overdue_cents":max(int(s["overdue_cents"]) for s in samples),"final_credit":finance["credit"],"finance_rows":rows,"boundaries":boundary,"reviews":reviews,"launch_fans":[r["metadata"]["review"]["launch_fans"] for r in outcome["releases"]],"launch_awareness":[r["metadata"]["review"]["fan_awareness"] for r in outcome["releases"]],"final_release_sales":[r["sales"] for r in outcome["releases"]],"request_signature":normalize([s["request"] for s in samples],case_id),"command_counts":dict(Counter(s["command_type"] for s in samples)),"detached_observations_path":str(captures[0].relative_to(HERE)),"detached_observations_sha256":hashlib.sha256(captures[0].read_bytes()).hexdigest()}
    comparisons=[]
    for seed in [4417,1104]:
        base=cases.get(f"post-{seed}-control")
        if base is None: continue
        for case_id,item in cases.items():
            if item["seed"]!=seed or item is base: continue
            same_actions=item["request_signature"]==base["request_signature"]
            same_rng=item["initial_rng"]==base["initial_rng"] and item["final_rng"]==base["final_rng"]
            check(same_actions,case_id+" normalized actions versus control")
            check(same_rng,case_id+" initial and final RNG versus control")
            comparisons.append({"case":case_id,"control":f"post-{seed}-control","same_normalized_actions":same_actions,"same_initial_final_rng":same_rng,"primary_cash_delta_cents":item["boundaries"]["50"]["cash_cents"]-base["boundaries"]["50"]["cash_cents"],"primary_fan_delta":item["boundaries"]["50"]["fans"]-base["boundaries"]["50"]["fans"],"primary_game4_settled_delta_cents":item["boundaries"]["50"]["game4_sales"]["settled_cents"]-base["boundaries"]["50"]["game4_sales"]["settled_cents"],"final_cash_delta_cents":item["final_cash_cents"]-base["final_cash_cents"]})
    for item in cases.values():
        del item["request_signature"]
    return {"ok":all(x["ok"] for x in checks),"checks":len(checks),"failures":[x for x in checks if not x["ok"]],"bundles":bundles,"cases":cases,"comparisons":comparisons,"all_checks":checks}

if __name__=="__main__":
    gates=sys.argv[1:] or ["solo","interaction"]
    report=audit(gates)
    path=HERE/("audit-"+"-".join(gates)+".json")
    path.write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"ok":report["ok"],"checks":report["checks"],"failures":report["failures"],"cases":len(report["cases"]),"path":str(path)}))
