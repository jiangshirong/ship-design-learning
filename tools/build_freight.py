"""Appearance assets for B02. Crates do not encode a particular mass or cargo type."""
import bpy,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def material(name,rgb):
    m=bpy.data.materials.new(name);m.diffuse_color=(*rgb,1);m.use_nodes=True
    shader=m.node_tree.nodes.get('Principled BSDF');shader.inputs['Base Color'].default_value=(*rgb,1);shader.inputs['Roughness'].default_value=.75
    return m
def box(name,loc,size,mat):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat)
    mod=o.modifiers.new('Rounded timber edges','BEVEL');mod.width=.012;mod.segments=2
    bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
for kind,color in [('first',(.13,.63,.55)),('second',(.98,.55,.09))]:
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    wood=material('Painted plywood',tuple(v*.65 for v in color));edge=material('Timber frame',(.56,.37,.18));strap=material('Port identification straps',color)
    box('Freight crate',(0,0,.52),(.92,.92,.86),wood)
    for y in [-.31,.31]:box('Pallet skid',(0,y,.045),(.96,.13,.09),edge)
    for x in [-.40,.40]:
        for y in [-.47,.47]:box('Vertical corner batten',(x,y,.52),(.08,.05,.88),edge)
    for z in [.14,.89]:
        for y in [-.47,.47]:box('Horizontal batten',(0,y,z),(.90,.05,.07),edge)
    for x in [-.23,.23]:
        box('Top strap',(x,0,.96),(.045,.96,.025),strap)
        for y in [-.485,.485]:box('Face strap',(x,y,.51),(.045,.025,.9),strap)
    bpy.ops.object.select_all(action='SELECT');bpy.context.view_layer.objects.active=bpy.context.selected_objects[0];bpy.ops.object.join()
    bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    bpy.context.object.name='Freight_'+kind
    bpy.ops.export_scene.gltf(filepath=str(ROOT/f'assets/freight_{kind}.glb'),export_format='GLB')
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/f'models/freight_{kind}.blend'))
(ROOT/'assets/freight-provenance.json').write_text(json.dumps({'source':'tools/build_freight.py','purpose':'B02 first and second port goods','boundary':'Crates are pictorial. No mass per crate is implied. Aggregate stowage envelopes use confirmed volume ratios; model dimensions are not assignment hold dimensions.'},indent=2),'utf8')
