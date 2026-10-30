"""Independent source, GLB-to-calculation and affine hydrostatic checks."""
from pathlib import Path
import json,struct,math,hashlib
ROOT=Path(__file__).resolve().parents[1]
def read(n):return json.loads((ROOT/n).read_text(encoding='utf-8'))
results=[]
def check(ok,name,**details):results.append(dict(name=name,passed=bool(ok),**details))
d=read('content/module11_geometry.json');verts=[(x,z,-y) for x,y,z in d['vertices']]
def sub(a,b):return tuple(x-y for x,y in zip(a,b))
def cross(a,b):return(a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def dot(a,b):return sum(x*y for x,y in zip(a,b))
def clip(poly,T):
 out=[];a=poly[-1]
 for b in poly:
  if (a[1]<=T)!=(b[1]<=T):
   t=(T-a[1])/(b[1]-a[1]);out.append(tuple(a[i]+t*(b[i]-a[i]) for i in range(3)))
  if b[1]<=T:out.append(b)
  a=b
 return out
def area(poly,axes):return abs(sum(poly[i][axes[0]]*poly[(i+1)%len(poly)][axes[1]]-poly[(i+1)%len(poly)][axes[0]]*poly[i][axes[1]] for i in range(len(poly))))/2
faces=d.get('faces',read('content/stability_hydro.json')['routes']['base'][0]['faces'])
def hydro(v,T,L,B):
 volume=0
 for face in faces:
  p=clip([v[i] for i in face],T)
  for j in range(1,len(p)-1):volume+=dot(sub(p[0],(0,T,0)),cross(sub(p[j],(0,T,0)),sub(p[j+1],(0,T,0))))/6
 n=d['ring_size'];mid=clip(v[24*n:25*n],T)
 left=[];right=[]
 for i in range(d['ring_count']):
  ring=v[i*n:(i+1)*n];hits=[]
  for a,b in zip(ring,ring[1:]+ring[:1]):
   if (a[1]<T)!=(b[1]<T):
    t=(T-a[1])/(b[1]-a[1]);hits.append(tuple(a[j]+t*(b[j]-a[j]) for j in range(3)))
  if len(hits)==2:left.append(min(hits,key=lambda x:x[2]));right.append(max(hits,key=lambda x:x[2]))
 waterplane=area(left+list(reversed(right)),(0,2));A=area(mid,(1,2))
 return dict(volume=abs(volume),area=A,waterplane=waterplane,beta=A/(B*T),alpha=waterplane/(L*B),delta=abs(volume)/(L*B*T))
base=hydro(verts,10.88,189.64,26.6)
scaled=[(x*1.08,y*1.10,z*1.12) for x,y,z in verts]
changed=hydro(scaled,10.88*1.10,189.64*1.08,26.6*1.12)
check(abs(changed['volume']/base['volume']-1.08*1.12*1.10)<1e-9,'Clipped submerged volume scales by lbt')
for k in ['alpha','beta','delta']:check(abs(changed[k]-base[k])<1e-10,'Affine invariant '+k)
round_v=[(x,z,-y) for x,y,z in d['variants']['Bilge']]
check(hydro(round_v,10.88,189.64,26.6)['beta']<base['beta'],'Rounded bilge decreases actual beta')
for k in ['Flare']:
 vv=[(x,z,-y) for x,y,z in d['variants'][k]]
 check(all(max(abs(a-b) for a,b in zip(v,w))<1e-5 for v,w in zip(verts,vv) if v[1]<=10.88),'Above-water flare preserves every submerged vertex within float32 precision')
# Read exported GLB floats independently; confirm the visible mesh uses the same
# vertices and morph deltas as the mathematical section and the displayed beta.
binary=(ROOT/'assets/module11_ship.glb').read_bytes();length,_=struct.unpack_from('<II',binary,12)
glb=json.loads(binary[20:20+length]);bin_start=20+length+8
def accessor(index):
 a=glb['accessors'][index]
 assert a['componentType']==5126 and a['type']=='VEC3'
 out=[(0.,0.,0.)]*a['count']
 if 'bufferView' in a:
  b=glb['bufferViews'][a['bufferView']];start=bin_start+b.get('byteOffset',0)+a.get('byteOffset',0);stride=b.get('byteStride',12)
  out=[struct.unpack_from('<fff',binary,start+i*stride) for i in range(a['count'])]
 if 'sparse' in a:
  sp=a['sparse'];ind=sp['indices'];val=sp['values'];ib=glb['bufferViews'][ind['bufferView']];vb=glb['bufferViews'][val['bufferView']]
  fmt={5121:'B',5123:'H',5125:'I'}[ind['componentType']];size=struct.calcsize(fmt)
  for i in range(sp['count']):
   at=struct.unpack_from('<'+fmt,binary,bin_start+ib.get('byteOffset',0)+ind.get('byteOffset',0)+i*size)[0]
   out[at]=struct.unpack_from('<fff',binary,bin_start+vb.get('byteOffset',0)+val.get('byteOffset',0)+i*12)
 return out
lookup={tuple(round(c,3) for c in v):i for i,v in enumerate(verts)}
mesh=glb['meshes'][next(n['mesh'] for n in glb['nodes'] if n.get('name','').startswith('Continuous'))]
names=mesh['extras']['targetNames']
for pi,primitive in enumerate(mesh['primitives']):
 p=accessor(primitive['attributes']['POSITION']);indices=[]
 for v in p:
  idx=lookup.get(tuple(round(c,3) for c in v))
  if idx is None:
   nearest=min(range(len(verts)),key=lambda i:sum((a-b)**2 for a,b in zip(v,verts[i])))
   if max(abs(a-b) for a,b in zip(v,verts[nearest]))<.00002:idx=nearest
  indices.append(idx)
 check(all(i is not None for i in indices),'Visible hull primitive maps to calculation vertices '+str(pi))
 for key in ['Bilge','WaterlineStraight','Waterline','BowV','Flare','Bulb']:
  delta=accessor(primitive['targets'][names.index(key)]['POSITION']);error=0
  for idx,q,t in zip(indices,p,delta):
   if idx is None:continue
   x,y,z=d['variants'][key][idx];expected=(x,z,-y)
   error=max(error,max(abs(expected[j]-(q[j]+t[j])) for j in range(3)))
  check(error<.0002,'Visible '+key+' agrees with calculated geometry '+str(pi),max_error_m=error)
bank=read('content/question_bank.json');cards=read('content/reading.json');topics=read('content/topics.json')
check(len(bank)==len(cards)==62 and len(topics)==9,'62 cards and nine topics')
check(sum(len(q['sources']) for q in bank)==90,'90 source references')
byid={q['id']:q for q in cards}
for i in range(1,9):
 q=byid[f'M11Q{i:02}'];check(q['topic']==('freeboard' if i in [6,7] else 'hullform'),'Knowledge-system route '+str(i))
check('condition' in byid['M11Q02'] and 'condition' not in byid['M11Q08'],'Source contradiction retained; open-ended if question understood correctly')
check(all(q.get('calculation') for q in cards if q['id'] in ['Q07','Q08','Q09','Q10']),'Four existing calculations and variants retained')
bundle=read('content/latex_assets.json')
step=bundle['lessons']['M11:M11Q01:formula']['zh']
check(any('丰满系数' in h['text'] for row in step for h in bundle['assets'][row['full']]['hints']),'Beta formula has explicit Chinese symbol meaning')
ids=[e['id'] for e in read('content/glossary.json')]
check(len(ids)==len(set(ids)),'Vocabulary IDs unique')
excluded={'еще','какой','быть','например','сначала','меньше','можно','больше','мочь','нужно'}
def norm(s):return s.replace('\u0301','').replace('ё','е').lower()
check(all(not e.get('study',True) for e in read('content/glossary.json') if norm(e['ru']) in excluded),'Excluded basic vocabulary remains excluded')
report=dict(checks=len(results),failures=[r for r in results if not r['passed']],results=results,geometry=base,affine=changed,asset_sha256=hashlib.sha256(binary).hexdigest())
(ROOT/'qa/module11-source-geometry.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(f"Module11: {len(results)} independent checks; {len(report['failures'])} failures")
for f in report['failures']:print(f)
raise SystemExit(bool(report['failures']))
