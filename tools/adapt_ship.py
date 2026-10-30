"""Run with Blender --background <source.blend> --python this_file.
Build derived teaching assets; never save over the source project.
"""
import bpy, json, collections
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets'; OUT.mkdir(exist_ok=True)
SOURCE=Path(r'D:\桌面文件夹\学习\大学课程\过考试\未过）造船绘图\ChatGPT\船体结构学习-v2\模型\完整教学杂货船.blend')

def export(kind):
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
    scene=bpy.context.scene
    keep=[]
    for o in list(scene.objects):
        zone=o.get('zone','')
        if not zone or zone in ['Studio','OpeningMarkers'] or o.type not in ['MESH','CURVE','FONT']:
            bpy.data.objects.remove(o,do_unlink=True); continue
        if kind=='tanker' and (any(x in o.name for x in ['Crane','Hatch','Cargo']) or zone in ['Frames','DoubleBottom','Bulkheads','Machinery']):
            bpy.data.objects.remove(o,do_unlink=True);continue
        o.hide_set(False);o.hide_render=False;keep.append(o)
    if kind=='tanker':
        def cube(name,loc,size,mat):
            bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=size
            bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
            o.data.materials.append(bpy.data.materials[mat]);o['zone']='TankerDeck';keep.append(o)
        cube('ContinuousCargoDeck',(-1,0,7.5),(45,11.8,.12),'V2_DeckPaint')
        for y in [-1.3,1.3]:
            bpy.ops.mesh.primitive_cylinder_add(vertices=20,radius=.16,depth=46,location=(0,y,8.1),rotation=(0,1.57079632679,0))
            o=bpy.context.object;o.name='CargoMainPipe';o.data.materials.append(bpy.data.materials['V2_WarmWhite']);o['zone']='TankerDeck';keep.append(o)
        for x in [-17,-7,3,13,22]:
            for y in [-3,3]:
                bpy.ops.mesh.primitive_cylinder_add(vertices=32,radius=.62,depth=.24,location=(x,y,7.72))
                o=bpy.context.object;o.name='TankAccess';o.data.materials.append(bpy.data.materials['V2_FrameSteel']);o['zone']='TankerDeck';keep.append(o)
        for x in [-14,0,14]:
            cube('PipeBridge',(x,0,7.8),(.18,4,.5),'V2_FrameSteel')
    # Evaluate bevels before merging. Keep semantic zone / cutaway metadata.
    bpy.context.view_layer.update();deps=bpy.context.evaluated_depsgraph_get();groups=collections.defaultdict(list)
    for o in keep:
        data=bpy.data.meshes.new_from_object(o.evaluated_get(deps),depsgraph=deps)
        n=bpy.data.objects.new('Prepared_'+o.name,data);scene.collection.objects.link(n);n.matrix_world=o.matrix_world.copy()
        key=(o.get('zone',''),bool(o.get('near_side',False)),bool(o.get('cutaway_hide',False)))
        groups[key].append(n)
    for o in keep:bpy.data.objects.remove(o,do_unlink=True)
    for (zone,near,hidden),objects in groups.items():
        bpy.ops.object.select_all(action='DESELECT')
        for o in objects:o.select_set(True)
        bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();o=objects[0]
        o.name=f'{zone}_{"near" if near else "far"}_{"cover" if hidden else "structure"}'
        o['zone']=zone;o['near_side']=near;o['cutaway_hide']=hidden
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=str(OUT/f'{kind}_ship.glb'),export_format='GLB',export_extras=True,export_cameras=False,export_lights=False)
    model=ROOT/'models';model.mkdir(exist_ok=True);(model/'.gdignore').write_text('')
    bpy.ops.wm.save_as_mainfile(filepath=str(model/f'{kind}_ship.blend'))
    return {'variant':kind,'mesh_groups':len(groups),'vertices':sum(len(o.data.vertices) for o in scene.objects if o.type=='MESH'),'reference_dimensions_m':{'length':78,'beam':12.6,'main_deck':7.5}}

result=[export('cargo'),export('tanker')]
(OUT/'model-provenance.json').write_text(json.dumps({'source':str(SOURCE),'models':result,'boundary':'Derived schematic geometry, rescaled for instruction. Not assignment hull lines or hydrostatic geometry.'},ensure_ascii=False,indent=2),encoding='utf-8')
print('ADAPTATION_COMPLETE',result)
