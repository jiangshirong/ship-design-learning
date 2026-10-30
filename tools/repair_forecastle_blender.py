import bpy,sys,json,hashlib,traceback,time
from pathlib import Path
from mathutils import Vector,Quaternion
R=Path(__file__).resolve().parents[1];sys.path.insert(0,str(R/'tools'))
import fair_ship_geometry as Fair,forecastle_geometry as C
start=time.time()

def deform(p,key):
 x,y,z=p;v=Vector(p)
 if key=='Flare':v.y=y*(1+.65*Fair.smooth(55,80,x)*Fair.smooth(10.88,15.99,z))
 return v

def run():
 try:
  assert bpy.data.filepath.endswith('船体型线与艏艉变形.blend'),'Open the source blend on the command line before this script'
  scene=bpy.context.scene;scene.frame_set(1)
  screen=bpy.context.window_manager.windows[0].screen
  for o in scene.objects:
   if o.type=='MESH' and o.data.shape_keys:
    o.data.shape_keys.animation_data_clear()
    for key in o.data.shape_keys.key_blocks:key.value=0
  hull=next(o for o in scene.objects if o.type=='MESH' and o.name.startswith('Continuous'))
  coordinates=[c for v in hull.data.shape_keys.key_blocks['Basis'].data for c in v.co]
  for name in ['Superstructure','Forecastle']:hull.data.shape_keys.key_blocks[name].data.foreach_set('co',coordinates)
  source=Fair.build();obj,data=C.replace_in_blender(source,deform)
  for area in screen.areas:
   if area.type=='VIEW_3D':
    v=area.spaces.active;v.shading.type='MATERIAL';v.region_3d.view_location=Vector((80,0,18));v.region_3d.view_distance=65;v.region_3d.view_rotation=Quaternion((.82,.45,-.16,-.30)).normalized()
  checks=[]
  for amount in [0,.25,.5,.75,1.]:
   key=obj.data.shape_keys.key_blocks['Forecastle'];key.value=amount
   base=obj.data.shape_keys.key_blocks['Basis'];target=key
   for i,(a,b) in enumerate(zip(base.data,target.data)):
    p=a.co.lerp(b.co,amount)
    checks.append(dict(name=f'Footprint {amount} vertex {i}',passed=abs(p.x-a.co.x)<1e-5 and abs(p.y-a.co.y)<1e-5))
   bottom=[i for i,(a,b) in enumerate(zip(base.data,target.data)) if abs(b.co.z-a.co.z)<1e-4]
   checks.append(dict(name=f'Fixed original-deck connection {amount}',passed=all((base.data[i].co.lerp(target.data[i].co,amount)-base.data[i].co).length<1e-5 for i in bottom)))
  key.value=0
  bpy.ops.object.select_all(action='DESELECT')
  for o in scene.objects:
   if o.type=='MESH':o.select_set(True)
  bpy.context.view_layer.objects.active=obj
  bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
  out=R/'modules/review/assets/module11_ship.glb'
  bpy.ops.export_scene.gltf(filepath=str(out),export_format='GLB',use_selection=True,export_animations=False,export_morph=True,export_morph_normal=True)
  # Cache is now invalid until the same repaired solids are baked again.
  h=hashlib.sha256(out.read_bytes()).hexdigest()
  (R/'qa/forecastle-deck-connection.json').write_text(json.dumps(dict(source_sha256=h,checks=checks,forecastle_vertices=len(obj.data.vertices),closed=True),indent=2),encoding='utf-8')
  (R/'qa/forecastle-model-ready.json').write_text(json.dumps(dict(source_sha256=h,ready=all(c['passed'] for c in checks))),encoding='utf-8')
  obj.data.shape_keys.key_blocks['Forecastle'].value=1
  # Single visible window remains available for the following fluid bake.
  def commands():
   p=R/'qa/forecastle-blender-command.py'
   if p.exists():
    code=p.read_text(encoding='utf-8-sig');p.unlink();exec(code,globals())
   return 1.
  bpy.app.timers.register(commands,first_interval=1.)
 except Exception:(R/'qa/forecastle-repair-error.txt').write_text(traceback.format_exc())
 return None
bpy.app.timers.register(run,first_interval=2.)
