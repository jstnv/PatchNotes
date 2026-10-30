from pathlib import Path
p=Path(__file__).resolve().parents[4]/'patch-notes/scripts/simulation/development_session.gd'
s=p.read_text(encoding='utf-8')
s=s.replace('"hand_revision":hand.revision,"candidates":candidates','"hand_revision":hand.revision,"can_exit":actions.can_finalize() if include_action_availability else false,"candidates":candidates')
s=s.replace('"pending_playtest":pending}\n\tif include_action_availability:\n\t\tresult["can_exit"]=actions.can_finalize()\n\t\tresult["swap_candidate_ids"]=swaps','"pending_playtest":pending,"swap_candidate_ids":swaps}\n\tif not include_action_availability:\n\t\tresult.erase("can_exit")\n\t\tresult.erase("swap_candidate_ids")')
p.write_text(s,encoding='utf-8',newline='\n')
