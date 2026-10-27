from pathlib import Path
import hashlib,json,shutil

BASE=Path(__file__).resolve().parent
OLD=BASE.parent/'queue-completion-20261011-v1'
origins=[]
for label,source in {
    'crown-rollback':'crown-pending/checkpoint.14.json',
    'neon-completed':'neon-resume-completed/checkpoint.3.json',
    'starwave-bank':'starwave-matrix-completed/checkpoint.12.json',
    'education-distress':'education-distressed-committed/checkpoint.34.json',
    'education-recovered':'education-recovered-next-month/checkpoint.35.json',
    'bank-recovered':'bank-paid-off/checkpoint.31.json',
    'legacy-preview':'legacy-preview-restored/checkpoint.1.json',
}.items():
    origin=OLD/'checkpoints'/source
    if not origin.exists():
        raise FileNotFoundError(origin)
    home=BASE/'profiles'/label/'APPDATA/Godot/app_userdata/Patch Notes Demo'
    saves=home/'saves/studio';saves.mkdir(parents=True,exist_ok=False)
    shutil.copy2(origin,saves/origin.name)
    preferences=OLD/'profiles/starwave-matrix/APPDATA/Godot/app_userdata/Patch Notes Demo/preferences-v1.cfg'
    if preferences.exists():shutil.copy2(preferences,home/preferences.name)
    (BASE/'profiles'/label/'LOCALAPPDATA').mkdir(parents=True)
    envelope=json.loads(origin.read_text());payload=json.loads(envelope['payload_utf8'])
    origins.append({'profile':label,'source':str(origin.relative_to(BASE.parent)),'sha256':hashlib.sha256(origin.read_bytes()).hexdigest(),'cycle':payload['run']['completed_run_cycles'],'cash_cents':payload['run']['cash_cents'],'run_id':payload['run_id'],'has_rivals': 'rival_world' in payload})
(BASE/'profile-origins.json').write_text(json.dumps(origins,indent=2)+'\n')
print(json.dumps(origins,indent=2))
