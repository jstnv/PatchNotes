from pathlib import Path
import copy,hashlib,json,sys,traceback
from itertools import combinations
from reference import *
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[5];THREAD=HERE.parents[1]
OLD=THREAD/'studies/early-brief-affordability-20261025-v1'
RAW=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/early-brief-affordability-20261025-v1')
OUT=HERE/sys.argv[1];OUT.mkdir(exist_ok=False)
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(name,data):(OUT/name).write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
def digest(v):return hashlib.sha256(json.dumps(v,sort_keys=True,separators=(',',':')).encode()).hexdigest()
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

try:
    input_paths=[OLD/n for n in ['analysis.json','hand-audit.json','verification.json','source-before.json','source-after.json','evidence-manifest.json']]+[RAW/('branches-'+g)/'experiment.log' for g in ['puzzle-a','puzzle-b','others']]
    pins={str(p):sha(p) for p in input_paths};write('input-pins.json',pins)
    previous=load(OLD/'analysis.json');audit=load(OLD/'hand-audit.json');assert len(previous['rows'])==12 and len(audit['rows'])==18
    events={};views={}
    for p in input_paths[-3:]:
        for line in p.read_text(encoding='utf-8').splitlines():
            if not line.startswith(('PN_CB_VIEW ','PN_CB_HAND ','PN_CB_RESULT ')):continue
            kind,raw=line.split(' ',1);e=json.loads(raw)
            if kind=='PN_CB_VIEW':views[e['view_hash']]=e;continue
            events.setdefault((e['case'],e['offer']),{}).setdefault(kind,[]).append(e)
    assert len(events)==18
    records=[];histories={};history_results=[];invalid=[];first_zero=[];alternatives=0
    for (case,offer),types in events.items():
        hands=types['PN_CB_HAND'];result=types['PN_CB_RESULT'][0];state=dict(scope=0,cores=[0,0,0,0]);assert len(hands)==2
        for h in hands:
            view=views[h['view_hash']]
            snapshot=dict(**state,standing_bp=view['reputation'],publisher='crown_quill',kind=KIND,terms=TERMS,offer_id=offer,hand_index=h['hand'],sequence=view['sequence'],view_hash=h['view_hash'],visible=h['visible'],coherent=True)
            immutable=digest(snapshot);selected=preview(snapshot,h['chosen'],identity(snapshot));assert selected['available']
            assert preview(snapshot,h['chosen'],identity(snapshot))==selected and digest(snapshot)==immutable
            projected=selected['projected'];assert projected['scope']==h['projected']['scope'] and projected['core_half_units']==h['projected']['cores']
            options=[project(snapshot,[h['visible'][i] for i in combo]) for combo in combinations(range(7),4)];alternatives+=len(options)
            warning=current_cards_warning(snapshot);assert digest(snapshot)==immutable
            if h['hand']==0:
                assert selected['provisional'] and not warning['available']
                if max(x['requested_bp'] for x in options)==0:first_zero.append(dict(case=case,offer=offer))
            else:
                assert not selected['provisional'] and warning['current_cards_zero']==(max(x['requested_bp'] for x in options)==0)
                assert (projected['completion_bp'],projected['balance_bp'],projected['grade_bp'],projected['requested_bp'])==(result['completion'],result['promise'],result['grade'],result['award'])
                assert projected['credited_bp']==result['award'] and projected['resulting_standing_bp']==result['total']
            records.append(dict(case=case,offer=offer,hand_index=h['hand'],snapshot=snapshot,selected_tokens=h['chosen'],feedback=selected,availability=warning,positive_current_options=sum(x['requested_bp']>0 for x in options)))
            # One representative recorded snapshot supplies bounded protocol mutations.
            if not invalid:
                trials=[('three_cards',snapshot,h['chosen'][:3],identity(snapshot)),('duplicate_card',snapshot,[h['chosen'][0]]*4,identity(snapshot)),('unknown_card',snapshot,h['chosen'][:3]+[-123456],identity(snapshot)),('stale_selection',snapshot,h['chosen'],('stale',)),('other_product',{**snapshot,'kind':'cash_contract'},h['chosen'],identity(snapshot)),('animation',{**snapshot,'coherent':False},h['chosen'],identity(snapshot))]
                for name,s,t,stamp in trials:
                    before=digest(s);r=preview(s,t,stamp);assert not r['available'] and digest(s)==before
                    invalid.append(dict(name=name,result=r))
            state=dict(scope=projected['scope'],cores=projected['core_half_units'])
        seq=histories.setdefault(case,[])
        seq.append(dict(ordinal=len(seq)+1,event_id=offer+':reputation',source_id=offer,publisher_id='crown_quill',kind=KIND,cycle=result['cycle'],requested_reputation_bp=result['award'],credited_reputation_bp=result['award'],source_verified=True))
        r=streak(seq);history_results.append(dict(case=case,brief_ordinal=result['ordinal'],award_bp=result['award'],streak=r))
    assert len(records)==36 and alternatives==1260
    assert sum(r['availability'].get('current_cards_zero',False) for r in records)==8
    assert sum(r['streak']['show'] for r in history_results)==2
    assert all('puzzle-4522' in r['case'] for r in history_results if r['streak']['show'])
    # Constructed scoring boundaries, separately labeled from recorded play.
    boundaries=[]
    for delta in range(15):
        r=scores(9,[8,8,8,8+delta]);assert r['completion_bp']==10000 and r['balance_bp']==max(0,10000-1250*max(0,delta-4))
        boundaries.append(dict(name='spread_half_units_'+str(delta),result=r))
    for name,scope,cores,standing,expected in [
        ('no_work',0,[0,0,0,0],0,(0,10000,0,0,'completion')),
        ('both_limit',7,[1,3,5,9],0,(5000,5000,500,500,'both')),
        ('full_cap',9,[8,8,8,8],10000,(10000,10000,1000,0,'full')),
        ('partial_cap',9,[8,8,8,8],9950,(10000,10000,1000,50,'full')),
        ('scope_over_target',12,[8,8,8,8],0,(10000,10000,1000,1000,'full')),
        ('half_point',9,[8,8,8,13],0,(10000,8750,875,875,'balance'))]:
        r=scores(scope,cores,standing);assert (r['completion_bp'],r['balance_bp'],r['requested_bp'],r['credited_bp'],r['limiting'])==expected
        boundaries.append(dict(name=name,result=r))
    # Exhaustive arithmetic domain, not extra gameplay cases: no positive grade
    # can round to zero requested Reputation under these exact pilot terms.
    domain=[min(10000*n//66,b) for n in range(67) for b in range(0,10001,1250)]
    assert len(domain)==603 and all((g//10==0)==(g==0) for g in domain)
    def event(i,req=0,credit=None,publisher='crown_quill',kind=KIND):
        return dict(ordinal=i,event_id='e'+str(i),source_id='s'+str(i),publisher_id=publisher,kind=kind,cycle=i*3,requested_reputation_bp=req,credited_reputation_bp=req if credit is None else credit,source_verified=True)
    z1=event(1);z2=event(2);z3=event(3);positive=event(3,1000,0)
    cases=[('empty',[],{},(True,0,False)),('one_zero',[z1],{},(True,1,False)),('two_zeros',[z1,z2],{},(True,2,True)),('three_zeros',[z1,z2,z3],{},(True,3,True)),('cap_positive_resets',[z1,z2,positive],{},(True,0,False)),('cap_positive_alone',[event(1,1000,0)],{},(True,0,False)),('other_publisher_ignored',[z1,event(2,500,publisher='sidestreet'),z3],{},(True,2,True)),('other_crown_product_ignored',[z1,event(2,500,kind='crown_cash_completion'),z3],{},(True,2,True)),('missing_history',[],{'history_available':False},(False,None,False)),('unvalidated_history',[z1,z2],{'validated':False},(False,None,False)),('missing_source',[z1,{**z2,'source_verified':False}],{},(False,None,False)),('duplicate_event',[z1,{**z2,'event_id':'e1'}],{},(False,None,False)),('duplicate_source',[z1,{**z2,'source_id':'s1'}],{},(False,None,False)),('wrong_ordinal',[z2],{},(False,None,False)),('reversed_cycle',[z1,{**z2,'cycle':2}],{},(False,None,False)),('invalid_credit',[{**z1,'credited_reputation_bp':1}],{},(False,None,False))]
    history_checks=[]
    for name,sequence,kwargs,expected in cases:
        before=digest(sequence);r=streak(sequence,**kwargs);assert (r['available'],r['count'],r['show'])==expected and digest(sequence)==before
        assert streak(sequence,**kwargs)==r
        history_checks.append(dict(name=name,result=r))
    assert all(sha(Path(p))==h for p,h in pins.items())
    write('feedback-fixtures.json',records);write('history-fixtures.json',dict(recorded_sequences=histories,recorded_results=history_results,constructed_checks=history_checks,limits='Recorded completion events reconstructed from verified result logs; no native persisted-ledger consumer was implemented or tested.'))
    write('constructed-checks.json',dict(score_boundaries=boundaries,invalid_selection=invalid,grade_domain_count=603))
    summary=dict(status='PASS',recorded_hands=36,recorded_final_results=18,current_card_projections=alternatives,final_hand_zero_warnings=8,first_hand_warnings=0,first_hand_all_provisional_options_zero=first_zero,recorded_reminder_points=[r for r in history_results if r['streak']['show']],score_boundaries=len(boundaries),selection_protocol_cases=len(invalid),history_protocol_cases=len(history_checks),grade_domain_count=603,input_files_unchanged=True,positive_first_hand_then_zero=[dict(case=records[i]['case'],offer=records[i]['offer'],first_requested_bp=records[i]['feedback']['projected']['requested_bp']) for i in range(0,len(records),2) if records[i]['feedback']['projected']['requested_bp']>0 and records[i+1]['feedback']['projected']['requested_bp']==0],limits='Offline read-only analysis of recorded play, not new campaigns, native UI, current-source parity, human acceptance or proof of runtime query purity.')
    write('summary.json',summary);print(json.dumps(summary))
except Exception as e:
    write('failure.json',dict(error=str(e),traceback=traceback.format_exc()));raise
