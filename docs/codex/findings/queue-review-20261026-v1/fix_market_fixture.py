from pathlib import Path
out=Path(__file__).resolve().parent
root=out.parents[3]
p=root/'patch-notes/scripts/debug/verify_market_browser.gd'
data=p.read_bytes();(out/'verify_market_browser.before.gd').write_bytes(data)
nl='\r\n' if b'\r\n' in data else '\n'
s=data.decode().replace('\r\n','\n')
old='\t\tgame.rival_world = world\n\t\troot.add_child(game)'
assert old in s
s=s.replace(old,'\t\tgame.rival_world = world\n\t\t# This fixture exercises Studio/Market; invitation/Skip has its own suite.\n\t\t# A fresh isolated profile otherwise hides Studio behind onboarding.\n\t\tgame._onboarding.answer(true)\n\t\troot.add_child(game)')
old='\t\troot.size = resolution\n\t\tvar studio:'
assert old in s
s=s.replace(old,'\t\troot.size = resolution\n\t\troot.content_scale_size = resolution\n\t\tvar studio:')
old='\t\texpect(studio.get_global_rect().encloses'
assert old in s
s=s.replace(old,'\t\texpect(studio.is_visible_in_tree() and game.guided_tutorial == null,"Experienced-profile Market fixture reaches visible Studio")\n\t\texpect(studio.get_global_rect().encloses')
p.write_bytes(s.replace('\n',nl).encode())
