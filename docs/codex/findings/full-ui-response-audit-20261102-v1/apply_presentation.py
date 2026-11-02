from pathlib import Path
import re,json
root=Path('patch-notes');changed=[]
def save(path,s):
 old=path.read_text(encoding='utf-8')
 if s!=old:path.write_text(s,encoding='utf-8');changed.append(str(path))
# One live authority, leaving historical theme asset available for old evidence.
for folder in ['scripts/ui','scripts/phases','scripts/publishers','scripts/developer','scenes']:
 for f in (root/folder).rglob('*'):
  if f.suffix not in ['.gd','.tscn']:continue
  s=f.read_text(encoding='utf-8').replace('res://resources/ui/workspace_theme.tres','res://resources/ui/onyx_theme.tres')
  save(f,s)
f=root/'resources/ui/onyx_theme.tres';s=f.read_text(encoding='utf-8')
for role in ['Button','CheckBox','CheckButton','FolderHeading','FolderTab','OptionButton','PrimaryButton','SidebarButton']:
 s=re.sub(r'('+role+r'/fonts/font = )ExtResource\("[^"\n]+"\)',r'\1ExtResource("1_f6ne0")',s)
s=s.replace('HeadingLabel/font_sizes/font_size = 38','HeadingLabel/font_sizes/font_size = 30')
s=s.replace('PrimaryButton/font_sizes/font_size = 17','PrimaryButton/font_sizes/font_size = 18')
s=s.replace('DocumentPanel/styles/panel = SubResource("StyleBoxFlat_im4je")','DocumentPanel/styles/panel = SubResource("StyleBoxFlat_gcq62")')
for role in ['FolderTab','SidebarButton']:
 for state,style in [('normal','8a8lm'),('hover','oprdq'),('pressed','h2buj'),('hover_pressed','h2buj'),('focus','8uuti')]:
  key=f'{role}/styles/{state}'
  line=f'{key} = SubResource("StyleBoxFlat_{style}")'
  s=re.sub(r'^'+re.escape(key)+r' = .*$',lambda m:line,s,flags=re.M) if re.search(r'^'+re.escape(key)+r' = ',s,re.M) else s+'\n'+line+'\n'
# Normalize remaining nonsemantic field/tooltip/slider surfaces to the accepted palette.
for old,new in [('Color(0.207843, 0.282353, 0.321569, 1)','Color(0.21960784, 0.14901961, 0.3529412, 1)'),('Color(0.145098, 0.172549, 0.2, 1)','Color(0.12941177, 0.105882354, 0.21960784, 1)'),('Color(0.12549, 0.145098, 0.168627, 1)','Color(0.078431375, 0.08235294, 0.09803922, 1)'),('Color(0.960784, 0.933333, 0.87451, 1)','Color(1, 0.9529412, 0.8862745, 1)'),('Color(0.25098, 0.788235, 0.811765, 1)','Color(0.36862746, 0.9490196, 0.7607843, 1)'),('Color(0.94902, 0.541176, 0.384314, 1)','Color(0.43529412, 0.25882354, 1, 1)')]:s=s.replace(old,new)
lines=['Button/font_sizes/font_size = 16','CheckBox/font_sizes/font_size = 16','CheckButton/font_sizes/font_size = 16','OptionButton/font_sizes/font_size = 16','SectionHeading/base_type = &"Label"','SectionHeading/fonts/font = ExtResource("1_f6ne0")','SectionHeading/font_sizes/font_size = 24','ActiveFolderTab/base_type = &"Button"','ActiveFolderTab/fonts/font = ExtResource("1_f6ne0")','ActiveFolderTab/font_sizes/font_size = 17','ActiveFolderTab/styles/normal = SubResource("StyleBoxFlat_h2buj")','ActiveFolderTab/styles/focus = SubResource("StyleBoxFlat_8uuti")','Window/fonts/title_font = ExtResource("1_f6ne0")','Window/font_sizes/title_font_size = 20','Window/styles/embedded_border = SubResource("StyleBoxFlat_gcq62")','Window/styles/embedded_unfocused_border = SubResource("StyleBoxFlat_gcq62")']
for role in ['PopupMenu','Tree','ItemList','AcceptDialog','PopupPanel','TabContainer']:
 lines.append(f'{role}/styles/panel = SubResource("StyleBoxFlat_gcq62")')
for role in ['Tree','ItemList']:
 for item in ['font_color','font_selected_color','title_button_color']:lines.append(f'{role}/colors/{item} = Color(1, 0.9529412, 0.8862745, 1)')
 for item in ['selected','selected_focus']:lines.append(f'{role}/styles/{item} = SubResource("StyleBoxFlat_h2buj")')
 lines.append(f'{role}/styles/cursor = SubResource("StyleBoxFlat_8uuti")')
for role in ['TabContainer','TabBar']:
 for item,style in [('tab_selected','h2buj'),('tab_unselected','8a8lm'),('tab_hovered','oprdq'),('tab_focus','8uuti')]:lines.append(f'{role}/styles/{item} = SubResource("StyleBoxFlat_{style}")')
 lines.extend([f'{role}/fonts/font = ExtResource("1_f6ne0")',f'{role}/font_sizes/font_size = 16'])
for line in lines:
 key=line.split(' = ')[0]
 if not re.search(r'^'+re.escape(key)+r' = ',s,re.M):s+='\n'+line
save(f,s+'\n' if not s.endswith('\n') else s)
# Apply the common theme before unowned/dynamic widgets enter the tree.
f=root/'project.godot';s=f.read_text(encoding='utf-8')
if '[gui]' not in s:s+='\n[gui]\n\ntheme/custom="res://resources/ui/onyx_theme.tres"\n'
else:
 s=s.replace('[gui]','[gui]\n\ntheme/custom="res://resources/ui/onyx_theme.tres"',1)
save(f,s)
# Explicit heading roles keep the original compact size overrides.
for folder in ['scripts/ui','scripts/phases','scripts/publishers']:
 for f in (root/folder).glob('*.gd'):
  s=f.read_text(encoding='utf-8')
  s=re.sub(r'(?m)^(\s*)(title|_title|heading|title_label|heading_label|page_title|_heading)\.add_theme_font_size_override\(',lambda m:m.group(1)+m.group(2)+'.theme_type_variation=&"HeadingLabel"\n'+m.group(0),s)
  save(f,s)
for f in (root/'scenes').rglob('*.tscn'):
 s=f.read_text(encoding='utf-8')
 s=re.sub(r'(\[node name="[^"]*(?:Title|Heading)[^"]*" type="Label"[^\n]*\]\n)(?!theme_type_variation)',r'\1theme_type_variation = &"HeadingLabel"\n',s)
 save(f,s)
# Pin card reading/counter glyphs; title is a deliberate display role.
f=root/'scenes/cards/card_view.tscn';s=f.read_text(encoding='utf-8');s=s.replace('[sub_resource type="SystemFont" id="Font_card_readable"]\nmultichannel_signed_distance_field = true','[ext_resource type="FontFile" path="res://assets/fonts/ibmplexmono/IBMPlexMono-Regular.ttf" id="6_readable"]');s=s.replace('default_font = SubResource("Font_card_readable")','default_font = ExtResource("6_readable")');save(f,s)
f=root/'scripts/cards/card_view.gd';s=f.read_text(encoding='utf-8').replace('func _ready() -> void:\n','func _ready() -> void:\n\tcard_name_label.add_theme_font_override("font",FolderUI.THEME.get_font("font",&"HeadingLabel"))\n',1);save(f,s)
# Body/heading helpers use roles, not engine font fallback.
for path,helper in [('scripts/ui/predevelopment_overlay.gd','_add_label'),('scripts/ui/guided_production_tutorial.gd','_label'),('scripts/ui/studio_finances.gd','_label'),('scripts/ui/continue_loading.gd','_label')]:
 f=root/path;s=f.read_text(encoding='utf-8')
 # Preserve explicit sizes and body text. Larger helper labels are page headings.
 marker='label.add_theme_font_size_override("font_size", font_size)'
 if marker in s:s=s.replace(marker,'label.theme_type_variation=&"HeadingLabel" if font_size>=20 else &"Label"\n\t'+marker)
 save(f,s)
f=root/'scripts/ui/continue_loading.gd';s=f.read_text(encoding='utf-8').replace('Color("10090e")','FolderUI.color(&"background")').replace('Color("f5bd59")','FolderUI.color(&"mint")');save(f,s)
# Replace unapproved decoration only; semantic category/status colors stay.
for path in ['scripts/ui/contextual_tip.gd','scripts/ui/tutorial_overlay.gd','scripts/ui/guided_production_tutorial.gd','scripts/ui/phase_workspace.gd','scripts/ui/synergy_notification.gd','scripts/ui/priority_overlay.gd']:
 f=root/path;s=f.read_text(encoding='utf-8').replace('Color("#f5bd59")','FolderUI.color(&"mint")').replace('Color("#79d4da")','FolderUI.color(&"mint")').replace('Color("#10090e")','FolderUI.color(&"background")');save(f,s)
print(json.dumps({'presentation_paths':changed,'count':len(changed)},indent=2))
