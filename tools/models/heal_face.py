"""Close the folded-over hole on the nose bridge of hero_m1_academy, on top of the shortened lock."""
import sys; sys.path.insert(0,'/home/claude/work/v033')
from glbio import *; from analyze import parts, classes
from collections import defaultdict
import struct, pygltflib
PATH='/home/claude/yugioh-crossroads/assets/models/people/hero_m1_academy.glb'
BAD=np.array([-0.0004,1.5028,0.0908])
g,blob,p,pos,uv,idx,tex=load(PATH)
tcomp,vcomp=parts(pos,idx)
key=np.round(pos*10000).astype(np.int64)
_,inv=np.unique(key,axis=0,return_inverse=True)
tw=inv[idx]
cen=pos[idx].mean(1); tcol=vcolors(uv[idx].mean(1),tex); tskin,tgrey=classes(tcol)
ids=np.unique(tcomp); hm=cen[:,1]>1.45
face=max(ids,key=lambda c:(tskin&hm&(tcomp==c)).sum())
fverts=np.where(vcomp==face)[0]
v_bad=fverts[np.argmin(np.linalg.norm(pos[fverts]-BAD,axis=1))]
assert np.linalg.norm(pos[v_bad]-BAD)<0.002, pos[v_bad]
wb=inv[v_bad]
keep=np.ones(len(idx),bool)
keep[(tw==wb).any(1)&(tcomp==face)]=False
def boundary():
    ec=defaultdict(list)
    for ti in np.where(keep&(tcomp==face))[0]:
        t=tw[ti]; a=idx[ti]
        for k in range(3):
            e=(t[k],t[(k+1)%3])
            ec[(min(e),max(e))].append((ti,a[k],a[(k+1)%3]))
    out=[]
    for e,ts in ec.items():
        if len(ts)==1:
            ti,a,b=ts[0]
            if np.linalg.norm(pos[a]-BAD)<0.02 and np.linalg.norm(pos[b]-BAD)<0.02:
                out.append((ti,a,b))
    return out
while True:
    be=boundary(); cnt=defaultdict(int)
    for ti,a,b in be: cnt[ti]+=1
    spikes=[ti for ti,c in cnt.items() if c>=2]
    if not spikes: break
    for ti in spikes: keep[ti]=False
print('removed tris',int((~keep).sum()),'boundary edges',len(be))
# order the loop (directed edges a->b as they run in their own triangle; the fill runs the other way)
nxt={inv[a]:(inv[b],a,b) for ti,a,b in be}
start=inv[be[0][1]]; loop=[]; cur=start
for _ in range(len(be)+1):
    w,a,b=nxt[cur]; loop.append((a,b)); cur=w
    if cur==start: break
assert cur==start and len(loop)==len(be), (len(loop),len(be))
lv=[a for a,b in loop]
c=pos[lv].mean(0)
# The skin around here is cut into many small texture islands, so the patch gets its own
# vertices and one flat skin colour: the middle of the neighbouring triangle whose colour is
# the most ordinary one.
owners=[ti for ti,a,b in be]
ocol=vcolors(uv[idx[owners]].mean(1),tex)
med=np.median(ocol,axis=0)
best=owners[int(np.argmin(np.abs(ocol-med).sum(1)))]
flat=uv[idx[best]].mean(0)
print('loop',len(lv),'patch colour',vcolors(flat[None,:],tex)[0].astype(int),'median',med.astype(int))
# ---- new vertices: a copy of each loop vertex and one in the middle
attrs={k:v for k,v in p.attributes.__dict__.items() if v is not None}
arrays={}
for k,ai in attrs.items():
    arr,_,_=acc(g,blob,ai); arrays[k]=arr.copy()
n0=len(pos)
src=lv+[lv[0]]
add={}
for k,arr in arrays.items():
    rows=arr[src].copy()
    if k=='POSITION': rows[-1]=c
    if k=='TEXCOORD_0': rows[:]=flat
    if k=='NORMAL':
        rows[:]=np.array([0.0,0.12,0.99],dtype=arr.dtype)
    add[k]=np.concatenate([arr,rows])
fan=[]
mid=n0+len(lv)
P_all=add['POSITION']
for i,(a,b) in enumerate(loop):
    ia_=n0+i; ib_=n0+((i+1)%len(lv))
    assert inv[lv[(i+1)%len(lv)]]==inv[b]
    tri=[mid,ib_,ia_]
    Pt=P_all[tri]; nz=np.cross(Pt[1]-Pt[0],Pt[2]-Pt[0])[2]
    if nz<=0: print('  warning: patch triangle faces back',i)
    fan.append(tri)
new_idx=np.concatenate([idx[keep],np.array(fan,dtype=np.int64)])
def push(raw,target=None):
    while len(blob)%4: blob.append(0)
    off=len(blob); blob.extend(raw)
    g.bufferViews.append(pygltflib.BufferView(buffer=0,byteOffset=off,byteLength=len(raw),target=target))
    return len(g.bufferViews)-1
for k,ai in attrs.items():
    a_=g.accessors[ai]; arr=add[k]
    a_.bufferView=push(arr.tobytes(),34962); a_.byteOffset=0; a_.count=int(len(arr))
    if k=='POSITION':
        a_.min=[float(x) for x in arr.min(0)]; a_.max=[float(x) for x in arr.max(0)]
ia=g.accessors[p.indices]
dt=np.uint32 if ia.componentType==5125 else np.uint16
assert new_idx.max()<np.iinfo(dt).max
ia.bufferView=push(new_idx.astype(dt).tobytes(),34963); ia.byteOffset=0; ia.count=int(new_idx.size)
g.buffers[0].byteLength=len(blob)
g.set_binary_blob(bytes(blob)); g.save(PATH)
print('saved; tris',len(idx),'->',len(new_idx),'verts',n0,'->',len(P_all))
