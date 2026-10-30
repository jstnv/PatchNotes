from pathlib import Path
import sys
p=Path(__file__).resolve().parent
s=(p/'instrument.py').read_text(encoding='utf-8')
s=s.replace("'before-'", "'stage4-before-'")
s=s.replace("'scripts/ui/feature_store.gd': ['_refresh'],", "'scripts/ui/feature_store.gd': ['_refresh'], 'scripts/market/rival_world.gd': ['_choice'], 'scripts/simulation/development_session.gd': ['observation','execute'],")
s=s.replace("'complete_productive_action']", "'complete_productive_action','_plan_productive_cycle']")
exec(compile(s,__file__,'exec'))
