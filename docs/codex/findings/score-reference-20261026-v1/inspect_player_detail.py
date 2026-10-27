from pathlib import Path
import subprocess
from PIL import Image,ImageDraw
out=Path(__file__).resolve().parent/'motion'
for label,start in [('player-entry-detail',4.8),('player-exit-detail',7.4)]:
    subprocess.run([r'C:\Program Files\Topaz Labs LLC\Topaz Video AI\ffmpeg.exe','-nostdin','-hide_banner','-loglevel','error','-ss',str(start),'-i',r'C:\Users\64jus\Videos\2026-10-26 22-49-42.mp4','-t','0.6','-vf','fps=20,crop=420:200:750:330',str(out/(label+'-%02d.png'))],check=True)
    canvas=Image.new('RGB',(1260,912),'#303030');draw=ImageDraw.Draw(canvas)
    for i,path in enumerate(sorted(out.glob(label+'-*.png'))[:12]):
        x=i%3*420;y=i//3*228;canvas.paste(Image.open(path),(x,y+28));draw.text((x+8,y+5),f'{start+i/20:.2f}s approx',fill='white')
    canvas.save(out/(label+'.jpg'))
