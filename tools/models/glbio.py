import pygltflib, numpy as np, io
from PIL import Image
CT={5120:np.int8,5121:np.uint8,5122:np.int16,5123:np.uint16,5125:np.uint32,5126:np.float32}
NC={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}
def acc(g,blob,i):
    a=g.accessors[i]; bv=g.bufferViews[a.bufferView]
    dt=np.dtype(CT[a.componentType]); n=NC[a.type]
    off=(bv.byteOffset or 0)+(a.byteOffset or 0)
    stride=bv.byteStride or dt.itemsize*n
    if stride==dt.itemsize*n:
        arr=np.frombuffer(blob,dtype=dt,count=a.count*n,offset=off).reshape(a.count,n)
    else:
        raw=np.frombuffer(blob,dtype=np.uint8,count=stride*a.count,offset=off).reshape(a.count,stride)
        arr=raw[:,:dt.itemsize*n].copy().view(dt).reshape(a.count,n)
    return arr, off, stride
def load(path):
    g=pygltflib.GLTF2().load(path); blob=bytearray(g.binary_blob())
    p=g.meshes[0].primitives[0]
    pos,poff,_=acc(g,blob,p.attributes.POSITION)
    uv,_,_=acc(g,blob,p.attributes.TEXCOORD_0)
    idx,_,_=acc(g,blob,p.indices)
    im=g.images[0]; bv=g.bufferViews[im.bufferView]
    tex=Image.open(io.BytesIO(bytes(blob[bv.byteOffset:bv.byteOffset+bv.byteLength]))).convert('RGB')
    return g,blob,p,pos.copy(),uv.copy().astype(np.float32),idx.reshape(-1,3).astype(np.int64),tex
def vcolors(uv,tex):
    t=np.asarray(tex).astype(np.float32); H,W=t.shape[:2]
    x=np.clip((uv[:,0]%1.0)*W,0,W-1).astype(int); y=np.clip((uv[:,1]%1.0)*H,0,H-1).astype(int)
    return t[y,x]
