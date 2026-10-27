from pathlib import Path
import hashlib,json,subprocess
from PIL import Image,ImageDraw
out=Path(__file__).resolve().parent;frames=out/'reference'
frames.mkdir(exist_ok=False)
video=Path(r'C:\Users\64jus\Videos\2026-10-26 22-49-42.mp4')
ff=Path(r'C:\Program Files\Topaz Labs LLC\Topaz Video AI')
info=json.loads(subprocess.check_output([str(ff/'ffprobe.exe'),'-v','error','-show_entries','format=duration:stream=width,height,avg_frame_rate','-of','json',str(video)]))
info['path']=str(video);info['sha256']=hashlib.sha256(video.read_bytes()).hexdigest()
(out/'reference.json').write_text(json.dumps(info,indent=2))
subprocess.run([str(ff/'ffmpeg.exe'),'-nostdin','-hide_banner','-loglevel','error','-i',str(video),'-vf','fps=4,scale=640:-1',str(frames/'frame-%03d.png')],check=True)
images=sorted(frames.glob('frame-*.png'))
for page in range(2):
    canvas=Image.new('RGB',(1920,1164),'#303030');draw=ImageDraw.Draw(canvas)
    for cell in range(9):
        sec=page*9+cell;index=min(sec*4,len(images)-1)
        x=cell%3*640;y=cell//3*388
        canvas.paste(Image.open(images[index]),(x,y+28));draw.text((x+8,y+5),f'{sec:.2f}s',fill='white')
    canvas.save(frames/f'overview-{page}.jpg')
print(json.dumps(info));print('frames',len(images))
