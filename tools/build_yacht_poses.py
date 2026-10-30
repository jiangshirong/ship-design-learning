"""Geometric immersion of the Blender hull at prescribed teaching attitudes.
This solves volume, not hydrodynamic lift or resistance. No fluid simulation.
"""
import json, math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
d=json.loads((ROOT/'modules/review/content/yacht_geometry.json').read_text())
V=[(v[0],v[2],-v[1]) for v in d['vertices']]
def cross(a,b):return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def sub(a,b):return tuple(x-y for x,y in zip(a,b))
def immersion(angle,heave):
 c,s=math.cos(math.radians(angle)),math.sin(math.radians(angle))
 vs=[(c*x-s*y,s*x+c*y+heave,z) for x,y,z in V];vol=area=0.
 for f in d['faces']:
  poly=[vs[i] for i in f];clipped=[]
  for a,b in zip(poly,poly[1:]+poly[:1]):
   if a[1]<=0:clipped.append(a)
   if (a[1]<0)!=(b[1]<0):
    t=-a[1]/(b[1]-a[1]);clipped.append(tuple(a[i]+t*(b[i]-a[i]) for i in range(3)))
  for j in range(1,len(clipped)-1):
   a,b,c=clipped[0],clipped[j],clipped[j+1]
   n=cross(b,c);vol+=sum(x*y for x,y in zip(a,n))/6
   n=cross(sub(b,a),sub(c,a));area+=math.sqrt(sum(x*x for x in n))/2
 return abs(vol),area
v0,a0=immersion(0,-d['static_draft']);rows=[]
for i in range(101):
 p=i/100;angle=14*p if p<=.5 else 10-6*p;target=v0*(1-.67*p)
 lo,hi=-2.,1.
 for _ in range(28):
  mid=(lo+hi)/2;vol,_=immersion(angle,mid)
  if vol>target:lo=mid
  else:hi=mid
 heave=(lo+hi)/2;vol,area=immersion(angle,heave)
 rows.append(dict(p=p,trim=angle,heave=heave,volume=vol,area=area,buoyancy=vol/v0,lift=1-vol/v0))
out=dict(length=d['L'],beam=d['B'],static_volume=v0,static_area=a0,rows=rows,
 method='Prescribed trim and buoyancy fraction; geometric heave bisection. Lift is required balance, not a flow prediction.')
(ROOT/'modules/review/content/yacht_poses.json').write_text(json.dumps(out,separators=(',',':')),encoding='utf8')
print(json.dumps(dict(volume=v0,area=a0,start=rows[0],end=rows[-1]),indent=2))
