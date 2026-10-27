"""Copy exact ordinary-input Studio checkpoints to disposable display replays."""
from pathlib import Path
import hashlib, json, shutil

base = Path(__file__).resolve().parent
preferences = base/'profiles/education-distress/APPDATA/Godot/app_userdata/Patch Notes Demo/preferences-v1.cfg'
rows = []
for publisher, folder, generation in [('crown', 'crown-pending', 14), ('neon', 'neon-completed', 2), ('starwave', 'starwave-completed', 11)]:
    source = base/'checkpoints'/folder/f'checkpoint.{generation}.json'
    envelope = json.loads(source.read_text())
    assert hashlib.sha256(envelope['payload_utf8'].encode()).hexdigest() == envelope['payload_sha256']
    profile = base/'profiles'/f'{publisher}-matrix'
    profile.mkdir(exist_ok=False)
    user = profile/'APPDATA/Godot/app_userdata/Patch Notes Demo'
    save = user/'saves/studio'
    save.mkdir(parents=True)
    (profile/'LOCALAPPDATA').mkdir()
    shutil.copy2(source, save/source.name)
    shutil.copy2(preferences, user/preferences.name)
    assert source.read_bytes() == (save/source.name).read_bytes()
    payload = json.loads(envelope['payload_utf8'])
    rows.append({'publisher': publisher, 'source': str(source.relative_to(base)), 'sha256': hashlib.sha256(source.read_bytes()).hexdigest(), 'profile': str(profile.relative_to(base)), 'run_id': payload['run_id'], 'cycle': payload['run']['completed_run_cycles'], 'purpose': 'Presentation replay from unmodified ordinary-input pending Studio checkpoint; preferences copied at 1152x648. No gameplay state injection.'})
(base/'matrix-profile-origins.json').write_text(json.dumps(rows, indent=2)+'\n')
print(json.dumps(rows, indent=2))
