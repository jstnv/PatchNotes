from pathlib import Path
P=Path(__file__).parent/'simulators/rival-quality-1977-20261030-v18/project'
f=P/'scripts/market/rival_world.gd';s=f.read_text()
s=s.replace('var _busy := false','var _busy := false\n## Scheduler only; policy/state/order remain the same. Tools may force serial.\nvar parallel_careers:=true',1)
old='''	for id: StringName in ids:
		var report := _advance_studio(id, policies[id], next_cycle+int(calendar_offsets.get(id,0)), max_zero_steps)
		reports.append(report)
		if not report.ok:
			_busy = false
			return {"ok":false,"reason":report.reason,"studio_id":id,"completed_studios":reports,"cycle":cycle}
		published.append_array(report.releases)'''
new='''	var parallel:=_parallel_safe(ids,policies)
	var jobs: Array[Thread]=[]
	var inline: Dictionary={}
	if parallel:
		for id: StringName in ids:
			var thread:=Thread.new()
			var error:=thread.start(_advance_studio.bind(id,policies[id],next_cycle+int(calendar_offsets.get(id,0)),max_zero_steps,true))
			jobs.append(thread)
			if error!=OK:inline[id]=_advance_studio(id,policies[id],next_cycle+int(calendar_offsets.get(id,0)),max_zero_steps,true)
	# Join every started owner before inspecting errors or publishing any facts.
	var joined: Dictionary={}
	if parallel:
		for i in range(ids.size()):joined[ids[i]]=jobs[i].wait_to_finish() if jobs[i].is_started() else inline[ids[i]]
	for id: StringName in ids:
		var report: Dictionary=joined[id] if parallel else _advance_studio(id,policies[id],next_cycle+int(calendar_offsets.get(id,0)),max_zero_steps)
		reports.append(report)
		if not report.ok:
			_busy = false
			return {"ok":false,"reason":report.reason,"studio_id":id,"completed_studios":reports,"cycle":cycle}
		if parallel:
			for release: Dictionary in report.releases:live_releases[release.release_id]=release
		published.append_array(report.releases)'''
assert old in s;s=s.replace(old,new,1)
s=s.replace('func _advance_studio(id: StringName, policy: Callable, target: int, limit: int) -> Dictionary:','func _advance_studio(id: StringName, policy: Callable, target: int, limit: int, collect_only: bool=false) -> Dictionary:',1)
s=s.replace('\t\tlive_releases[release_id] = record','\t\tif not collect_only:live_releases[release_id] = record',1)
s+='''
## Only the fixed detached Career policy can run independently. No arbitrary
## closures, legacy rules, scene listeners or checkpoint callbacks cross threads.
## Every owner observes the same already-frozen month; publication stays sorted.
func _parallel_safe(ids: Array,policies: Dictionary) -> bool:
	if not parallel_careers or ids.size()!=8:return false
	for id: StringName in ids:
		var run: RunState=studios[id].run
		if run._rival_founder_profile!="rival-founder-active-1977-v2" or run.get_script()!=preload("res://scripts/run_state.gd") or calendar_offsets.get(id)!=72:return false
		var decision: Object=policies[id].get_object()
		if decision==null or decision.get_script()!=preload("res://scripts/market/rival_career_decision.gd"):return false
		if run.checkpoint_before_mutation.is_valid() or run.studio_departure_guard.is_valid():return false
		for signal_info: Dictionary in run.get_signal_list():
			if not run.get_signal_connection_list(signal_info.name).is_empty():return false
	return true
'''
f.write_bytes(s.encode())
(P/'export_presets.cfg').write_bytes((P.parents[1]/'rival-quality-1977-20261030-v17/project/export_presets.cfg').read_bytes())
print('Private scheduler: only detached exact 8-owner Career; sorted publication; serial fallback.')
