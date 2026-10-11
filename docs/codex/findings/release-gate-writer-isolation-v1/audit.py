"""Independent offline audit of focused test-only writer instrumentation."""
from pathlib import Path
import hashlib,json,re,ast
H=Path(__file__).resolve().parent;ROOT=H.parents[3];checks=0
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def read(p):return json.loads(Path(p).read_text(encoding='utf8'))
def check(ok,label):
    global checks
    checks+=1
    if not ok:raise AssertionError(label)
source=read(H/'source-before.json');result=read(H/'result.json');wrappers=read(H/'wrappers.json')
check(source==read(H/'source-after.json'),'source stable throughout focused verification')
for name,digest in source.items():check(sha(ROOT/name)==digest,'pinned source currently exact '+name)
check(result['passed'] and result['source_unchanged'] and result['native_processes']==4 and result['preflight_negative_controls']==2,'declared bounded run complete')
check(result['helper_sha256']==sha(ROOT/'tools/release_gate.py'),'helper binding')
ast.parse((ROOT/'tools/release_gate.py').read_text(encoding='utf8'))
check(len(wrappers)==result['wrappers_generated']==104,'all maintained wrappers generated')
original=(ROOT/'patch-notes/scripts/debug/verify_checkpoint_store.gd').read_text(encoding='utf8')
acquire=original[original.index('\tfunc acquire()'):original.index('\nvar failures')].strip()
for name,item in wrappers.items():
    path=Path(item['path']);text=path.read_text(encoding='utf8')
    check(sha(path)==item['sha256'],'wrapper bytes '+name)
    check(sha(ROOT/'patch-notes'/item['original'].removeprefix('res://'))==item['original_sha256'],'original verifier bytes '+name)
    start=text.index('\tfunc acquire()');end=text.index('\nfunc _initialize')
    check(text[start:end].strip()==acquire,'same TCP acquire semantics '+name)
    check('node_added.connect(_gate_isolate_checkpoint_writer)' in text,'hook connected '+name)
    if item['parent_initialize_called']:check(text.index('node_added.connect')<text.index('super._initialize()'),'hook before original initializer')
    else:check('super._initialize()' not in text,'no invented native parent callback')
    check(item['preserve_source_owned_lease']==(name=='verify_genre_checkpoint'),'narrow existing-lease exception')
passes=0
for name in ['verify_main_menu_history','verify_checkpoint_runtime','verify_genre_checkpoint','lease_collision']:
    m=read(H/(name+'.manifest.json'));c=read(H/(name+'.command.json'));log=(H/(name+'.log')).read_text(encoding='utf8')
    check(m['source_sha256']==sha(H/'source-before.json'),'process source binding')
    for ext,digest in m['artifacts'].items():check(sha(H/(name+'.'+ext))==digest,'process artifact binding')
    path=H/'lease_collision.gd' if name=='lease_collision' else H/'wrappers'/(name+'.gd')
    check(m['script_sha256']==sha(path),'executed script bytes')
    check(c['exit']==0 and c['errors']==[] and c['command'][-1]==str(path),'native command/exit')
    errors=[s for s in log.splitlines() if re.match(r'^(?:SCRIPT ERROR:|ERROR:|FAIL(?:ED|URE)?[: ])',s.strip(),re.I) and s.strip()!='ERROR: Failed to read the root certificate store.']
    check(not errors,'no unclassified engine/assertion error')
    lines=[s for s in log.splitlines() if s.startswith('PASS:')];passes+=len(lines)
    if name=='verify_genre_checkpoint':check(log.count('CHECKPOINT_WRITER_EXISTING')==1 and 'CHECKPOINT_WRITER_ISOLATED' not in log,'existing Genre lease preserved')
    else:check(log.count('CHECKPOINT_WRITER_ISOLATED')==(2 if name=='lease_collision' else 1),'fresh stores instrumented')
    if name=='lease_collision':check(len(lines)==10 and 'Second owner rejected without phantom lease' in log and 'Final coordinator exit releases port' in log,'meaningful real lease collision/release acceptance')
for label,enabled in [('default-production-held',False),('explicit-test-held',True)]:
    report=read(H/label/'gate-result.json');cmd=read(H/(label+'.command.json'))
    check(cmd['exit']==2 and report['checks']==[] and bool(report['blocked']),'preflight rejects occupied expected port')
    check(report['checkpoint_writer_instrumentation']['enabled']==enabled,'explicit mode only')
    check(not (H/label/'import.log').exists(),'preflight stops before native run')
    if enabled:check('47733' in report['blocked'],'test port classification')
    else:check(report['blocked']=='Close the running game before this serial release gate; its Studio writer is active.','default production behavior retained')
check(passes==97,'97 native assertions')
audit={'passed':True,'checks':checks,'native_assertions':passes,'native_processes':4,'preflight_negative_controls':2,'wrappers':104,'source_entries':len(source),'helper_sha256':result['helper_sha256'],'auditor_sha256':sha(__file__)}
(H/'audit.json').write_text(json.dumps(audit,indent=2)+'\n',encoding='utf8');print(json.dumps(audit,indent=2))
