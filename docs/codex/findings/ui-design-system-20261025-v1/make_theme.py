"""Generate the shared Godot Theme resource; tokens remain in the Theme itself."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[4]
colors={'background':'20252B','secondary':'252C33','folder':'303943','active':'354852','text':'F5EEDF','muted':'A7B1BA','cyan':'40C9CF','orange':'F28A62','border':'46515B'}
def color(code):
    if code=='clear':return 'Color(0, 0, 0, 0)'
    code=colors.get(code,code)
    return 'Color('+', '.join(str(round(int(code[i:i+2],16)/255,6)) for i in [0,2,4])+', 1)'
fonts={'body':'ibmplexsans/IBMPlexSans[wdth,wght].ttf','heading':'chakrapetch/ChakraPetch-Bold.ttf','tab':'chakrapetch/ChakraPetch-SemiBold.ttf','button':'chakrapetch/ChakraPetch-Medium.ttf','mono':'ibmplexmono/IBMPlexMono-Regular.ttf'}
boxes={
 'panel':('secondary','border',1,6,12),'document':('active','clear',0,4,20),
 'normal':('folder','border',1,4,10),'hover':('active','cyan',1,4,10),
 'pressed':('active','cyan',1,4,10),'disabled':('secondary','border',1,4,10),
 'focus':('clear','cyan',2,4,0),'primary':('orange','orange',1,4,12),
 'primary_hover':('F5A17F','orange',1,4,12),
 'tab':('secondary','border',1,8,14),'tab_active':('active','cyan',1,8,14),
 'menu':('clear','clear',0,4,14),'menu_hover':('folder','cyan',1,4,14),
 'input':('background','border',1,4,12),'input_focus':('background','cyan',2,4,12),
 'card_hover':('clear','orange',2,4,0),'card_pressed':('clear','orange',1,4,0),
}
lines=['[gd_resource type="Theme" load_steps=%d format=3]'%(len(fonts)+len(boxes)+3),'']
for name,path in fonts.items():lines += ['[ext_resource type="FontFile" path="res://assets/fonts/'+path+'" id="'+name+'"]','']
for name,(fill,border,width,radius,pad) in boxes.items():
    lines += ['[sub_resource type="StyleBoxFlat" id="'+name+'"]','bg_color = '+color(fill),'border_color = '+color(border),'corner_detail = 1']
    for edge in ['left','right','top','bottom']:lines+=['border_width_'+edge+' = '+str(width),'content_margin_'+edge+' = '+str(pad if edge in ['left','right'] else (8 if pad else 0))+'.0']
    for corner in ['top_left','top_right','bottom_left','bottom_right']:lines+=['corner_radius_'+corner+' = '+str(0 if name.startswith('tab') and corner.startswith('bottom') else radius)]
    if name=='tab_active':lines+=['border_width_bottom = 0','expand_margin_bottom = 1.0']
    lines+=['']
lines+=['[sub_resource type="StyleBoxEmpty" id="clear"]','','[sub_resource type="FontVariation" id="body_bold"]','base_font = ExtResource("body")','variation_opentype = {"wght": 700.0}','','[resource]','default_font = ExtResource("body")','default_font_size = 16']
for name,value in colors.items():lines+=['PatchNotes/colors/'+name+' = '+color(value)]
for kind in ['Label','Button','LineEdit','CheckBox','CheckButton','OptionButton','RichTextLabel']:
    lines += [kind+'/colors/font_color = '+color('text'),kind+'/colors/font_disabled_color = '+color('muted')]
for kind in ['Button','CheckBox','CheckButton','OptionButton']:
    lines += [kind+'/fonts/font = ExtResource("button")']
for state in ['normal','hover','pressed','disabled','focus']:
    lines += ['Button/styles/'+state+' = SubResource("'+state+'")']
lines+=['Button/styles/hover_pressed = SubResource("pressed")','PanelContainer/styles/panel = SubResource("panel")',
        'RichTextLabel/fonts/normal_font = ExtResource("body")','RichTextLabel/fonts/bold_font = SubResource("body_bold")',
        'LineEdit/styles/normal = SubResource("input")','LineEdit/styles/focus = SubResource("input_focus")',
        'LineEdit/colors/caret_color = '+color('cyan'),'LineEdit/colors/font_placeholder_color = '+color('muted'),
        'TooltipLabel/fonts/font = ExtResource("body")','TooltipLabel/colors/font_color = '+color('text'),'TooltipPanel/styles/panel = SubResource("panel")']
for name,(base,font,size) in {
    'HeadingLabel':('Label','heading',30),'FolderHeading':('Label','heading',24),
    'SecondaryLabel':('Label','body',16),'MetadataLabel':('Label','mono',14),
    'PrimaryButton':('Button','tab',17),'TitleMenuButton':('Button','tab',20),
    'FolderTab':('Button','tab',17),'SidebarButton':('Button','tab',16),
    'MetadataButton':('Button','mono',14),
}.items():
    lines += [name+'/base_type = &"'+base+'"',name+'/fonts/font = ExtResource("'+font+'")',name+'/font_sizes/font_size = '+str(size)]
lines+=['SecondaryLabel/colors/font_color = '+color('muted'),'PrimaryButton/colors/font_color = '+color('background')]
for state,box in [('normal','primary'),('hover','primary_hover'),('pressed','primary_hover'),('hover_pressed','primary_hover')]:lines+=['PrimaryButton/styles/'+state+' = SubResource("'+box+'")']
for kind in ['FolderTab','SidebarButton']:
    for state,box in [('normal','tab'),('hover','hover'),('pressed','tab_active'),('hover_pressed','tab_active')]:lines+=[kind+'/styles/'+state+' = SubResource("'+box+'")']
for state,box in [('normal','menu'),('hover','menu_hover'),('pressed','pressed')]:lines+=['TitleMenuButton/styles/'+state+' = SubResource("'+box+'")']
for kind,box in [('FolderPanel','panel'),('DocumentPanel','document')]:lines += [kind+'/base_type = &"PanelContainer"',kind+'/styles/panel = SubResource("'+box+'")']
lines+=['CardInput/base_type = &"Button"','CardInput/styles/normal = SubResource("clear")','CardInput/styles/disabled = SubResource("clear")','CardInput/styles/hover = SubResource("card_hover")','CardInput/styles/pressed = SubResource("card_pressed")','CardInput/styles/focus = SubResource("focus")','VSlider/styles/grabber_area = SubResource("pressed")','VSlider/styles/grabber_area_highlight = SubResource("hover")']
(ROOT/'patch-notes/resources/ui/workspace_theme.tres').write_text('\n'.join(lines)+'\n',encoding='utf8')
