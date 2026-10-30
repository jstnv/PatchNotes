"""Independent Python audit of public-pool sampling and conservative redraw."""
from itertools import combinations
from math import isclose
STATS={'graphics':0,'sound':1,'technology':2,'design':3}
QUARTETS=list(combinations(range(7),4))
def grade(scope,cores):
    c=10000*(2*min(scope,9)+sum(min(x,8) for x in cores)+2*min(min(cores),8))//66
    g=max(0,10000-1250*max(0,max(cores)-min(cores)-4))
    return min(c,g),c
def project(scope,cores,cards):
    cores=cores.copy();mult=3 if len({c['primary_stat'] for c in cards})==1 else 2
    for c in cards:
        scope+=c['scope'];cores[STATS[c['primary_stat']]]+=mult*c['primary_value']
        if c['secondary_stat']:cores[STATS[c['secondary_stat']]]+=mult*c['secondary_value']
    return scope,cores
def best(scope,cores,cards):
    ranks=[]
    for indexes in QUARTETS:
        s,h=project(scope,cores,[cards[i] for i in indexes]);g,c=grade(s,h)
        ranks.append((g*1000000+c*100-max(h)+min(h),g,indexes))
    return max(ranks,key=lambda x:x[0])
def groups(pool,visible,kind='',excluded=''):
    reserved={c['definition'] for c in visible if not c['renewable']}
    result=[[] for _ in range(4)]
    for c in pool:
        if c['definition']==excluded or c['card_type']=='feature' and c['definition'] in reserved:continue
        if kind and c['card_type']!=kind:continue
        result[STATS[c['primary_stat']]].append(c)
    return [sorted(g,key=lambda c:c['definition']) for g in result]
def priorities(row):return [int(row['priorities'][str(i)]) for i in range(4)]
def sample(row):
    x=20261024;out=[];weights=priorities(row)
    for scenario in range(32):
        reserved=row['visible'].copy();cards=[]
        for slot in range(4):
            x=x*16807%2147483647;u=x/2147483647
            x=x*16807%2147483647;v=x/2147483647
            gs=groups(row['pool'],reserved);total=sum(weights[i] for i,g in enumerate(gs) if g)
            target=u*total;acc=0
            for i,g in enumerate(gs):
                if not g:continue
                acc+=weights[i]
                if target<acc:
                    card=g[min(int(v*len(g)),len(g)-1)].copy();break
            card['token']=-1-slot;cards.append(card);reserved.append(card)
        out.append(cards)
    return out
def audit(notes,check):
    rows=[]
    for label,n in notes.items():
        for row in n['LOOKAHEAD']:
            check(sample(row)==row['samples'],label+' exact independently generated public-pool samples')
            check(all((c['card_type']=='pass')==c['renewable'] for c in row['pool']),label+' finite/public pool premise')
            check(len({c['definition'] for c in row['pool']})==len(row['pool']),label+' unique public definitions')
            initial=[row['cores'][str(i)] for i in range(4)]
            for indexes,r in zip(QUARTETS,row['ranking']):
                hand=[row['visible'][i] for i in indexes]
                s,h=project(row['scope'],initial,hand)
                kept=[c for i,c in enumerate(row['visible']) if i not in indexes]
                grades=[best(s,h,kept+sample)[1] for sample in row['samples']]
                total=sum(grades);full=grades.count(10000);positive=sum(g>0 for g in grades);spread=max(h)-min(h)
                expected={'tokens':[c['token'] for c in hand],'total':total,'full':full,'positive':positive,'spread':spread,'rank':total*1000000+full*10000+positive*100-spread}
                check(r==expected,label+' exact sampled rank for actual opening quartet')
            selected=next(h for h in n['HAND'] if h['offer']==row['offer'] and h['hand']==0)
            top=max(row['ranking'],key=lambda r:r['rank'])
            check(selected['chosen']==top['tokens'],label+' selected maximal sampled expectation')
            rows.append({'case':label,'offer':row['offer'],'planning_ms':row['elapsed_ms'],'chosen':top['tokens'],'expected_grade':top['total']/32,'sample_full':top['full'],'sample_positive':top['positive']})
        for row in n['SAFE_DECISION']:
            cards=row['visible'];cores=[row['cores'][str(i)] for i in range(4)];weights=priorities(row)
            ranked=best(row['scope'],cores,cards)
            protected=[cards[i]['token'] for i in ranked[2]]
            check(row['before_grade']==ranked[1] and row['decision']['protected']==protected,label+' protects actual best quartet')
            alternatives=[]
            for slot,c in enumerate(cards):
                if c['token'] in protected:continue
                kind=next(p['card_type'] for p in row['pool'] if p['definition']==c['definition'])
                gs=groups(row['pool'],cards,kind,c['definition']);total=sum(weights[i] for i,g in enumerate(gs) if g)
                if not total:continue
                outcomes=[];expected=0
                for i,g in enumerate(gs):
                    for replacement in g:
                        p=weights[i]/total/len(g);hyp=cards.copy();hyp[slot]=replacement
                        score=best(row['scope'],cores,hyp)[1]
                        check(score>=ranked[1],label+' every legal conservative replacement preserves best grade')
                        outcomes.append({'definition':replacement['definition'],'probability':p,'grade':score});expected+=p*score
                alternatives.append({'token':c['token'],'expected':expected,'outcomes':outcomes})
            actual=row['decision']['options']
            check(len(actual)==len(alternatives),label+' legal redraw option count')
            value=float(row['before_grade']);token=-1
            for a,b in zip(actual,alternatives):
                check(a['token']==b['token'] and isclose(a['expected'],b['expected'],abs_tol=1e-7),label+' exact redraw expectation')
                check(len(a['outcomes'])==len(b['outcomes']),label+' replacement count')
                for x,y in zip(a['outcomes'],b['outcomes']):
                    check(x['definition']==y['definition'] and x['grade']==y['grade'] and isclose(x['probability'],y['probability'],abs_tol=1e-12),label+' legal replacement probability and grade')
                if b['expected']>value+1e-9:value=b['expected'];token=b['token']
            check(row['decision']['token']==token and isclose(row['decision']['expected'],value,abs_tol=1e-7),label+' positive-benefit redraw selection')
        safe=[r for r in n['REDRAW'] if r.get('safe')]
        check(len(safe)==len(n['SAFE_MONOTONE']),label+' all safe redraws evaluated afterwards')
        for before,after in zip(safe,n['SAFE_MONOTONE']):
            check(before['offer']==after['offer'] and before['before_grade']==after['before']<=after['after'],label+' actual safe redraw monotonicity')
            check(before['token'] not in before['decision']['protected'],label+' only unselected token redrawn')
    return rows
