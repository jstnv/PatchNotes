from pathlib import Path
import subprocess,sys,json
out=Path(__file__).resolve().parent
results=[]
for name in ['verify_game_lifespan_sales','verify_monthly_sales_report','verify_lifespan_reporting_integrity','verify_studio_fanbase','verify_fanbase_incremental','verify_fanbase_checkpoint','verify_contract_challenge_publishers','verify_studio_roster_versions','verify_rival_synergy','verify_production_extraction','verify_primitive_review']:
    p=subprocess.run([sys.executable,str(out/'run.py'),'focused-'+name,'res://scripts/debug/'+name+'.gd'],capture_output=True,text=True)
    results.append({'name':name,'exit':p.returncode,'stdout':p.stdout,'stderr':p.stderr})
    (out/'focused-results.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
    print(name,p.returncode,flush=True)
