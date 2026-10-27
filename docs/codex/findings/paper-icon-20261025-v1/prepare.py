"""Copy the generated master unchanged; convert to native Windows ICO frames."""
from pathlib import Path
import argparse, hashlib, json, shutil, struct
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
RAW = Path('C:/Users/64jus/AppData/Local/Temp/pn-paper-icon-20261025-v1')
SIZES = [16, 32, 48, 64, 128, 256]
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
parser = argparse.ArgumentParser()
parser.add_argument('generated', type=Path)
parser.add_argument('--verify-existing', action='store_true')
args = parser.parse_args()
RAW.mkdir(exist_ok=args.verify_existing)
assets = ROOT/'patch-notes/assets/branding'
logo = assets/'patch_notes_logo.png'
png = assets/'patch_notes_paper.png'
ico = assets/'patch_notes_paper.ico'
original = sha(logo)
if args.verify_existing:
    assert sha(png) == sha(args.generated)
else:
    assert not png.exists() and not ico.exists()
    shutil.copy2(args.generated, png)
image = Image.open(png)
assert image.mode == 'RGBA' and image.width == image.height
assert image.getextrema()[3] == (0, 255)
assert all(image.getpixel(p)[3] == 0 for p in [(0,0),(0,image.height-1),(image.width-1,0),(image.width-1,image.height-1)])
bounds = image.getchannel('A').getbbox()
assert bounds and bounds[0] > 0 and bounds[1] > 0 and bounds[2] < image.width and bounds[3] < image.height
if not args.verify_existing:
    image.save(ico, format='ICO', sizes=[(s,s) for s in SIZES], bitmap_format='bmp')
native = Image.open(ico)
assert native.ico.sizes() == {(s,s) for s in SIZES}
data = ico.read_bytes()
frames = []
for index, size in enumerate(SIZES):
    entry = struct.unpack_from('<BBBBHHII', data, 6+16*index)
    assert entry[5] == 32
    frame = native.ico.getimage((size,size)).convert('RGBA')
    assert frame.getpixel((0,0))[3] == 0 and frame.getchannel('A').getbbox()
    frames.append({'size':size, 'bits':entry[5], 'transparent_corner':True,
                   'rgba_sha256':hashlib.sha256(frame.tobytes()).hexdigest()})
assert sha(png) == sha(args.generated) and sha(logo) == original

# Preview-only comparison; the project assets above are not composited/edited.
proof = Image.new('RGB', (960, 440), '#20252B')
draw = ImageDraw.Draw(proof)
draw.text((18,12), 'Old full-logo icon', fill='#F5EEDF')
draw.text((514,12), 'New paper icon', fill='#F5EEDF')
old = Image.open(assets/'patch_notes.ico')
for row, background in enumerate(['#E9EBED', '#20252B']):
    y = 50+row*180
    draw.rectangle((0,y,959,y+174), fill=background)
    ink = '#20252B' if row == 0 else '#F5EEDF'
    for index, size in enumerate([16,32,48,64,128]):
        x = 14+index*76
        for offset, source in [(0,old), (500,native)]:
            sample = source.ico.getimage((size,size)).convert('RGBA')
            proof.paste(sample,(x+offset,y+28),sample)
            draw.text((x+offset,y+8),str(size)+'px',fill=ink)
proof.save(HERE/'icon-comparison.png')
report = {'pass':True,'tool':'built-in image_gen','generated':str(args.generated),
          'png':{'path':str(png.relative_to(ROOT)), 'sha256':sha(png),'pixels':list(image.size),'alpha_bounds':bounds},
          'ico':{'path':str(ico.relative_to(ROOT)), 'sha256':sha(ico),'frames':frames},
          'wordmark_unchanged':True,'wordmark_sha256':original,
          'conversion':'PNG copied unchanged; Pillow ICO format conversion to six 32-bit DIB frames; comparison is preview-only'}
(HERE/'asset-result.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print(json.dumps(report),flush=True)
