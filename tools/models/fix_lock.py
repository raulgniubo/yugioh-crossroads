import sys; sys.path.insert(0,'/home/claude/work/v033')
from glbio import *; from analyze import parts, classes
import struct
SRC='/home/claude/work/v033/orig/hero_m1_academy.glb'
DST='/home/claude/yugioh-crossroads/assets/models/people/hero_m1_academy.glb'
YC=float(sys.argv[1]) if len(sys.argv)>1 else 1.540   # the lock now ends about here
K=float(sys.argv[2]) if len(sys.argv)>2 else 0.30
g,blob,p,pos,uv,idx,tex=load(SRC)
tcomp,vcomp=parts(pos,idx)
cen=pos[idx].mean(1); tcol=vcolors(uv[idx].mean(1),tex); tskin,tgrey=classes(tcol)
ids=np.unique(tcomp); hm=cen[:,1]>1.45
face=max(ids,key=lambda c:(tskin&hm&(tcomp==c)).sum())
hair=max(ids,key=lambda c:((~tskin)&hm&(tcomp==c)&(cen[:,1]>1.6)).sum())
assert face!=hair
fv=(vcomp==face)&(pos[:,2]>0.04)&(pos[:,1]>1.40)
# face depth map on a 3 mm grid (max z), with a small dilation
G=0.003
def cell(x,y): return (np.floor(x/G).astype(int), np.floor(y/G).astype(int))
depth={}
cx,cy=cell(pos[fv,0],pos[fv,1])
for a,b,z in zip(cx,cy,pos[fv,2]):
    depth[(a,b)]=max(depth.get((a,b),-1),z)
def zface(x,y):
    a,b=int(np.floor(x/G)),int(np.floor(y/G)); best=-1
    for da in range(-3,4):
        for db in range(-3,4):
            best=max(best,depth.get((a+da,b+db),-1))
    return best
hv=np.where((vcomp==hair)&(pos[:,1]<YC)&(pos[:,2]>0.075)&(np.abs(pos[:,0])<0.045))[0]
print('lock verts',len(hv),'y min %.3f'%pos[hv,1].min())
new=pos.copy()
moved=0
for v in hv:
    x,y,z=pos[v]
    w=1.0 if abs(x)<0.032 else max(0.0,(0.045-abs(x))/0.013)
    y2=YC-(YC-y)*(1.0-(1.0-K)*w)
    zf=zface(x,y2)
    z2=max(z, zf+0.011*w) if zf>0 else z
    new[v]=[x,y2,z2]; moved+=1
print('moved',moved,'new y min %.3f'%new[hv,1].min(),'max push z %.4f'%(new[hv,2]-pos[hv,2]).max())
# keep the hair above the cut clear of the face too (a strip just above the cut)
hv2=np.where((vcomp==hair)&(pos[:,1]>=YC)&(pos[:,1]<YC+0.03)&(pos[:,2]>0.075)&(np.abs(pos[:,0])<0.04))[0]
for v in hv2:
    x,y,z=pos[v]; zf=zface(x,y)
    if zf>0 and z<zf+0.006:
        new[v,2]=zf+0.006
# write back
a=g.accessors[p.attributes.POSITION]; bv=g.bufferViews[a.bufferView]
off=(bv.byteOffset or 0)+(a.byteOffset or 0)
stride=bv.byteStride or 12
for i in range(a.count):
    struct.pack_into('<3f',blob,off+i*stride,*[float(c) for c in new[i]])
a.min=[float(c) for c in new.min(0)]; a.max=[float(c) for c in new.max(0)]
g.set_binary_blob(bytes(blob))
g.save(DST)
print('saved',DST)
