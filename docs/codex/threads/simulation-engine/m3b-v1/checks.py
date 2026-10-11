from pathlib import Path
import importlib.util,json,os,sys
ROOT=Path(__file__).resolve().parents[5]
HERE=Path(__file__).resolve().parent
GATE=ROOT/'docs/codex/findings/card-presentation-v2'
spec=importlib.util.spec_from_file_location('focused',GATE/'run.py')
focused=importlib.util.module_from_spec(spec);spec.loader.exec_module(focused)
prefix=sys.argv[1]
suites=['verify_contract_extraction','verify_campaign_continuation','verify_campaign_session',
 'verify_balanced_primitive_contract','verify_sidestreet_contract','verify_starwave',
 'verify_publisher_trial_offers','verify_publisher_trial_cash','verify_publisher_trial_promotion',
 'verify_candidate_retention','verify_shared_redraw_and_priority_adjustment','verify_studio_finance_ledger',
 'verify_bank_integration','verify_education_atomicity','verify_education_edges',
 'verify_employees','verify_employee_hands','verify_studio_checkpoint','verify_checkpoint_rng',
 'verify_checkpoint_runtime','verify_development_protocol','verify_development_replay']
reports=[]
for suite in suites:
    label=prefix+'-'+suite.removeprefix('verify_').replace('_','-')
    focused.run(label,suite+'.gd')
    reports.append({'suite':suite,'evidence':str((GATE/label).relative_to(ROOT))})
# Six independent processes decode disk Studio envelopes and replay suffix tapes.
base=GATE/(prefix+'-contract-extraction')
inputs=list(base.glob('*.checkpoint.json'))+[GATE/(prefix+'-campaign-continuation')/'fit.json.checkpoint.json']
assert len(inputs)==6,inputs
for index,checkpoint in enumerate(inputs):
    tape=checkpoint.with_name(checkpoint.name.replace('.checkpoint.json','.tape.json'))
    os.environ['PN_CAMPAIGN_CHECKPOINT']=str(checkpoint)
    os.environ['PN_CAMPAIGN_TAPE']=str(tape)
    label=prefix+'-fresh-'+str(index)
    focused.run(label,'campaign_replay_cli.gd')
    result=json.loads((GATE/label/'fit.json').read_text())
    assert result['ok'],result
    reports.append({'suite':'fresh_checkpoint_replay','checkpoint':str(checkpoint.relative_to(ROOT)),
                    'steps':len(result['steps']),'final_state':result['final_state'],'evidence':str((GATE/label).relative_to(ROOT))})
(HERE/(prefix+'-checks.json')).write_text(json.dumps(reports,indent=2),encoding='utf-8')
print('ALL PASSED:',len(reports),flush=True)
