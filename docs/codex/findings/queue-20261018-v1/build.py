from pathlib import Path
import importlib.util,sys,shutil,subprocess
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[3]
stage=OUT/sys.argv[1];stage.mkdir();sys.argv=sys.argv[:1]
s=importlib.util.spec_from_file_location('exporter',ROOT/'docs/codex/findings/export-queue-v3/export.py');m=importlib.util.module_from_spec(s);s.loader.exec_module(m);m.OUT=stage;m.main()
shutil.copy2(ROOT/'docs/codex/findings/export-queue-v3/inspect.py',stage/'inspect.py')
subprocess.run([sys.executable,str(stage/'inspect.py')],check=True)
