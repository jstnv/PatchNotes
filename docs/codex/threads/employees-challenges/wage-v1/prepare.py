from pathlib import Path
import hashlib,json,shutil,subprocess
HERE=Path(__file__).resolve().parent;REPO=HERE.parents[4];SOURCE=REPO/'patch-notes'
PROJECT=Path(r'C:\Users\64jus\Downloads\Patch Notes Design Folder\employees-wage-20261007\patch-notes')
if PROJECT.exists():raise SystemExit('Existing snapshot preserved')
shutil.copytree(SOURCE,PROJECT,ignore=shutil.ignore_patterns('.godot','design-logs','.codex-godot-temp'))
manifest={p.relative_to(SOURCE).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for folder in ['scripts','scenes','data'] for p in (SOURCE/folder).rglob('*') if p.is_file()}
p=PROJECT/'scripts/finance/studio_finance_ledger.gd';s=p.read_text(encoding='utf-8');assert '"wage_cents":1000' in s;s=s.replace('"wage_cents":1000','"wage_cents":int(OS.get_environment("WAGE_CENTS"))');p.write_text(s,encoding='utf-8',newline='\n')
p=PROJECT/'analysis/task32_routes_v1.gd';s=p.read_text(encoding='utf-8');needle='menu.get_node("CenterContainer/MenuLayout/StudioSetup/EnterStudio").pressed.emit()';s=s.replace(needle,needle+'\n\tif OS.get_environment("STARTUP") == "legacy":\n\t\tgame.run_state.set_studio_name("Legacy wage",specialty_id)\n\t\tgame._enter_initial_studio()\n\telse:\n\t\tif OS.get_environment("STRATUM") == "lease": menu.get("_trait_checks")[&"expensive_lease"].button_pressed=true\n\t\tmenu._show_review()\n\t\tmenu._confirm_studio()');s=s.replace('range(1, 6)','range(1, 4)').replace('if number == 5: break','if number == 3: break').replace('"five releases"','"three releases"');a=s.index('\tvar path :=');b=s.index('\n',a);s=s[:a]+'\tvar path := OS.get_environment("OUTPUT_JSON")'+s[b:];p.write_text(s,encoding='utf-8',newline='\n')
p=PROJECT/'analysis/task29_routes_v1.gd';s=p.read_text(encoding='utf-8').replace('var budgets := [3, 4, 4] if release_band == "early" else [5, 6, 6]','var budgets := [3,4,4] if release_band == "early" else ([7,7,7] if release_band == "stress" else [5,6,6])');s=s.replace('_curtail(game, out, label, hand)\n\t\t\t\tcurtailed = true\n\t\t\t\tbreak','_stop(game,out,label,"first rejected productive hand; censored")\n\t\t\t\treturn false').replace('_curtail(game, out, "beta", hand)\n\t\t\tcurtailed = true\n\t\t\tbreak','_stop(game,out,"beta","first rejected productive hand; censored")\n\t\t\treturn false');p.write_text(s,encoding='utf-8',newline='\n')
script=(HERE/'route.gd').read_text(encoding='utf-8');(PROJECT/'analysis/wage_route.gd').write_text(script,encoding='utf-8',newline='\n')
for saved in (HERE/'harness').glob('*.gd'):shutil.copy2(saved,PROJECT/'analysis'/saved.name)
changes={p.relative_to(PROJECT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for folder in ['scripts','scenes','data'] for p in (PROJECT/folder).rglob('*') if p.is_file()}
(HERE/'source.json').write_text(json.dumps(dict(head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=REPO).decode().strip(),project=str(PROJECT),main=manifest,isolated=changes),indent=2))
print(PROJECT)
