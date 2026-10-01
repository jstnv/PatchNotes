"""Import and verify the current specialty implementation with fresh profiles."""
import concurrent.futures,json,sys
import tutorial_task17_verify_v1 as v
v.OUT=v.ROOT/'design-logs/task25-v1'
results=[v.run('import',v.ROOT,['--editor','--import'])]
if results[0]['exit']==0 and not results[0]['errors']:
    names=list((v.ROOT/'scripts/debug').glob('verify_*.gd')) if '--full' in sys.argv else [v.ROOT/'scripts/debug'/('verify_'+n+'.gd') for n in ['studio_specialties','first_studio_feature_economy','first_game_and_tips','main_menu_history','feature_store_navigation']]
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        results+=list(pool.map(lambda p:v.run(p.stem,v.ROOT,['--script','res://scripts/debug/'+p.name],90),names))
(v.OUT/('full-verification.json' if '--full' in sys.argv else 'verification.json')).write_text(json.dumps(results,indent=2))
assert all(r['exit']==0 and not r['errors'] for r in results)
