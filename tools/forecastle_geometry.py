"""Forecastle footprint taken verbatim from the current hull's deck-edge rings."""
def build(source):
 n=source['ring_size'];half=(n+1)//2
 rings=[]
 for i,s in enumerate(source['stations']):
  if s>=61:
   port=source['vertices'][i*n+half-1];starboard=source['vertices'][i*n+half]
   rings.append((port,starboard))
 vertices=[];raised=[];lookup={};sections=[]
 for port,starboard in rings:
  ids=[]
  for is_roof,p in [(False,port),(False,starboard),(True,port),(True,starboard)]:
   x,y,z=p;base=(x,y,z+(-.02 if is_roof else -.04));target=(x,y,z+(5 if is_roof else -.04));key=tuple(round(q,8) for q in base)
   if key not in lookup:lookup[key]=len(vertices);vertices.append(base);raised.append(target)
   ids.append(lookup[key])
  sections.append(ids)
 faces=[];roof=[]
 def face(v,on_roof=False):
  v=tuple(dict.fromkeys(v))
  if len(v)>=3:
   if on_roof:roof.append(len(faces))
   faces.append(v)
 for a,b in zip(sections,sections[1:]):
  face((a[0],b[0],b[1],a[1]))
  face((a[0],a[2],b[2],b[0]))
  face((a[2],a[3],b[3],b[2]),True)
  face((a[1],b[1],b[3],a[3]))
 a=sections[0];face((a[0],a[1],a[3],a[2]))
 a=sections[-1];face((a[0],a[2],a[3],a[1]))
 return dict(vertices=vertices,raised=raised,faces=faces,roof=roof,rings=rings)

def replace_in_blender(source,deform):
 import bpy,bmesh
 from mathutils import Vector
 old=next(o for o in bpy.context.scene.objects if o.name.startswith('Forecastle tapered'))
 mats=list(old.data.materials);bpy.data.objects.remove(old,do_unlink=True)
 data=build(source);mesh=bpy.data.meshes.new('Forecastle exact shared deck footprint');mesh.from_pydata(data['vertices'],[],data['faces']);mesh.update()
 bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));assert all(e.is_manifold for e in bm.edges);bm.to_mesh(mesh);bm.free()
 obj=bpy.data.objects.new('Forecastle tapered hull extension',mesh);bpy.context.scene.collection.objects.link(obj)
 for m in mats:mesh.materials.append(m)
 for p in mesh.polygons:p.material_index=1 if p.index in data['roof'] and len(mats)>1 else 0
 obj.shape_key_add(name='Basis')
 for name in ['Sheer','Superstructure','Forecastle','Bilge','WaterlineStraight','Waterline','BowV','Flare','Bulb']:
  key=obj.shape_key_add(name=name)
  coords=data['raised'] if name=='Forecastle' else data['vertices']
  if name in ['Bilge','WaterlineStraight','Waterline','BowV','Flare','Bulb']:coords=[deform(Vector(v),name) for v in coords]
  key.data.foreach_set('co',[c for v in coords for c in v])
 # Relocate only the aft cross-rail/doors to the actual new aft bulkhead plane.
 stern=data['rings'][0][0][0]
 for part in bpy.context.scene.objects:
  if not part.name.startswith(('Forecastle aft rail','Forecastle aft weather')) or not part.data.shape_keys:continue
  blocks=part.data.shape_keys.key_blocks;centre=sum((v.co.x for v in blocks[0].data))/len(blocks[0].data)
  for key in blocks:
   for v in key.data:v.co.x+=stern-centre
 return obj,data
