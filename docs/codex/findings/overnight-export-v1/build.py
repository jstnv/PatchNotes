from pathlib import Path
import importlib.util
root=Path.cwd()
spec=importlib.util.spec_from_file_location('exporter',root/'docs/codex/findings/export-queue-v3/export.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
m.OUT=root/'docs/codex/findings/overnight-export-v1'
m.main()
