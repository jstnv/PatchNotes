from pathlib import Path
import re
OUT=Path(__file__).resolve().parent
source=(OUT/'before-scripts__run_state.gd').read_text(encoding='utf-8')
parts=['extends RunState\n# Frozen pre-fix individual quote implementation, test oracle only.\n']
for name in ['get_feature_research_quote','get_primitive_reserve_offer','get_feature_store_offer','_plan_productive_cycle','research_feature']:
 match=re.search(r'^func '+name+r'\(.*?(?=^func |^##|\Z)',source,re.M|re.S)
 assert match,name
 parts.append(match.group(0))
(OUT.parents[3]/'patch-notes/scripts/debug/fixtures/store_before_research_latency.gd').write_text('\n'.join(parts),encoding='utf-8')
