"""One-command local release checks; exit 2 means human acceptance remains.

python tools/release_gate.py --godot PATH [--output PATH]
No source edits, downloading, publishing, or user-save access. Each run retains
fresh evidence. Interactive and audible acceptance are never inferred from CI.
"""
from pathlib import Path
import argparse,hashlib,importlib.util,json,os,re,runpy,shutil,socket,subprocess,sys,tempfile,datetime

REPO=Path(__file__).resolve().parents[1]
def load(name,path):
 spec=importlib.util.spec_from_file_location(name,path);module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def verifier_has_initializer(path):
 # Some older verifiers schedule _run from _init and do not implement the
 # optional SceneTree _initialize callback. Do not invent a parent callback.
 seen=set()
 while path not in seen:
  seen.add(path);text=path.read_text(encoding='utf8')
  if re.search(r'^func _initialize\s*\(',text,re.M):return True
  parent=re.search(r'^extends\s+(.+)$',text,re.M)
  if parent is None:raise RuntimeError('Unknown verifier base: '+str(path))
  name=parent.group(1).strip()
  if name=='SceneTree':return False
  if not (name.startswith('"res://') and name.endswith('"')):raise RuntimeError('Unsupported verifier inheritance: '+name)
  path=REPO/'patch-notes'/name[7:-1]
 raise RuntimeError('Cyclic verifier inheritance: '+str(path))

def checkpoint_wrapper(path,directory):
 """Generate test-only inheritance instrumentation; never edit game source."""
 parent='res://'+path.relative_to(REPO/'patch-notes').as_posix()
 call_parent=verifier_has_initializer(path)
 # This source-pinned verifier deliberately acquires PN_CHECKPOINT_TEST_PORT
 # before adding its coordinator. Keep that real lease; never replace it.
 preserve_existing=path.name=='verify_genre_checkpoint.gd'
 text='extends '+json.dumps(parent)+'\n'+'''\
class GateCheckpointStore extends StudioCheckpointStore:
\tfunc acquire() -> bool:
\t\tvar test_port := OS.get_environment("PN_CHECKPOINT_TEST_PORT")
\t\tif test_port.is_empty(): return super.acquire()
\t\tif _writer != null: return true
\t\tvar server := TCPServer.new()
\t\tif server.listen(int(test_port),"127.0.0.1") != OK: return false
\t\t_writer = server
\t\treturn true

func _initialize() -> void:
\tif OS.get_environment("PN_CHECKPOINT_TEST_PORT") != "47733":
\t\tpush_error("Gate checkpoint isolation requires dedicated port47733")
\t\tquit(1)
\t\treturn
\tnode_added.connect(_gate_isolate_checkpoint_writer)
'''+('\tsuper._initialize()\n' if call_parent else '\t# Parent _init already scheduled its original deferred verifier.\n')+'''
func _gate_isolate_checkpoint_writer(node: Node) -> void:
\tif not node is CheckpointCoordinator: return
\tvar original: StudioCheckpointStore = node.store
'''+('''\
\tif original != null and original.get_script() == preload("res://scripts/persistence/studio_checkpoint_store.gd") and original._writer != null and original._writer.is_listening() and original.fault == &"":
\t\tprint("CHECKPOINT_WRITER_EXISTING verify_genre_checkpoint retains its source-verified PN_CHECKPOINT_TEST_PORT lease")
\t\treturn
''' if preserve_existing else '')+'''\
\tif original == null or original.get_script() != preload("res://scripts/persistence/studio_checkpoint_store.gd") or original._writer != null or original.fault != &"":
\t\tpush_error("Gate isolation refuses a non-pristine coordinator store")
\t\tquit(1)
\t\treturn
\tnode.store = GateCheckpointStore.new(original.directory,original.validator)
\tprint("CHECKPOINT_WRITER_ISOLATED port=47733 directory=",node.store.directory)
'''
 directory.mkdir(parents=True,exist_ok=True)
 target=directory/(path.stem+'.gd')
 if target.exists() and target.read_text(encoding='utf8')!=text:raise RuntimeError('Wrapper changed since prior execution: '+str(target))
 if not target.exists():target.write_text(text,encoding='utf8')
 return target,{'path':str(target),'sha256':sha(target),'original':parent,'original_sha256':sha(path),'parent_initialize_called':call_parent,'preserve_source_owned_lease':preserve_existing}
def main():
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--godot',required=True,type=Path)
 parser.add_argument('--output',type=Path)
 parser.add_argument('--resume',action='store_true',help='Resume an interrupted gate only when every source hash still matches')
 parser.add_argument('--defer-graphical-startup',action='store_true',help='Run headless checks and export now; leave visible startup for a later acceptance session')
 parser.add_argument('--isolate-checkpoint-writer',action='store_true',help='Instrument verifier-only fresh coordinator stores to use the real TCP lease on47733; leaves production62741 and runtime source unchanged')
 args=parser.parse_args()
 out=(args.output or REPO/'docs/codex/findings'/('release-gate-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))).resolve()
 out.mkdir(parents=True,exist_ok=args.resume)
 (out/'.gdignore').touch()
 report=json.loads((out/'gate-result.json').read_text()) if args.resume else {'source_head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=REPO,text=True).strip(),'output':str(out),'automated_pass':False,'release_ready':False,'remaining':['Exported legal Bank/exit/Continue/installment/payoff/two-game interaction','Approved asset/license set and audible music/SFX acceptance'],'checks':[]}
 if args.resume:report['previous_failure']=report.pop('failure',None)
 report['automated_pass']=False;report['headless_automated_pass']=False
 graphical_pending='Graphical exported startup deferred to the overnight acceptance session'
 report['graphical_startup_deferred']=args.defer_graphical_startup
 report['remaining']=[item for item in report['remaining'] if item!=graphical_pending]
 if args.defer_graphical_startup:report['remaining'].append(graphical_pending)
 # This existing verifier override isolates its writer from a running game.
 os.environ['PN_CHECKPOINT_TEST_PORT']='47733';report['test_writer_port']=47733
 # New simulator verifiers require their own recoverable tape/report path.
 # Do not inherit one caller's capture path or a single-mode oracle override.
 for name in ['PN_ALPHA_COMMAND_MODE','PN_BETA_COMMAND_MODE','PN_DESIGN_COMMAND_MODE','PN_DEVELOPMENT_MODE','PN_STORE_COPY_CAPTURE','PN_CARD_FRAME_CAPTURE']:
  os.environ.pop(name,None)
 def record(): (out/'gate-result.json').write_text(json.dumps(report,indent=2))
 record()
 try:
  prior_isolation=report.get('checkpoint_writer_instrumentation',{})
  if args.resume and bool(prior_isolation.get('enabled',False))!=args.isolate_checkpoint_writer:raise RuntimeError('Cannot resume with a different checkpoint-writer mode')
  helper_hash=sha(Path(__file__))
  if args.isolate_checkpoint_writer:
   if args.resume and prior_isolation.get('helper_sha256')!=helper_hash:raise RuntimeError('Cannot resume: checkpoint instrumentation helper changed')
   report['checkpoint_writer_instrumentation']={'enabled':True,'port':47733,'helper_sha256':helper_hash,'wrappers':prior_isolation.get('wrappers',{}),'scope':'Per-verifier inheritance wrappers replace only pristine CheckpointCoordinator stores before use; isolated user profiles remain mandatory.','limits':['Real TCP collision/release semantics retained on47733; production62741 is not acquired or tested by instrumented coordinators.','Existing verifier-specific writer overrides remain under their original verifier control.','No runtime/package modification; exported smoke is uninstrumented main-menu startup, not save/Continue acceptance.']}
  else:report['checkpoint_writer_instrumentation']={'enabled':False}
  record()
  # Several scene-input suites create actual Studio coordinators. A running
  # game's global writer would open failure modals and invalidate those tests.
  with socket.socket() as probe:
   preflight_port=47733 if args.isolate_checkpoint_writer else 62741
   try:probe.bind(('127.0.0.1',preflight_port))
   except OSError:
    report['blocked']='Dedicated checkpoint test writer47733 is active; wait for that test process to exit.' if args.isolate_checkpoint_writer else 'Close the running game before this serial release gate; its Studio writer is active.'
    record();print(report['blocked']);return 2
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
   evidence=out/'verifier-artifacts'/path.stem
   evidence.mkdir(parents=True,exist_ok=True)
   os.environ['PN_CARD_FRAME_OUTPUT']=str(evidence/'result.json')
   script='res://scripts/debug/'+path.name
   if args.isolate_checkpoint_writer:
    wrapper,metadata=checkpoint_wrapper(path,out/'checkpoint-wrappers')
    cached=report['checkpoint_writer_instrumentation']['wrappers'].get(path.stem)
    if cached is not None and cached!=metadata:raise RuntimeError('Cannot reuse changed wrapper: '+path.stem)
    report['checkpoint_writer_instrumentation']['wrappers'][path.stem]=metadata
    script=str(wrapper);record()
   if path.stem in report['checks']:
    prior=json.loads((out/(path.stem+'.command.json')).read_text())
    if prior['exit'] or prior['errors']:raise RuntimeError('Invalid cached result '+path.stem)
    continue
   checks.run(path.stem,['--script',script])
   report.setdefault('verifier_evidence',{})[path.stem]=str(evidence)
   report['checks'].append(path.stem);record()
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
  startup_modes=[('headless',['--headless'])]
  if not args.defer_graphical_startup:startup_modes.append(('graphical',['--rendering-method','gl_compatibility']))
  for name,mode in startup_modes:
   command=[str(workspace/'demo/Patch Notes Demo.exe'),*mode,'--quit-after','60']
   p=subprocess.run(command,env=env,capture_output=True,timeout=90)
   text=(p.stdout+p.stderr).decode(errors='replace');(out/(name+'-startup.log')).write_text(text)
   errors=[line for line in text.splitlines() if ('SCRIPT ERROR' in line or line.startswith('ERROR:')) and 'root certificate store' not in line]
   (out/(name+'-startup.command.json')).write_text(json.dumps(dict(command=command,exit=p.returncode,errors=errors),indent=2))
   if p.returncode or errors:raise RuntimeError(name+' exported startup failed')
  for rel,digest in source.items():
   if sha(REPO/'patch-notes'/rel)!=digest:raise RuntimeError('Source changed during gate: '+rel)
  if args.isolate_checkpoint_writer:
   if sha(Path(__file__))!=helper_hash:raise RuntimeError('Checkpoint instrumentation helper changed during gate')
   for item in report['checkpoint_writer_instrumentation']['wrappers'].values():
    if sha(Path(item['path']))!=item['sha256']:raise RuntimeError('Checkpoint wrapper changed during gate: '+item['path'])
  report['headless_automated_pass']=True;report['automated_pass']=not args.defer_graphical_startup;report['artifact_hashes']=m['artifacts'];report['artifact_directory']=str(workspace/'demo');record()
  print('HEADLESS AUTOMATED PASS:' if args.defer_graphical_startup else 'AUTOMATED PASS:',len(report['checks']),'suites, import, export, PCK audit, '+str(len(startup_modes))+' startup mode(s). Release acceptance remains:',*report['remaining'],sep='\n')
  return 2
 except Exception as error:
  report['failure']=str(error);record();raise
if __name__=='__main__':sys.exit(main())
