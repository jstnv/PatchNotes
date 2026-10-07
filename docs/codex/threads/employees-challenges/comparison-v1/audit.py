from pathlib import Path
import subprocess,hashlib,json,gzip,datetime

HERE=Path(__file__).resolve().parent
REPO=HERE.parents[4]
SNAPSHOT=Path(r'C:\Users\64jus\Downloads\Patch Notes Design Folder\employees-comparison-20261006/patch-notes')
paths=['scripts/run_state.gd','scripts/project_state.gd','scripts/phases/design_phase.gd','scripts/phases/alpha_phase.gd','scripts/phases/beta_phase.gd',
       'scripts/finance/studio_finance_ledger.gd','scripts/finance/outstanding_expenses.gd','scripts/sales/released_game_sales.gd',
       'analysis/b1_banking_route_v1.gd','analysis/lifespan_verify_routes_v2.gd','analysis/task27_routes_v1.gd','analysis/task24_current_v2.gd',
       'analysis/task24_normal_v1.gd','analysis/task21_route_v1.gd','analysis/task17_strong_route_v1.gd','analysis/contract_synergy_first_capture_v1.gd','analysis/task18_curated_trial_v1.gd']
source=[]
for relative in paths:
    path=SNAPSHOT/relative; checkout=REPO/'patch-notes'/relative
    data=path.read_bytes(); current=checkout.read_bytes()
    source.append(dict(path='patch-notes/'+relative,archive_sha256=hashlib.sha256(data).hexdigest(),checkout_sha256=hashlib.sha256(current).hexdigest(),
                       source_equal_ignoring_line_endings=data.replace(b'\r\n',b'\n')==current.replace(b'\r\n',b'\n')))
assert all(r['source_equal_ignoring_line_endings'] for r in source)
def git(*args): return subprocess.check_output(['git',*args],cwd=REPO,text=True).strip()
runtime_diff=git('diff','--name-only','--','patch-notes')
assert runtime_diff=='',runtime_diff
assert git('rev-parse','HEAD')=='553d1a46f33d59641efa4c2e4ff141f958c1230d'
primary=json.loads((HERE/'run-index.json').read_text())
assert len(primary)==76 and all(r['exit']==0 and r['valid'] for r in primary)
finance=json.loads((HERE/'finance-summary.json').read_text())
assert finance['arms']==56832 and len(finance['native_validation'])==46
assert all(v['valid'] and v['monthly_exact'] for v in finance['native_validation'])
assert not json.loads((HERE/'reward-summary.json').read_text())['errors']
assert json.loads((HERE/'native-bill-protocol.json').read_text())['failures']==[]
assert json.loads((HERE/'employee-model-results.json').read_text())['checks']==36
for name in ['optional-run-index','after-hire-run-index']:
    rows=json.loads((HERE/f'{name}.json').read_text()); assert len(rows)==4 and all(r['valid'] and r['exit']==0 for r in rows)
assessment=json.loads((HERE/'assessment.json').read_text())
assert len(assessment['narrow_after_hire'])==96
assert len(assessment['after_hire_native_validation'])==4 and all(r['valid'] for r in assessment['after_hire_native_validation'])
for case in assessment['narrow_after_hire']:
    assert isinstance(case['final']['cash'],int) and case['final']['cash']>=0
assert all(not r['script_errors'] and not r['other_errors'] for r in assessment['log_scan'])
assert len(assessment['log_scan'])==84
files=[]
for path in sorted(HERE.iterdir()):
    if path.is_file() and path.suffix in ['.gd','.py','.gz','.json'] and path.name not in ['audit-results.json','source-hashes.json']:
        files.append(dict(file=path.name,bytes=path.stat().st_size,sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
(HERE/'source-hashes.json').write_text(json.dumps(source,indent=2))
out=dict(date_local=datetime.datetime.now().astimezone().isoformat(),branch=git('branch','--show-current'),head=git('rev-parse','HEAD'),runtime_diff=runtime_diff,
         tracked_docs_diff=git('diff','--name-only','--','docs/codex'),checks=dict(primary_native_routes=76,optional_routes=4,post_hire_routes=4,final_route_logs_scanned=84,
         exact_native_finance_reconciliations=50,primary_financial_arms=56832,post_hire_financial_arms=96,native_earning_steps=2478+204,native_bill_protocol=46,constructed_employee_model=36),artifacts=files)
(HERE/'audit-results.json').write_text(json.dumps(out,indent=2))
print(json.dumps(out['checks'],indent=2)); print('Pinned source unchanged; audit passed.')

if __name__=='__main__': pass
