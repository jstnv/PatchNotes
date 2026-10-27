"""Read-only bounded checkout inventory; skips directory links and never reads file data."""
from pathlib import Path
from collections import defaultdict
import ctypes,heapq,json,os,stat,time

out=Path(__file__).resolve().parent;root=out.parents[3]
assert root==Path(r'C:\Users\64jus\OneDrive\Documents\GitHub\PatchNotes')
kernel=ctypes.WinDLL('kernel32',use_last_error=True)
compressed=kernel.GetCompressedFileSizeW
compressed.argtypes=[ctypes.c_wchar_p,ctypes.POINTER(ctypes.c_uint32)];compressed.restype=ctypes.c_uint32
started=time.monotonic();last=started;count=0;seen=set();errors=[];links=[]
groups={};caches=[];extensions=defaultdict(lambda:[0,0]);big=[]

def allocated(path,st):
    high=ctypes.c_uint32();ctypes.set_last_error(0)
    low=compressed('\\\\?\\'+str(path),ctypes.byref(high))
    if low==0xffffffff and ctypes.get_last_error():
        errors.append({'path':str(path.relative_to(root)),'allocation_error':ctypes.get_last_error()})
        return st.st_size
    return (high.value<<32)|low

def scan(folder):
    global count,last
    logical=physical=files=0;latest=0
    try:
        entries=list(os.scandir(folder))
    except OSError as exc:
        errors.append({'path':str(folder.relative_to(root)),'error':str(exc)});return (0,0,0,0)
    for entry in entries:
        path=Path(entry.path)
        try:
            st=entry.stat(follow_symlinks=False)
            if getattr(st,'st_reparse_tag',0) in [0xa0000003,0xa000000c]:
                links.append(str(path.relative_to(root)));continue
            if stat.S_ISDIR(st.st_mode):
                a,b,c,d=scan(path);logical+=a;physical+=b;files+=c;latest=max(latest,d)
            elif stat.S_ISREG(st.st_mode):
                count+=1;files+=1;logical+=st.st_size;latest=max(latest,st.st_mtime_ns)
                # Some sandbox metadata providers return inode zero for every file.
                # Such values cannot identify hard links or physical allocation.
                ident=(st.st_dev,st.st_ino) if st.st_ino else str(path)
                size=0 if ident in seen else allocated(path,st)
                seen.add(ident);physical+=size
                suffix=path.suffix.lower() or '<none>';extensions[suffix][0]+=st.st_size;extensions[suffix][1]+=1
                row=(st.st_size,str(path.relative_to(root)),size)
                if len(big)<80:heapq.heappush(big,row)
                elif row>big[0]:heapq.heapreplace(big,row)
                if time.monotonic()-last>8:
                    print(json.dumps({'files':count,'elapsed':round(time.monotonic()-started,1),'at':str(path.relative_to(root))}),flush=True);last=time.monotonic()
        except OSError as exc:
            errors.append({'path':str(path.relative_to(root)),'error':str(exc)})
    rel=str(folder.relative_to(root))
    data={'path':rel,'logical_bytes':logical,'allocated_bytes':physical,'files':files,'latest_mtime_ns':latest}
    if len(folder.relative_to(root).parts)<=4:groups[rel]=data
    if folder.name in ['.godot','__pycache__','node_modules']:
        caches.append(data)
    return logical,physical,files,latest

total=scan(root)
report={'root':str(root),'elapsed_seconds':round(time.monotonic()-started,3),'logical_bytes':total[0],
        'allocated_bytes':total[1],'files':count,'unique_files':len(seen),'groups':sorted(groups.values(),key=lambda r:r['logical_bytes'],reverse=True),
        'caches':sorted(caches,key=lambda r:r['logical_bytes'],reverse=True),'largest_files':[{'logical_bytes':a,'path':b,'allocated_bytes':c} for a,b,c in sorted(big,reverse=True)],
        'extensions':dict(sorted(extensions.items(),key=lambda item:item[1][0],reverse=True)),
        'skipped_links':links,'errors':errors,'notes':'Allocation deduplicates hard links; filesystem directory overhead is excluded. No file contents were read.'}
if any(isinstance(item,str) for item in seen):
    report['allocated_bytes']=None
    report['unique_files']=None
    for row in report['groups']+report['caches']+report['largest_files']:
        row['allocated_bytes']=None
    report['notes']='Logical sizes only: metadata provider returned zero inode values, so hard-link identity and physical allocation are unavailable. Inaccessible folders are excluded. No file contents were read.'
(out/'inventory.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({k:report[k] for k in ['logical_bytes','allocated_bytes','files','elapsed_seconds']},indent=2))
for row in report['groups']:
    if len(Path(row['path']).parts)==1:print(f"{row['logical_bytes']/2**30:8.2f} GiB logical | {row['path']}")
print('CACHE TOTAL GiB',sum(r['logical_bytes'] for r in caches)/2**30)
