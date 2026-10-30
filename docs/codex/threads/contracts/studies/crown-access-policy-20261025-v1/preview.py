from run import *
BASE=RAW.parent/'crown-search-brief-20261025-v1/branches'
log=BASE/'experiment.log';states={};hands=[];results=[];checks=0
stats={'graphics':0,'sound':1,'technology':2,'design':3}
def grade(scope,cores):
    completion=(2*min(scope,9)+sum(min(h,8) for h in cores)+2*min(min(cores),8))*10000//66
    balance=max(0,10000-1250*max(0,max(cores)-min(cores)-4))
    return dict(completion_bp=completion,balance_bp=balance,grade_bp=min(completion,balance),requested_reputation_bp=min(completion,balance)//10)
for line in log.read_text(encoding='utf-8').splitlines():
    if line.startswith('PN_CB_HAND '):
        r=json.loads(line.split(' ',1)[1]);key=(r['case'],r['offer']);prior=states.get(key,dict(scope=0,cores=[0]*4))
        assert len(set(r['chosen']))==4
        cards=[c for c in r['visible'] if c['token'] in r['chosen']];assert len(cards)==4
        same=len(set(c['primary_stat'] for c in cards))==1;multiplier=3 if same else 2
        scope=prior['scope'];cores=prior['cores'].copy()
        for card in cards:
            scope+=card['scope']
            for entry in card.get('core_contributions',[dict(stat=card['primary_stat'],value=card['primary_value']),dict(stat=card['secondary_stat'],value=card['secondary_value'])]):
                if entry['stat']:cores[stats[entry['stat']]]+=multiplier*entry['value']
        projected=dict(scope=scope,cores=cores);assert projected==r['projected'];checks+=1
        states[key]=projected
        hands.append(dict(case=r['case'],offer=r['offer'],hand=r['hand']+1,before=prior,after=projected,score=grade(scope,cores),view_hash=r['view_hash'],selected_tokens=r['chosen']))
    elif line.startswith('PN_CB_RESULT '):
        r=json.loads(line.split(' ',1)[1]);g=grade(r['scope'],r['cores'])
        assert g['completion_bp']==r['completion'] and g['balance_bp']==r['promise'] and g['grade_bp']==r['grade'] and g['requested_reputation_bp']==r['award'];checks+=1
        assert states[(r['case'],r['offer'])]==dict(scope=r['scope'],cores=r['cores']);checks+=1
        results.append(r)
assert len(hands)==12 and len(results)==6
write(HERE/'preview-evidence.json',dict(status='PASS',checks=checks,scope='Read-only extraction and integer recomputation; no new UI execution',log=str(log),log_sha256=hashlib.sha256(log.read_bytes()).hexdigest(),runtime_source=load(THREAD/'studies/crown-search-brief-20261025-v1/execution-pin.json'),hands=hands,results=results))
for h in hands:print(json.dumps({k:v for k,v in h.items() if k not in ['selected_tokens','view_hash']}))
