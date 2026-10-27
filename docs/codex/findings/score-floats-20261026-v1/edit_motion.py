from pathlib import Path
out=Path(__file__).resolve().parent;root=out.parents[3]
p=root/'patch-notes/scripts/ui/hand_presentation.gd'
data=p.read_bytes();nl='\r\n' if b'\r\n' in data else '\n';s=data.decode().replace('\r\n','\n')
def replace(a,b):
 global s
 assert a in s,a[:120]
 s=s.replace(a,b)
replace('const PlayBurst :=', 'const ScoreFloats := preload("res://scripts/ui/card_score_floats.gd")\nconst PlayBurst :=')
replace('var _card_bursts: Array[Dictionary] = []','var _card_bursts: Array[Dictionary] = []\nvar _score_flow: Control\nvar _confirmed_values: Dictionary = {}\nvar _starting_values: Dictionary = {}\nvar _deposit_beat := 0.0\nvar _deposited := false')
replace('\tfor effect in _bonus_labels:\n', '\tif is_instance_valid(_score_flow): _score_flow.sample(now)\n\tfor effect in _bonus_labels:\n')
replace('\t_first_beat += skipped_beats','\t_first_beat += skipped_beats\n\t_deposit_beat += skipped_beats\n\tif is_instance_valid(_score_flow): _score_flow.rejoin(shift)')
replace('\tbusy = true\n\taction_kind = kind','\tbusy = true\n\t_deposited = false\n\t_starting_values = before.duplicate()\n\t_confirmed_values = after.duplicate()\n\taction_kind = kind')
replace('\t_first_beat = ceili((_music_cursor + BEAT_SECONDS) / BEAT_SECONDS)','\t_first_beat = ceili((_music_cursor + BEAT_SECONDS) / BEAT_SECONDS)\n\t_deposit_beat = _first_beat + _hand.size() + (5 if _specialization else 1)\n\tif kind != "redraw": _create_score_flow()')
start=s.index('\telse:\n\t\t_tween.chain().tween_interval(maxf(0.0, _first_beat')
end=s.index('\n\t_tween.chain().tween_callback(_return_fan)',start)
s=s[:start]+'''	else:
		_tween.chain().tween_interval(maxf(0.0, _first_beat * BEAT_SECONDS - _music_cursor - BEAT_SECONDS))
		for i in range(_hand.size()): _activation_bounce(i, scale_value, false)
		if _specialization:
			_tween.chain().tween_callback(_begin_specialization)
			_tween.chain().tween_interval(2 * BEAT_SECONDS)
			_tween.chain().tween_callback(_merge_numbers)
			_tween.chain().tween_interval(BEAT_SECONDS)
			_tween.chain().tween_callback(_numbers_ready)
			_tween.chain().tween_interval(BEAT_SECONDS)
			_tween.chain().tween_callback(_record.bind(-1, "specialization_complete"))
		_tween.chain().tween_callback(_begin_number_exit)
		_tween.chain().tween_interval(BEAT_SECONDS)
		_tween.chain().tween_callback(_deposit_scores)
		_tween.chain().tween_callback(_record.bind(-1, "exit_slide"))
		_tween.chain()
		for ghost in _hand:
			_tween.parallel().tween_property(ghost, "position:x", size.x + CardFan.CARD_SIZE.x, BEAT_SECONDS).as_relative().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
'''.rstrip()+s[end:]
start=s.index('func _begin_specialization()')
end=s.index('\nfunc _record(',start)
s=s[:start]+'''func _scalar(card: CardData, row: Dictionary) -> int:
	var core := 0
	for key in CORE: core += int(row.get(key, 0))
	if not card.core_contributions().is_empty(): return core
	if card.qa_operation == &"debug": return int(row.get(&"fixed", 0))
	if card.qa_operation == &"search": return int(row.get(&"discovered", 0))
	return int(row.get(&"marketing", 0))

func _create_score_flow() -> void:
	_score_flow = ScoreFloats.new()
	_score_flow.name = "FloatingScores"
	_score_flow.z_index = 400
	add_child(_score_flow)
	var bases: Array = []
	var finals: Array = []
	for index in range(_cards.size()):
		var raw := {}
		var resolved := _timeline[index].duplicate()
		for key in resolved: resolved[key] += int(_bonus_timeline[index].get(key, 0))
		for key in CORE + [&"marketing", &"fixed", &"discovered"]: raw[key] = _weight(_cards[index], key)
		bases.append(_scalar(_cards[index], raw if _specialization else resolved))
		finals.append(_scalar(_cards[index], resolved))
	var categories: Array = []
	for key in CORE: categories.append(int(_confirmed_values.get(key, 0)) - int(_starting_values.get(key, 0)))
	_score_flow.configure(_hand, bases, finals, categories)

func _begin_specialization() -> void:
	_record(-1, "specialization_started")
	_score_flow.begin_synergy(_balanced, (_first_beat + _hand.size()) * BEAT_SECONDS)
	if not _balanced:
		for index in range(_hand.size()): _record(index, "bonus_rise")
	if _specialization_header.is_valid():
		_specialization_header.call()
		_specialization_header = Callable()

func _merge_numbers() -> void:
	if _balanced: _record(-1, "balanced_merge")
	else:
		for index in range(_hand.size()): _score_bonus(index)

func _numbers_ready() -> void:
	if _balanced: _record(-1, "balanced_split")
	else:
		for index in range(_hand.size()): _record(index, "bonus_grounded")

func _score_bonus(index: int) -> void:
	# The simultaneous number merge is visual; gameplay already committed.
	_record(index, "bonus")

func _begin_number_exit() -> void:
	_score_flow.begin_exit((_deposit_beat - 1.0) * BEAT_SECONDS)
	_record(-1, "numbers_exit")

func _deposit_scores() -> void:
	if _deposited: return
	_deposited = true
	_score_flow.sample(_deposit_beat * BEAT_SECONDS)
	_record(-1, "numbers_hidden")
	var deltas := {}
	for key in _confirmed_values:
		if not str(key).begins_with("_"): deltas[key] = int(_confirmed_values[key]) - int(_starting_values.get(key, 0))
	display_values = _confirmed_values.duplicate()
	if _update.is_valid(): _update.call(display_values.duplicate(), deltas)
	_record(-1, "hud_deposit")
	if _balanced: _record(-1, "balanced_redistributed")
''' +s[end:]
start=s.index('\t\t"bonus_rise": beat =')
end=s.index('\n\tvar now := _music_seconds()',start)
s=s[:start]+'''		"bonus_rise": beat = _first_beat + count
		"bonus": beat = _first_beat + count + 2
		"bonus_grounded": beat = _first_beat + count + 3
		"specialization_started": beat = _first_beat + count
		"specialization_complete": beat = _first_beat + count + 4
		"balanced_merge": beat = _first_beat + count + 2
		"balanced_split": beat = _first_beat + count + 3
		"numbers_exit": beat = _deposit_beat - 1
		"numbers_hidden", "hud_deposit", "balanced_redistributed", "exit_slide": beat = _deposit_beat
''' .rstrip()+s[end:]
replace('if event in ["score", "bonus"] and now - beat * BEAT_SECONDS < 0.12:', 'if (event == "score" or (event == "bonus" and index == 0)) and now - beat * BEAT_SECONDS < 0.12:')
start=s.index('func _redistribute_balanced()')
end=s.index('\nfunc cancel()',start)
s=s[:start]+'''func _redistribute_balanced() -> void:
	_deposit_scores()

func _score_card(index: int) -> void:
	_emit_card_burst(index)
	_score_flow.reveal(index, (_first_beat + index + 0.5) * BEAT_SECONDS)
	_record(index, "score")
''' +s[end:]
replace('\t_balanced_deltas.clear()\n\t_balanced = false','\t_balanced_deltas.clear()\n\tif is_instance_valid(_score_flow):\n\t\tremove_child(_score_flow)\n\t\t_score_flow.queue_free()\n\t_score_flow = null\n\t_confirmed_values.clear()\n\t_starting_values.clear()\n\t_balanced = false')
p.write_bytes(s.replace('\n',nl).encode())
