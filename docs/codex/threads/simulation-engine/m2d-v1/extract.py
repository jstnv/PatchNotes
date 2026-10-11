from pathlib import Path
import re, shutil
ROOT=Path(__file__).resolve().parents[5]
S=ROOT/'patch-notes/scripts'
HERE=Path(__file__).resolve().parent

def read(p): return p.read_text(encoding='utf-8')
def write(p,t): p.write_text(t,encoding='utf-8',newline='\n')
def function(t,name):
    return re.search(r'^func '+name+r'\(.*?(?=^func |\Z)',t,re.M|re.S).group().rstrip()+'\n'
def replace(t,name,new): return t.replace(function(t,name).rstrip(),new.rstrip())

shutil.copyfile(ROOT/'docs/codex/findings/card-presentation-v2/m2d-oracle-v1/fit.json.oracle.digests.json',S/'debug/fixtures/development_replay_oracle_digests.json')
original={p:read(HERE/f'{p}_phase_oracle.gd') for p in ['design','alpha','beta']}

# Move finalization arithmetic and historical validation verbatim, replacing the
# autoload lookup with an explicit immutable definition provider.
header='''## Development boundary rules shared by scenes and the replay runner.
## The catalog is a RefCounted provider containing canonical immutable CardData.
extends RefCounted

const PERFECT_PRODUCTION_THRESHOLD := 0.05
const PERFECT_BUG_PRESSURE_MULTIPLIER := 0.80
const BUG_VARIANCE_NEGATIVE_TWO_THRESHOLD := 0.08
const BUG_VARIANCE_NEGATIVE_ONE_THRESHOLD := 0.25
const BUG_VARIANCE_ZERO_THRESHOLD := 0.75
const BUG_VARIANCE_POSITIVE_ONE_THRESHOLD := 0.92
const FINITE_IDS = preload("res://scripts/simulation/beta_hand_command.gd").FINITE_IDS
var _project_state: ProjectState
var _exhausted_card_ids: Dictionary[StringName,bool] = {}
var _exhausted_feature_ids: Dictionary[StringName,bool] = {}
var catalog: RefCounted

'''
names={'design':['_build_design_feature_history','_is_valid_design_feature_history','_calculate_design_finalization','_is_perfect_production','_are_core_scores_perfect','_get_bug_variance'], 'alpha':['_build_alpha_feature_history','_calculate_alpha_finalization','_get_alpha_bug_variance'], 'beta':['_build_launch_warnings','_validate_exhausted_beta_ids','_validate_feature_histories']}
for phase, funcs in names.items():
    for name in funcs:
        f=function(original[phase],name)
        f=f.replace('get_node("/root/CardDatabase")','catalog').replace('get_node_or_null("/root/CardDatabase")','catalog').replace('database: Node','database: RefCounted')
        header+=f+'\n\n'
write(S/'simulation/development_finalization.gd',header)

# Extract redraw selection. It receives candidate slots, never views.
body=function(original['alpha'],'_plan_selected_redraw')
body=body.replace('func _plan_selected_redraw(controlled_rolls: Array[float])','func core_redraw_plan(slots: Array[int], controlled_rolls: Array[float])')
body=body.replace('Array[CardView]','Array[int]').replace('_selected_card_views.size()','slots.size()').replace('var view := _selected_card_views[index]\n\t\tvar old_card := view.card_data','var slot := slots[index]\n\t\tvar old_card: CardData = hand._candidate_cards[slot]').replace('failed_features.append(view)','failed_features.append(slot)')
for name in ['_available_features','_candidate_cards','_pass_definitions','_deal_rng','_calculate_candidate_weight','get_priority_distribution','_select_weighted_entry']:
    body=re.sub(r'(?<![\w.])'+name+r'\b','hand.'+name,body)
# Prepend the data-only tutorial guarantee.
body=body.replace('\n\tvar cards:', '''
\tif phase == &"design":
\t\tvar tutorial: FirstGameTutorial = hand._get_first_game_tutorial()
\t\tif tutorial != null:
\t\t\tvar selected: Array[CardData] = []
\t\t\tfor slot in slots: selected.append(hand._candidate_cards[slot])
\t\t\tvar guided := tutorial.guaranteed_redraw_cards(hand._candidate_cards,selected,hand._pass_definitions)
\t\t\tif guided != null: return {"valid":true,"cards":[guided] as Array[CardData],"failed_features":[],"guided_redraw":true}
\tvar cards:''',1)
write(HERE/'redraw-method.txt',body)

# Split the existing tutorial UI adapter from its rule.
p=S/'first_game_tutorial.gd'; t=read(p)
f=function(t,'guaranteed_redraw')
data=f.replace('func guaranteed_redraw(','func guaranteed_redraw_cards(').replace('selected: Array[CardView]','selected: Array[CardData]').replace('selected[0].card_data','selected[0]')
adapter='''func guaranteed_redraw(current: Array[CardData], selected: Array[CardView], passes: Array[CardData]) -> CardData:
\tvar cards: Array[CardData] = []
\tfor view in selected: cards.append(view.card_data)
\treturn guaranteed_redraw_cards(current,cards,passes)
'''
write(p,replace(t,'guaranteed_redraw',adapter)+'\n\n'+data)
print('Extracted finalization rules and data-only redraw planner')
