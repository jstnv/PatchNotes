from pathlib import Path
import shutil
r=Path('patch-notes');p=Path('docs/codex/findings/full-ui-response-audit-20261102-v1')
paths=['scripts/finance/studio_finance_ledger.gd','scripts/persistence/checkpoint_coordinator.gd','scripts/market/rival_world.gd','scripts/market/rival_world_checkpoint.gd']
for f in paths:
 dst=p/'before_perf'/f;dst.parent.mkdir(parents=True,exist_ok=True);assert not dst.exists();shutil.copy2(r/f,dst)
f=r/'scripts/market/rival_world.gd';s=f.read_text(encoding='utf-8');a=s.index('\tvar history: Array = live_releases.values().map',s.index('func observation()'));b=s.index('\n\treturn {"cycle":cycle',a);history=s[a:b]
s=s[:a]+s[b:];s=s.replace('"live_releases":history,"historical_archive"','"live_releases":detached_live_history(),"historical_archive"',1)
method='func detached_live_history() -> Array:\n'+history+'\n\treturn history\n\n';at=s.index('func observation()');s=s[:at]+method+s[at:];f.write_text(s,encoding='utf-8')
f=r/'scripts/market/rival_world_checkpoint.gd';s=f.read_text(encoding='utf-8');assert s.count('world.observation().live_releases')==1;s=s.replace('world.observation().live_releases','world.detached_live_history()');f.write_text(s,encoding='utf-8')
f=r/'scripts/persistence/checkpoint_coordinator.gd';s=f.read_text(encoding='utf-8')
for key in ['last_payload','_last_write_player','_last_write_world']:s=s.replace('='+key+'.duplicate(true)','='+key)
for key in ['player','world']:s=s.replace('=completed_job.'+key+'.duplicate(true)','=completed_job.'+key)
s=s.replace('_last_write_player.clear();_last_write_world.clear()','_last_write_player={};_last_write_world={}')
f.write_text(s,encoding='utf-8')
f=r/'scripts/finance/studio_finance_ledger.gd';s=f.read_text(encoding='utf-8');a=s.index('static func _remember_valid_journal');b=s.index('\nstatic func _validate_journal',a)
s=s[:a]+'''static func _remember_valid_journal(key: PackedByteArray, ledger: Dictionary={}) -> void:
\tif key.size() > VALIDATED_JOURNAL_BYTES: return
\t_validation_lock.lock()
\tfor proof: Dictionary in _validated_journals:
\t\tif proof.key==key:
\t\t\t_validation_lock.unlock()
\t\t\treturn
\t_validation_lock.unlock()
\tvar cost:=key.size()+(0 if ledger.is_empty() else key.size())
\tvar native: Dictionary=ledger.duplicate(true) if cost<=VALIDATED_JOURNAL_BYTES else {}
\tif native.is_empty():cost=key.size()
\t_validation_lock.lock()
\tvar known:=false
\tfor proof: Dictionary in _validated_journals:
\t\tif proof.key==key:known=true;break
\tif not known:
\t\t_validated_journals.append({"key":key,"ledger":native,"cost":cost})
\t\t_validated_journal_bytes+=cost
\twhile _validated_journals.size()>VALIDATED_JOURNAL_LIMIT or _validated_journal_bytes>VALIDATED_JOURNAL_BYTES:
\t\t_validated_journal_bytes-=int(_validated_journals.pop_front().cost)
\t_validation_lock.unlock()

'''+s[b:]
marker='static var _validation_lock := Mutex.new()'
s=s.replace(marker,marker+'''
## Successful pure plans, keyed by every typed input and the loaded rules.
## Retained DTOs are detached; validation/publication/receipts remain unchanged.
const PLAN_MEMO_LIMIT := 128
const PLAN_MEMO_BYTES := 32 * 1024 * 1024
static var _plan_memos: Array[Dictionary]=[]
static var _plan_memo_bytes:=0
static var _plan_memo_lock:=Mutex.new()
''',1)
a=s.index('static func plan(');b=s.index('\n\n\nstatic func _unpaid_category',a);original=s[a:b]
original=original.replace('\tif not _is_valid(ledger)', '''\tvar rules:=_plan_rule_context()
\tvar key:=var_to_bytes([rules,ledger,cycle,cash_before,direct_delta,kind,sales_earned,settled,productive,source_id])
\tvar memo:Variant=_memo_plan(key)
\tif memo!=null:return memo
\tif not _is_valid(ledger)''',1)
original=original.replace('\treturn result','\tif not result.is_empty() and rules==_plan_rule_context():_remember_plan(key,result)\n\treturn result',1)
methods='''

static func _plan_rule_context() -> PackedByteArray:
\t# Loaded code, not disk text: editor hot reload cannot reuse old rule plans.
\tvar current:Script=load("res://scripts/finance/studio_finance_ledger.gd")
\tvar values:Array=[]
\tfor script:Script in [current,Clock,Bank,Education,Bills]:
\t\tvalues.append(script.get_instance_id());values.append(script.get_source_code())
\treturn var_to_bytes(values)

static func _memo_plan(key:PackedByteArray) -> Variant:
\tif key.size()>PLAN_MEMO_BYTES:return null
\tvar result:Variant=null
\t_plan_memo_lock.lock()
\tfor i in _plan_memos.size():
\t\tif _plan_memos[i].key==key:
\t\t\tvar memo:Dictionary=_plan_memos[i]
\t\t\t_plan_memos.remove_at(i);_plan_memos.append(memo)
\t\t\tresult=memo.result
\t\t\tbreak
\t_plan_memo_lock.unlock()
\treturn result.duplicate(true) if result!=null else null

static func _remember_plan(key:PackedByteArray,result:Dictionary) -> void:
\tvar cost:=key.size()+var_to_bytes(result).size()
\tif cost>PLAN_MEMO_BYTES:return
\tvar detached:=result.duplicate(true)
\t_plan_memo_lock.lock()
\tfor memo:Dictionary in _plan_memos:
\t\tif memo.key==key:
\t\t\t_plan_memo_lock.unlock();return
\t_plan_memos.append({"key":key,"result":detached,"cost":cost});_plan_memo_bytes+=cost
\twhile _plan_memos.size()>PLAN_MEMO_LIMIT or _plan_memo_bytes>PLAN_MEMO_BYTES:
\t\t_plan_memo_bytes-=int(_plan_memos.pop_front().cost)
\t_plan_memo_lock.unlock()
'''
s=s[:a]+original+methods+s[b:];f.write_text(s,encoding='utf-8');print('Four bounded performance files updated; typed validation and detached live snapshots retained.')
