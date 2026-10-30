"""Read the delivered GLB, weld only exact duplicate export positions and test it.
Run inside Blender for its native BVH; does not modify the open scene or asset.
"""
import json,struct,collections,hashlib
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
ROOT=Path(__file__).resolve().parents[1]
path=ROOT/'modules/review/assets/module11_ship.glb'
blob=path.read_bytes();length=struct.unpack_from('<I',blob,12)[0]
g=json.loads(blob[20:20+length]);start=28+length
def accessor(i):
 a=g['accessors'][i];n={'VEC3':3,'SCALAR':1}[a['type']];fmt={5121:'B',5123:'H',5125:'I',5126:'f'}[a['componentType']];unit=struct.calcsize(fmt)*n
 out=[(0.,)*n for _ in range(a['count'])]
 if 'bufferView' in a:
  b=g['bufferViews'][a['bufferView']];offset=start+b.get('byteOffset',0)+a.get('byteOffset',0);stride=b.get('byteStride',unit)
  out=[struct.unpack_from('<'+fmt*n,blob,offset+j*stride) for j in range(a['count'])]
 if 'sparse' in a:
  s=a['sparse'];ind=s['indices'];val=s['values'];ib=g['bufferViews'][ind['bufferView']];vb=g['bufferViews'][val['bufferView']]
  ifmt={5121:'B',5123:'H',5125:'I'}[ind['componentType']];isize=struct.calcsize(ifmt)
  for j in range(s['count']):
   idx=struct.unpack_from('<'+ifmt,blob,start+ib.get('byteOffset',0)+ind.get('byteOffset',0)+j*isize)[0]
   out[idx]=struct.unpack_from('<'+fmt*n,blob,start+vb.get('byteOffset',0)+val.get('byteOffset',0)+j*unit)
 return out
node=next(n for n in g['nodes'] if n.get('name','').startswith('Continuous'))
assert not any(k in node for k in ['matrix','rotation','scale','translation']),'Unexpected hull transform; apply before verification'
mesh=g['meshes'][node['mesh']];names=mesh['extras']['targetNames'];vertices=[];faces=[];lookup={};deltas={k:[] for k in names};checks=[]
for prim in mesh['primitives']:
 p=accessor(prim['attributes']['POSITION']);mapping=[]
 targets={k:accessor(prim['targets'][j]['POSITION']) for j,k in enumerate(names)}
 for j,v in enumerate(p):
  if v not in lookup:
   lookup[v]=len(vertices);vertices.append(Vector(v))
   for k in names:deltas[k].append(Vector(targets[k][j]))
  mapping.append(lookup[v])
 indices=[a[0] for a in accessor(prim['indices'])]
 for j in range(0,len(indices),3):faces.append(tuple(mapping[indices[j+i]] for i in range(3)))
for key in ['Forecastle','Superstructure']:
 checks.append(dict(name='Original hull fixed during '+key,passed=max((v.length for v in deltas[key]),default=0.)<1e-5))
edge_counts=collections.Counter(tuple(sorted((a,b))) for f in faces for a,b in zip(f,f[1:]+f[:1]))
directions=collections.Counter((a,b) for f in faces for a,b in zip(f,f[1:]+f[:1]))
checks.append(dict(name='GLB welded watertight manifold',passed=all(c==2 for c in edge_counts.values()),bad_edges=sum(c!=2 for c in edge_counts.values())))
checks.append(dict(name='GLB coherent face winding',passed=all(directions[a,b]==directions[b,a]==1 for a,b in edge_counts)))
euler=len(vertices)-len(edge_counts)+len(faces)
checks.append(dict(name='GLB closed genus-zero shell',passed=euler==2,euler=euler))
for key in ['Basis','Bilge','WaterlineStraight','Waterline','BowV','Flare','Bulb','Sheer']:
 for amount in ([0.] if key=='Basis' else [.5,1.]):
  v=vertices if key=='Basis' else [a+d*amount for a,d in zip(vertices,deltas[key])]
  tree=BVHTree.FromPolygons(v,faces,all_triangles=True,epsilon=0.)
  intersections=[(a,b) for a,b in tree.overlap(tree) if a<b and not(set(faces[a])&set(faces[b]))]
  volume=sum(v[a].dot(v[b].cross(v[c])) for a,b,c in faces)/6
  checks.append(dict(name=f'GLB {key} {amount}',passed=not intersections and volume>0,nonadjacent_intersections=len(intersections),signed_volume_m3=volume,samples=intersections[:8]))
geometry=json.loads((ROOT/'modules/review/content/module11_geometry.json').read_text())
n=geometry['ring_size'];nr=geometry['ring_count']
for key,verts in [('Basis',geometry['vertices']),*geometry['variants'].items()]:
 bad=[]
 for j in range(n):
  for i in range(35,nr-1):
   if verts[(i+1)*n+j][0]<verts[i*n+j][0]-1e-5:bad.append((i,j))
 checks.append(dict(name='No folded bow strips '+key,passed=not bad,folded_strips=len(bad)))
report=dict(source_asset=str(path),asset_sha256=hashlib.sha256(blob).hexdigest(),vertices=len(vertices),triangles=len(faces),checks=checks,failures=[c for c in checks if not c['passed']],welding='Exact exported positions only, preserving all geometry; shading/material splits are not physical openings.',boundary='Closed geometric shell validation, not a completed FLIP collision or seaworthiness certificate.')
(ROOT/'qa/hull-repair-export.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
result={k:report[k] for k in ['asset_sha256','vertices','triangles','failures']}
