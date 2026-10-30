"""Run in a new visible Blender instance; preserve the original tanker asset."""
import bpy, math, json, traceback
from pathlib import Path
from mathutils import Quaternion, Vector
ROOT=Path(__file__).resolve().parents[1]
report={'startup_objects':[(o.name,o.type) for o in bpy.context.scene.objects]}
def import_model():
    for obj in list(bpy.context.scene.objects):
        bpy.data.objects.remove(obj,do_unlink=True)
    bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/tanker_learning.glb'))
    report['existing_bulkheads']=[o.name for o in bpy.context.scene.objects if o.name.startswith('Bulkheads')]
    scene=bpy.context.scene;scene.unit_settings.system='METRIC'
    for area in bpy.context.window_manager.windows[0].screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.shading.type='MATERIAL'
            area.spaces.active.clip_end=2000
            area.spaces.active.region_3d.view_distance=185
            area.spaces.active.region_3d.view_location=Vector((0,0,8))
            area.spaces.active.region_3d.view_rotation=Quaternion((.81,.48,-.17,-.27)).normalized()
def peak():
    x=80.0;w=13.3*(.78+(.55-.78)*((x-72)/10)**2*(3-2*(x-72)/10))
    h=14.89+1.1*((x-53)/41.82)**2
    profile=[(0,0),(.7,0),(.79,.01),(.86,.03),(.92,.065),(.967,.11),(1,.18),(1,.4),(1,.75),(1,1)]
    ring=[(y*w,z*h) for y,z in profile]+[(-y*w,z*h) for y,z in profile[:0:-1]]
    n=len(ring);vertices=[(xx,y,z) for xx in (x-.09,x+.09) for y,z in ring]
    faces=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]
    faces.extend((i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n))
    mesh=bpy.data.meshes.new('Forepeak solid plate');mesh.from_pydata(vertices,[],faces);mesh.update()
    obj=bpy.data.objects.new('PeakBulkhead_far_structure',mesh);bpy.context.scene.collection.objects.link(obj)
    mat=bpy.data.materials.new('Forepeak watertight steel');mat.diffuse_color=(.32,.43,.48,1);mat.use_nodes=True
    mat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=mat.diffuse_color
    mat.node_tree.nodes.get('Principled BSDF').inputs['Metallic'].default_value=.2
    mesh.materials.append(mat)
    for y in (-4,-2,0,2,4):
        bpy.ops.mesh.primitive_cube_add(size=1,location=(80.22,y,h*.57))
        stiff=bpy.context.object;stiff.name='PeakFrame_far_structure'
        stiff.dimensions=(.26,.14,h*.81)
        bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
        stiff.data.materials.append(mat)
    report['added_forepeak_bulkhead']={'x_m':x,'thickness_m':.18,'stiffeners':5}
def save():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'models/进水与水密分舱学习模型.blend'))
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/damage_tanker.glb'),export_format='GLB',export_animations=False)
    report['object_count']=len(bpy.context.scene.objects)
    (ROOT/'qa/damage-blender-build.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
stages=[import_model,peak,save]
def step():
    try:
        stages.pop(0)()
        for window in bpy.context.window_manager.windows:
            for area in window.screen.areas:area.tag_redraw()
        return 2.0 if stages else None
    except Exception:
        (ROOT/'qa/damage-blender-error.txt').write_text(traceback.format_exc())
    return None
bpy.app.timers.register(step,first_interval=1)
