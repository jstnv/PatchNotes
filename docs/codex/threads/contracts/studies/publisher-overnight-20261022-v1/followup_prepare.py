import copy, json, pathlib
HERE=pathlib.Path(__file__).resolve().parent
THREAD=HERE.parents[1]
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
def write(name,obj):
    p=HERE/name
    if p.exists(): raise RuntimeError('Refusing overwrite')
    p.write_text(json.dumps(obj,indent=2)+'\n',encoding='utf-8')
renew=read(HERE/'renewal.json')
reduced=copy.deepcopy(renew)
c=reduced['cases'][0]; c['case_id']='second-support-minimal'; c['max_commands']=40
c['policy']['config']['schedules']['7']={'design':1,'alpha':1,'beta':1}
write('renewal-reduced.json',reduced)
cp=read(THREAD/'sims/publisher-overnight-weak-pairs-20261022-v1/cases/weak2-support/studio_checkpoint.json')
base={'schema_version':'1','case_id':'miss-recovery-commission','initial':{'checkpoint':cp},'max_commands':100,'target_release_count':8,'telemetry':True,
      'policy':{'config':{'schedules':{'8':{'design':5,'alpha':7,'beta':6}},'deal_game':8,'deal_kind':'commission'}}}
write('recovery.json',{'schema_version':'1','policy':renew['policy'],'cases':[base]})
revive=copy.deepcopy(base);revive['case_id']='post-cutoff-revival';revive['max_commands']=80
revive['policy']['config']={'schedules':{'8':{'design':2,'alpha':2,'beta':2}},'deal_game':-1,'deal_kind':'','revive_release_index':4}
pol=copy.deepcopy(renew['policy']);pol['script']='revival_policy.gd';pol['version']='2'
write('revival.json',{'schema_version':'1','policy':pol,'cases':[revive]})
text=(HERE/'policy.gd').read_text()
text=text.replace('var _reported: Dictionary = {}','var _reported: Dictionary = {}\nvar _revive_index := -1\nvar _revived := false\nvar _observed_ages: Dictionary = {}')
text=text.replace('p._deal_game = int(config.get("deal_game", -1))','p._deal_game = int(config.get("deal_game", -1))\n\tp._revive_index = int(config.get("revive_release_index", -1))')
needle='\tvar game: int = view.releases.size() + 1'
extra='''\tif _revive_index >= 0 and _revive_index < view.releases.size():
\t\tvar title: Dictionary = view.releases[_revive_index]
\t\tvar age := int(title.sales.total_earned_cycles)
\t\tif not _observed_ages.has(age):
\t\t\t_observed_ages[age] = true
\t\t\tprint("PN_REVIVAL_RIGHTS " + JSON.stringify({"cycle":view.run_cycle,"age":age,"raw_net":title.sales.entitlement_cents,"units":title.sales.earned_units,"rights":title.support_rights}))
\t\tif view.phase == &"studio" and not _revived:
\t\t\t_revived = true
\t\t\tif not title.campaign.get("can_purchase",false): return {"type":&"declared_campaign_unavailable"}
\t\t\treturn {"type":&"campaign","payload":{"release_id":title.id}}
'''
text=text.replace(needle,extra+needle)
p=HERE/'revival_policy.gd'
if p.exists(): raise RuntimeError('Refusing policy overwrite')
p.write_text(text,encoding='utf-8')
print('Prepared reduced renewal, recovery commission, and declared post-cutoff revival.')
