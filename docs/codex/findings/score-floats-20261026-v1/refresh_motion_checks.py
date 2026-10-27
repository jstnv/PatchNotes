from pathlib import Path
out=Path(__file__).resolve().parent;root=out.parents[3]
p=root/'patch-notes/scripts/debug/verify_card_motion.gd';data=p.read_bytes();nl='\r\n' if b'\r\n' in data else '\n';s=data.decode().replace('\r\n','\n')
old='expect(hud.stats[1].text == "Graphics\\n2 / 33" and not hud._score_pulses.is_empty(), "First bounce updates the scoreboard and exposes a +2 base indicator")'
new='expect(hud.stats[1].text == "Graphics\\n0 / 33" and is_instance_valid(motion._score_flow), "First bounce holds the HUD while the card score floats")'
assert old in s;s=s.replace(old,new)
needle='\tawait shot("score-bounce-%d" % width)'
assert needle in s
s=s.replace(needle,needle+'\n\twhile not motion.trace.any(func(e): return e.event == "hud_deposit"): await process_frame\n\texpect(hud.stats[1].text == "Graphics\\n12 / 33" and not hud.scoreboard._punches.is_empty(), "Falling values deposit the final score and punch the HUD")')
s=s.replace('"Four bonus bounces form one specialization cycle at4:1"','"Simultaneous multipliers finish the four-subdivision merge cycle"')
s=s.replace('"Specialization bonuses reveal once per card, left to right"','"Simultaneous specialization merge records each card exactly once"')
p.write_bytes(s.replace('\n',nl).encode())
