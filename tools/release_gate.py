"""One-command local release checks; exit 2 means human acceptance remains.

python tools/release_gate.py --godot PATH [--output PATH]
No source edits, downloading, publishing, or user-save access. Each run retains
fresh evidence. Interactive and audible acceptance are never inferred from CI.
"""
from pathlib import Path
import argparse,hashlib,importlib.util,json,os,runpy,shutil,socket,subprocess,sys,tempfile,datetime

REPO=Path(__file__).resolve().parents[1]
def load(name,path):
 spec=importlib.util.spec_from_file_location(name,path);module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def main():
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--godot',required=True,type=Path)
 parser.add_argument('--output',type=Path)
 parser.add_argument('--resume',action='store_true',help='Resume an interrupted gate only when every source hash still matches')
 args=parser.parse_args()
 out=(args.output or REPO/'docs/codex/findings'/('release-gate-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))).resolve()
 out.mkdir(parents=True,exist_ok=args.resume)
 (out/'.gdignore').touch()
 report=json.loads((out/'gate-result.json').read_text()) if args.resume else {'source_head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=REPO,text=True).strip(),'output':str(out),'automated_pass':False,'release_ready':False,'remaining':['Exported legal Bank/exit/Continue/installment/payoff/two-game interaction','Approved asset/license set and audible music/SFX acceptance'],'checks':[]}
 if args.resume:report['previous_failure']=report.pop('failure',None)
 # This existing verifier override isolates its writer from a running game.
 os.environ['PN_CHECKPOINT_TEST_PORT']='47733';report['test_writer_port']=47733
 def record(): (out/'gate-result.json').write_text(json.dumps(report,indent=2))
 record()
 try:
  # Several scene-input suites create actual Studio coordinators. A running
  # game's global writer would open failure modals and invalidate those tests.
  with socket.socket() as probe:
   try:probe.bind(('127.0.0.1',62741))
   except OSError:
    report['blocked']='Close the running game before this serial release gate; its Studio writer is active.';record();print(report['blocked']);return 2
  report.pop('blocked',None)
  checks=load('checks',REPO/'docs/codex/findings/checkpoint-runtime-v1/run_checks.py')
  checks.HERE=out;checks.GODOT=str(args.godot.resolve());checks.PROFILE=out/'profiles'
  source={str(p.relative_to(REPO/'patch-notes')):sha(p) for base in ['scripts','scenes','data'] for p in (REPO/'patch-notes'/base).rglob('*') if p.is_file()}
  if args.resume:
   original=json.loads((out/'source.json').read_text())
   added=set(source)-set(original)
   if any(source.get(k)!=v for k,v in original.items()) or any(not k.endswith('.uid') for k in added):raise RuntimeError('Cannot resume: source changed')
   report['import_generated_uid_files']=sorted(added)
  (out/'source.json').write_text(json.dumps(source,indent=2))
  checks.run('import',['--editor','--import','--quit'])
  for path in sorted((REPO/'patch-notes/scripts/debug').glob('verify_*.gd')):
   if path.stem in report['checks']:
    prior=json.loads((out/(path.stem+'.command.json')).read_text())
    if prior['exit'] or prior['errors']:raise RuntimeError('Invalid cached result '+path.stem)
    continue
   checks.run(path.stem,['--script','res://scripts/debug/'+path.name]);report['checks'].append(path.stem);record()
  exporter=load('exporter',REPO/'docs/codex/findings/export-queue-v3/export.py');exporter.OUT=out
  saved=sys.argv;sys.argv=['export.py','--godot',str(args.godot.resolve())]
  try:exporter.main()
  finally:sys.argv=saved
  shutil.copy2(REPO/'docs/codex/findings/export-queue-v3/inspect.py',out/'inspect.py')
  runpy.run_path(str(out/'inspect.py'),run_name='__main__')
  m=json.loads((out/'build-manifest.json').read_text());workspace=Path(m['workspace'])
  env=os.environ.copy();profile=Path(tempfile.mkdtemp(prefix='export-smoke-',dir=out))
  for key in ['APPDATA','LOCALAPPDATA']:
   d=profile/key;d.mkdir();env[key]=str(d)
  for name,mode in [('headless',['--headless']),('graphical',['--rendering-method','gl_compatibility'])]:
   command=[str(workspace/'demo/Patch Notes Demo.exe'),*mode,'--quit-after','60']
   p=subprocess.run(command,env=env,capture_output=True,timeout=90)
   text=(p.stdout+p.stderr).decode(errors='replace');(out/(name+'-startup.log')).write_text(text)
   errors=[line for line in text.splitlines() if ('SCRIPT ERROR' in line or line.startswith('ERROR:')) and 'root certificate store' not in line]
   (out/(name+'-startup.command.json')).write_text(json.dumps(dict(command=command,exit=p.returncode,errors=errors),indent=2))
   if p.returncode or errors:raise RuntimeError(name+' exported startup failed')
  for rel,digest in source.items():
   if sha(REPO/'patch-notes'/rel)!=digest:raise RuntimeError('Source changed during gate: '+rel)
  report['automated_pass']=True;report['artifact_hashes']=m['artifacts'];report['artifact_directory']=str(workspace/'demo');record()
  print('AUTOMATED PASS:',len(report['checks']),'suites, import, export, PCK audit, two startup modes. Release acceptance remains:',*report['remaining'],sep='\n')
  return 2
 except Exception as error:
  report['failure']=str(error);record();raise
if __name__=='__main__':sys.exit(main())
