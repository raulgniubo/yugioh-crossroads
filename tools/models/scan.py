import sys,glob,os; sys.path.insert(0,'/home/claude/work/v033')
from glbio import *; from analyze import parts, classes
from collections import defaultdict
for path in sorted(glob.glob('/home/claude/yugioh-crossroads/assets/models/people/hero_*.glb')):
    name=os.path.basename(path)[:-4]
    g,blob,p,pos,uv,idx,tex=load(path)
    tcomp,vcomp=parts(pos,idx)
    key=np.round(pos*10000).astype(np.int64)
    _,inv=np.unique(key,axis=0,return_inverse=True)
    tw=inv[idx]
    top=pos[:,1].max()
    P=pos[idx]; n=np.cross(P[:,1]-P[:,0],P[:,2]-P[:,0]); nn=n/np.maximum(np.linalg.norm(n,axis=1,keepdims=True),1e-12)
    cen=P.mean(1); tcol=vcolors(uv[idx].mean(1),tex); tskin,tgrey=classes(tcol)
    ids,counts=np.unique(tcomp,return_counts=True); big={c for c,k in zip(ids,counts) if k>200}
    reg=(np.abs(cen[:,0])<0.06)&(cen[:,1]>top-0.25)&(cen[:,1]<top-0.12)&(cen[:,2]>0.06)&np.isin(tcomp,list(big))
    skinreg=reg&tskin
    back=skinreg&(nn[:,2]<-0.3)
    ec=defaultdict(list)
    for ti in np.where(np.isin(tcomp,list(big))&(cen[:,1]>top-0.3))[0]:
        t=tw[ti]
        for k in range(3):
            e=(t[k],t[(k+1)%3]); ec[(min(e),max(e))].append(ti)
    be=[ts[0] for e,ts in ec.items() if len(ts)==1 and skinreg[ts[0]]]
    print('%-22s skin tris %4d  back-facing skin %2d  boundary edges on skin %2d'%(name,skinreg.sum(),back.sum(),len(be)), ' at', sorted({(round(float(cen[t,0]),2),round(float(cen[t,1]),2)) for t in be})[:6])
