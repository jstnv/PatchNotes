from pathlib import Path
import importlib.util, shutil, runpy

BASE=Path(__file__).resolve().parent
helper=BASE/'snapshot/docs/codex/findings/export-queue-v3/export.py'
spec=importlib.util.spec_from_file_location('acceptance_export',helper)
module=importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
module.OUT=BASE/'delivery'
module.main()
shutil.copy2(BASE/'snapshot/docs/codex/findings/export-queue-v3/inspect.py',module.OUT/'inspect.py')
runpy.run_path(str(module.OUT/'inspect.py'),run_name='__main__')
