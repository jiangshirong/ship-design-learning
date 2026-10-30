"""Independent asset/geometry verification, no application state or user saves."""
import json,struct,math,hashlib
from collections import Counter
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];checks=[]
def check(ok,name):checks.append(dict(passed=bool(ok),name=name))
d=json.loads((ROOT/'modules/review/content/yacht_geometry.json').read_text())
v=[(x,z,-y) for x,y,z in d['vertices']];f=d['faces']
edges=Counter(tuple(sorted((a,b))) for face in f for a,b in zip(face,face[1:]+face[:1]))
check(all(n==2 for n in edges.values()),'Calculation hull is closed and edge-manifold')
def volume(v,f):
 s=0
 for ia,ib,ic in f:
  a,b,c=[v[i] for i in (ia,ib,ic)]
  s+=(a[0]*(b[1]*c[2]-b[2]*c[1])+a[1]*(b[2]*c[0]-b[0]*c[2])+a[2]*(b[0]*c[1]-b[1]*c[0]))/6
 return abs(s)
blob=(ROOT/'modules/review/assets/planing_yacht.glb').read_bytes();n=struct.unpack_from('<I',blob,12)[0];g=json.loads(blob[20:20+n]);binary=blob[28+n:]
def accessor(i):
 a=g['accessors'][i];view=g['bufferViews'][a['bufferView']];n={'SCALAR':1,'VEC3':3}[a['type']];fmt={5126:'f',5123:'H',5125:'I'}[a['componentType']];size=struct.calcsize('<'+fmt*n);stride=view.get('byteStride',size)
 return [struct.unpack_from('<'+fmt*n,binary,view.get('byteOffset',0)+a.get('byteOffset',0)+j*stride) for j in range(a['count'])]
h=next(n for n in g['nodes'] if n['name']=='Yacht_Hull_Closed');gv=[];gf=[]
for p in g['meshes'][h['mesh']]['primitives']:
 points=accessor(p['attributes']['POSITION']);idx=[x[0] for x in accessor(p['indices'])];base=len(gv);gv.extend(points);gf.extend([[base+k for k in idx[j:j+3]] for j in range(0,len(idx),3)])
check(abs(volume(v,f)-volume(gv,gf))<1e-5,'Exported hull volume matches calculation hull')
check({tuple(round(x,5) for x in p) for p in gv}=={tuple(round(x,5) for x in p) for p in v},'GLB and calculation use the same vertices')
nodes=[n['name'] for n in g['nodes']]
for prefix in ['Engine_block_','Gearbox_','Shaft_','Propeller_','Rudder_']:
 for side in ['-1','1']:check(prefix+side in nodes,'Actual model part '+prefix+side)
for name in ['Deck_EngineCover','Engine_bay_floor','Engine_bay_bulkhead']:check(name in nodes,'Inspection part '+name)
poses=json.loads((ROOT/'modules/review/content/yacht_poses.json').read_text());rows=poses['rows'];v0=poses['static_volume']
def clipped_measure(trim,heave):
 c,s=math.cos(math.radians(trim)),math.sin(math.radians(trim));points=[(c*x-s*y,s*x+c*y+heave,z) for x,y,z in v];pv=[];pf=[];area=0
 for face in f:
  poly=[points[i] for i in face];out=[]
  previous=poly[-1]
  for current in poly:
   if (previous[1]<0)!=(current[1]<0):
    t=-previous[1]/(current[1]-previous[1]);out.append(tuple(previous[k]+t*(current[k]-previous[k]) for k in range(3)))
   if current[1]<=0:out.append(current)
   previous=current
  for j in range(1,len(out)-1):
   a,b,c=out[0],out[j],out[j+1];base=len(pv);pv.extend([a,b,c]);pf.append([base,base+1,base+2])
   u=[b[k]-a[k] for k in range(3)];w=[c[k]-a[k] for k in range(3)]
   cr=(u[1]*w[2]-u[2]*w[1],u[2]*w[0]-u[0]*w[2],u[0]*w[1]-u[1]*w[0]);area+=math.sqrt(sum(x*x for x in cr))/2
 return volume(pv,pf),area
for r in rows:
 check(abs(r['volume']/v0-(1-.67*r['p']))<1e-7,'Immersion bisection residual '+str(r['p']))
 check(abs(r['buoyancy']+r['lift']-1)<1e-12,'Fixed weight balance '+str(r['p']))
 check(0<r['area']<100,'Wetted area in square metres '+str(r['p']))
for r in rows[::10]:
 actual,area=clipped_measure(r['trim'],r['heave'])
 check(abs(actual-r['volume'])<1e-8 and abs(area-r['area'])<1e-8,'Independently clip actual hull '+str(r['p']))
check(rows[-1]['heave']>rows[0]['heave'] and rows[-1]['area']<rows[0]['area'],'Raised planing pose reduces immersion')
check(16/math.sqrt(9.81*v0**(1/3))>3,'Final speed uses the volume-Froude planing interval')
check(1<9/math.sqrt(9.81*v0**(1/3))<3,'Transition speed uses volume-Froude interval')
courses=json.loads((ROOT/'modules/review/content/topics.json').read_text());topic=next(c for c in courses if c['id']=='propulsion')
check(len(topic['questions'])==9,'All nine original propulsion questions remain')
fail=[x for x in checks if not x['passed']]
out=dict(checks=len(checks),failures=fail,full_volume=volume(v,f),static_volume=v0,static_wetted_area=poses['static_area'],planing_wetted_area=rows[-1]['area'],glb_sha256=hashlib.sha256(blob).hexdigest())
(ROOT/'qa/yacht-geometry-results.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps(out,ensure_ascii=False,indent=2));raise SystemExit(bool(fail))
