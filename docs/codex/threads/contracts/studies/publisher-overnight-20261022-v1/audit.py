"""Audit retained legal runs and their exact-cent Studio records. No game writes."""
import hashlib,json,pathlib,sys
H=pathlib.Path(__file__).resolve().parent; T=H.parents[1]; S=T/'sims'
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
mapping=lambda a:{x['key']:x['value'] for x in a}
failures=[]; checks=0
def check(ok,where):
    global checks
    checks+=1
    if not ok:failures.append(where)
rows=[]; data={}; retained={}
for bundle in ['weak-pairs','renewal','renewal-reduced','recovery','revival','recovery-renewal']:
    folder=S/f'publisher-overnight-{bundle}-20261022-v1'
    report=read(folder/'run-report.json')
    retained[bundle]={k:report.get(k) for k in ['ok','runner_sha256','godot_sha256','godot_version','frozen_source_identity']}
    retained[bundle]['variant']={k:report['variant'][k] for k in ['id','base_identity','creation_identity','candidate_identity','canonical_identity','baseline_drift']}
    for p in sorted((folder/'cases').iterdir()):
        r=read(p/'result.json'); tel=read(p/'telemetry.json'); samples=tel['samples']; name=r['case_id'];data[name]=(r,tel)
        check(r['source_identity']=='b53d9a31b1f54155324e3ec942d86baedd7facae9adf519fd644690326fc8b07',name+':mechanics')
        check(hashlib.sha256((p/'telemetry.json').read_bytes()).hexdigest()==r['telemetry_sha256'],name+':telemetry_hash')
        check(tel['initial_state']==r['initial_state'] and tel['final_state']==r['final_state'],name+':state_digests')
        check(r['ok'] and r['outcome']['in_studio'],name+':declared_finish')
        check(r['commands']<=r['max_commands'] and r['accepted_commands']==r['commands'],name+':command_bound')
        check(int(samples[-1]['cash_cents'])==int(r['outcome']['cash_cents']),name+':cash_sample')
        row={'case':name,'bundle':bundle,'commands':r['commands'],'cycle':r['final_run_cycle'],'releases':r['final_release_count'],
            'cash_cents':r['outcome']['cash_cents'],'fans':r['outcome']['fans'],'max_observed_arrears':max(int(x['overdue_cents']) for x in samples),
            'checkpoint_available':bool(r['artifacts']['studio_checkpoint']),'initial_state':r['initial_state']}
        missing_expected=name in ['second-support','second-support-minimal','support-after-recovery']
        check(row['checkpoint_available'] != missing_expected,name+':expected_checkpoint_acceptance')
        if not row['checkpoint_available']:
            row['adoption_failure']='Completed Studio has no valid checkpoint; frozen validator forbids more than one historical support deal.'
            rows.append(row);continue
        cp=read(p/'studio_checkpoint.json'); run=cp['studio_payload']['run']; fin=run['studio_finance']; rights=mapping(run['support_rights']);deals=mapping(run['support_deals']);events=mapping(run['support_events'])
        row['reputation']=mapping(run['publisher_reputation_bp']);row['investment']=mapping(run['publisher_investment_capacity_bp'])
        row['support_events']=events;row['support_rights']=rights
        expected_earned=expected_settled=0
        for title in r['outcome']['releases']:
            title_id=title['id'];raw=int(title['sales']['entitlement_cents'])
            if title['metadata'].get('owner','studio')=='publisher': earned=settled=0
            elif title_id in rights:
                rr=rights[title_id];earned=int(rr['studio_earned_cents']);settled=int(rr['studio_settled_cents'])
                check(raw==int(rr['raw_net_cents']) and earned+int(rr['publisher_recoup_cents'])==raw,name+':title_rights:'+title_id)
                check(0<=settled<=earned,name+':settled_limit:'+title_id)
            else:earned=raw;settled=int(title['sales']['settled_cents'])
            expected_earned+=earned;expected_settled+=settled
        transactions=fin['transactions'];monthly=fin['monthly_rows']
        check(expected_earned==sum(int(x['amount_cents']) for x in transactions if x['kind']=='sales_earned'),name+':journal_earned')
        check(expected_settled==sum(int(x['amount_cents']) for x in transactions if x['kind']=='sales_settlement'),name+':journal_settled')
        check(expected_earned==sum(int(x['sales_net_earned_cents']) for x in monthly),name+':monthly_earned')
        check(expected_settled==sum(int(x['sales_settled_cents']) for x in monthly),name+':monthly_settled')
        check(expected_earned-expected_settled==int(fin['unsettled_sales_net_cents']),name+':unsettled')
        check(sum(int(x['cash_delta_cents']) for x in transactions)==int(fin['cash_cents'])==int(r['outcome']['cash_cents']),name+':cash_journal')
        for m in monthly:
            check(int(m['operating_revenue_cents'])==int(m['sales_net_earned_cents'])+int(m['other_income_cents']),name+':support_excluded_operating:'+m['month'])
        for title_id,term in deals.items():
            receipts=[x for x in transactions if x['kind']=='publisher_support_advance' and x['source_id']==term['quote_id']]
            check(len(receipts)==1 and int(receipts[0]['amount_cents'])==int(term['funding_cents']),name+':once_funding:'+title_id)
        for event in events.values():
            term=deals[event['project_id']]
            qualified=int(event['review_tenths'])>=int(term['review_target_tenths']) and int(event['actual_units'])>=int(term['month3_units_target'])
            check(event['passed']==qualified and int(event['investment_award_bp'])==(1000 if qualified else 0),name+':assessment')
        if name.startswith('weak'):
            game5=r['outcome']['releases'][4]
            row['game5']={'review':game5['metadata']['review']['final_review'],'launch_cycle':game5['metadata']['release_cycle'],
                'raw_net_cents':game5['sales']['entitlement_cents'],'units':game5['sales']['earned_units'],'age':game5['sales']['total_earned_cycles']}
        rows.append(row)
pairs=[]
for n in [2,3]:
    a,ta=data[f'weak{n}-support'];b,tb=data[f'weak{n}-self']
    for k in ['initial_state','initial_rng','source_identity','initial_run_cycle','initial_release_count','target_release_count','max_commands']:
        check(a[k]==b[k],f'pair{n}:{k}')
    check(read(S/'publisher-overnight-weak-pairs-20261022-v1/cases'/f'weak{n}-support/initial.json')==read(S/'publisher-overnight-weak-pairs-20261022-v1/cases'/f'weak{n}-self/initial.json'),f'pair{n}:whole_initial')
    maps=[]
    for tel in [ta,tb]:
        d={}
        for sample in tel['samples']:d[int(sample['run_cycle'])]=sample
        maps.append(d)
    common=[]
    for cycle in sorted(maps[0].keys()&maps[1].keys()):
        l,rr=maps[0][cycle],maps[1][cycle]
        common.append({'cycle':cycle,'support_minus_self_cash_cents':int(l['cash_cents'])-int(rr['cash_cents']),'fans_difference':int(l['fans'])-int(rr['fans'])})
    pairs.append({'pair':n,'endpoint_cycle_equal':a['final_run_cycle']==b['final_run_cycle'],'matched_cycles':common})
before=read(S/'publisher-overnight-weak-pairs-20261022-v1/cases/weak2-support/studio_checkpoint.json')['studio_payload']['run']
after=read(S/'publisher-overnight-revival-20261022-v1/cases/post-cutoff-revival/studio_checkpoint.json')['studio_payload']['run']
title='contracts-r20-sports-1112:project:5';x=mapping(before['support_rights'])[title];y=mapping(after['support_rights'])[title]
revival={'before_age':int(x['earning_cycles']),'after_age':int(y['earning_cycles']),'raw_gain_cents':int(y['raw_net_cents'])-int(x['raw_net_cents']),
         'studio_earned_gain_cents':int(y['studio_earned_cents'])-int(x['studio_earned_cents']),'recoup_before':int(x['publisher_recoup_cents']),'recoup_after':int(y['publisher_recoup_cents'])}
check(revival['raw_gain_cents']>0 and revival['raw_gain_cents']==revival['studio_earned_gain_cents'] and revival['recoup_before']==revival['recoup_after']<87500,'revival:uncapped_expiry')
check(before['support_events']==after['support_events'] and before['publisher_investment_capacity_bp']==after['publisher_investment_capacity_bp'],'revival:no_retroactive_reward')
out={'audit_script_sha256':hashlib.sha256(pathlib.Path(__file__).read_bytes()).hexdigest(),'checks':checks,'failures':failures,
     'source_reports':retained,'cases':rows,'pairs':pairs,'revival':revival,
     'scope':'Artifact and exact-cent accounting audit. Expected checkpoint failures retained; no UI, native disk or balance approval.'}
p=H/sys.argv[1]
if p.exists():raise RuntimeError('Refusing overwrite')
p.write_text(json.dumps(out,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'checks':checks,'failures':failures,'cases':len(rows),'checkpoint_failures':[r['case'] for r in rows if not r['checkpoint_available']],'revival':revival}))
if failures:raise SystemExit(1)
