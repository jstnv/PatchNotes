from pathlib import Path
import json, os, subprocess
BASE=Path(__file__).resolve().parent; ROOT=BASE.parents[3]
OUT=BASE/'age-probe-v4';OUT.mkdir(exist_ok=False)
old=ROOT/'docs/codex/findings/queue-completion-20261011-v1/education_distress_plan.gd'
text=old.read_text()
text=text.replace('for reserve: int in [40000]:','for reserve: int in [150000]:')
text=text.replace('if int(finance.get("total_overdue_cents",0)) > 0: observed_distress = true','''for bill: Dictionary in session.run.get_studio_finance_snapshot().obligations:
				if bill.expense_type==&"student_loan" and ((bill.unpaid_cents>0 and int(view.run_cycle)-bill.due_cycle>=2) or bill.recovery_overdue_cycles>=2): observed_distress=true''')
start=text.index('\t\t\t\t\tif debt_checkpoint.is_empty():')
end=text.index('\n\t\t\t\telif view.phase',start)
text=text[:start]+'''\t\t\t\t\tdebt_checkpoint=view.duplicate(true)
					var saved := StudioCheckpoint.new().capture(session.run)
					FileAccess.open(OS.get_environment("PN_PROBE_OUTPUT")+"-"+str(reserve)+"-checkpoint.json",FileAccess.WRITE).store_string(CheckpointCodec.new().envelope(saved))
					stop="aged_education_studio";break'''+text[end:]
text=text.replace('range(180)','range(120)')
text=text.replace('var request := session.command(next.type,next.get("payload",{}))','''if not observed_distress and int(view.run_cycle)>=50:
				if view.phase==&"studio": next=fixture.call(view)
				elif next.type==&"development" and next.payload.request.type==&"play":
					var cards: Array=view.development.candidates
					var best: Array[int]=[];var best_distance:=9223372036854775807
					var target:=7000 if int(view.run_cycle)==51 else 0
					for a in range(cards.size()):
						for b in range(a+1,cards.size()):
							for c in range(b+1,cards.size()):
								for d in range(c+1,cards.size()):
									var hand: Array[CardData]=[];var tokens: Array[int]=[]
									for i in [a,b,c,d]: hand.append(root.get_node("CardDatabase").get_card(StringName(cards[i].definition)));tokens.append(int(cards[i].token))
									var cost:=session.run.primitive_feature_hand_cost_cents(hand,session.project_id())
									if cost>=0 and cost<=int(view.cash_cents) and absi(cost-target)<best_distance: best=tokens;best_distance=absi(cost-target)
					if not best.is_empty(): next.payload.request=session.development.command(&"play",{"candidate_ids":best})
			var request := session.command(next.type,next.get("payload",{}))''')
script=OUT/'legal_age_route.gd';script.write_text(text)
env=os.environ.copy()
for key in ('APPDATA','LOCALAPPDATA'):
 p=ROOT/'.codex-godot-temp/qv2-age-probe'/key;p.mkdir(parents=True,exist_ok=True);env[key]=str(p)
env['PN_SAVED_EVIDENCE']=str(ROOT/'docs/codex/findings/queue-completion-20261011-v1/checkpoints/education-g3-studio/checkpoint.4.json')
env['PN_PROBE_OUTPUT']=str(OUT/'routes.json')
cmd=[r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe','--headless','--audio-driver','Dummy','--path',str(BASE/'integrated-v6/project'),'--script',str(script)]
(OUT/'command.json').write_text(json.dumps(dict(command=cmd,input=env['PN_SAVED_EVIDENCE'],reserves=[150000],bound=120),indent=2))
with (OUT/'run.log').open('wb') as log:r=subprocess.run(cmd,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=600)
print('exit',r.returncode);print((OUT/'run.log').read_text(errors='replace')[-2500:]);raise SystemExit(r.returncode)
