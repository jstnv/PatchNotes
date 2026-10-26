"""Read actual PE icon resources without executing the EXE; compare every size."""
from pathlib import Path
import ctypes, hashlib, io, json, struct
from ctypes import wintypes as w
from PIL import Image

def verify(exe: Path, expected: Path, output: Path):
    kernel=ctypes.WinDLL('kernel32',use_last_error=True)
    kernel.LoadLibraryExW.argtypes=[w.LPCWSTR,w.HANDLE,w.DWORD];kernel.LoadLibraryExW.restype=w.HMODULE
    kernel.FindResourceW.argtypes=[w.HMODULE,ctypes.c_void_p,ctypes.c_void_p];kernel.FindResourceW.restype=w.HANDLE
    kernel.LoadResource.argtypes=[w.HMODULE,w.HANDLE];kernel.LoadResource.restype=w.HANDLE
    kernel.SizeofResource.argtypes=[w.HMODULE,w.HANDLE];kernel.SizeofResource.restype=w.DWORD
    kernel.LockResource.argtypes=[w.HANDLE];kernel.LockResource.restype=ctypes.c_void_p
    kernel.FreeLibrary.argtypes=[w.HMODULE];kernel.FreeLibrary.restype=w.BOOL
    callback=ctypes.WINFUNCTYPE(w.BOOL,w.HMODULE,ctypes.c_void_p,ctypes.c_void_p,ctypes.c_ssize_t)
    kernel.EnumResourceNamesW.argtypes=[w.HMODULE,ctypes.c_void_p,callback,ctypes.c_ssize_t];kernel.EnumResourceNamesW.restype=w.BOOL
    handle=kernel.LoadLibraryExW(str(exe),None,0x2|0x20)
    assert handle,ctypes.get_last_error()
    def resource(kind,name):
        found=kernel.FindResourceW(handle,name,kind);assert found,(kind,name,ctypes.get_last_error())
        pointer=kernel.LockResource(kernel.LoadResource(handle,found));assert pointer
        return ctypes.string_at(pointer,kernel.SizeofResource(handle,found))
    groups=[]
    @callback
    def visit(_module,_kind,name,_data):
        groups.append(resource(14,name));return True
    try:
        assert kernel.EnumResourceNamesW(handle,14,visit,0)
        source=Image.open(expected)
        records=[]
        for group in groups:
            reserved,kind,count=struct.unpack_from('<HHH',group)
            assert (reserved,kind)==(0,1)
            for i in range(count):
                width,height,colors,zero,planes,bits,size,identifier=struct.unpack_from('<BBBBHHIH',group,6+i*14)
                blob=resource(3,identifier);assert len(blob)==size
                ico=struct.pack('<HHH',0,1,1)+struct.pack('<BBBBHHII',width,height,colors,zero,planes,bits,size,22)+blob
                image=Image.open(io.BytesIO(ico)).convert('RGBA')
                wanted=source.ico.getimage(image.size).convert('RGBA')
                assert image.tobytes()==wanted.tobytes(),('Wrong executable icon',image.size)
                assert image.getpixel((0,0))[3]==0
                records.append({'size':list(image.size),'rgba_sha256':hashlib.sha256(image.tobytes()).hexdigest(),'exact':True,'transparent_corner':True})
        assert {tuple(row['size']) for row in records}==source.ico.sizes()
        result={'pass':True,'exe':str(exe),'ico':str(expected),'frames':records}
        output.write_text(json.dumps(result,indent=2)+'\n',encoding='utf8')
        print('Actual PE icons PASS:',[row['size'] for row in records],flush=True)
        return result
    finally:kernel.FreeLibrary(handle)
