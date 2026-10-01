"""Focused current-source calendar-era evidence checks; no runtime writes."""
import hashlib,json,subprocess
import tutorial_task17_verify_v1 as v
v.OUT=v.ROOT/'design-logs/task24-v1'
results=[v.run('editor-import',v.ROOT,['--editor','--import'])]
for name in ['sidestreet_scope_and_year','sidestreet_contract','run_calendar_and_studio_entry',
             'first_game_scripted_tutorial','feature_store_cycle_purchase','feature_store',
             'primitive_run_initialization','main_menu_history','sales_earning_and_settlement']:
    results.append(v.run('verify_'+name,v.ROOT,['--script','res://scripts/debug/verify_'+name+'.gd']))
before=json.loads((v.OUT/'source-before.json').read_text())
after={str(p.relative_to(v.ROOT)):hashlib.sha256(p.read_bytes()).hexdigest()
       for f in ['scripts','scenes','data'] for p in (v.ROOT/f).rglob('*') if p.is_file()}
diff=subprocess.run(['git','diff','--check'],cwd=v.ROOT,capture_output=True)
(v.OUT/'diff-check.log').write_bytes(diff.stdout+diff.stderr)
report=dict(results=results,source_unchanged=before==after,source_file_count=len(before),
            changed_source_files=[p for p in before.keys()|after.keys() if before.get(p)!=after.get(p)],
            diff_check=diff.returncode,head=v.git('rev-parse','HEAD').decode().strip(),
            origin_tracking=v.git('rev-parse','origin/main').decode().strip())
(v.OUT/'verification-focused.json').write_text(json.dumps(report,indent=2))
assert report['source_unchanged'] and diff.returncode==0
assert all(r['exit']==0 and not r['errors'] for r in results)
print('PASS focused import + nine suites, source unchanged, diff check')
