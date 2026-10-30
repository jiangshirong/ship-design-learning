"""Visible Blender build: retain detailed tanker exterior; T2 6a-specific layout is runtime driven."""
import bpy,json,traceback
from pathlib import Path
from mathutils import Vector,Quaternion,Matrix
ROOT=Path(__file__).resolve().parents[1]
def build():
 try:
  for o in list(bpy.context.scene.objects):bpy.data.objects.remove(o,do_unlink=True)
  bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/tanker_learning.glb'))
  removed=[]
  for o in list(bpy.context.scene.objects):
   if o.type!='MESH':continue
   zone=o.name.split('_')[0]
   if zone in ['Bulkheads','InnerSide','InnerBottom','DoubleBottom','Frames','Girders','Longitudinal','CargoLiquidOil','CargoLiquidSurface','CargoTanks','Ballast','TankAccess','Piping']:
    removed.append(o.name);bpy.data.objects.remove(o,do_unlink=True);continue
   matrix=o.matrix_world.copy();o.data=o.data.copy()
   for v in o.data.vertices:
    q=matrix@v.co;v.co=(q.x*189.13/189.64+189.13/2,q.y*26.53/26.6,q.z*14.97/14.89)
   o.matrix_world=Matrix.Identity(4)
  mat=bpy.data.materials.new('T2 cargo piping');mat.diffuse_color=(.65,.24,.13,1)
  def box(name,loc,dim):
   bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=dim;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat)
  ends=[14.4,39.24,60.33,80.73,101.13,121.53,141.93]
  for i in range(6):
   x=189.13-(ends[i]+ends[i+1])/2
   for lane,y in enumerate([-7.4,0,7.4]):
    bpy.ops.mesh.primitive_cylinder_add(vertices=24,radius=.6,depth=.25,location=(x,y,15.35))
    o=bpy.context.object;o.name=f'TankAccess_{i+1}_{lane+1}';o.data.materials.append(mat)
    box(f'Piping_branch_{i}_{lane}',(x,y*.5,15.55),(.13,max(.13,abs(y)),.13))
  for y in [-.6,0,.6]:box('Piping_cargo_main',(110,y,15.8),(125,.14,.14))
  for w in bpy.context.window_manager.windows:
   for a in w.screen.areas:
    if a.type=='VIEW_3D':
     a.spaces.active.shading.type='MATERIAL';a.spaces.active.clip_end=2000
     a.spaces.active.region_3d.view_location=Vector((95,0,8));a.spaces.active.region_3d.view_distance=220
     a.spaces.active.region_3d.view_rotation=Quaternion((.81,.48,-.17,-.27)).normalized()
  bpy.context.scene['source']='6a/6a-Женя.docx; L=189.13 B=26.53 H=14.97 T=10.85. Runtime internal geometry uses the same frame map.'
  bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'models/T2-6a舱壁布置.blend'))
  bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/bulkhead_t2.glb'),export_format='GLB',export_animations=False)
  (ROOT/'qa/bulkhead-t2-model.json').write_text(json.dumps({'removed_old_internals':removed,'objects':len(bpy.context.scene.objects),'cargo_accesses':18,'dimensions':[189.13,26.53,14.97,10.85]},ensure_ascii=False,indent=2),encoding='utf-8')
 except Exception:(ROOT/'qa/bulkhead-t2-model-error.txt').write_text(traceback.format_exc(),encoding='utf-8')
 return None
bpy.app.timers.register(build,first_interval=2)
