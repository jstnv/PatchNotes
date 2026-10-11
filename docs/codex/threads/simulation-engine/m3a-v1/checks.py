from pathlib import Path
import importlib.util,json,os,sys
ROOT=Path(__file__).resolve().parents[5]
HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('runner',ROOT/'docs/codex/findings/card-presentation-v2/run.py')
runner=importlib.util.module_from_spec(spec);spec.loader.exec_module(runner)
scripts=['verify_launch_extraction','verify_begin_project_extraction','verify_campaign_session',
'verify_predevelopment','verify_beta_finalization_and_launch','verify_primitive_review','verify_primitive_awareness',
'verify_primitive_launch_market_context','verify_primitive_units_sold','verify_primitive_month_one_sales_revenue',
'verify_sales_earning_and_settlement','verify_game_lifespan_sales','verify_publisher_trial_promotion',
'verify_feature_research','verify_first_studio_feature_economy','verify_studio_checkpoint','verify_checkpoint_rng',
'verify_development_replay','verify_development_protocol']
results=[]
prefix=sys.argv[1] if len(sys.argv)>1 else 'm3a-final'
for script in scripts:
    label=prefix+'-'+script
    try:
        runner.run(label,script+'.gd')
        results.append({'script':script,'label':label,'passed':True})
    except (SystemExit,Exception) as error:
        results.append({'script':script,'label':label,'passed':False,'error':str(error)})
    (HERE/'check-results.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
if not all(row['passed'] for row in results): sys.exit(1)
protocol=ROOT/('docs/codex/findings/card-presentation-v2/'+prefix+'-verify_campaign_session/fit.json')
os.environ['PN_CAMPAIGN_RECIPE']=str(protocol)+'.recipe.json'
os.environ['PN_CAMPAIGN_TAPE']=str(protocol)+'.tape.json'
runner.run(prefix+'-cli','campaign_replay_cli.gd')
