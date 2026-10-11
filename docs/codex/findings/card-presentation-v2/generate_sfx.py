from pathlib import Path
import math,random,wave,struct
out=Path('patch-notes/assets/audio/card_sfx');out.mkdir(parents=True,exist_ok=True)
for name,duration in [('card_play',.09),('card_whoosh',.30)]:
 rng=random.Random(100 if name=='card_play' else 200);samples=[];low=0
 for i in range(round(duration*48000)):
  t=i/48000;x=t/duration;low=.78*low+.22*rng.uniform(-1,1)
  v=(.5*low+.18*math.sin(2*math.pi*220*t)*math.exp(-t*60))*min(1,t/.002)*math.exp(-t*55)*(1-x) if name=='card_play' else .55*low*math.sin(math.pi*x)**2
  samples.append(int(max(-1,min(1,v))*32767))
 with wave.open(str(out/(name+'.wav')),'wb') as f:f.setparams((1,2,48000,len(samples),'NONE','not compressed'));f.writeframes(struct.pack('<'+'h'*len(samples),*samples))
(out/'PROVENANCE.md').write_text('Original procedural card tap (90ms) and filtered-noise whoosh (300ms), created for Patch Notes on 2026-10-10. No external samples. Mono 48kHz PCM16. User requested cues; audible mix preference pending. Generator: docs/codex/findings/card-presentation-v2/generate_sfx.py.\n',encoding='utf-8')
