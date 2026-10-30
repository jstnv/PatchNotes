from pathlib import Path
p=Path(__file__).resolve().parent
s=(p.parent/'crown-balance-20261024-v1/analyze.py').read_text(encoding='utf-8')
s=s.replace("check(int(saved['hands'])==2 and int(saved['challenge_redraws'])==0,label+' hands/redraws')", "check(int(saved['hands'])==2 and int(saved['challenge_redraws'])==item['redraws']<=2,label+' hands/redraws')")
s=s.replace("check(len(cohort)==4,", "check(len(cohort)==5,")
s=s.replace("reputation_bp=total,", "reputation_bp=total,redraws=sum(x['redraws'] for x in n['RESULT']),remaining_redraws=int(run['available_redraws']),")
# New observation changes mechanics identity; compare control behavior via durable payload fields.
extra='''
from itertools import combinations
import math
stats={'graphics':0,'sound':1,'technology':2,'design':3}
def grade(s,h):
    c=10000*(2*min(s,9)+sum(min(x,8) for x in h)+2*min(min(h),8))//66
    g=max(0,10000-1250*max(0,max(h)-min(h)-4))
    return min(c,g),c,g
def project(s,h,cards):
    h=h.copy(); shared=len({x['primary_stat'] for x in cards})==1
    m=3 if shared else 2
    for c in cards:
        s+=c['scope'];h[stats[c['primary_stat']]]+=m*c['primary_value']
        if c['secondary_stat']:h[stats[c['secondary_stat']]]+=m*c['secondary_value']
    return s,h
def contrib(c):
    h=[0.0]*4;h[stats[c['primary_stat']]]+=2*c['primary_value']
    if c['secondary_stat']:h[stats[c['secondary_stat']]]+=2*c['secondary_value']
    return h
def forecast(s,h,hand,cards):
    kept=[c for c in cards if c not in hand]
    means=[sum(contrib(c)[i] for c in cards)/7 for i in range(4)]
    ms=sum(c['scope'] for c in cards)/7
    best=-1
    for mask in range(8):
        cs=[c for j,c in enumerate(kept) if mask&(1<<j)]
        hh=[h[i]+sum(contrib(c)[i] for c in cs)+(4-len(cs))*means[i] for i in range(4)]
        ss=s+sum(c['scope'] for c in cs)+(4-len(cs))*ms
        cc=10000*(2*min(ss,9)+sum(min(x,8) for x in hh)+2*min(min(hh),8))/66
        gg=max(0,10000-1250*max(0,max(hh)-min(hh)-4))
        best=max(best,min(cc,gg))
    return best
audit=[]
for row in results:
    label=row['case']; n=notes[label]; before={}
    for hand in n['HAND']:
        s,h=before.get(hand['offer'],(0,[0]*4))
        cards=hand['visible']; chosen=[c for c in cards if c['token'] in hand['chosen']]
        ps,ph=project(s,h,chosen)
        check(ps==hand['projected']['scope'] and ph==hand['projected']['cores'],label+' independent actual projection')
        ranks=[]
        for indexes in combinations(range(7),4):
            quartet=[cards[i] for i in indexes];ss,hh=project(s,h,quartet);g,c,_=grade(ss,hh)
            spread=max(hh)-min(hh)
            rank=g*1000000+c*100-spread
            if hand['hand']==0:
                rank=g*1000000-sum(max(0,4-x) for x in hh)*1000-spread
                if row['arm'].startswith('retained'):rank=int(forecast(ss,hh,quartet,cards)*1000000)+g*100-spread
            ranks.append((rank,[x['token'] for x in quartet]))
        top=max(x[0] for x in ranks)
        # Floating forecast can differ by a sub-unit rounding error between Python and GDScript.
        actual=next(x for x in ranks if x[1]==hand['chosen'])
        check(top-actual[0]<=2,label+' independently ranked visible choice')
        if hand['hand']==1: check(grade(ps,ph)[0]==max(grade(*project(s,h,[cards[i] for i in ids]))[0] for ids in combinations(range(7),4)),label+' best final quartet')
        before[hand['offer']]=(ps,ph)
    check(len(n['REDRAW'])==len(n['REDRAW_AFTER']),label+' redraw acknowledgments')
    check(len(n['REDRAW'])==sum(x['redraws'] for x in n['RESULT']),label+' actual debits equal saved brief counters')
    for pre,post in zip(n['REDRAW'],n['REDRAW_AFTER']):
        check(pre['offer']==post['offer'] and post['remaining']==pre['budget']-1 and post['used']==pre['used']+1 and post['cycle']==pre['cycle'],label+' one token debit no cycle')
        check(pre['hand']==1 and pre['used']<2 and pre['budget']>0 and pre['before_grade']<10000,label+' bounded legal redraw intent')
    audit.append({'case':label,'hands_checked':len(n['HAND']),'redraws':len(n['REDRAW'])})
priorroot=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-balance-20261024-v1/candidate-v1')
control_parity=[]
for row in results:
    if row['arm'] not in ['balanced','skip']:continue
    old=load(priorroot/'cases'/row['case']/'result.json')
    now=load(bundle/'cases'/row['case']/'result.json')
    check(old['outcome']==now['outcome'] and old['final_rng']==now['final_rng'],row['case']+' prior control outcome/RNG parity')
    if row['ok']:
        oldcp=load(priorroot/'cases'/row['case']/'studio_checkpoint.json')['studio_payload']
        newcp=load(bundle/'cases'/row['case']/'studio_checkpoint.json')['studio_payload']
        check(oldcp==newcp,row['case']+' all saved payload fields match prior control')
    control_parity.append({'case':row['case'],'outcome_and_rng':True,'saved_payload':row['ok']})
'''
s=s.replace("summary=dict(status='PASS'",extra+"\nsummary=dict(status='PASS'")
s=s.replace("results=results,pairs=pairs,", "results=results,pairs=pairs,policy_audit=audit,control_parity=control_parity,")
with (p/'analyze.py').open('x',encoding='utf-8',newline='\n') as f:f.write(s)
print('prepared analysis')
