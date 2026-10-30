"""Independent analytic examples + interpolation/error and curriculum invariants."""
import json,math
from pathlib import Path
import numpy as np
from build_stability import immersed,solve,waterplane,rotate
ROOT=Path(__file__).resolve().parents[1]
checks=[]
def check(ok,name,value=None):checks.append(dict(name=name,passed=bool(ok),value=value))
v=np.array([[-10,-3,0],[-10,3,0],[-10,3,4],[-10,-3,4],[10,-3,0],[10,3,0],[10,3,4],[10,-3,4]],dtype=float)
f=np.array([[0,2,1],[0,3,2],[4,5,6],[4,6,7],[0,1,5],[0,5,4],[1,2,6],[1,6,5],[2,3,7],[2,7,6],[3,0,4],[3,4,7]])
# Orient from centre once; expected box quantities do not use hull generator.
for face in f:
 if np.dot(np.cross(v[face[1]]-v[face[0]],v[face[2]]-v[face[0]]),v[face].mean(axis=0)-[0,0,2])<0:face[1],face[2]=face[2],face[1]
volume,c=immersed(v[f],2,True);area,ix=waterplane(v[f],2)
check(abs(volume-240)<1e-9,'Box displacement volume 20*6*2',volume)
check(np.linalg.norm(c-[0,0,1])<1e-10,'Box buoyancy centre',c.tolist())
check(abs(ix/volume-6**2/(12*2))<1e-10,'Box BM=B²/(12T)',ix/volume)
check(abs(area-120)<1e-10,'Box waterplane area',area)
data=json.loads((ROOT/'content/stability_hydro.json').read_text());angles=np.array(data['angles']);max_res=max_arm=0
base=data['routes']['base'][0]
def curve(s,zg):return np.array(s['hydro'])[:,2]-zg*np.sin(np.deg2rad(angles))
def avs(c):
 for i in range(1,len(c)):
  if c[i-1]>0>=c[i]:return angles[i-1]+(angles[i]-angles[i-1])*c[i-1]/(c[i-1]-c[i])
 return -1
for route,series in data['routes'].items():
 for s in series:
  vertices=np.array(s['vertices']);faces=np.array(s['faces']);tri=vertices[faces]
  # Manifold edge test independent of volume solver.
  edges={}
  for a,b,c_ in faces:
   for edge in [(a,b),(b,c_),(c_,a)]:edges.setdefault(tuple(sorted(edge)),[]).append(edge)
  check(all(len(e)==2 and e[0]==e[1][::-1] for e in edges.values()),route+' closed consistently oriented manifold '+str(s['amount']))
  h=s['km']-8.7;arm=curve(s,8.7)
  check(abs(arm[1]/math.radians(angles[1])-h)<.004,'Initial slope equals independently computed GM '+route,float(arm[1]/math.radians(angles[1])-h))
  check(max(abs(r[-1]) for r in s['hydro'])<1e-6,'Bisection volume residual '+route)
 if route!='base':
  for fraction,angle in [(.0833,7.37),(.25,27.41),(.4167,63.47),(.5833,100.7),(.9167,144.2)]:
   x=fraction*6;i=int(x);t=x-i;a,b=series[i:i+2]
   vertices=np.array(a['vertices'])*(1-t)+np.array(b['vertices'])*t;faces=np.array(a['faces']);target=a['volume']*(1-t)+b['volume']*t
   row=(1-t)*np.array([np.interp(angle,angles,np.array(a['hydro'])[:,k]) for k in range(5)])+t*np.array([np.interp(angle,angles,np.array(b['hydro'])[:,k]) for k in range(5)])
   vol,c=immersed(rotate(vertices,angle)[faces],row[0],True);res=abs(vol/target-1);max_res=max(max_res,res)
   direct=solve(vertices,faces,target,angle);error=abs(row[2]-direct[2]);max_arm=max(max_arm,error)
   check(res<.0005,'Interpolated animation volume '+route+str(fraction),res)
   check(error<.015,'Interpolated animation buoyancy arm '+route+str(fraction),error)
for angle in [3,23,61,115]:
 v=np.array(base['vertices']);f=np.array(base['faces']);a=solve(v,f,base['volume'],angle);b=solve(v,f,base['volume'],-angle)
 check(abs(a[2]+b[2])<1e-8 and abs(a[0]-b[0])<1e-8,'Port/starboard symmetry '+str(angle))
old=curve(base,8.7);new=curve(base,7.7)
check(np.max(abs(new-old-np.sin(np.deg2rad(angles))))<1e-10,'G shift exact sine correction')
check(avs(new)>avs(old)>0,'Lower G increases AVS',[avs(old),avs(new)])
check(new.max()>old.max(),'Lower G increases peak')
lower=data['routes']['lower'][-1];narrow=data['routes']['narrow'][-1]
check(abs(lower['volume']/base['volume']-1)<1e-6,'H change preserves upright underwater volume (relative 1e-6)',lower['volume']-base['volume'])
check(abs(lower['km']-base['km'])<1e-4,'H change preserves initial KM (0.1 mm)',lower['km']-base['km'])
check(curve(lower,8.7).max()<old.max(),'Lower H reduces peak with G fixed')
check(0<narrow['km']-8.7<base['km']-8.7,'Narrow comparison reduces positive GM')
tau=lambda h:2*math.pi*8/math.sqrt(9.81*h)
check(abs(tau(4)/tau(1)-.5)<1e-12,'Fourfold GM halves period')
check(abs((9.81*4/64)/(9.81/64)-4)<1e-12,'Same amplitude fourfold acceleration')
report=dict(checks=checks,max_interpolated_relative_volume_residual=max_res,max_interpolated_arm_error_m=max_arm,baseline=dict(volume=base['volume'],km=base['km'],avs=avs(old),peak=float(old.max())),failures=sum(not c['passed'] for c in checks))
(ROOT/'qa/stability-physics.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k!='checks'},ensure_ascii=False))
for c in checks:
 if not c['passed']:print('FAIL',c)
raise SystemExit(bool(report['failures']))
