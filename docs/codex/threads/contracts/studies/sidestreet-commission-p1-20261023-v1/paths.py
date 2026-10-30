from pathlib import Path
H=Path(__file__).resolve().parent;T=H.parents[1]
def bundle(stage,tag='v3'):
    suffix='-stable1' if stage=='delivery' and tag=='v3' else ''
    return T/f'sims/sidestreet-commission-p1-{stage}-20261023-{tag}{suffix}'
