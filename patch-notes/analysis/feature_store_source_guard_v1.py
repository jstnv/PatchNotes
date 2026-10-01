"""Preserve source inputs and verify no pre-existing gameplay file changed."""
import hashlib,json,shutil,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'design-logs/feature-store-staged-v1'
DESIGN=Path(r'C:\Users\64jus\Downloads\Patch Notes Design Folder')
names=['Feature_Store_Productive_Cycle_Correction_v1.txt','Design_Alpha_Redraw_Class_Parity_Implementation_v1.txt','Playable_Game_Lifespan_Trial_v1.txt','SideStreet_Cash_Contract_Implementation_and_Acceptance_Stress_v1.txt','Feature_Pools_Autonomous_Read_Only_Batch_v1.txt','First_Studio_Feature_Economy_v2.txt','First_Game_Scripted_Synergy_Tutorial_v1.txt']
sources=[DESIGN/'New Data Logs'/n for n in names]+list((DESIGN/'Cards').glob('*LEDGER.docx'))
records=[]
for src in sources:
    dst=OUT/'sources'/src.name
    if not dst.exists(): shutil.copyfile(src,dst)
    records.append({'source':str(src),'snapshot':str(dst.relative_to(OUT)),'sha256':hashlib.sha256(dst.read_bytes()).hexdigest(),'matches_source':dst.read_bytes()==src.read_bytes()})
baseline=json.loads((OUT/'baseline_source_manifest.json').read_text())
changed=[path for path,sha in baseline['files'].items() if not (ROOT/path).exists() or hashlib.sha256((ROOT/path).read_bytes()).hexdigest()!=sha]
head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
result={'starting_head':baseline['head'],'current_head':head,'changed_preexisting_gameplay_files':changed,'source_snapshots':records}
(OUT/'source_preservation_audit_v1.json').write_text(json.dumps(result,indent=2))
print(json.dumps({'head':head,'changed_preexisting_gameplay_files':changed,'source_snapshots':len(records)}))
raise SystemExit(1 if changed else 0)
