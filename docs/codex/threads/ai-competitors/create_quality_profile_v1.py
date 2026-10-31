"""Keep the existing actual Studio/Store/background-save performance scenario.
Only extend explicit synthetic PLAYER funds and duration; not rival funding proof.
"""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[4];out=Path(__file__).parent/'quality_campaign_profile_v1.gd'
text=(ROOT/'patch-notes/scripts/debug/profile_background_campaign.gd').read_text(encoding='utf-8')
text=text.replace('session.run.add_cash(100000)','session.run.add_cash(10000000)',1).replace('if OS.get_environment("PN_LATENCY_LONG")=="1":','if true: # Explicit96-cycle performance fixture, not player/rival balance.',1).replace('if OS.get_environment("PN_LATENCY_NEXT")=="1":','if true:',1)
text=text.replace('var output:=OS.get_environment("PN_CARD_FRAME_OUTPUT")','''var output:=""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):output=argument.trim_prefix("--output=")''',1)
out.write_bytes(text.encode());print(str(out))
