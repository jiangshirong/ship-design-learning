"""Copy the existing tanker fittings into independently positioned rigid parts.
This is a GLB asset adapter, not a Blender edit. Source .blend/.glb are untouched.
"""
import json,struct
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
source=ROOT.parents[1]/'assets/tanker_learning.glb'
d=source.read_bytes();n=struct.unpack_from('<I',d,12)[0];j=json.loads(d[20:20+n]);binary=d[28+n:]
def arr(i):
 a=j['accessors'][i];v=j['bufferViews'][a['bufferView']];dt={5126:'<f4',5125:'<u4',5123:'<u2',5121:'u1'}[a['componentType']];nc={'SCALAR':1,'VEC3':3,'VEC2':2,'VEC4':4}[a['type']]
 return np.frombuffer(binary,dtype=dt,count=a['count']*nc,offset=v.get('byteOffset',0)+a.get('byteOffset',0)).reshape(-1,nc).copy()
out={'asset':{'version':'2.0'},'scene':0,'scenes':[{'nodes':[]}],'nodes':[],'meshes':[],'materials':j['materials'],'accessors':[],'bufferViews':[]};buf=bytearray()
def accessor(a,kind):
 while len(buf)%4:buf.append(0)
 off=len(buf);buf.extend(a.tobytes());v=len(out['bufferViews']);out['bufferViews'].append({'buffer':0,'byteOffset':off,'byteLength':a.nbytes})
 info={'bufferView':v,'componentType':5126 if a.dtype.kind=='f' else 5125,'count':len(a),'type':kind}
 if kind=='VEC3':info.update(min=a.min(axis=0).tolist(),max=a.max(axis=0).tolist())
 out['accessors'].append(info);return len(out['accessors'])-1
exclude=['Hull','Decks','Ballast','Bulkheads','CargoLiquid','DoubleBottom','Frames','Machinery','Propulsion','Markings']
count=0
for node in j['nodes']:
 name=node.get('name','')
 if any(name.startswith(x) for x in exclude):continue
 for primitive in j['meshes'][node['mesh']]['primitives']:
  vertices=arr(primitive['attributes']['POSITION']);indices=arr(primitive['indices']).reshape(-1,3);normals=arr(primitive['attributes']['NORMAL'])
  # Weld only for connectivity (GLTF normals cause duplicated vertices at seams).
  _,inverse=np.unique(np.round(vertices,4),axis=0,return_inverse=True);parent=list(range(int(inverse.max())+1))
  def find(x):
   while parent[x]!=x:parent[x]=parent[parent[x]];x=parent[x]
   return x
  for tri in inverse[indices]:
   a=find(int(tri[0]));parent[find(int(tri[1]))]=a;parent[find(int(tri[2]))]=a
  components={}
  for f in indices:components.setdefault(find(int(inverse[f[0]])),[]).append(f)
  for faces in components.values():
   faces=np.array(faces);used,remapped=np.unique(faces,return_inverse=True);v=vertices[used];centre=(v.min(axis=0)+v.max(axis=0))/2
   pa=accessor((v-centre).astype('<f4'),'VEC3');na=accessor(normals[used].astype('<f4'),'VEC3');ia=accessor(remapped.astype('<u4').reshape(-1,1),'SCALAR')
   mesh=len(out['meshes']);out['meshes'].append({'primitives':[{'attributes':{'POSITION':pa,'NORMAL':na},'indices':ia,'material':primitive['material']}]})
   index=len(out['nodes']);out['nodes'].append({'mesh':mesh,'name':name+'_'+str(count),'translation':centre.tolist(),'extras':{'zone':name}});out['scenes'][0]['nodes'].append(index);count+=1
out['buffers']=[{'byteLength':len(buf)}];header=json.dumps(out,separators=(',',':')).encode();header+=b' '*((-len(header))%4);buf+=b'\0'*((-len(buf))%4)
payload=struct.pack('<II',len(header),0x4e4f534a)+header+struct.pack('<II',len(buf),0x004e4942)+buf
(ROOT/'assets/stability_fittings.glb').write_bytes(struct.pack('<III',0x46546c67,2,12+len(payload))+payload)
print('Rigid fitting components',count)
