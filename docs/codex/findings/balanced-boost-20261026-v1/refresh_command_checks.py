from pathlib import Path
root=Path(__file__).resolve().parents[4]
for phase in ['design','alpha']:
    p=root/f'patch-notes/scripts/debug/verify_{phase}_command.gd'
    data=p.read_bytes(); nl='\r\n' if b'\r\n' in data else '\n'
    s=data.decode().replace('\r\n','\n')
    assert '[6,5,5,5,4], "Balanced conserves 21 points"' in s
    s=s.replace('[6,5,5,5,4], "Balanced conserves 21 points"','[7,7,6,6,4], "Balanced boosts 21 to26 and splits whole points"')
    if phase=='design':
        s=s.replace('scenario != "production_overflow"','scenario not in ["production_overflow", "balanced"]')
        s=s.replace('# oracle immutable; compare every other case and assert rejection above.', '# oracle immutable; exclude the approved 1.25 Balanced change too.\n\t\t# New Balanced full-state parity: verify_balanced_boost_parity.gd.')
    else:
        old='\t\t_expect(JSON.parse_string(JSON.stringify(digests)) == expected, "%s full state/RNG/signal trace matches pre-extraction oracle" % mode)'
        assert old in s
        s=s.replace(old, '\t\t# Retain the historical oracle. The approved 1.25 Balanced change has\n\t\t# exact current live/headless coverage in verify_balanced_boost_parity.\n\t\texpected = expected.filter(func(row: Dictionary) -> bool: return row.scenario != "balanced")\n\t\tvar unchanged := digests.filter(func(row: Dictionary) -> bool: return row.scenario != "balanced")\n\t\t_expect(JSON.parse_string(JSON.stringify(unchanged)) == expected, "%s unchanged state/RNG/signal trace matches pre-extraction oracle" % mode)')
    p.write_bytes(s.replace('\n',nl).encode())

for name in ['tutorial_overlay.gd','guided_production_tutorial.gd']:
    p=root/'patch-notes/scripts/ui'/name
    data=p.read_bytes()
    p.write_bytes(data.replace(b'by1.25',b'by 1.25').replace(b'ten:3 Graphics,3 Sound,2 Tech,2 Design.',b'ten: 3 Graphics, 3 Sound, 2 Tech, 2 Design.'))
