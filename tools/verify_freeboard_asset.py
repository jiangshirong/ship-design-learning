"""Check the exported morph deltas independently of Blender authoring code."""
import json, struct
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
blob=(ROOT/'modules/review/assets/freeboard_ship.glb').read_bytes()
n=struct.unpack_from('<I',blob,12)[0]
gltf=json.loads(blob[20:20+n]);binary=blob[28+n:]
def data(index):
    a=gltf['accessors'][index]
    out=np.zeros((a['count'],3))
    if 'bufferView' in a:
        v=gltf['bufferViews'][a['bufferView']]
        out=np.frombuffer(binary,dtype='<f4',count=a['count']*3,
                          offset=v.get('byteOffset',0)+a.get('byteOffset',0)).reshape(-1,3).copy()
    if 'sparse' in a:
        s=a['sparse'];i=s['indices'];v=s['values']
        iv=gltf['bufferViews'][i['bufferView']];vv=gltf['bufferViews'][v['bufferView']]
        ids=np.frombuffer(binary,dtype={5121:'u1',5123:'<u2',5125:'<u4'}[i['componentType']],
                          count=s['count'],offset=iv.get('byteOffset',0)+i.get('byteOffset',0))
        out[ids]=np.frombuffer(binary,dtype='<f4',count=s['count']*3,
                              offset=vv.get('byteOffset',0)+v.get('byteOffset',0)).reshape(-1,3)
    return out
checks=[]
def check(name,value):
    checks.append({'name':name,'passed':bool(value)})
for node in gltf['nodes']:
    if 'mesh' not in node:continue
    mesh=gltf['meshes'][node['mesh']]
    names=mesh.get('extras',{}).get('targetNames',[])
    for p in mesh['primitives']:
        if node['name'].startswith('Original rail region'):
            for key in ('Superstructure','Forecastle'):
                d=data(p['targets'][names.index(key)]['POSITION'])
                moving=('Middle' in node['name'] if key=='Superstructure' else 'Bow' in node['name'])
                check(node['name']+' / '+key,np.max(np.abs(d[:,[0,2]]))<1e-5)
                check(node['name']+' vertical / '+key,np.allclose(d[:,1],(6 if key=='Superstructure' else 5) if moving else 0,atol=1e-5))
        if node['name'].startswith('Continuous'):
            base=data(p['attributes']['POSITION']);d=data(p['targets'][names.index('Sheer')]['POSITION'])
            check('Underwater hull does not move',np.max(np.abs(d[base[:,1]<=10.88]))<1e-4)
            check('Bow deck actually rises',np.max(d[:,1])>4.9)
            check('Aft and midship deck remain fixed',np.max(np.abs(d[base[:,0]<=38]))<1e-5)
            for key in ('Superstructure','Forecastle'):
                check('Original hull retained / '+key,np.max(np.abs(data(p['targets'][names.index(key)]['POSITION'])))<1e-5)
(ROOT/'qa/freeboard-asset-checks.json').write_text(json.dumps(checks,indent=2),encoding='utf-8')
assert checks and all(c['passed'] for c in checks),checks
print(f'Exported Blender asset: {len(checks)} geometry checks passed')
