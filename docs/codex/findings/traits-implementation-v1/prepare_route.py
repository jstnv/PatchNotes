from pathlib import Path
import hashlib,json,shutil,subprocess
HERE=Path(__file__).resolve().parent
REPO=HERE.parents[3];SOURCE=REPO/'patch-notes'
PROJECT=Path(r'C:\Users\64jus\Downloads\Patch Notes Design Folder\traits-route-20261007\patch-notes')
if PROJECT.exists():raise SystemExit('Existing capture preserved')
shutil.copytree(SOURCE,PROJECT,ignore=shutil.ignore_patterns('.godot','design-logs','.codex-godot-temp'))
p=PROJECT/'analysis/task32_routes_v1.gd';s=p.read_text(encoding='utf-8')
needle='menu.get_node("CenterContainer/MenuLayout/StudioSetup/EnterStudio").pressed.emit()'
s=s.replace(needle,needle+'\n\tfor id in [&"lean_production", &"studio_buzz", &"expensive_lease"]: menu.get("_trait_checks")[id].button_pressed=true\n\tmenu.call("_show_review")\n\tmenu.call("_confirm_studio")')
s=s.replace('range(1, 6)','range(1, 3)').replace('if number == 5: break','if number == 2: break').replace('five releases','two releases')
p.write_text(s,encoding='utf-8')
base=(SOURCE/'analysis/contract_synergy_first_capture_v1.gd').read_text(encoding='utf-8');a=base.index('func _production_hand(');b=base.index('\nfunc ',a+5);method=base[a:b]
method=method.replace('entry["cost_cents"] = run.primitive_feature_hand_cost_cents(selected)','entry["normal_cents"] = run.primitive_feature_hand_cost_cents(selected)\n\tentry["cost_cents"] = run.primitive_feature_hand_cost_cents(selected,project.get_release_id())')
script='extends "res://analysis/task32_routes_v1.gd"\nfunc _state_for(project: ProjectState, run: RunState) -> Dictionary:\n\tvar state := super._state_for(project,run)\n\tstate["traits"] = run.get_studio_traits()\n\tstate["lean_savings"] = run.get_lean_savings()\n\treturn state\n\n'+method
(PROJECT/'analysis/traits_native_route.gd').write_text(script,encoding='utf-8');(HERE/'route-adapter.gd').write_text(script,encoding='utf-8')
(PROJECT/'design-logs/task32-v1').mkdir(parents=True,exist_ok=True)
manifest={p.relative_to(SOURCE).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for directory in ['scripts','scenes','data'] for p in (SOURCE/directory).rglob('*') if p.is_file()}
(HERE/'route-source.json').write_text(json.dumps(dict(head=subprocess.check_output(['git','rev-parse','HEAD']).decode().strip(),files=manifest,project=str(PROJECT)),indent=2))
print(PROJECT)
