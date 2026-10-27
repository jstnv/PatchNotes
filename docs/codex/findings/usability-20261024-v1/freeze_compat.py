"""Freeze the accepted P4 reader before expanding rules; explicit local wiring only."""
from pathlib import Path
from work import ROOT, HOME, sim

target=ROOT/'patch-notes/scripts/persistence/pre_usability'
target.mkdir(exist_ok=False)
base=HOME/'baseline/project/scripts'
items={'studio.gd':'persistence/studio_checkpoint.gd','schema.gd':'persistence/checkpoint_schema.gd',
       'finance.gd':'finance/studio_finance_ledger.gd','bank.gd':'finance/bank_loan.gd','traits.gd':'studio_traits.gd'}
manifest={}
for leaf,rel in items.items():
    source=base/rel
    text=source.read_text(encoding='utf8')
    if text.startswith('class_name '): text=text.split('\n',1)[1]
    if leaf=='studio.gd':
        for old,new in [('CheckpointSchema','FrozenSchema'),('StudioFinanceLedger','FrozenFinance'),('StudioTraits','FrozenTraits')]: text=text.replace(old,new)
        text=text.replace('extends RefCounted','extends RefCounted\nconst FrozenSchema := preload("res://scripts/persistence/pre_usability/schema.gd")\nconst FrozenFinance := preload("res://scripts/persistence/pre_usability/finance.gd")\nconst FrozenTraits := preload("res://scripts/persistence/pre_usability/traits.gd")',1)
    if leaf=='finance.gd': text=text.replace('res://scripts/finance/bank_loan.gd','res://scripts/persistence/pre_usability/bank.gd')
    (target/leaf).write_text(text,encoding='utf8')
    manifest[leaf]={'baseline':rel,'baseline_sha256':sim.sha(source),'adapted_sha256':sim.sha(target/leaf)}
sim.write_json(Path(__file__).with_name('frozen-reader.json'),manifest)
