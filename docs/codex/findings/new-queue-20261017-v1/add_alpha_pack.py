from run_checks import *
p=ROOT/'patch-notes/data/feature_store_ledger.json'
old=sim.read_json(p)
assert len(old)==11
rows=[]
for id,name,dept,primary,pv,secondary,sv,parents in [
 ('turn_based_combat','Turn-Based Combat','gameplay','design',5,'',0,['general_combat']),
 ('character_classes','Character Classes','gameplay','technology',2,'design',3,['general_combat','save_files']),
 ('character_development','Character Development','story','design',5,'',0,['character_backstories','save_files']),
 ('branching_dialogue','Branching Dialogue','story','technology',2,'design',3,['dialogue','branching_nodes'])]:
 rows.append(dict(id=id,name=name,type='feature',phase='alpha',department=dept,primary_stat=primary,primary_value=pv,secondary_stat=secondary,secondary_value=sv,scope=2,renewable=False,artwork='',purchase_parent=parents[0],purchase_parents=parents,gameplay_features_required=0,base_price_cents=170000))
sim.write_json(BASE/'alpha-pack-content.json',{'before_sha256':sim.sha(p),'existing':old,'added':rows})
# Keep the existing ledger bytes and append only the selected four rows.
text=p.read_bytes().decode('utf-8');newline='\r\n' if '\r\n' in text else '\n'
addition=json.dumps(rows,indent=2,ensure_ascii=False)[2:-2].replace('\n',newline)
p.write_bytes((text.rstrip()[:-1].rstrip()+','+newline+addition+newline+']'+newline).encode())
assert sim.read_json(p)==old+rows
