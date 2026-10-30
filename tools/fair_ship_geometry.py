"""Fair, closed teaching hull. Does not alter the validated stability envelope.

Monotone Hermite section/waterline interpolation, a non-folding raked stem and
a single continuous bulb morph replace the old folded end-ring/fan construction.
Coordinates: Blender x forward, y port, z up; metres.
"""
import math

B,H,T=26.60,14.89,10.88
END=94.82
STATIONS=[(-98,.42),(-92,.66),(-80,.88),(-64,1),(-44,1),(40,1),(58,.93),(72,.78),(82,.55),(90,.27),(END,0.)]
PROFILE=[(0,0),(.70,0),(.79,.01),(.86,.03),(.92,.065),(.967,.11),(1,.18),(1,3.4/H),(1,.40),(1,6.8/H),(1,10.2/H),(1,11.35/H),(1,.92),(1,1)]

def smooth(a,b,x):
    t=max(0.,min(1.,(x-a)/(b-a)));return t*t*(3-2*t)

def pchip(xs,ys,x):
    """Shape-preserving C1 Hermite; never introduces overshooting lobes."""
    n=len(xs);h=[xs[i+1]-xs[i] for i in range(n-1)]
    delta=[(ys[i+1]-ys[i])/h[i] for i in range(n-1)]
    m=[0.]*n
    for i in range(1,n-1):
        a,b=delta[i-1],delta[i]
        if a*b>0:
            w1=2*h[i]+h[i-1];w2=h[i]+2*h[i-1];m[i]=(w1+w2)/(w1/a+w2/b)
    for idx,d0,d1,h0,h1 in [(0,delta[0],delta[1],h[0],h[1]),(n-1,delta[-1],delta[-2],h[-1],h[-2])]:
        v=((2*h0+h1)*d0-h0*d1)/(h0+h1)
        m[idx]=0. if v*d0<=0 else (3*d0 if d0*d1<0 and abs(v)>3*abs(d0) else v)
    if x<=xs[0]:return ys[0]
    if x>=xs[-1]:return ys[-1]
    i=next(i for i in range(n-1) if xs[i]<=x<=xs[i+1]);q=(x-xs[i])/h[i]
    return (2*q**3-3*q*q+1)*ys[i]+(q**3-2*q*q+q)*h[i]*m[i]+(-2*q**3+3*q*q)*ys[i+1]+(q**3-q*q)*h[i]*m[i+1]

def deck(s):return H+1.1*max(0.,(s-53)/(END-53))**2+.45*max(0.,(-s-68)/30)**2
def half_width(s):return B*.5*pchip([p[0] for p in STATIONS],[p[1] for p in STATIONS],s)
def stem(z):
    # Same waterline and upper tip as before; one smooth, forward-raked curve.
    x0=88.5;ztop=deck(END);xtop=END+(ztop-T)*5.18/(H-T)
    b=((xtop-x0)/ztop-(END-x0)/T)/(ztop-T);a=(END-x0)/T-b*T
    return x0+a*z+b*z*z

def build():
    refs=[-98+i*(END+98)/48 for i in range(49)]
    # Keep the existing midship station (index24); densify only the forebody.
    stations=[]
    for i,s in enumerate(refs[:-1]):
        for k in range(4 if i>=35 else 1):stations.append(s+(refs[i+1]-s)*k/(4 if i>=35 else 1))
    stations.append(END)
    vertices=[];half_count=0
    for s in stations:
        rise=6.2*max(0.,(-s-66)/32)**2
        half=[(y,rise+(deck(s)-rise)*z) for y,z in PROFILE]
        if s>=-64:
            # Exact bulb-height planes keep its nose genuinely rounded.
            half[7]=(1.,3.4);half[9]=(1.,6.8)
        for i in range(len(half)-1):
            if half[i][1]<T<half[i+1][1]:
                a,z0=half[i];b,z1=half[i+1];half.insert(i+1,(a+(b-a)*(T-z0)/(z1-z0),T));break
        t=list(range(len(half)));dense=[]
        for j in range((len(half)-1)*3+1):
            q=j/3;y=pchip(t,[p[0] for p in half],q)*half_width(s);z=pchip(t,[p[1] for p in half],q)
            x=s+smooth(65,END,s)*(stem(z)-END)
            dense.append((x,y,z))
        half_count=len(dense);vertices.extend(dense+[(x,-y,z) for x,y,z in dense[:0:-1]])
    n=2*half_count-1;nr=len(stations);mapping={};tip={}
    for j in range(n):
        idx=(nr-1)*n+j;p=vertices[idx];key=tuple(round(c,9) for c in p)
        mapping[idx]=tip.setdefault(key,idx)
    faces=[];deck_faces=[]
    def add(f,on_deck=False):
        f=tuple(mapping.get(i,i) for i in f)
        if len(set(f))<3:return
        a,b,c=[vertices[i] for i in f]
        cross=((b[1]-a[1])*(c[2]-a[2])-(b[2]-a[2])*(c[1]-a[1]),(b[2]-a[2])*(c[0]-a[0])-(b[0]-a[0])*(c[2]-a[2]),(b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0]))
        if sum(v*v for v in cross)<1e-18:return
        if on_deck:deck_faces.append(len(faces))
        faces.append(f)
    for i in range(nr-1):
        for j in range(n):
            a=i*n+j;b=i*n+(j+1)%n;c=b+n;d=a+n
            for tri in ([(a,b,c),(a,c,d)] if j<=n//2 else [(a,b,d),(b,c,d)]):add(tri,j==half_count-1)
    centre=len(vertices);vertices.append((-98,0,T))
    for j in range(n):add((centre,(j+1)%n,j))
    total=sum(vertices[a][0]*(vertices[b][1]*vertices[c][2]-vertices[b][2]*vertices[c][1])+vertices[a][1]*(vertices[b][2]*vertices[c][0]-vertices[b][0]*vertices[c][2])+vertices[a][2]*(vertices[b][0]*vertices[c][1]-vertices[b][1]*vertices[c][0]) for a,b,c in faces)
    if total<0:faces=[tuple(reversed(f)) for f in faces]
    return dict(vertices=vertices,faces=faces,ring_size=n,ring_count=nr,stations=stations,deck_faces=deck_faces,midship_index=24,fairing='PCHIP-C1 sections and width; welded smooth quadratic stem; continuous hull bulb morph')

def bulb(p):
    x,y,z=p
    if not 0<z<6.8 or x<80:return p
    span=max(1.,stem(z)-80);u=max(0.,min(1.,(x-80)/span))
    bump=max(0.,1-((z-3.4)/3.4)**2)**2
    # At the nose-height tip dx/du becomes zero: width then grows as sqrt(dx),
    # giving a rounded nose instead of the former conical/knife-like tip.
    extension=11.5*u*u*(3-2*u)+span*u**4*(1-u)
    return (x+extension*bump,y,z)

def fit_deck_point(p,legacy):
    """Fit original railings/gear to the new deck edge, preserving their height."""
    x,y,z=p
    if x<=40 or z<10:return p
    n=legacy['ring_size'];rows=[legacy['vertices'][i*n+n//2] for i in range(legacy['ring_count'])]
    old_x=[p[0] for p in rows];refs=[-98+i*(END+98)/48 for i in range(len(rows))]
    s=pchip(old_x,refs,x)
    old_w=pchip(old_x,[p[1] for p in rows],x)
    target_x=s+smooth(65,END,s)*(stem(deck(s))-END)
    delta=target_x-x
    ratio=half_width(s)/max(.16,old_w)
    return (x+delta,y*ratio,z)
