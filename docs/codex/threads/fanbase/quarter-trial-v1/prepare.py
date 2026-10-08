from pathlib import Path
import hashlib,io,json,shutil,subprocess,zipfile
HERE=Path(__file__).resolve().parent
WORK=Path(r'C:\Users\64jus\.codex\worktrees\fanbase-quarter\PatchNotes')
ROOT=Path(r'C:\Users\64jus\Downloads\Patch Notes Design Folder\fanbase-quarter-20261007')
PROJECT=ROOT/'patch-notes'
if PROJECT.exists(): raise SystemExit('Existing capture preserved')
ROOT.mkdir(parents=True,exist_ok=True)
archive=subprocess.check_output(['git','-c','safe.directory='+str(WORK),'archive','--format=zip','HEAD'],cwd=WORK)
zipfile.ZipFile(io.BytesIO(archive)).extractall(ROOT)
for name in ['scripts/fanbase/studio_fanbase.gd','scripts/debug/verify_studio_fanbase.gd']:
 shutil.copy2(WORK/'patch-notes'/name,PROJECT/name)
p=PROJECT/'analysis/task32_routes_v1.gd';s=p.read_text(encoding='utf-8');needle='menu.get_node("CenterContainer/MenuLayout/StudioSetup/EnterStudio").pressed.emit()';s=s.replace(needle,needle+'\n\tvar backgrounds: OptionButton = menu.get_node("CenterContainer/MenuLayout/StudioTraits/Background")\n\tbackgrounds.select(1)\n\tmenu.get_node("CenterContainer/MenuLayout/StudioTraits/ReviewChoices").pressed.emit()\n\tmenu.get_node("CenterContainer/MenuLayout/CreationReview/ConfirmStudio").pressed.emit()');p.write_text(s,encoding='utf-8')
p=PROJECT/'analysis/task29_routes_v1.gd';s=p.read_text(encoding='utf-8');needle='var budgets := [3, 4, 4] if release_band == "early" else [5, 6, 6]';s=s.replace(needle,needle+'\n\tif number == 3 and _arg("--weak=", "none") != "none":\n\t\tbudgets = [1,0,0] if _arg("--weak=", "none") == "restrained" else [2,1,0]');p.write_text(s,encoding='utf-8')
(PROJECT/'analysis/fanbase_quarter_capture.gd').write_text('extends "res://analysis/task32_routes_v1.gd"\n\nfunc _state_for(project: ProjectState, run: RunState) -> Dictionary:\n\tvar state := super._state_for(project, run)\n\tstate["fans"] = run.get_fans()\n\tstate["fan_history"] = run.get_fanbase_history()\n\tstate["fan_snapshot"] = run.get_fanbase_snapshot()\n\treturn state\n',encoding='utf-8')
(PROJECT/'design-logs/task32-v1').mkdir(parents=True,exist_ok=True)
manifest={str(p.relative_to(PROJECT)):hashlib.sha256(p.read_bytes()).hexdigest() for folder in ['scripts','scenes','data','analysis'] for p in (PROJECT/folder).rglob('*') if p.is_file()}
(HERE/'source.json').write_text(json.dumps(dict(head=subprocess.check_output(['git','-c','safe.directory='+str(WORK),'rev-parse','HEAD'],cwd=WORK).decode().strip(),branch='codex/fanbase-quarter-trial',project=str(PROJECT),archive_sha256=hashlib.sha256(archive).hexdigest(),files=manifest),indent=2))
print(PROJECT)
