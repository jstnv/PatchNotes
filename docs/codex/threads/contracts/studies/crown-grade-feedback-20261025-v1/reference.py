"""Offline presentation reference. Never imported by Godot or used for settlement."""
from itertools import combinations

STATS=('graphics','sound','technology','design')
KIND='crown_quill_brief_completion_v1'
TERMS='balanced-craft-approved-20261025'

def scores(scope,cores,standing=0):
    if type(scope) is not int or scope<0 or len(cores)!=4 or any(type(x) is not int or x<0 for x in cores):raise ValueError('invalid scores')
    if type(standing) is not int or not 0<=standing<=10000:raise ValueError('invalid standing')
    n=2*min(scope,9)+sum(min(x,8) for x in cores)+2*min(min(cores),8)
    completion=10000*n//66;spread=max(cores)-min(cores)
    balance=max(0,10000-1250*max(0,spread-4));grade=min(completion,balance)
    requested=grade//10;credited=min(requested,10000-standing)
    if completion==balance==10000:limit='full'
    elif completion==balance:limit='both'
    elif completion<balance:limit='completion'
    else:limit='balance'
    return dict(scope=scope,core_half_units=list(cores),completion_bp=completion,balance_bp=balance,grade_bp=grade,spread_half_units=spread,limiting=limit,highest=[STATS[i] for i,x in enumerate(cores) if x==max(cores)],lowest=[STATS[i] for i,x in enumerate(cores) if x==min(cores)],requested_bp=requested,credited_bp=credited,resulting_standing_bp=standing+credited,cap_clipped=credited<requested)

def project(state,cards):
    cores=list(state['cores']);scope=state['scope']
    multiplier=3 if len({c['primary_stat'] for c in cards})==1 else 2
    for c in cards:
        scope+=c['scope'];cores[STATS.index(c['primary_stat'])]+=multiplier*c['primary_value']
        if c['secondary_stat']:cores[STATS.index(c['secondary_stat'])]+=multiplier*c['secondary_value']
    return scores(scope,cores,state['standing_bp'])

def identity(state):
    return tuple(state[k] for k in ('offer_id','hand_index','sequence','view_hash','terms'))

def eligible(state):
    return state['publisher']=='crown_quill' and state['kind']==KIND and state['terms']==TERMS and state['hand_index'] in (0,1) and state['coherent']

def preview(state,tokens,expected_identity):
    if not eligible(state):return dict(available=False,reason='unavailable_state')
    if expected_identity!=identity(state):return dict(available=False,reason='stale_selection')
    if len(tokens)!=4 or any(type(t) is not int for t in tokens) or len(set(tokens))!=4:return dict(available=False,reason='select_four_distinct_cards')
    visible=state['visible']
    if len({c['token'] for c in visible})!=len(visible):return dict(available=False,reason='invalid_candidates')
    if not set(tokens)<=set(c['token'] for c in visible):return dict(available=False,reason='unknown_card')
    projected=project(state,[c for c in visible if c['token'] in tokens]);committed=scores(state['scope'],state['cores'],state['standing_bp'])
    return dict(available=True,provisional=state['hand_index']==0,score_value_change_bp=projected['requested_bp']-committed['requested_bp'],projected=projected)

def current_cards_warning(state):
    # No first-hand future-draw assertion, no random stream, no recommended cards.
    if not eligible(state) or state['hand_index']!=1 or len(state['visible'])!=7:return dict(available=False)
    tokens=[c['token'] for c in state['visible']]
    if len(set(tokens))!=7 or any(type(x) is not int for x in tokens):return dict(available=False)
    values=[project(state,[state['visible'][i] for i in c])['requested_bp'] for c in combinations(range(7),4)]
    return dict(available=True,current_cards_zero=max(values)==0,options=len(values),max_requested_bp=max(values))

def streak(events,history_available=True,validated=True):
    # Production must obtain this projection from the trusted reconstructed ledger.
    if not history_available or not validated:return dict(available=False,count=None,show=False)
    seen=set();sources=set();cycle=-1;count=0
    for index,e in enumerate(events):
        key=(e['kind'],e['source_id'])
        if e['ordinal']!=index+1 or e['cycle']<cycle or e['event_id'] in seen or key in sources:return dict(available=False,count=None,show=False)
        req=e['requested_reputation_bp'];credit=e['credited_reputation_bp']
        if type(req) is not int or type(credit) is not int or not 0<=credit<=req<=10000:return dict(available=False,count=None,show=False)
        seen.add(e['event_id']);sources.add(key);cycle=e['cycle']
        if e['publisher_id']!='crown_quill' or e['kind']!=KIND:continue
        if not e['source_verified']:return dict(available=False,count=None,show=False)
        count=count+1 if req==0 else 0
    return dict(available=True,count=count,show=count>=2)
