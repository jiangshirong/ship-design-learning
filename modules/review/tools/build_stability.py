"""Closed teaching envelope derived from build_learning_tanker.py's loft.
No decorative mesh participates in hydrostatics. Python is build-time only.
Coordinates x forward, y port, z up. Heel: y'=y cos+z sin, z'=-y sin+z cos.
"""
import json, math, time
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
B,H,T=26.60,14.89,10.88
PROFILE=[(0,0),(.70,0),(.79,.01),(.86,.03),(.92,.065),(.967,.11),(1,.18),(1,.40),(1,10.2/H),(1,11.35/H),(1,.92),(1,1)]
STATIONS=[(-98,.42),(-92,.66),(-80,.88),(-64,1),(-44,1),(40,1),(58,.93),(72,.78),(82,.55),(90,.27),(94.82,.012)]
def width(x):
    for (a,wa),(b,wb) in zip(STATIONS,STATIONS[1:]):
        if a<=x<=b:
            q=(x-a)/(b-a);q=q*q*(3-2*q);return B/2*(wa+(wb-wa)*q)
    return B/2*.012
def hull(route='base',amount=0):
    breadth=B*(1-.10*amount if route=='narrow' else 1)
    depth=H-2*amount if route=='lower' else H
    draft=T+1.0*amount if route=='draft' else T
    rings=[]
    for x in np.linspace(-98,94.82,49):
        rise=6.2*max(0,(-x-66)/32)**2
        sheer=1.1*max(0,(x-53)/(94.82-53))**2+.45*max(0,(-x-68)/30)**2
        half=[(y,rise+(H+sheer-rise)*zf) for y,zf in PROFILE]
        for i in range(len(half)-1):
            if half[i][1]<T<half[i+1][1]:
                y0,z0=half[i];y1,z1=half[i+1];half.insert(i+1,(y0+(y1-y0)*(T-z0)/(z1-z0),T));break
        profile=half+ [(-y,z) for y,z in half[:0:-1]]
        ring=[]
        for y,z in profile:
            y=y*width(x)*breadth/B
            if route=='shape':y*=1-.32*amount*max(0,1-z/T)**2
            rake=max(0,(x-75)/(94.82-75))**3*(z-T)*5.18/(H-T)
            if z>T:z=T+(z-T)*(depth-T)/(H-T)
            ring.append([float(x+rake),float(y),float(z)])
        rings.append(ring)
    vertices=np.array(rings).reshape(-1,3);n=len(rings[0]);faces=[]
    for i in range(len(rings)-1):
        for j in range(n):
            a=i*n+j;b=i*n+(j+1)%n;c=b+n;d=a+n
            # Mirror diagonals across the centreplane. Non-planar loft quads
            # must not give the two sides subtly different enclosed volumes.
            faces.extend([(a,b,c),(a,c,d)] if j<=n//2 else [(a,b,d),(b,c,d)])
    for i,reverse in [(0,True),(len(rings)-1,False)]:
        # Fan from the unchanged design waterline, so raising/lowering the
        # above-water bow never changes submerged end-cap triangulation.
        centre=len(vertices);vertices=np.vstack([vertices,[[-98 if i==0 else 94.82,0,T]]])
        for j in range(n):
            f=(centre,i*n+j,i*n+(j+1)%n);faces.append(f[::-1] if reverse else f)
    faces=np.array(faces)
    tri=vertices[faces]
    signed=np.einsum('ij,ij->i',tri[:,0],np.cross(tri[:,1],tri[:,2])).sum()/6
    if signed<0:faces=faces[:,::-1]
    return vertices,faces,dict(B=breadth,H=depth,T=draft)
def rotate(v,deg):
    a=math.radians(deg);r=v.copy();r[:,1]=v[:,1]*math.cos(a)+v[:,2]*math.sin(a);r[:,2]=-v[:,1]*math.sin(a)+v[:,2]*math.cos(a);return r
def immersed(tri,level,centroid=False):
    """Oriented clipped triangles; cap lies in reference plane so tetra volume=0."""
    inside=tri[:,:,2]<=level;counts=inside.sum(axis=1);chunks=[tri[counts==3]]
    for count in (1,2):
        a=tri[counts==count]
        if not len(a):continue
        mask=inside[counts==count]
        start=np.argmax(mask if count==1 else ~mask,axis=1)
        v=a[np.arange(len(a))[:,None],(start[:,None]+np.arange(3))%3]
        p,q,r=v[:,0],v[:,1],v[:,2]
        t=((level-p[:,2])/(q[:,2]-p[:,2]))[:,None];u=((level-p[:,2])/(r[:,2]-p[:,2]))[:,None]
        pq=p+t*(q-p);pr=p+u*(r-p)
        if count==1:chunks.append(np.stack([p,pq,pr],axis=1))
        else:chunks.extend([np.stack([pq,q,r],axis=1),np.stack([pq,r,pr],axis=1)])
    a=np.concatenate(chunks).copy();a[:,:,2]-=level
    vol=np.einsum('ij,ij->i',a[:,0],np.cross(a[:,1],a[:,2]))/6
    total=vol.sum()
    if not centroid:return float(total)
    centre=(vol[:,None]*a.sum(axis=1)/4).sum(axis=0)/total;centre[2]+=level
    return float(total),centre
def solve(vertices,faces,target,angle):
    rot=rotate(vertices,angle);tri=rot[faces];lo=float(rot[:,2].min());hi=float(rot[:,2].max())
    for _ in range(24):
        mid=(lo+hi)/2
        if immersed(tri,mid)<target:lo=mid
        else:hi=mid
    level=(lo+hi)/2;vol,c=immersed(tri,level,True)
    return [level,*map(float,c),float((vol-target)/target)]
def waterplane(tri,level):
    points=[]
    for face in tri:
        intersections=[]
        for a,b in zip(face,np.roll(face,-1,axis=0)):
            if (a[2]<level)!=(b[2]<level):intersections.append(a+(b-a)*(level-a[2])/(b[2]-a[2]))
        if len(intersections)!=2:continue
        p,q=intersections;normal=np.cross(face[1]-face[0],face[2]-face[0])
        if np.dot(q-p,np.cross([0,0,1],normal))<0:p,q=q,p
        points.append((p,q))
    area=ix=0.
    for p,q in points:
        cross=p[0]*q[1]-q[0]*p[1];area+=cross/2;ix+=cross*(p[1]**2+p[1]*q[1]+q[1]**2)/12
    return area,ix
def main():
    start=time.time();angles=sorted(set([0,.05,.1,.25,.5,.75]+[float(x) for x in range(1,181)]))
    result={'version':1,'axes':'x forward, y port, z up','angles':angles,'routes':{},'source':'build_learning_tanker.py loft; closed main-hull envelope, no deckhouse buoyancy; no downflooding; fixed trim','samples':6}
    errors=[]
    for route in ['base','narrow','lower','draft','shape']:
        series=[]
        for k in range(1 if route=='base' else 7):
            if k==0 and route!='base':series.append(result['routes']['base'][0]);continue
            amount=k/6;vertices,faces,params=hull(route,amount)
            volume,c=immersed(vertices[faces],params['T'],True)
            row=[solve(vertices,faces,volume,a) for a in angles]
            # d(C_world.y)/dtheta at zero = KM, computed from exact clipped geometry.
            area,ix=waterplane(vertices[faces],params['T']);zc=float(c[2]);km=zc+ix/volume
            item={'amount':amount,'params':params,'volume':volume,'waterplane_area':area,'ix':ix,'zc':zc,'km':km,'r':km-zc,'ring_size':25,'ring_count':49,'vertices':vertices.round(8).tolist(),'faces':faces.tolist(),'hydro':row}
            series.append(item);errors.extend(abs(r[-1]) for r in row)
            print(route,k,'V',round(volume,2),'KM',round(km,4),'elapsed',round(time.time()-start),flush=True)
        result['routes'][route]=series
    (ROOT/'content/stability_hydro.json').write_text(json.dumps(result,separators=(',',':')),encoding='utf-8')
    print('DONE max relative volume residual',max(errors),'seconds',time.time()-start,flush=True)
if __name__=='__main__':main()
