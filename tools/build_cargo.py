"""Blender-authored bundled steel cargo. Appearance is illustrative, not assignment geometry."""
import bpy, math, json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def mat(name,color,metal=0):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=.34
    return m
steel=mat('Rolled steel',(.55,.66,.72),.72)
edge=mat('Layer edges',(.12,.21,.26),.7)
strap=mat('Orange transport straps',(.95,.36,.055),.2)
wood=mat('Timber bearers',(.30,.16,.065))
def box(name,loc,scale,material):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(material)
    mod=o.modifiers.new('Rounded edges','BEVEL');mod.width=.045;mod.segments=3
    o.modifiers.new('Normals','WEIGHTED_NORMAL')
def tube(name,xyz,outer,inner,depth,material):
    verts=[];faces=[];n=96
    for x,r in [(-depth/2,outer),(depth/2,outer),(-depth/2,inner),(depth/2,inner)]:
        for i in range(n):
            a=i*math.tau/n;verts.append((xyz[0]+x,xyz[1]+r*math.cos(a),xyz[2]+r*math.sin(a)))
    for i in range(n):
        j=(i+1)%n
        faces.extend([(i,j,n+j,n+i),(2*n+j,2*n+i,3*n+i,3*n+j),(j,i,2*n+i,2*n+j),(n+i,n+j,3*n+j,3*n+i)])
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);o.data.materials.append(material)
    for p in mesh.polygons:p.use_smooth=p.index%4<2
for x in [-3.25,0,3.25]:
    for y in [-1.55,1.55]:
        tube('Hollow rolled steel coil',(x,y,0),1.25,.38,2.6,steel)
        for side in [-1,1]:
            for r in [.50,.65,.80,.95,1.10,1.235]:tube('Concentric rolled layers',(x+side*1.306,y,0),r+.012,r,.012,edge)
        for dx in [-.78,.78]:tube('Securing band',(x+dx,y,0),1.276,1.251,.11,strap)
        for dy in [-.72,.72]:box('Timber cradle',(x,y+dy,-1.16),(2.85,.36,.38),wood)
        box('Base skid',(x,y,-1.43),(2.95,2.6,.18),wood)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/steel_cargo.glb'),export_format='GLB',export_cameras=False,export_lights=False)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'models/steel_cargo.blend'))
(ROOT/'assets/cargo-provenance.json').write_text(json.dumps({'kind':'Bundled steel coils','source':'tools/build_cargo.py','reference_origin':'Assignment cargo centre in metres; visual shape does not determine mass or CG','mass_t':100,'appearance_only':True,'assignment_does_not_specify_cargo_type':True},ensure_ascii=False,indent=2),encoding='utf-8')
print('CARGO_READY')
