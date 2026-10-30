"""Run in one visible Blender window. Reuse the current authored tanker geometry."""
import bpy, json, traceback
from pathlib import Path
from mathutils import Vector, Quaternion
ROOT=Path(__file__).resolve().parents[1]
report={}
def subset(src,polygons,name,shapes=True):
    indices=sorted({i for p in polygons for i in p.vertices});lookup={i:j for j,i in enumerate(indices)}
    mesh=bpy.data.meshes.new(name);mesh.from_pydata([src.data.vertices[i].co[:] for i in indices],[],[tuple(lookup[i] for i in p.vertices) for p in polygons]);mesh.update()
    obj=bpy.data.objects.new(name,mesh);bpy.context.scene.collection.objects.link(obj);obj.matrix_world=src.matrix_world.copy()
    for m in src.data.materials:mesh.materials.append(m)
    for p,old in zip(mesh.polygons,polygons):p.material_index=old.material_index;p.use_smooth=old.use_smooth
    if shapes and src.data.shape_keys:
        for key in src.data.shape_keys.key_blocks:
            sk=obj.shape_key_add(name=key.name);sk.data.foreach_set('co',[c for i in indices for c in key.data[i].co]);sk.value=0
    return obj
def import_ship():
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(ROOT/'modules/review/assets/module11_ship.glb'))
    for obj in bpy.context.scene.objects:
        if obj.type=='MESH' and obj.data.shape_keys:
            obj.data.shape_keys.animation_data_clear()
            for key in obj.data.shape_keys.key_blocks:key.value=0
    for area in bpy.context.screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.shading.type='MATERIAL';area.spaces.active.region_3d.view_distance=210
            area.spaces.active.region_3d.view_location=Vector((0,0,12))
            area.spaces.active.region_3d.view_rotation=Quaternion((.81,.48,-.17,-.27)).normalized()
def bridge():
    src=next(o for o in bpy.context.scene.objects if o.type=='MESH' and o.name.startswith('Original') and 'pipework' in o.name)
    pts=[src.matrix_world@v.co for v in src.data.vertices]
    tower=[p for p in src.data.polygons if all(pts[i].x < -60 and pts[i].z>15.5 for i in p.vertices)]
    ids={p.index for p in tower};other=[p for p in src.data.polygons if p.index not in ids]
    subset(src,other,src.name+'_Retained');subset(src,tower,'OriginalAftHouse')
    top=[p for p in tower if all(pts[i].z>25.0 for i in p.vertices)]
    cabin=subset(src,top,'BridgeCabin',False)
    vertices=[cabin.matrix_world@v.co for v in cabin.data.vertices]
    lo=Vector(tuple(min(v[a] for v in vertices) for a in range(3)));hi=Vector(tuple(max(v[a] for v in vertices) for a in range(3)))
    report.update(cabin_base=lo.z,deck=15.6,cabin_bounds=[list(lo),list(hi)],tower_faces=len(tower),cabin_faces=len(top))
    assert len(top)>100 and lo.z>25
    bpy.data.objects.remove(src,do_unlink=True)
    # Railings/stairs belong to other mesh groups in the source asset. The
    # fixed accommodation must disappear together, and the bridge rails move
    # rigidly with its cabin instead of floating above the lowered roof.
    report['attached_detail_faces']=0
    for detail in list(bpy.context.scene.objects):
        if detail.type!='MESH' or not detail.name.startswith('Original') or detail.name.startswith('OriginalAftHouse'):continue
        points=[detail.matrix_world@v.co for v in detail.data.vertices]
        elevated=[p for p in detail.data.polygons if all(points[i].x < -60 and points[i].z>18.0 for i in p.vertices)]
        if not elevated:continue
        selected={p.index for p in elevated}
        remaining=[p for p in detail.data.polygons if p.index not in selected]
        if remaining:subset(detail,remaining,detail.name+'_Deck')
        subset(detail,elevated,'OriginalAftHouseDetail')
        upper=[p for p in elevated if all(points[i].z>lo.z-1.05 for i in p.vertices)]
        if upper:subset(detail,upper,'BridgeCabinDetail',False)
        report['attached_detail_faces']+=len(elevated)
        bpy.data.objects.remove(detail,do_unlink=True)
    # Closed steel pedestal is anchored on the real aft deck, with a separate rigid cabin.
    width=min(18.0,hi.y-lo.y);length=min(22.0,hi.x-lo.x);height=lo.z-15.6;cx=(hi.x+lo.x)*.5
    vs=[(x*length/2,y*width/2,z*height) for x,y,z in [(-1,-1,0),(1,-1,0),(1,1,0),(-1,1,0),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    mesh=bpy.data.meshes.new('Bridge support');mesh.from_pydata(vs,[],[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]);mesh.update()
    obj=bpy.data.objects.new('BridgeSupport',mesh);bpy.context.scene.collection.objects.link(obj);obj.location=(cx,0,15.6)
    mat=bpy.data.materials.new('Bridge painted steel');mat.diffuse_color=(.72,.81,.81,1);mat.use_nodes=True;mat.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.72,.81,.81,1);mesh.materials.append(mat)
    report['bridge_eye']=[cx+length*.45,0,lo.z+1.8]
    # The original aft house is retained for other scenes; show the new high bridge here.
    for o in bpy.context.scene.objects:
        if o.name.startswith('OriginalAftHouse'):o.hide_set(True)
def export():
    for obj in bpy.context.scene.objects:obj.hide_set(False)
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'models/总布置与驾驶室.blend'))
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'modules/review/assets/arrangement_ship.glb'),export_format='GLB',export_yup=True,export_animations=False,export_morph=True,export_apply=False,export_cameras=False,export_lights=False)
    (ROOT/'modules/review/content/arrangement_geometry.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
    (ROOT/'qa/repair-20261023/blender-complete.json').write_text(json.dumps(report,indent=2),encoding='utf8')
stages=[import_ship,bridge,export]
def tick():
    try:
        if stages:stages.pop(0)();return 2.0
        return None
    except Exception:
        (ROOT/'qa/repair-20261023/blender-error.txt').write_text(traceback.format_exc(),encoding='utf8');return None
bpy.app.timers.register(tick,first_interval=2.0)
