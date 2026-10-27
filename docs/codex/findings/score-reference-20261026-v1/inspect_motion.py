from pathlib import Path
import subprocess,hashlib,json
from PIL import Image,ImageDraw
out=Path(__file__).resolve().parent;frames=out/'motion'
frames.mkdir(exist_ok=False)
video=r'C:\Users\64jus\Videos\2026-10-26 22-49-42.mp4'
ff=r'C:\Program Files\Topaz Labs LLC\Topaz Video AI\ffmpeg.exe'
for label,start in [('players-in',4.4),('players-out',7.0)]:
    subprocess.run([ff,'-nostdin','-hide_banner','-loglevel','error','-ss',str(start),'-i',video,'-t','1.2','-vf','fps=10,crop=420:240:750:450',str(frames/(label+'-%02d.png'))],check=True)
    canvas=Image.new('RGB',(1260,1072),'#303030');draw=ImageDraw.Draw(canvas)
    for index,path in enumerate(sorted(frames.glob(label+'-*.png'))[:12]):
        x=index%3*420;y=index//3*268
        canvas.paste(Image.open(path),(x,y+28));draw.text((x+8,y+5),f'{start+index/10:.2f}s approx',fill='white')
    canvas.save(frames/(label+'.jpg'))
source=Path(r'C:\Users\64jus\OneDrive\Documents\GitHub\outtapocket\outta-pocket\scripts\game_screen.gd')
lines=source.read_text().splitlines()
pin={'path':str(source),'sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'player_in':[360,408],'player_out':[411,422],'assign_skip_in':[425,444],'notes':'Read-only source reference; clip-to-build identity not established.'}
(out/'outta-pocket-source.json').write_text(json.dumps(pin,indent=2))
(out/'outta-pocket-snippet.txt').write_text('\n'.join(f'{i+1}: {lines[i]}' for i in range(359,444)))
