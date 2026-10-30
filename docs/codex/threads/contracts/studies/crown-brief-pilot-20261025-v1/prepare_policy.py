from run import *
old=(HERE.parent/'crown-lookahead-20261024-v1/policy.gd').read_text()
# Retain previously checked scoring projection, but no lookahead or redraw experiment.
brief=old[old.index('func brief('):old.index('static func contribution(')]
a=brief.index('\tif not redraw_expected.is_empty():');b=brief.index('\tif not prediction.is_empty():',a)
brief=brief[:a]+brief[b:]
a=brief.index('\tvar planning: Array = []');b=brief.index('\tvar chosen :=',a)
brief=brief[:a]+brief[b:]
a=brief.index('\t\t\t\t\tif int(state.hand_count)==0 and str(config.arm).begins_with("retained")')
b=brief.index('\t\t\t\t\tif config.arm=="completion"',a)
brief=brief[:a]+brief[b:]
brief=brief.replace('\t\t\t\t\tif config.arm!="naive"', '''\t\t\t\t\tif config.arm=="passes":
\t\t\t\t\t\tvar passes := 0
\t\t\t\t\t\tfor card: Dictionary in hand:
\t\t\t\t\t\t\tif card.renewable: passes += 1
\t\t\t\t\t\trank=passes*100000000000+int(score.grade)*1000000+int(score.completion)*100-spread
\t\t\t\t\tif config.arm!="naive"''')
a=brief.index('\tvar prospective :=');b=brief.index('\tprediction = project(state,chosen)',a)
brief=brief[:a]+brief[b:]
brief=brief.replace('\t\t\t\t\tif int(state.hand_count)==0: rank = int(score.grade)*1000000-deficits*1000-spread\n','')
header='''extends RefCounted
const Base = preload("res://scripts/debug/cb2_access.gd")
const STATS = {"graphics":0,"sound":1,"technology":2,"design":3}
var config: Dictionary
var legacy: Callable
var brief_active := false
var briefs := 0
var earned := 0
var offers: Array = []
var prediction: Dictionary = {}
var reached := false
static func factory(cfg: Dictionary) -> Callable:
\tvar p = new()
\tp.config=cfg.duplicate(true)
\tp.earned=int(cfg.get("starting_reputation",0))
\tp.legacy=Base.factory({"arm":"acquire","specialty":"action","label":cfg.label,"extra_hand":true})
\treturn func(view: Dictionary) -> Dictionary: return p.choose(view)
func note(kind: String,data: Dictionary) -> void:
\tdata.case=config.label
\tprint("PN_CB_"+kind+" "+JSON.stringify(data))
func fail(message: String) -> Dictionary:
\tnote("FAIL",{"reason":message})
\treturn {"type":&"crown_study_invalid"}
func choose(view: Dictionary) -> Dictionary:
\tvar rep: int=int(view.publisher_relationships.get(&"crown_quill",{}).get("reputation_bp",0))
\tnote("VIEW",{"sequence":view.sequence,"cycle":view.run_cycle,"phase":view.phase,"release_count":view.releases.size(),"cash":view.cash_cents,"reputation":rep,"view_hash":JSON.stringify(view).sha256_text()})
\tif view.phase==&"contract" and brief_active: return brief(view)
\tif view.phase==&"studio" and config.arm!="skip" and briefs<3 and rep<2000:
\t\tfor offer: Dictionary in view.studio_actions.contract_offers:
\t\t\tif str(offer.kind)!="crown_brief": continue
\t\t\tif offer.offer_id in offers: return fail("reused Brief")
\t\t\toffers.append(offer.offer_id)
\t\t\tbrief_active=true
\t\t\tnote("ACCEPT",{"offer":offer.offer_id,"source":offer.quote.source_release_id,"cycle":view.run_cycle,"cash":view.cash_cents,"prior_reputation":rep,"view_hash":JSON.stringify(view).sha256_text()})
\t\t\treturn {"type":&"accept_contract","payload":offer}
\treturn legacy.call(view)
'''
(HERE/'policy.gd').write_text(header+brief,encoding='utf-8')
write(HERE/'policy-pins.json',dict(policy=sha(HERE/'policy.gd'),plan=sha(HERE/'PLAN.md')))
print('Prepared fixed five-arm policy; no Brief redraw code')
