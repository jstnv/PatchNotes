from setup import *
import re,shutil
P=VAR/'project'
def edit(path,fn):
 p=P/path;s=p.read_text(encoding='utf-8');p.write_text(fn(s),encoding='utf-8',newline='\n')
def replace(s,a,b):
 assert a in s,a[:100]
 return s.replace(a,b)
def resolve(i,fn):
 path=json.loads((HERE/'merge.json').read_text())[i]['path']
 s=(HERE/'merge'/f'{i}-result-utf8').read_text(encoding='utf-8')
 def sub(m):
  a,b=m.group(1),m.group(2);return fn(a,b)
 s=re.sub(r'^<<<<<<<[^\n]*\n(.*?)^=======\n(.*?)^>>>>>>>[^\n]*\n',sub,s,flags=re.M|re.S)
 assert '<<<<<<<' not in s;(P/path).write_text(s,encoding='utf-8')
resolve(5,lambda a,b:a+b)
resolve(6,lambda a,b:a.replace('-contractsearch1"','-contractsearch1-crownsearch-private1"'))
resolve(7,lambda a,b:a if not a.strip() else a+'\n'+b)
edit('scripts/run_state.gd',lambda s:re.sub(r'func _issue_crown_brief\(.*?(?=func _plan_finishing_crown_brief)', '',s,flags=re.S))
# The only Crown source is an actual paid Search, with an empty release field.
edit('scripts/contracts/crown_relationship_rules.gd',lambda s:replace(s,'if id != StringName("%s:crown-brief:%s" % [owner,offer.source_release_id]) or not releases.has(offer.source_release_id): return {}','if not offer.source_release_id.is_empty() or preload("res://scripts/contracts/contract_search.gd").source(run,id,&"brief",&"crown_quill").is_empty(): return {}'))
edit('scripts/persistence/studio_checkpoint.gd',lambda s:replace(s,'if not r.released_games.has(source) or id != StringName("%s:crown-brief:%s" % [r.bank_run_id,source]) or brief.offer_id != id or not _valid_contract(brief.state,r,ContractDefinitions.CROWN_BRIEF,id,source): return "Invalid Brief provenance"','if not source.is_empty() or RunState.ContractSearch.source(r,id,&"brief",&"crown_quill").is_empty() or brief.offer_id != id or not _valid_contract(brief.state,r,ContractDefinitions.CROWN_BRIEF,id,source): return "Invalid Crown Search provenance"'))
def search(s):
 s=replace(s,'"sidestreet_briefs":run._sidestreet_briefs,','"sidestreet_briefs":run._sidestreet_briefs,"crown_briefs":run._crown_briefs,')
 s=replace(s,'static func terms(work: StringName) -> Dictionary:', '''static func supported(publisher: StringName,work: StringName) -> bool:
\treturn (publisher==&"sidestreet" and work in WORK_TYPES) or (publisher==&"crown_quill" and work==&"brief")
static func terms(work: StringName,publisher: StringName=&"sidestreet") -> Dictionary:
\tif publisher==&"crown_quill":
\t\treturn {"version":1,"required_hands":2,"scope":9,"core_target":4,"cash_cents":0,"review_target_tenths":0,"reputation_gate_bp":0,"owner":&"studio"} if work==&"brief" else {}''')
 s=replace(s,'static func template(work: StringName) -> StringName:return StringName("sidestreet-%s-v1"%work)','static func template(work: StringName,publisher: StringName=&"sidestreet") -> StringName:return StringName("%s-%s-v1"%[publisher,work])')
 s=replace(s,'static func source(run: Variant, offer_id: StringName, work: StringName) -> Dictionary:','static func source(run: Variant, offer_id: StringName, work: StringName,publisher: StringName=&"sidestreet") -> Dictionary:')
 s=replace(s,'offer.get("publisher_id")!=&"sidestreet"','offer.get("publisher_id")!=publisher')
 s=replace(s,'receipt.get("work")==work:return','receipt.get("work")==work and receipt.get("publisher_id")==publisher:return')
 s=replace(s,'static func pending(run: Variant, work: StringName) -> bool:\n\tvar d:=data(run)','''static func pending(run: Variant, work: StringName,publisher: StringName=&"sidestreet") -> bool:
\tvar d:=data(run)
\tif publisher==&"crown_quill":
\t\tfor offer: Dictionary in d.crown_briefs.values():
\t\t\tif offer.state==null or (not offer.state.is_completed() if offer.state is ContractState else offer.state.hands<2):return true
\t\treturn false''')
 s=replace(s,'r.publisher_id!=&"sidestreet" or r.work not in WORK_TYPES or r.template_id!=template(r.work) or r.terms!=terms(r.work)','not supported(r.publisher_id,r.work) or not d.unlocked_publishers.has(r.publisher_id) or r.template_id!=template(r.work,r.publisher_id) or r.terms!=terms(r.work,r.publisher_id)')
 s=replace(s,'\t\tif prior_by_work.has(r.work) and not completed_before(d,prior_by_work[r.work],r.work,r.before_cycle):return false','\t\tvar work_key:=StringName("%s:%s"%[r.publisher_id,r.work])\n\t\tif prior_by_work.has(work_key) and not completed_before(d,prior_by_work[work_key],r.work,r.before_cycle):return false')
 s=replace(s,'if r.work in [&"cash",&"brief"]:', 'if r.publisher_id==&"sidestreet" and r.work in [&"cash",&"brief"]:')
 s=replace(s,'prior_by_work[r.work]=r.offer_id','prior_by_work[work_key]=r.offer_id')
 s=replace(s,'if not d.sidestreet_briefs.has(r.offer_id) or not d.sidestreet_briefs[r.offer_id].source_release_id.is_empty():return false','var briefs: Dictionary=d.crown_briefs if r.publisher_id==&"crown_quill" else d.sidestreet_briefs\n\t\t\t\tif not briefs.has(r.offer_id) or not briefs[r.offer_id].source_release_id.is_empty():return false')
 return s
edit('scripts/contracts/contract_search.gd',search)
def runstate(s):
 s=replace(s,'if publisher!=&"sidestreet" or work not in ContractSearch.WORK_TYPES:', 'if not ContractSearch.supported(publisher,work):')
 s=replace(s,'if not can_browse_contract_search():return "Unlock SideStreet first"','if not can_browse_contract_search() or not _unlocked_publishers.has(publisher):return "Unlock publisher first"')
 s=replace(s,'ContractSearch.pending(self,work)','ContractSearch.pending(self,work,publisher)')
 s=replace(s,'"template_id":ContractSearch.template(work),"terms":ContractSearch.terms(work)','"template_id":ContractSearch.template(work,publisher),"terms":ContractSearch.terms(work,publisher)')
 s=replace(s,'elif quote.work==&"brief":_sidestreet_briefs[plan.offer_id]={"offer_id":plan.offer_id,"source_release_id":&"","state":null}', '''elif quote.work==&"brief":
\t\t\tvar briefs: Dictionary=_crown_briefs if quote.publisher_id==&"crown_quill" else _sidestreet_briefs
\t\t\tbriefs[plan.offer_id]={"offer_id":plan.offer_id,"source_release_id":&"","state":null}''')
 s=replace(s,'\treturn rows\n\nfunc get_contract_search_state()', '\trows.append({"publisher_id":&"crown_quill","work":&"brief","terms":ContractSearch.terms(&"brief",&"crown_quill"),"blocker":contract_search_blocker(&"crown_quill",&"brief"),"quote":get_contract_search_quote(&"crown_quill",&"brief")})\n\treturn rows\n\nfunc get_contract_search_state()')
 return s
edit('scripts/run_state.gd',runstate)
shutil.copyfile(HERE.parent/'crown-search-access-20261025-v1/policy-v2.gd',P/'scripts/debug/csa_access.gd')
sys.path.insert(0,str(ROOT/'tools'));import simulator_variant as sv
meta,base,current,integrity=sv.load_variant(VAR)
write(HERE/'candidate-pin.json',dict(meta=meta,identity=sv.identity(current),changes=sv.delta(base,current),integrity=integrity))
print('Adapted private Search Brief',sv.identity(current))
