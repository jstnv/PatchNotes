from pathlib import Path
out=Path(__file__).resolve().parent;root=out.parents[3]
p=root/'patch-notes/scripts/debug/verify_soundtrack_sync.gd'
data=p.read_bytes();nl='\r\n' if b'\r\n' in data else '\n';s=data.decode().replace('\r\n','\n')
s=s.replace('(count * 3 + 4) * Grid.STEP','(count + 10) * Grid.STEP')
s=s.replace('if i > 0: check(is_equal_approx(rows[i].beat_index - rows[i-1].beat_index, 1.0), "Fixed subdivision cadence")', 'if i > 0: check(is_equal_approx(rows[i].beat_index - rows[i-1].beat_index, 0.0 if event.begins_with("bonus") else 1.0), "Base cards keep cadence; synergy text is simultaneous")')
s=s.replace('rise[0].beat_index - start[0].beat_index == HandPresentation.SPECIALIZATION_LEAD_BEATS, "Popup precedes bonuses by one music subdivision"','rise[0].beat_index == start[0].beat_index, "All multiplier rises begin with the popup"')
s=s.replace('played[-1].values[&"graphics"] == 105 and played[-1].values[&"design"] == 7, "Balanced first displays printed hand gains"','played[-1].values[&"graphics"] == 100 and played[-1].values[&"design"] == 1, "Balanced keeps HUD unchanged while card values float"')
s=s.replace('splits[0].beat_index - starts[0].beat_index == 1, "Balanced popup then redistribution share continuous music grid"','splits[0].beat_index - starts[0].beat_index == 5, "Balanced merge/split/sink deposits five music subdivisions after popup"')
p.write_bytes(s.replace('\n',nl).encode())
