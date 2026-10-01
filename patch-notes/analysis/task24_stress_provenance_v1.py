"""Preserve the pre-progress harness loaded by the long-running Godot process."""
from pathlib import Path
import difflib,hashlib,json
root=Path(__file__).resolve().parents[1]
out=root/'design-logs/task24-v1'
current=(root/'analysis/task24_stress_v1.gd').read_text(encoding='utf-8')
name_new='\tvar tag := _arg("--tag=", "")\n\tvar file := FileAccess.open("res://design-logs/task24-v1/stress_" + stress_arm + ("_" + tag if not tag.is_empty() else "") + ".json", FileAccess.WRITE)'
name_old='\tvar file := FileAccess.open("res://design-logs/task24-v1/stress_" + stress_arm + ".json", FileAccess.WRITE)'
progress_new='''\t\tif number % 50 == 0:
\t\t\tprint("STRESS progress ", stress_arm, " cycle=", run.get_completed_run_cycles(), " releases=", number - 1)
\t\t\tvar partial := FileAccess.open("res://design-logs/task24-v1/stress_" + stress_arm + "_progress_" + _arg("--tag=", "main") + ".json", FileAccess.WRITE)
\t\t\tpartial.store_string(JSON.stringify({"arm": stress_arm, "completed_checkpoint_only": true, "cycles": stress_cycles, "releases": out.releases, "studio_visits": out.studios}, "  "))
\t\t\tpartial.close()'''
progress_old='\t\tif number % 50 == 0: print("STRESS progress ", stress_arm, " cycle=", run.get_completed_run_cycles(), " releases=", number - 1)'
assert current.count(name_new)==current.count(progress_new)==1
loaded=current.replace(name_new,name_old).replace(progress_new,progress_old)
(out/'stress-harness-loaded-long.gd.txt').write_text(loaded,encoding='utf-8',newline='\n')
(out/'stress-harness-progress-revision.gd.txt').write_text(current,encoding='utf-8',newline='\n')
(out/'stress-harness-progress-only.diff').write_text(''.join(difflib.unified_diff(loaded.splitlines(True),current.splitlines(True),fromfile='loaded-long',tofile='progress-revision')),encoding='utf-8')
sha=lambda t:hashlib.sha256(t.encode('utf-8')).hexdigest()
sources={str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [root/'analysis/task21_route_v1.gd',root/'analysis/task17_strong_route_v1.gd',root/'analysis/contract_synergy_first_capture_v1.gd']}
report={'reconstruction':'Exact inverse of the two instrumentation-only edits applied while the native long process was running. The diff records filename tagging and periodic progress saving; no action or policy changed.',
        'loaded_long_sha256':sha(loaded),'progress_revision_sha256':sha(current),'dependencies':sources,
        'commands':{'stress-priority':'stress-harness-loaded-long.gd.txt','stress-empty':'stress-harness-loaded-long.gd.txt','stress-empty-checkpoint240':'stress-harness-progress-revision.gd.txt','stress-repeat':'stress-harness-progress-revision.gd.txt','stress-repeat-independent':'stress-harness-progress-revision.gd.txt','stress-repeat-checkpoint96':'stress-harness-progress-revision.gd.txt'}}
(out/'stress-harness-provenance.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
