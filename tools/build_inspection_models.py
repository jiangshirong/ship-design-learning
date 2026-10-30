import bpy, math, traceback, json
from pathlib import Path
from mathutils import Vector, Quaternion
ROOT=Path(__file__).resolve().parents[1]
report={}; sources=[]
def mat(name,c):
 m=bpy.data.materials.new(name);m.diffuse_color=(*c,1);m.use_nodes=True
 bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*c,1);bs.inputs['Roughness'].default_value=.55;bs.inputs['Metallic'].default_value=.15
 return m
steel=None;red=None;paint=None;deckmat=None
def mesh(name,v,f,m):
 d=bpy.data.meshes.new(name);d.from_pydata(v,[],f);d.update();o=bpy.data.objects.new(name,d);bpy.context.scene.collection.objects.link(o);d.materials.append(m);return o
def box(name,loc,dim,m):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=dim;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(m);return o
def start():
 global sources,steel,red,paint,deckmat
 for o in list(bpy.context.scene.objects):bpy.data.objects.remove(o,do_unlink=True)
 bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/cargo_ship.glb'))
 for o in list(bpy.context.scene.objects):
  zone=o.name.split('_')[0]
  if zone in ['Accommodation','Windows','Equipment','Navigation','Survival','Mooring','Funnel','Anchors','Cranes','Propulsion']:
   sources.append((o.name,o.data.copy(),o.matrix_world.copy()))
  bpy.data.objects.remove(o,do_unlink=True)
 steel=mat('Inspection structural steel',(.49,.52,.51));red=mat('Hull antifouling',(.34,.075,.055));paint=mat('Hull upper paint',(.10,.15,.17));deckmat=mat('Deck coating',(.32,.35,.32))
def build(kind,L,B,H,base,centre):
 for o in list(bpy.context.scene.objects):bpy.data.objects.remove(o,do_unlink=True)
 def width(x):
  s=x+L/2
  return B/2*max(.025,min((max(s,0)/(L*.122))**.55,(max(L-s,0)/(L*.165))**.62,1))
 profile=[(-1,1),(-1,.4),(-.98,.15),(-.9,0),(0,0),(.9,0),(.98,.15),(1,.4),(1,1)]
 N=120;verts=[]
 for i in range(N+1):
  x=-L/2+L*i/N;w=width(x)
  verts.extend((x+centre,y*w,base+z*H) for y,z in profile)
 for band in range(8):
  faces=[]
  for i in range(N):a=i*9+band;b=(i+1)*9+band;faces.append((a,b,b+1,a+1))
  mesh('Hull_'+str(band),verts,faces,paint if band in [0,7] else red)
 dv=[];df=[]
 for i in range(N+1):
  x=-L/2+L*i/N;w=width(x);dv.extend([(x+centre,-w,base+H),(x+centre,w,base+H)])
 for i in range(N):df.append((i*2,i*2+1,i*2+3,i*2+2))
 mesh('Decks_main',dv,df,deckmat)
 # Actual metal rails and longitudinal coamings retain a spatial reference.
 for side in [-1,1]:
  for i in range(0,N,2):
   x=-L/2+L*i/N;w=width(x);box('Rails_post',(x+centre,side*w,base+H+.5*(B/23.8)),(.07*B/23.8,.07*B/23.8,B/23.8),steel)
  rv=[];rf=[]
  for i in range(N+1):
   x=-L/2+L*i/N;w=width(x)
   for dz in [0,.045*B/23.8]:rv.append((x+centre,side*w,base+H+B/23.8+dz))
  for i in range(N):rf.append((i*2,i*2+1,i*2+3,i*2+2))
  mesh('Rails_top',rv,rf,steel)
 for name,data,matrix in sources:
  d=data.copy();o=bpy.data.objects.new(name,d);bpy.context.scene.collection.objects.link(o)
  for v in d.vertices:
   q=matrix@v.co;v.co=(q.x*L/78+centre,q.y*B/12.6,base+q.z*H/7.5)
 if kind=='study_cargo':
  # Exact 8 x 2 x 2 net space used by existing worked examples.
  for x in [-4.07,4.07]:box('Bulkheads_hold_end',(x,0,1),(.14,2.14,2),steel)
  for side in [-1,1]:box('InnerSide_hold',(0,side*1.07,1),(8.14,.14,2),steel)
  box('InnerBottom_hold',(0,0,-.07),(8.14,2.14,.14),steel)
  for x in range(-4,5):
   box('Frames_floor',(x,0,-.22),(.06,2.25,.30),steel)
   for y in [-1.12,1.12]:box('Frames_side',(x,y,1),(.06,.07,2),steel)
  for y in [-.7,0,.7]:box('Girders_bottom',(0,y,-.22),(8.2,.04,.30),steel)
 # Apply all coordinates: clip shaders use a single, stable ship coordinate space.
 bpy.context.view_layer.update()
 for w in bpy.context.window_manager.windows:
  for a in w.screen.areas:
   if a.type=='VIEW_3D':
    a.spaces.active.shading.type='MATERIAL';a.spaces.active.clip_end=2000;a.spaces.active.region_3d.view_location=Vector((centre,0,H*.5));a.spaces.active.region_3d.view_distance=L*1.15;a.spaces.active.region_3d.view_rotation=Quaternion((.81,.48,-.17,-.27)).normalized()
 bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/('models/'+kind+'_inspection.blend')))
 bpy.ops.export_scene.gltf(filepath=str(ROOT/('assets/'+kind+'_inspection.glb')),export_format='GLB',export_animations=False)
 report[kind]={'L':L,'B':B,'H':H,'objects':len(bpy.context.scene.objects)}
 (ROOT/'qa/inspection-model-build.json').write_text(json.dumps(report,indent=2))
stages=[start,lambda:build('bulkhead',139.5,23.8,13.25,0,69.75),lambda:build('study_cargo',20,3,2.4,-.4,0)]
def tick():
 try:
  stages.pop(0)()
  return 2.0 if stages else None
 except Exception:(ROOT/'qa/inspection-model-build-error.txt').write_text(traceback.format_exc())
 return None
bpy.app.timers.register(tick,first_interval=2)
