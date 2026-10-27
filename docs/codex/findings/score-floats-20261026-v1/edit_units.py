from pathlib import Path
out=Path(__file__).resolve().parent;root=out.parents[3]
def edit(name,fn):
 p=root/'patch-notes'/name;data=p.read_bytes();nl='\r\n' if b'\r\n' in data else '\n'
 before=out/'before'/name
 if not before.exists():before.parent.mkdir(parents=True,exist_ok=True);before.write_bytes(data)
 s=fn(data.decode().replace('\r\n','\n'));p.write_bytes(s.replace('\n',nl).encode())
def flow(s):
 s=s.replace('var balanced := false','var balanced := false\nvar divisor := 1\nvar multiplier_text := "×1.5"')
 s=s.replace('label.text = "+%d" % value if key == "value" else multiplier', 'label.text = _value_text(value) if key == "value" else multiplier')
 s=s.replace('"×1.5", minf','multiplier_text, minf').replace('"×1.5", 2.0','multiplier_text, 2.0')
 at=s.index('func _pose(')
 s=s[:at]+'''func _value_text(value: int) -> String:
	if divisor == 2:
		@warning_ignore("integer_division")
		var whole := value / 2
		return "+%d%s" % [whole, ".5" if value % 2 else ""]
	return "+%d" % value

'''+s[at:]
 return s
edit('scripts/ui/card_score_floats.gd',flow)
def motion(s):
 s=s.replace('var _deposited := false','var _deposited := false\nvar _number_multiplier := 1.5')
 s=s.replace('func note_specialization(header: Callable, balanced := false)', 'func note_specialization(header: Callable, balanced := false, multiplier := 1.5)')
 s=s.replace('\t\t_balanced = balanced','\t\t_balanced = balanced\n\t\t_number_multiplier = multiplier',1)
 s=s.replace('\t_specialization = false\n\t_balanced = false','\t_specialization = false\n\t_number_multiplier = 1.5\n\t_balanced = false',1)
 s=s.replace('bases.append(_scalar(_cards[index], raw if _specialization else resolved))', 'bases.append(_scalar(_cards[index], raw) * int(_starting_values.get("_score_divisor", 1)) if _specialization else _scalar(_cards[index], resolved))')
 s=s.replace('\t_score_flow.configure(_hand, bases, finals, categories)', '\t_score_flow.configure(_hand, bases, finals, categories)\n\t_score_flow.divisor = int(_starting_values.get("_score_divisor", 1))\n\t_score_flow.multiplier_text = "×%s" % str(_number_multiplier)')
 return s
edit('scripts/ui/hand_presentation.gd',motion)
edit('scripts/ui/phase_workspace.gd',lambda s:s.replace('title == "Balanced Production!")','title == "Balanced Production!", 1.25 if title == "Balanced Operations!" else 1.5)'))
def scoreboard(s):
 a=s.index('\tfor index in indices:');b=s.index('\nfunc reset_punches()',a)
 s=s[:a]+'''	for index in indices:
		if _punches.has(index): _punches[index].kill()
		var tween := animate_number(stats[index])
		_punches[index] = tween
		tween.finished.connect(func():
			if _punches.get(index) == tween: _punches.erase(index))

static func animate_number(label: Label) -> Tween:
	label.pivot_offset = label.size / 2.0
	label.scale = Vector2.ONE * 0.9
	label.rotation = -0.025
	label.self_modulate = Color("#f5ce69")
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "scale", Vector2.ONE * 1.18, 0.075).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "rotation", 0.025, 0.075)
	tween.chain().tween_property(label, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "rotation", 0.0, 0.22)
	tween.parallel().tween_property(label, "self_modulate", Color.WHITE, 0.22)
	return tween
'''+s[b:]
 return s
edit('scripts/ui/production_scoreboard.gd',scoreboard)
def contract(s):
 s=s.replace('var hand_motion: HandPresentation','var hand_motion: HandPresentation\nvar _score_synergy: SynergyNotification')
 s=s.replace('\thand_motion = HandPresentation.new()','\t_score_synergy = SynergyNotification.new()\n\tadd_child(_score_synergy)\n\thand_motion = HandPresentation.new()',1)
 s=s.replace('"_redraws": _run.get_available_redraws()}', '"_redraws": _run.get_available_redraws(), "_score_divisor": 2}',1)
 a=s.index('\tvar parts: Array[String] = []',s.index('func _display_scores'))
 b=s.index('\nfunc _restore_scores()',a)
 s=s[:a]+'''	for index in range(5):
		var key: StringName = HandPresentation.CORE[index] if index < 4 else &"scope"
		if int(deltas.get(key, 0)) != 0: ProductionScoreboard.animate_number(_score_values[index])

func _show_score_synergy(stat: StringName) -> void:
	_score_synergy.banner.offset_left = -220
	_score_synergy.banner.offset_right = 220
	_score_synergy.banner.offset_top = maxf(160.0, get_global_rect().end.y - 112.0)
	_score_synergy.banner.offset_bottom = _score_synergy.banner.offset_top + 62
	_score_synergy.show_message("%s Specialization!" % str(stat).capitalize(), "Core ×1.5 · Scope stays printed")
'''+s[b:]
 a=s.index('\tif _state.is_completed(): _show_completion()',s.index('func _play_selected_hand()'))
 s=s[:a]+'''	var stat: StringName = result.events[0].plan.specialization_stat
	if not stat.is_empty(): hand_motion.note_specialization(_show_score_synergy.bind(stat))
'''+s[a:]
 return s
edit('scripts/phases/contract_phase.gd',contract)
