"""Entrypoint-only native acceptance copy; exact gameplay and opening assets."""
from pathlib import Path
import argparse,shutil,sys,re
ROOT=Path(__file__).resolve().parents[4];sys.path.insert(0,str(ROOT/'tools'));import simulate as sim
def main():
 p=argparse.ArgumentParser();p.add_argument('--project',type=Path,required=True);p.add_argument('--script',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args();out=a.output.resolve();out.mkdir(parents=True,exist_ok=False);project=out/'project';baseline=sim.copy_snapshot(a.project.resolve(),project)
 folder=project/'acceptance';folder.mkdir();text=a.script.read_text(encoding='utf-8').replace('extends SceneTree','extends Node',1).replace('func _initialize() -> void:','func _ready() -> void:',1)
 text+='\n@onready var root: Window = get_tree().root\nvar process_frame: Signal:\n\tget: return get_tree().process_frame\nfunc quit(code: int=0) -> void:\n\tget_tree().quit(code)\n'
 (folder/'main.gd').write_bytes(text.encode('utf-8'));(folder/'main.tscn').write_bytes(b'[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://acceptance/main.gd" id="1"]\n\n[node name="Acceptance" type="Node"]\nscript = ExtResource("1")\n')
 config=project/'project.godot';original=config.read_text(encoding='utf-8');changed,count=re.subn(r'(?m)^run/main_scene=.*$', 'run/main_scene="res://acceptance/main.tscn"',original);assert count==1;config.write_bytes(changed.encode('utf-8'));shutil.copy2(a.project/'export_presets.cfg',project/'export_presets.cfg')
 current=sim.source_hashes(project);delta=[k for k in sorted(set(baseline)|set(current)) if baseline.get(k)!=current.get(k)];assert delta==['project.godot'],delta
 sim.write_json(out/'entrypoint-provenance.json',{'baseline':baseline,'fixture':current,'entrypoint_only':True,'adapter_sha256':sim.sha(folder/'main.gd'),'original_probe_sha256':sim.sha(a.script),'export_preset_sha256':sim.sha(project/'export_presets.cfg'),'gameplay_and_certificates_exact':True});print(str(project))
if __name__=='__main__':main()
