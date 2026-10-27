"""Freeze the accepted P2/P3 validators; no historical identity is rewritten."""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[4]
BEFORE=Path('C:/Users/64jus/AppData/Local/Temp/pn-p4-execution-20261024-v1/pre-p4-accepted/project')
OUT=ROOT/'patch-notes/scripts/contracts/pre_support'
def main():
    OUT.mkdir(exist_ok=False)
    files={'studio.gd':'scripts/persistence/studio_checkpoint.gd','schema.gd':'scripts/persistence/checkpoint_schema.gd','finance.gd':'scripts/finance/studio_finance_ledger.gd','commission.gd':'scripts/contracts/publisher_commission_trial.gd','relationships.gd':'scripts/contracts/publisher_relationship_rules.gd'}
    manifest={}
    for leaf,rel in files.items():
        raw=(BEFORE/rel).read_bytes();s=raw.decode('utf8')
        s='\n'.join(x for x in s.split('\n') if not x.startswith('class_name '))
        if leaf=='studio.gd':
            s=s.replace('extends RefCounted','extends RefCounted\nconst FrozenSchema := preload("res://scripts/contracts/pre_support/schema.gd")\nconst FrozenFinance := preload("res://scripts/contracts/pre_support/finance.gd")\nconst FrozenCommission := preload("res://scripts/contracts/pre_support/commission.gd")\nconst FrozenRelationships := preload("res://scripts/contracts/pre_support/relationships.gd")',1)
            s=s.replace('CheckpointSchema.','FrozenSchema.').replace('StudioFinanceLedger.','FrozenFinance.').replace('RunState.Commission.','FrozenCommission.').replace('RunState.RelationshipRules.','FrozenRelationships.')
        if leaf=='schema.gd':
            s=s.replace('extends RefCounted','extends RefCounted\nconst FrozenFinance := preload("res://scripts/contracts/pre_support/finance.gd")',1)
            s=s.replace('StudioFinanceLedger.','FrozenFinance.').replace('res://scripts/contracts/publisher_commission_trial.gd','res://scripts/contracts/pre_support/commission.gd')
        if leaf=='relationships.gd':s=s.replace('res://scripts/contracts/publisher_commission_trial.gd','res://scripts/contracts/pre_support/commission.gd')
        target=OUT/leaf;target.write_text(s,encoding='utf8',newline='')
        manifest[leaf]={'original_path':rel,'original_sha256':hashlib.sha256(raw).hexdigest(),'frozen_sha256':hashlib.sha256(target.read_bytes()).hexdigest()}
    (Path(__file__).parent/'predecessor-source.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf8')
    print(json.dumps({'frozen_files':len(files),'source':'accepted P2/P3 snapshot; explicit class/reference adaptations only'}))
if __name__=='__main__':main()
