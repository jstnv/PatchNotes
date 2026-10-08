from pathlib import Path
import hashlib,json,shutil,subprocess
HERE=Path(__file__).resolve().parent
REPO=HERE.parents[3]
SOURCE=REPO/'patch-notes'
ROOT=Path(r'C:\Users\64jus\Downloads\Patch Notes Design Folder\employee-route-20261007')
PROJECT=ROOT/'patch-notes'
if PROJECT.exists():raise SystemExit('Capture already exists; preserved')
shutil.copytree(SOURCE,PROJECT,ignore=shutil.ignore_patterns('.godot','design-logs','.codex-godot-temp'))
p=PROJECT/'analysis/task32_routes_v1.gd';s=p.read_text(encoding='utf-8');needle='menu.get_node("CenterContainer/MenuLayout/StudioSetup/EnterStudio").pressed.emit()';s=s.replace(needle,needle+'\n\tvar backgrounds: OptionButton = menu.get_node("CenterContainer/MenuLayout/StudioTraits/Background")\n\tbackgrounds.select(1)\n\tmenu.get_node("CenterContainer/MenuLayout/StudioTraits/ReviewChoices").pressed.emit()\n\tmenu.get_node("CenterContainer/MenuLayout/CreationReview/ConfirmStudio").pressed.emit()');s=s.replace('range(1, 6)','range(1, 4)').replace('if number == 5: break','if number == 3: break');needle='_visit(game, out, "committed release")';s=s.replace(needle,needle+"\n\t\tif number == 1:\n\t\t\tvar before_hire := _state(game)\n\t\t\tvar studio: StudioPhase = game.get(\"_active_phase\")\n\t\t\tstudio._open_employees()\n\t\t\tvar offered := studio._employees_panel.quote.duplicate(true)\n\t\t\tstudio._employees_panel.hide()\n\t\t\tstudio._employees_panel.confirmed.emit()\n\t\t\tvar hired: bool = not run.get_employees().employees.is_empty()\n\t\t\tout.actions.append({\"phase\":\"hire\",\"game\":1,\"quote\":offered,\"success\":hired,\"before\":before_hire,\"after\":_state(game)})\n\t\t\tif not hired: _stop(game,out,\"hire\",\"hire rejected\");break")
p.write_text(s,encoding='utf-8')
base=(SOURCE/'analysis/contract_synergy_first_capture_v1.gd').read_text(encoding='utf-8');start=base.index('func _production_hand(');end=base.index('\nfunc ',start+5);method=base[start:end]
needle='if label == "design": phase.call("_on_play_card_pressed")\n\telse: phase.call("_on_play_alpha_hand_pressed")'
replacement='var employee: Dictionary = phase.get_employee_hand_status()\n\tvar proposal: Dictionary = phase.get_priority_distribution().duplicate()\n\tproposal[0] += 5\n\tproposal[3] -= 5\n\tif employee.available and employee.qualifying and PriorityAllocation.is_valid_distribution(proposal):\n\t\tentry["employee_plan"] = proposal.duplicate()\n\t\tentry["employee_plan_success"] = phase.play_hand_with_employee_plan(proposal)\n\telse:\n\t\tif label == "design": phase.call("_on_play_card_pressed")\n\t\telse: phase.call("_on_play_alpha_hand_pressed")'
if needle not in method:raise RuntimeError('Hand adapter source changed')
method=method.replace(needle,replacement)
script='extends "res://analysis/task32_routes_v1.gd"\n\nfunc _state_for(project: ProjectState, run: RunState) -> Dictionary:\n\tvar state := super._state_for(project,run)\n\tstate["employees"] = run.get_employees()\n\treturn state\n\n'+method
(PROJECT/'analysis/employee_native_route.gd').write_text(script,encoding='utf-8')
(HERE/'route-adapter.gd').write_text(script,encoding='utf-8')
(PROJECT/'design-logs/task32-v1').mkdir(parents=True,exist_ok=True)
manifest={p.relative_to(SOURCE).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for directory in ['scripts','scenes','data'] for p in (SOURCE/directory).rglob('*') if p.is_file()}
(HERE/'route-source.json').write_text(json.dumps(dict(head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=REPO).decode().strip(),files=manifest,project=str(PROJECT)),indent=2))
print(PROJECT)
