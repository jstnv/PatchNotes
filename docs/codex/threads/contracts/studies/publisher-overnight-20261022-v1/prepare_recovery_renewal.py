import copy,json,pathlib
h=pathlib.Path(__file__).resolve().parent;t=h.parents[1]
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
src=t/'sims/publisher-overnight-recovery-20261022-v1/cases/miss-recovery-commission'
cp=read(src/'studio_checkpoint.json');run=cp['studio_payload']['run']
assert dict((x['key'],x['value']) for x in run['publisher_investment_capacity_bp'])['sidestreet']=='3000'
config=read(h/'renewal.json');c=config['cases'][0]
c.update(case_id='support-after-recovery',initial={'checkpoint':cp},target_release_count=9)
c['policy']['config']={'schedules':{'9':{'design':2,'alpha':2,'beta':2}},'deal_game':9,'deal_kind':'support'}
p=h/'recovery-renewal.json'
if p.exists():raise RuntimeError('Refusing overwrite')
p.write_text(json.dumps(config,indent=2)+'\n',encoding='utf-8')
print('Prepared I30 renewal from intact full-commission recovery Studio.')
