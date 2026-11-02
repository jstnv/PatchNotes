## Funded verifier setup only: current real creation/FIFO APIs; no gameplay authority.
extends RefCounted
static func create_owned(run: RunState,label: String) -> bool:
 var created:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote(label))
 return created.get("ok",false) and run.select_engine(created.engine_id)
static func acquire(run: RunState,id: StringName) -> bool:
 if run.owns_feature(id):return true
 var graph:=FeatureStoreCatalog.graph(run._feature_definitions,run._feature_offers)
 if graph.has("error") or not graph.parents.has(id):return false
 for parent: StringName in graph.parents[id]:
  if not acquire(run,parent):return false
 return run.admit_feature_research(run.get_feature_research_quote(id)) and run.research_feature(run.get_feature_research_quote(id))

## Bounded public-candidate choice; model preflight reads only, all commits use commands.
static func tokens(session: RefCounted,preferred: Array=[]) -> Array[int]:
 var hand: RefCounted=session.development.hand
 var cards: Array=session.observation().development.candidates.duplicate()
 cards.sort_custom(func(a,b):
  if preferred.has(StringName(a.definition))!=preferred.has(StringName(b.definition)):return preferred.has(StringName(a.definition))
  if (a.type=="feature")!=(b.type=="feature"):return a.type=="feature"
  return int(a.token)<int(b.token))
 for count in range(mini(4,cards.size()),0,-1):
  for mask in range(1,1<<cards.size()):
   var ids: Array[int]=[];var selected: Array[CardData]=[]
   for slot in cards.size():
    if mask&(1<<slot):
     ids.append(int(cards[slot].token));selected.append(session.catalog.get_card(StringName(cards[slot].definition)))
   if ids.size()==count and hand.calculate_base(selected).valid and hand.can_play_pass_budget(selected):return ids
 return []
static func current_choice(session: RefCounted,choice: Dictionary,preferred: Array=[]) -> Dictionary:
 if session.in_studio or session.contract!=null or session.development.phase_index==2:return choice
 if choice.get("type")!=&"development" or choice.payload.request.type!=&"play":return choice
 var ids:=tokens(session,preferred)
 return {"type":&"development","payload":{"request":session.development.command(&"play",{"candidate_ids":ids})}} if not ids.is_empty() else {"type":&"development","payload":{"request":session.development.command(&"request_exit")}}
