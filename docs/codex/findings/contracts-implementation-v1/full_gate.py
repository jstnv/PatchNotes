from run_checks import run, PROJECT, HERE
import json,sys
records=json.loads((HERE/"gate.json").read_text())["results"] if "--resume" in sys.argv else []
completed={r["name"] for r in records}
for path in sorted((PROJECT/"scripts/debug").glob("verify_*.gd")):
    if path.stem in completed: continue
    run(path.stem,["--script","res://scripts/debug/"+path.name])
    records.append(dict(name=path.stem,**json.loads((HERE/(path.stem+".command.json")).read_text())))
    (HERE/"gate.json").write_text(json.dumps(dict(results=records),indent=2))
print("ALL",len(records),"PASSED")
