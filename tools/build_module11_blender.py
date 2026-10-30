"""Run in ONE visible Blender window. Build editable morphs on the detailed ship."""
import bpy,json,math,traceback,sys,importlib
from pathlib import Path
from mathutils import Vector,Quaternion
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(Path(__file__).resolve().parent))
import fair_ship_geometry as Fair
import forecastle_geometry as Forecastle
Fair=importlib.reload(Fair)
KEYS=['Bilge','WaterlineStraight','Waterline','BowV','Flare','Bulb']
report={};stage=0
def smooth(a,b,x):
 t=max(0,min(1,(x-a)/(b-a)));return t*t*(3-2*t)
legacy_source=json.loads((ROOT/'modules/review/content/stability_hydro.json').read_text())['routes']['base'][0]
source=Fair.build()
waterline=[]
for i in range(source['ring_count']):
 ring=source['vertices'][i*source['ring_size']:(i+1)*source['ring_size']]
 for a,b in zip(ring,ring[1:]+ring[:1]):
  if (a[2]<10.88)!=(b[2]<10.88):
   t=(10.88-a[2])/(b[2]-a[2]);p=[a[j]+t*(b[j]-a[j]) for j in range(3)]
   if p[1]>=0:waterline.append(p)
waterline.sort()
def width(x):
 for a,b in zip(waterline,waterline[1:]):
  if a[0]<=x<=b[0]:return a[1]+(b[1]-a[1])*(x-a[0])/max(.001,b[0]-a[0])
 return waterline[-1][1] if x>waterline[-1][0] else waterline[0][1]
def deform(p,key):
 x,y,z=p;out=Vector(p)
 if key=='Bilge':
  # Round the lower bilge in the real hull, keep B and T fixed.
  weight=(1-smooth(0,72,abs(x)))*(1-smooth(0,10.88,z))*smooth(.25,.70,abs(y)/13.3)
  out.y=y*(1-.26*weight)
 elif key in ['Waterline','WaterlineStraight'] and x>38:
  u=max(0,min(1,(x-38)/(Fair.stem(z)-38)))
  target=width(38)*(1-u)**(1.45 if key=='Waterline' else 1.)
  reference=38+u*(94.82-38)
  ratio=target/max(.000001,width(reference)) if u<.999999 else 1.
  out.y=y*(1+(ratio-1)*smooth(38,52,x))
 elif key=='BowV':
  out.y=y*(1-.75*smooth(46,80,x)*(1-smooth(0,12,z)))
 elif key=='Flare':
  out.y=y*(1+.65*smooth(55,80,x)*smooth(10.88,15.99,z))
 elif key=='Bulb':out=Vector(Fair.bulb(p))
 return out
def setup():
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.gltf(filepath=str(ROOT/'modules/review/assets/freeboard_ship.glb'))
 report['base']='freeboard_ship.glb';report['original_meshes']=sum(o.type=='MESH' for o in bpy.context.scene.objects)
 for area in bpy.context.screen.areas:
  if area.type=='VIEW_3D':
   s=area.spaces.active;s.shading.type='MATERIAL';s.clip_end=2000
   s.region_3d.view_distance=155;s.region_3d.view_location=Vector((43,0,7));s.region_3d.view_rotation=Quaternion((.81,.48,-.17,-.27)).normalized()
 bpy.context.scene.unit_settings.system='METRIC'
def fair_hull():
 old=next(o for o in bpy.context.scene.objects if o.type=='MESH' and o.name.startswith('Continuous'))
 materials=list(old.data.materials);bpy.data.objects.remove(old,do_unlink=True)
 mesh=bpy.data.meshes.new('Fair closed hull loft');mesh.from_pydata(source['vertices'],[],source['faces']);mesh.update()
 obj=bpy.data.objects.new('Continuous hull and deck',mesh);bpy.context.scene.collection.objects.link(obj)
 for mat in materials:mesh.materials.append(mat)
 deck_faces=set(source['deck_faces'])
 for p in mesh.polygons:p.use_smooth=p.index not in deck_faces;p.material_index=1 if p.index in deck_faces and len(materials)>1 else 0
 obj.shape_key_add(name='Basis')
 for key in ['Sheer','Superstructure','Forecastle']:
  shape=obj.shape_key_add(name=key)
  if key=='Sheer':
   for i,p in enumerate(shape.data):
    ring=min(i//source['ring_size'],source['ring_count']-1);s=source['stations'][ring]
    rise=5*smooth(38,100,p.co.x)*max(0,min(1,(p.co.z-10.88)/max(.01,Fair.deck(s)-10.88)))
    p.co.z+=rise
 # These structures have their own authored solids; the original hull stays fixed.
 basis=[c for v in obj.data.shape_keys.key_blocks['Basis'].data for c in v.co]
 for name in ['Superstructure','Forecastle']:obj.data.shape_keys.key_blocks[name].data.foreach_set('co',basis)
 report['fair_hull']={k:source[k] for k in ['ring_size','ring_count','midship_index','fairing']}
def fit_fittings():
 for obj in list(bpy.context.scene.objects):
  if obj.type!='MESH' or obj.name.startswith('Continuous'):continue
  if not obj.data.shape_keys:obj.shape_key_add(name='Basis')
  world=obj.matrix_world;inverse=world.inverted()
  basis=[world@v.co for v in obj.data.shape_keys.key_blocks[0].data]
  span=max(v.x for v in basis)-min(v.x for v in basis)
  compact=span<=8 and not obj.name.startswith(('Original rail','Forecastle tapered'))
  for block in obj.data.shape_keys.key_blocks:
   original=[world@v.co for v in block.data]
   centre=sum(original,Vector())/len(original)
   shift=Vector(Fair.fit_deck_point(centre,legacy_source))-centre
   fitted=[v+shift if compact else Vector(Fair.fit_deck_point(v,legacy_source)) for v in original]
   block.data.foreach_set('co',[c for v in fitted for c in inverse@v])
def repair_forecastle():
 Forecastle.replace_in_blender(source,deform)

def morph():
 objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
 report['morphs']={}
 for obj in objects:
  if not obj.data.shape_keys:obj.shape_key_add(name='Basis')
  base=obj.data.shape_keys.key_blocks[0];world=obj.matrix_world;inverse=world.inverted()
  coords=[world@v.co for v in base.data]
  centre=sum(coords,Vector())/max(1,len(coords))
  span=max(v.x for v in coords)-min(v.x for v in coords)
  for key in KEYS:
   shape=obj.data.shape_keys.key_blocks.get(key) or obj.shape_key_add(name=key)
   structural=obj.name.startswith(('Continuous','Original rail','Forecastle tapered'))
   # Long pipelines follow the deck; small equipment translates rigidly.
   values=[inverse@deform(v,key) for v in coords] if structural or span>8 else [inverse@(v+deform(centre,key)-centre) for v in coords]
   shape.data.foreach_set('co',[c for v in values for c in v])
   report['morphs'][key]=report['morphs'].get(key,0)+sum((Vector(a.co)-b).length>.00001 for a,b in zip(base.data,values))
def hardware():
 def mat(name,color):
  m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True;m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(*color,1);m.node_tree.nodes['Principled BSDF'].inputs['Metallic'].default_value=.2;return m
 steel=mat('Module11 submerged hull coating',(.34,.075,.055))
 # Bulb is a morph of the ONE welded hull, not an intersecting extra solid.
 # Curved lower stern support and heel bearing, not a floating teaching block.
 outline=[(-87,-.42,1.0),(-98,-.42,1.0),(-101,-.42,2.8),(-101,-.42,3.7),(-98,-.42,2.2),(-87,-.42,2.0)]
 v=outline+[(x,.42,z) for x,y,z in outline];n=len(outline)
 f=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
 mesh=bpy.data.meshes.new('Stern heel support');mesh.from_pydata(v,[],f);mesh.materials.append(steel)
 obj=bpy.data.objects.new('M11 closed stern support',mesh);bpy.context.scene.collection.objects.link(obj)
 obj.shape_key_add(name='Basis');sh=obj.shape_key_add(name='ClosedStern')
 for a,b in zip(obj.data.shape_keys.key_blocks[0].data,sh.data):a.co=Vector((-87,0,5));b.co=b.co
 bevel=obj.modifiers.new('Cast support rounded edges','BEVEL');bevel.width=.2;bevel.segments=3
 bronze=mat('Propeller bronze',(.48,.29,.085));rudder_mat=mat('Rudder underwater coating',(.25,.09,.055))
 bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=16,location=(-93,0,2.6))
 hub=bpy.context.object;hub.name='M11 propeller hub';hub.scale=(1.25,.43,.43);hub.data.materials.append(bronze)
 for polygon in hub.data.polygons:polygon.use_smooth=True
 for blade in range(5):
  vs=[];fs=[];nr=12;nc=10
  for side in [-1,1]:
   for i in range(nr):
    r=.35+1.80*i/(nr-1)
    for j in range(nc):
     c=2*j/(nc-1)-1;angle=blade*2*math.pi/5+.30*r+c*.18
     vs.append((-93+.42*c+.10*r+side*.055,r*math.cos(angle),2.6+r*math.sin(angle)))
  for side in range(2):
   offset=side*nr*nc
   for i in range(nr-1):
    for j in range(nc-1):
     a=offset+i*nc+j;fs.append((a,a+nc,a+nc+1,a+1) if side else (a+1,a+nc+1,a+nc,a))
  for i in range(nr-1):
   for j in [0,nc-1]:
    a=i*nc+j;b=(i+1)*nc+j;fs.append((a,b,b+nr*nc,a+nr*nc))
  for j in range(nc-1):
   for i in [0,nr-1]:
    a=i*nc+j;fs.append((a,a+1,a+1+nr*nc,a+nr*nc))
  mesh=bpy.data.meshes.new('Swept twisted blade');mesh.from_pydata(vs,[],fs);mesh.materials.append(bronze)
  obj=bpy.data.objects.new('M11 propeller blade '+str(blade+1),mesh);bpy.context.scene.collection.objects.link(obj)
  for polygon in mesh.polygons:polygon.use_smooth=True
 bpy.ops.mesh.primitive_cylinder_add(vertices=24,radius=.22,depth=11.,location=(-88,0,2.6),rotation=(0,math.pi/2,0))
 bpy.context.object.name='M11 propeller shaft';bpy.context.object.data.materials.append(steel)
 # Foil-shaped spade rudder aft of the propeller, hung from its stock.
 vs=[];fs=[];nr=12;nc=18
 for i in range(nr):
  z=.5+i*4.4/(nr-1)
  for j in range(nc):
   a=j*2*math.pi/nc;vs.append((-99.5+1.9*math.cos(a),.28*math.sin(a),z))
 for i in range(nr-1):
  for j in range(nc):fs.append((i*nc+j,i*nc+(j+1)%nc,(i+1)*nc+(j+1)%nc,(i+1)*nc+j))
 fs.extend([tuple(reversed(range(nc))),tuple((nr-1)*nc+j for j in range(nc))])
 mesh=bpy.data.meshes.new('Spade rudder foil');mesh.from_pydata(vs,[],fs);mesh.materials.append(rudder_mat)
 obj=bpy.data.objects.new('M11 spade rudder',mesh);bpy.context.scene.collection.objects.link(obj)
 for polygon in mesh.polygons:polygon.use_smooth=True
 bpy.ops.mesh.primitive_cylinder_add(vertices=24,radius=.22,depth=3.2,location=(-98.7,0,5.6))
 bpy.context.object.name='M11 rudder stock';bpy.context.object.data.materials.append(steel)
 # Coordinates driving cut lines and all numerical area records, same morph functions.
 d={k:source[k] for k in ['ring_size','ring_count','vertices','faces','stations','midship_index','fairing']};d.update(waterline=waterline,variants={})
 for key in KEYS:d['variants'][key]=[list(deform(Vector(v),key)) for v in source['vertices']]
 (ROOT/'modules/review/content/module11_geometry.json').write_text(json.dumps(d,separators=(',',':')),encoding='utf-8')
def finish():
 bpy.context.scene.frame_start=1;bpy.context.scene.frame_end=280
 for obj in bpy.context.scene.objects:
  if obj.type!='MESH' or not obj.data.shape_keys:continue
  for key,start in [('Bilge',10),('Waterline',55),('BowV',100),('Bulb',145),('Flare',190),('ClosedStern',235)]:
   if key not in obj.data.shape_keys.key_blocks:continue
   s=obj.data.shape_keys.key_blocks[key]
   for f,v in [(1,0),(start,0),(start+20,1),(start+30,1),(start+40,0),(280,0)]:s.value=v;s.keyframe_insert('value',frame=f)
 bpy.context.scene.frame_set(1)
 for obj in bpy.context.scene.objects:obj.select_set(obj.type=='MESH')
 bpy.context.view_layer.objects.active=next(o for o in bpy.context.scene.objects if o.type=='MESH')
 out=ROOT/'modules/review/assets/module11_ship.glb'
 bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'models/船体型线与艏艉变形.blend'))
 bpy.ops.export_scene.gltf(filepath=str(out),export_format='GLB',use_selection=True,export_animations=False,export_morph=True,export_morph_normal=True)
 report.update(glb=str(out),visible_authoring=True,shape_keys=KEYS+['ClosedStern'],propeller_blades=5,rudder='spade with stock',stern_support='morphs between lower heel support and open configuration',bulb='integrated closed hull morph; no intersecting shell')
 (ROOT/'qa/module11-blender.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
 for area in bpy.context.screen.areas:
  if area.type=='VIEW_3D':
   with bpy.context.temp_override(area=area):bpy.ops.screen.animation_play()
   break
def step():
 global stage
 try:
  stages=[setup,fair_hull,fit_fittings,repair_forecastle,morph,hardware,finish]
  stages[stage]();stage+=1
  for area in bpy.context.screen.areas:area.tag_redraw()
  return 2. if stage<len(stages) else None
 except Exception:
  (ROOT/'qa/module11-blender-error.txt').write_text(traceback.format_exc());return None
bpy.app.timers.register(step,first_interval=3.)
