import sys; sys.path.insert(0,'/home/claude/work/v033')
from glbio import *
def parts(pos,idx):
    key=np.round(pos*10000).astype(np.int64)
    _,inv=np.unique(key,axis=0,return_inverse=True)
    tri_w=inv[idx]
    parent=np.arange(inv.max()+1)
    def find(a):
        while parent[a]!=a:
            parent[a]=parent[parent[a]]; a=parent[a]
        return a
    for t in tri_w:
        a,b_,c=find(t[0]),find(t[1]),find(t[2]); parent[b_]=a; parent[c]=a
    comp=np.array([find(v) for v in range(len(parent))])
    return comp[tri_w[:,0]], comp[inv]
def classes(col):
    sat=col.max(1)-col.min(1)
    skin=(col[:,0]>150)&(col[:,0]-col[:,2]>35)&(col[:,0]>col[:,1])
    grey=(sat<28)&(col.mean(1)>110)
    return skin,grey
if __name__=='__main__':
    name=sys.argv[1]
    g,blob,p,pos,uv,idx,tex=load('/home/claude/yugioh-crossroads/assets/models/people/%s.glb'%name)
    tcomp,vcomp=parts(pos,idx)
    cen=pos[idx].mean(1); tcol=vcolors(uv[idx].mean(1),tex); tskin,tgrey=classes(tcol)
    ids,counts=np.unique(tcomp,return_counts=True)
    print(name,'comps:')
    for c,n in sorted(zip(ids,counts),key=lambda x:-x[1])[:8]:
        m=tcomp==c
        print('  comp',c,'tris',n,'grey %.2f skin %.2f'%(tgrey[m].mean(),tskin[m].mean()),'y %.3f..%.3f'%(cen[m,1].min(),cen[m,1].max()))
    # face comp = the one with most skin tris above 1.45
    hm=cen[:,1]>1.45
    face=max(ids,key=lambda c:(tskin&hm&(tcomp==c)).sum())
    hair=max(ids,key=lambda c:((~tskin)&hm&(tcomp==c)&(cen[:,1]>1.6)).sum())
    print('  face comp',face,'hair comp',hair)
    fg=(tcomp==face)&tgrey&(cen[:,1]>1.44)&(cen[:,1]<1.56)&(cen[:,2]>0.06)
    print('  grey tris on face comp:',fg.sum())
    for t in np.where(fg)[0]:
        print('    x %.3f y %.3f z %.3f col %s'%(cen[t,0],cen[t,1],cen[t,2],tcol[t].astype(int)))
    hl=(tcomp==hair)&(cen[:,1]<1.56)&(cen[:,2]>0.06)&(abs(cen[:,0])<0.06)
    print('  hair tris low front:',hl.sum(),'y min %.3f'%cen[hl,1].min())
    import collections
    for y0 in np.arange(1.55,1.46,-0.01):
        m=hl&(cen[:,1]<=y0)&(cen[:,1]>y0-0.01)
        if m.any(): print('    y %.2f n %3d x %.3f..%.3f z %.3f..%.3f'%(y0,m.sum(),cen[m,0].min(),cen[m,0].max(),cen[m,2].min(),cen[m,2].max()))
