from pathlib import Path
P=Path(__file__).parent/'simulators/rival-quality-1977-20261030-v7/project'
def edit(path,old,new,count=1):
 f=P/path;s=f.read_text(encoding='utf-8');assert old in s,(path,old[:50]);f.write_bytes(s.replace(old,new,count).encode())
edit('scripts/simulation/campaign_session.gd','func _execute(kind: StringName,payload: Dictionary) -> Dictionary:', '''func _execute(kind: StringName,payload: Dictionary) -> Dictionary:
	# Explicit counterpart of the existing automatic rival calendar settlement.
	# It advances real sales/bills only; never a player's clock or project work.
	if kind==&"rival_wait":
		if run._rival_founder_profile!="rival-founder-active-1977-v2" or not payload.is_empty():return reject("Rival calendar unavailable")
		if not run.complete_productive_action(Callable(),0,run.get_completed_run_cycles()):return reject("Rival calendar settlement rejected")
		return {"ok":true,"events":[{"type":"rival_calendar_advanced","run_cycle":run.get_completed_run_cycles()}]}''')
edit('scripts/market/rival_world.gd','sessions.keys()!=archives.keys()','sessions.size()!=archives.size()')
edit('scripts/market/rival_world.gd','if id.is_empty() or id==player_run._bank_run_id','if not archives.has(id) or id.is_empty() or id==player_run._bank_run_id')
edit('scripts/market/rival_world.gd','''if not run.complete_productive_action(Callable(),0,target-1): return {"ok":false,"reason":"Rival idle calendar rejected"}''','''if run._rival_founder_profile=="rival-founder-active-1977-v2":
			var waiting: Dictionary=session.execute(session.command(&"rival_wait"))
			if not waiting.ok:return {"ok":false,"reason":"Rival idle calendar rejected"}
			accepted.append({"type":&"rival_wait","events":waiting.events.duplicate(true)})
		elif not run.complete_productive_action(Callable(),0,target-1): return {"ok":false,"reason":"Rival idle calendar rejected"}''')
edit('scripts/market/rival_world.gd','&"begin_development",&"research": return true','&"begin_development",&"research",&"rival_wait": return true')
edit('scripts/market/rival_career_policy.gd','''var tokens:=_hand(session,view,true)
		var finite:=false
		for card: Dictionary in current.candidates:
			if card.type=="feature":finite=true
		finite=finite or not session.development.hand._available_features.is_empty()
		var goal:=''','''var goal:=''')
edit('scripts/market/rival_career_policy.gd','if not finite and not needs_more and current.can_exit:return _dev(view,&"request_exit")','''# can_exit includes the complete affordable visible/undrawn supply gate.
		if not needs_more and current.can_exit:return _dev(view,&"request_exit")
		var tokens:=_hand(session,view,true)''')
edit('scripts/market/rival_career_policy.gd','var conditional:=false','var conditional:=false\n\tvar planned_schedule: Dictionary=loan.get("payload",{}).get("quote",{}).get("schedule",{})')
edit('scripts/market/rival_career_policy.gd','reserve+=int(recovery.net_proceeds_cents);conditional=true','reserve+=int(recovery.net_proceeds_cents);conditional=true;planned_schedule=recovery.schedule')
edit('scripts/market/rival_career_policy.gd','var cost: int=fee+int(run._studio_finance.monthly_rent_cents)*ceili(float(cycles)/2.0)','''var cost: int=fee+_known_dues(run,cycles,planned_schedule)''')
f=P/'scripts/market/rival_career_policy.gd';s=f.read_text(encoding='utf-8');s+='''
func _known_dues(run: RunState,cycles: int,planned_schedule: Dictionary={}) -> int:
	var ledger: Dictionary=run._studio_finance;var first:=run.get_completed_run_cycles();var last:=first+cycles
	var months: int=last/2-first/2
	var total: int=months*(int(ledger.monthly_rent_cents)+StudioFinanceLedger._monthly_payroll(ledger))
	var schedules: Array=[]
	for loan: Dictionary in ledger.bank_loans:
		if not loan.closed:schedules.append(loan.schedule)
	if not planned_schedule.is_empty():schedules.append(planned_schedule)
	var bank:=preload("res://scripts/finance/bank_loan.gd")
	for schedule: Dictionary in schedules:
		var start: int=maxi(1,(first-int(schedule.first_due_cycle))/2+2) if first>=int(schedule.first_due_cycle) else 1
		var stop: int=mini(int(schedule.term_months),(last-int(schedule.first_due_cycle))/2+1) if last>=int(schedule.first_due_cycle) else 0
		for number in range(start,stop+1):
			var due: Dictionary=bank.installment(schedule,number)
			if int(due.due_cycle)>first and int(due.due_cycle)<=last:total+=int(due.payment_cents)
	# Existing dated education payments, not a new course or tuition assumption.
	var dates: Dictionary=bank.schedule(maxi(bank.MIN_PRINCIPAL,months),maxi(1,months),first)
	if not dates.is_empty():total+=months*StudioFinanceLedger.Education.overlap_reserve(ledger.education,dates)
	return total
''';f.write_bytes(s.encode())
f=P/'scripts/debug/quality_cohort_probe.gd';s=f.read_text(encoding='utf-8')
s=s.replace('if choice.get("type")==&"blocked":issues.append({"id":str(id),"tick":tick,"reason":choice.payload.reason});break','''var wait_reason: String=""
				if choice.get("type")==&"blocked":
					if session.run.get_completed_run_cycles()==tick:break
					wait_reason=str(choice.payload.reason);choice={"type":&"rival_wait","payload":{}}''',1)
s=s.replace('"error":result.get("error","")})','"error":result.get("error",""),"wait_reason":wait_reason})',1)
f.write_bytes(s.encode());print('Review fixes: affordable exit, known dues, key sets; recorded ordinary rival waits.')
