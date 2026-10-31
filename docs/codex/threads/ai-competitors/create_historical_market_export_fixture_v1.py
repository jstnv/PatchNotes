"""Create an entrypoint-only private UI fixture with explicit UTF-8 provenance."""
from pathlib import Path
import argparse,shutil,sys
ROOT=Path(__file__).resolve().parents[4];sys.path.insert(0,str(ROOT/'tools'));import simulate as sim
def main():
 p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);a=p.parse_args();out=a.output.resolve();out.mkdir(parents=True,exist_ok=False);project=out/'project'
 baseline=sim.copy_snapshot(ROOT/'patch-notes',project);folder=project/'acceptance';folder.mkdir()
 text=(project/'scripts/debug/verify_historical_market.gd').read_text(encoding='utf-8')
 text=text.replace('extends SceneTree','extends Node',1).replace('func _initialize() -> void:','func _ready() -> void:',1).replace('node_added.connect(', 'get_tree().node_added.connect(',1)
 text+='\n@onready var root: Window = get_tree().root\nvar process_frame: Signal:\n\tget: return get_tree().process_frame\nvar paused: bool:\n\tget: return get_tree().paused\nfunc create_timer(seconds: float) -> SceneTreeTimer:\n\treturn get_tree().create_timer(seconds)\nfunc quit(code: int = 0) -> void:\n\tget_tree().quit(code)\n'
 (folder/'main.gd').write_bytes(text.encode('utf-8'));(folder/'main.tscn').write_bytes(b'[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://acceptance/main.gd" id="1"]\n\n[node name="Acceptance" type="Node"]\nscript = ExtResource("1")\n')
 config=project/'project.godot';original=config.read_bytes();old=b'run/main_scene="uid://bjuqd0td2mtbm"';new=b'run/main_scene="res://acceptance/main.tscn"';assert original.count(old)==1;config.write_bytes(original.replace(old,new))
 shutil.copy2(ROOT/'patch-notes/export_presets.cfg',project/'export_presets.cfg')
 current=sim.source_hashes(project);delta=[k for k in sorted(set(baseline)|set(current)) if baseline.get(k)!=current.get(k)];assert delta==['project.godot'],delta
 token=next(line for line in text.splitlines() if 'get_text(4)' in line).split('=="')[1].split('"')[0];assert [ord(c) for c in token]==[8212]
 sim.write_json(out/'entrypoint-only-provenance.json',{'baseline_manifest':baseline,'fixture_manifest':current,'adapter_files':{f.name:sim.sha(f) for f in folder.iterdir()},'export_preset_sha256':sim.sha(project/'export_presets.cfg'),'semantic_config_delta':'application/run/main_scene only','expected_dash_codepoints':[ord(c) for c in token],'canonical_gameplay_source_exact':True,'purpose':'Compiled UI acceptance entrypoint only; normal game scene and mechanics unchanged. Not the normal distributed entrypoint.'});shutil.copy2(__file__,out/'builder.py');print('Entry-only fixture with exact canonical runtime and UTF-8 PASS')
if __name__=='__main__':main()
