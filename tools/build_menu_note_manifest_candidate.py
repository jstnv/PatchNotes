"""Derive audio note-on events from the original, source-pinned arrangements.

This is an isolated candidate; it does not modify production assets or audio.
"""
from pathlib import Path
import argparse, hashlib, json, struct, wave
import numpy as np

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--music-root', type=Path, required=True, help='Path to soundtrack/prototype-01-crunch-time')
parser.add_argument('--output', type=Path, required=True, help='Path for the extracted evidence JSON')
args = parser.parse_args()
ROOT = args.music_root
BASE = ROOT / 'Tempo_70'
MUSIC = BASE / 'Main_Menu_Theme_Echo_Dreamwave_Bass_v03'
BOOT = BASE / 'Boot_Dreamwave_Set_v05/Separate_Tracks'
SWITCH = BASE / 'Boot_Switch_v10_Rhythm_Alignment/v10_continuous_two_bar_switch.wav'
RUNTIME = Path('patch-notes/assets/boot/sequence_v1')
OUT = args.output
RATE, BPM, FRAMES, SWITCH_FRAMES = 48000, 70, 1316571, 329143
CHORDS = ((53,60,64),(53,59,64),(52,59,62),(55,61,65),
          (53,60,64),(57,62,65),(55,58,62),(55,61,64))
RESPONSES = ((1,(57,59,64)),(3,(58,61,65)),(5,(58,62,65)),(7,(58,61,64)))

def digest(path):
    h=hashlib.sha256()
    with path.open('rb') as f:
        for data in iter(lambda:f.read(1<<20),b''):h.update(data)
    return h.hexdigest()

def vlq(data, pos):
    n=0
    while True:
        b=data[pos];pos+=1;n=(n<<7)|(b&127)
        if not b&128:return n,pos

def midi(path):
    data=path.read_bytes(); assert data[:4]==b'MThd'
    form,count,ppq=struct.unpack('>HHH',data[8:14]); assert form==1 and ppq==960
    tracks={};pos=14
    for _ in range(count):
        assert data[pos:pos+4]==b'MTrk'
        end=pos+8+int.from_bytes(data[pos+4:pos+8],'big');i=pos+8;t=0;status=0;name='';notes=[]
        while i<end:
            dt,i=vlq(data,i);t+=dt
            if data[i]>=128:status=data[i];i+=1
            if status==255:
                kind=data[i];i+=1;n,i=vlq(data,i);body=data[i:i+n];i+=n
                if kind==3:name=body.decode('latin1')
                status=0
            elif status in (240,247):n,i=vlq(data,i);i+=n;status=0
            else:
                op=status>>4;n=1 if op in (12,13) else 2;body=data[i:i+n];i+=n
                if op==9 and body[1]>0:
                    frame=(t*RATE*60+BPM*ppq//2)//(BPM*ppq)
                    assert 0<=frame<FRAMES
                    notes.append({'frame':frame,'note':body[0],'velocity':body[1]})
        tracks[name]=notes;pos=end
    return tracks

def stem_audio(path):
    with wave.open(str(path),'rb') as f:
        assert f.getnchannels()==2 and f.getframerate()==RATE
        return f.getsampwidth(),f.getnframes(),f.readframes(f.getnframes())

def verify_24_to_16(src,dst):
    sw,n,a=stem_audio(src);dw,m,b=stem_audio(dst)
    assert sw==3 and dw==2 and n==m
    a=np.frombuffer(a,np.uint8).reshape(-1,3).astype(np.int32)
    a=(a[:,0]|a[:,1]<<8|a[:,2]<<16);a=(a^0x800000)-0x800000
    b=np.frombuffer(b,'<i2').astype(np.int32)
    assert np.array_equal(a>>8,b)
    return {'frames':n,'all_16bit_samples_equal_24bit_shift_8':True}

def labelled(notes,layer):
    return [dict(e,layer=layer) for e in notes]

dream_path=MUSIC/'MIDI/dreamwave_synth_and_bass.mid'
sway_path=BASE/'Main_Menu_Sway_v01/MIDI/crunch_time_menu_sway_v01.mid'
jazz_path=BASE/'MIDI/crunch_time_A_jazz_70bpm.mid'
dream,sway,jazz=map(midi,(dream_path,sway_path,jazz_path))
bass=labelled(dream['Adapted super-wet bass notes'],'adapted_bass')
low=labelled(dream['Dream Groove low synth'],'low_synth')
chord_synth=labelled(dream['Dream Groove chord synth'],'dreamwave_chord_synth')
jazz_chords=chord_synth+labelled(sway['Warm Rhodes ninth chords'],'warm_rhodes')+labelled(sway['Warm plucked strings'],'warm_plucked_strings')+labelled(jazz['Rhodes-style electric piano'],'jazz_electric_piano')+labelled(jazz['Muted electric guitar comp'],'jazz_muted_guitar')+labelled(jazz['Electronic arpeggiator'],'jazz_arpeggiator')

def comp(is_b):
    out=[]
    for bar,ch in enumerate(CHORDS):
        hits=((.75,78),(1.5,83),(2.75,73),(3.5,80)) if not is_b else ((.5,74),(1.5,82),(2.5,73),(3.5,81))
        for j,(beat,velocity) in enumerate(hits):
            for n in ch[(j+bar)%2:]:
                out.append({'frame':round((bar*4+beat)*RATE*60/BPM),'note':n,'velocity':velocity,'layer':'boot_comp_b' if is_b else 'boot_comp_a'})
    return out

responses=[{'frame':round((bar*4+2.5)*RATE*60/BPM),'note':n,'velocity':55,'layer':'boot_b_response'} for bar,notes in RESPONSES for n in notes]
def ordered(events):return sorted(events,key=lambda e:(e['frame'],e['layer'],e['note']))
def track(chords):return {'frames':FRAMES,'bass':ordered(bass),'chords':ordered(chords),'other_low_synth_optional':ordered(low)}
tracks={'startup':track(chord_synth+comp(False)),'loop_a':track(chord_synth+comp(False)),
        'loop_b':track(chord_synth+comp(True)+responses),'menu':track(jazz_chords)}
offset=FRAMES-SWITCH_FRAMES
tracks['switch']={'frames':SWITCH_FRAMES}
for key in ('bass','chords','other_low_synth_optional'):
    tracks['switch'][key]=[dict(e,frame=e['frame']-offset) for e in tracks['loop_a'][key] if offset<=e['frame']<FRAMES]

source_pairs=[(BOOT/'01_startup.wav',RUNTIME/'01_startup.wav'),(BOOT/'02_logo_loop_A.wav',RUNTIME/'02_logo_loop_A.wav'),
              (BOOT/'03_logo_loop_B.wav',RUNTIME/'03_logo_loop_B.wav'),(SWITCH,RUNTIME/'04_start_switch.wav'),
              (MUSIC/'WAV/crunch_time_menu_theme_echo_dreamwave_bass_v03.wav',RUNTIME/'crunch_time_menu_theme_echo_dreamwave_bass_v03.wav')]
conversions={dst.name:verify_24_to_16(src,dst) for src,dst in source_pairs}
def pcm(path):return stem_audio(path)[2]
assert pcm(RUNTIME/'startup_ab_continuous.wav')==b''.join(pcm(RUNTIME/x) for x in ('01_startup.wav','02_logo_loop_A.wav','03_logo_loop_B.wav'))
assert pcm(RUNTIME/'switch_menu_continuous.wav')==pcm(RUNTIME/'04_start_switch.wav')+pcm(RUNTIME/'crunch_time_menu_theme_echo_dreamwave_bass_v03.wav')
assert stem_audio(RUNTIME/'04_start_switch.wav')[1]==SWITCH_FRAMES

sources=[dream_path,sway_path,jazz_path,ROOT/'make_boot_continuous_groove.py',ROOT/'make_boot_dreamwave_set.py',ROOT/'make_boot_short_transitions.py',ROOT/'audition_boot_rhythm_alignment.py',ROOT/'make_main_menu_theme_echo_dreamwave_bass.py',ROOT/'make_main_menu_theme_echo_reverb.py',ROOT/'make_main_menu_sway.py',MUSIC/'time_map.json']+[p for pair in source_pairs for p in pair]+[RUNTIME/'startup_ab_continuous.wav',RUNTIME/'switch_menu_continuous.wav']
result={'status':'CANDIDATE; implementation and interpretation not approved by this file',
 'sample_rate':RATE,'bpm':BPM,'loop_frames':FRAMES,'switch_frames':SWITCH_FRAMES,
 'events':'Each entry is one distinct source note-on, including simultaneous chord voices; render/frame timing is integer source-sample position.',
 'chord_scope':'Dreamwave chord synth and chord/arpeggiated accompaniment. Hook, motif and percussion are not chord or bass voices; low synth is carried separately pending a role decision.',
 'notes':'Boot startup comp has zero envelope at sample 0 and is retained from its first actual comp note. Loop B includes response chord notes. Switch uses the final two bars of loop A. Samples are exact 24-bit-to-16-bit shifts with no phase change; composite streams are exact concatenations.',
 'sources':[{'path':str(p),'sha256':digest(p)} for p in sources],
 'audio_comparison':conversions,'continuous_streams_equal_concatenation':True,
 'tracks':tracks}
OUT.write_text(json.dumps(result,indent=2)+'\n',encoding='utf8')
for name,t in tracks.items():print(name,'frames',t['frames'],'bass',len(t['bass']),'chords',len(t['chords']),'optional_low',len(t['other_low_synth_optional']))
print('OUTPUT',OUT.resolve(),'sha256',digest(OUT));print('source PCM/concatenations verified')
