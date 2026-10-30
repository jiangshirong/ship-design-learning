"""Visible Blender authoring: persistent hull + three independent morph targets.
Run without --background. Original tanker sources remain untouched.
"""
import bpy, json, math, traceback
from pathlib import Path
from mathutils import Vector, Quaternion
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'modules/review/assets/freeboard_ship.glb'
H=14.89
KEYS=('Sheer','Superstructure','Forecastle')
parts=[]; mats={}; report={}

def material(name,color,metal=.0):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    shader=m.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value=(*color,1)
    shader.inputs['Metallic'].default_value=metal;shader.inputs['Roughness'].default_value=.48
    mats[name]=m;return m

def deck(x):
    return H+1.1*max(0,(x-53)/41.82)**2+.45*max(0,(-x-68)/30)**2

def rise(x):
    t=max(0,min(1,(x-38)/62))
    return 5*t*t*(3-2*t)
def smooth(a,b,x):
    t=max(0,min(1,(x-a)/(b-a)))
    return t*t*(3-2*t)

def create(name,verts,faces,material_name,targets=None):
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    obj=bpy.data.objects.new(name,mesh);bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mats[material_name])
    obj.shape_key_add(name='Basis')
    for key in KEYS:
        shape=obj.shape_key_add(name=key)
        coords=(targets or {}).get(key,verts)
        shape.data.foreach_set('co',[v for p in coords for v in p])
    parts.append(obj);return obj

def setup():
    # This is our fresh modelling process, never the user's existing .blend.
    report['startup']=[(o.name,o.type) for o in bpy.context.scene.objects]
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    material('Hull steel',(.19,.31,.34),.25)
    material('Deck',(.20,.38,.38),.15)
    material('Ivory painted steel',(.78,.84,.83),.10)
    material('Window',(.035,.12,.17),.25)
    material('Rails',(.69,.77,.76),.50)
    material('Door',(.36,.49,.49),.2)
    scene=bpy.context.scene;scene.unit_settings.system='METRIC'
    scene.frame_start=1;scene.frame_end=420
    for area in bpy.context.screen.areas:
        if area.type=='VIEW_3D':
            space=area.spaces.active;space.shading.type='MATERIAL'
            space.region_3d.view_distance=190
            space.region_3d.view_location=Vector((0,0,10))
            space.region_3d.view_rotation=Quaternion((.81,.48,-.17,-.27)).normalized()
            space.clip_end=2000

def hull():
    source=json.loads((ROOT/'modules/review/content/stability_hydro.json').read_text())['routes']['base'][0]
    verts=source['vertices'];faces=source['faces']
    n=source['ring_size']
    tops=[max(v[2] for v in verts[i*n:(i+1)*n]) for i in range(source['ring_count'])]
    raised=[(x,y,z+rise(x)*max(0,min(1,(z-10.88)/(tops[min(i//n,len(tops)-1)]-10.88)))) for i,(x,y,z) in enumerate(verts)]
    obj=create('Continuous hull and deck',verts,faces,'Hull steel',{'Sheer':raised})
    obj.data.materials.append(mats['Deck'])
    for p in obj.data.polygons:
        p.use_smooth=abs(p.normal.z)<.5
        if p.normal.z>.7:p.material_index=1
    report['hull_vertices']=len(verts)

def clipped(poly,bound,keep_right):
    out=[]
    a=poly[-1];da=(a.x-bound)*(1 if keep_right else -1)
    for b in poly:
        db=(b.x-bound)*(1 if keep_right else -1)
        if (da>=0)!=(db>=0):out.append(a.lerp(b,da/(da-db)))
        if db>=0:out.append(b.copy())
        a,da=b,db
    return out

def fitted_rails(objects):
    # Split each face at the real construction boundaries. Shared long handrails
    # must never drag their fixed portions upward with the raised deck.
    zones=[('Aft',-1000,-33,False,False),('Middle',-33,15,True,False),
           ('Forward',15,61,False,False),('Bow',61,1000,False,True)]
    fixed_error=0
    for name,lo,hi,middle,bow in zones:
        verts=[];faces=[]
        for obj in objects:
            world=[obj.matrix_world@v.co for v in obj.data.vertices]
            for p in obj.data.polygons:
                poly=clipped([world[i] for i in p.vertices],lo,True)
                if poly:poly=clipped(poly,hi,False)
                if len(poly)<3:continue
                start=len(verts)
                verts.extend((v.x,v.y,v.z-2.45*smooth(74,79,v.x)) for v in poly)
                faces.append(tuple(range(start,len(verts))))
        targets={
            'Sheer':[(x,y,z+rise(x)) for x,y,z in verts],
            'Superstructure':[(x,y,z+(6 if middle else 0)) for x,y,z in verts],
            'Forecastle':[(x,y,z+(5 if bow else 0)) for x,y,z in verts]}
        create('Original rail region '+name,verts,faces,'Rails',targets)
        if not middle:
            fixed_error=max(fixed_error,max((abs(a[2]-b[2]) for a,b in zip(verts,targets['Superstructure'])),default=0))
        if not bow:
            fixed_error=max(fixed_error,max((abs(a[2]-b[2]) for a,b in zip(verts,targets['Forecastle'])),default=0))
    report['fixed_railing_displacement_m']=fixed_error

def fittings():
    before=set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=str(ROOT/'modules/review/assets/stability_fittings.glb'))
    imported=[o for o in bpy.context.scene.objects if o not in before and o.type=='MESH']
    rail_objects=[o for o in imported if o.name.startswith('Railings')]
    fitted_rails(rail_objects)
    verts=[];faces=[];indices=[];materials=[];targets={k:[] for k in KEYS}
    # Consolidate original detail into one morph mesh without losing materials.
    for obj in imported:
        if obj in rail_objects:continue
        world=[obj.matrix_world@v.co for v in obj.data.vertices]
        centre=sum(world,Vector())/max(1,len(world))
        if obj.name.startswith('Forecastle') or (obj.name.startswith('Stairs') and centre.x>70):
            continue
        span=max(v.x for v in world)-min(v.x for v in world)
        # The original fittings came from a ship with an already raised forecastle.
        # Remove that inherited step for the before/after lesson's flush-deck baseline.
        for v in world:v.z-=2.45*smooth(74,79,v.x if span>8 else centre.x)
        start=len(verts);verts.extend(tuple(v) for v in world)
        local_mats=[]
        for m in obj.data.materials:
            if m not in materials:materials.append(m)
            local_mats.append(materials.index(m))
        for p in obj.data.polygons:
            faces.append(tuple(start+i for i in p.vertices))
            indices.append(local_mats[p.material_index] if local_mats else 0)
        # Long rails/pipes bend continuously; compact machinery remains rigid.
        for v in world:
            shift=rise(v.x) if span>8 else rise(centre.x)
            targets['Sheer'].append((v.x,v.y,v.z+shift))
            # Relocate deck equipment to the newly raised working deck.
            # Keep cargo pipes/supports on the original working deck, enclosed
            # where the new structure occupies it. Roof ventilation is separate.
            lift=0
            targets['Superstructure'].append((v.x,v.y,v.z+lift))
            lift=5 if span<=8 and centre.x>=61 and centre.z<22 else 0
            targets['Forecastle'].append((v.x,v.y,v.z+lift))
    for obj in imported:bpy.data.objects.remove(obj,do_unlink=True)
    obj=create('Original pipework railings and deck machinery',verts,faces,'Rails',targets)
    obj.data.materials.clear()
    for m in materials:obj.data.materials.append(m)
    for p,idx in zip(obj.data.polygons,indices):p.material_index=idx;p.use_smooth=True
    report['original_fittings']=len(imported)

def extruded(name,outline,height,key):
    # Matching bottom perimeter lies on the real deck, not at a floating centre.
    n=len(outline)
    final=[(x,y,deck(x)+z) for z in (0,height) for x,y in outline]
    base=[(x,y,deck(x)-.025+.003*(z-deck(x))) for x,y,z in final]
    faces=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]
    faces.extend((i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n))
    obj=create(name,base,faces,'Hull steel',{key:final})
    obj.data.materials.append(mats['Deck'])
    obj.data.polygons[1].material_index=1
    return obj

def detail_box(name,centre,size,key,mat):
    x,y,z=centre;a,b,c=[v/2 for v in size]
    final=[(x+sx*a,y+sy*b,z+sz*c) for sx,sy,sz in
           [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    base=[(vx,vy,deck(vx)-.035+.001*(vz-deck(vx))) for vx,vy,vz in final]
    return create(name,base,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],mat,{key:final})

def rail(name,a,b,key,r=.055):
    a,b=Vector(a),Vector(b);t=(b-a).normalized();side=t.cross(Vector((0,0,1)))
    if side.length<.01:side=t.cross(Vector((0,1,0)))
    side.normalize();up=t.cross(side).normalized()
    final=[tuple(p+r*(side*math.cos(j*math.tau/8)+up*math.sin(j*math.tau/8))) for p in (a,b) for j in range(8)]
    base=[(x,y,deck(x)-.04+.001*(z-deck(x))) for x,y,z in final]
    faces=[(j,(j+1)%8,(j+1)%8+8,j+8) for j in range(8)]
    create(name,base,faces,'Rails',{key:final})

def building():
    key='Superstructure'
    outline=[(-32,-12.9),(14,-12.9),(15,-11.9),(15,11.9),(14,12.9),(-32,12.9),(-33,11.9),(-33,-11.9)]
    extruded('Enclosed superstructure continuous sides',outline,6,key)
    for side in (-1,1):
        for x in range(-28,13,5):
            detail_box('Superstructure window', (x,side*12.94,H+4), (1.5,.09,1.0),key,'Window')
        for x in (-27,8):
            detail_box('Weather tight door',(x,side*12.97,H+1.35),(1.3,.12,2.7),key,'Door')
    for x in (-33,15):
        for y in range(-12,13,3):rail('Roof end post',(x,y,H+6),(x,y,H+7.1),key)
        for z in (6.5,7.1):rail('Roof end rail',(x,-12.9,H+z),(x,12.9,H+z),key)
    for x in (-24,-4,8):
        for y in (-7,7):
            detail_box('Roof ventilation trunk',(x,y,H+6.7),(1,1,1.4),key,'Ivory painted steel')
            detail_box('Roof ventilation cap',(x,y,H+7.4),(1.6,1.6,.22),key,'Door')
    report['superstructure_height']=6

def forecastle():
    key='Forecastle'
    # Read the actual deck-edge stations to match taper and stem rake precisely.
    source=json.loads((ROOT/'modules/review/content/stability_hydro.json').read_text())['routes']['base'][0]
    n=source['ring_size'];edge=[]
    for i in range(source['ring_count']):
        ring=source['vertices'][i*n:(i+1)*n]
        top=max(ring,key=lambda p:p[2])
        # Both top corners have the same z; choose positive y explicitly.
        candidates=[p for p in ring if abs(p[2]-top[2])<.001]
        p=max(candidates,key=lambda p:p[1])
        if p[0]>=61:edge.append(p)
    outline=[(x,-y) for x,y,z in edge]+[(x,y) for x,y,z in reversed(edge)]
    # Use measured deck heights (raked x differs from loft station x).
    lookup={(round(x,5),round(y,5)):z for x,y,z in edge}
    final=[(x,y,lookup[(round(x,5),round(abs(y),5))]+z) for z in (0,5) for x,y in outline]
    count=len(outline);base=[(x,y,z-5 if i>=count else z) for i,(x,y,z) in enumerate(final)]
    base=[(x,y,z-.025+(.015 if i>=count else 0)) for i,(x,y,z) in enumerate(base)]
    # Explicit station strips preserve the curved deck, avoiding a nonplanar n-gon.
    half=len(edge)
    faces=[]
    for i in range(half-1):
        a,b,c,d=i,i+1,count-2-i,count-1-i
        faces.extend([(d,c,b,a),(a+count,b+count,c+count,d+count)])
    faces.extend((i,(i+1)%count,(i+1)%count+count,i+count) for i in range(count))
    o=create('Forecastle tapered hull extension',base,faces,'Hull steel',{key:final})
    o.data.materials.append(mats['Deck'])
    for i in range(1,2*(half-1),2):o.data.polygons[i].material_index=1
    x0=edge[0][0]
    for y in (-4,4):detail_box('Forecastle aft weather tight door',(x0-.06,y,deck(x0)+1.35),(.12,1.4,2.7),key,'Door')
    for y in range(-10,11,2):rail('Forecastle aft rail post',(x0,y,deck(x0)+5),(x0,y,deck(x0)+6.1),key)
    for z in (5.55,6.1):rail('Forecastle aft rail',(x0,-edge[0][1],deck(x0)+z),(x0,edge[0][1],deck(x0)+z),key)
    report['forecastle_height']=5

def finish():
    for obj in parts:
        keys=obj.data.shape_keys.key_blocks
        for key,start,end in [('Superstructure',30,100),('Sheer',160,230),('Forecastle',290,360)]:
            for frame,value in [(1,0),(start,0),(end,1),(end+20,1),(end+40,0),(420,0)]:
                keys[key].value=value;keys[key].keyframe_insert('value',frame=frame)
    bpy.context.scene.frame_set(1)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in parts:obj.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'models/干舷与艏部高度连续变形.blend'))
    bpy.ops.export_scene.gltf(filepath=str(OUT),export_format='GLB',use_selection=True,
                              export_animations=False,export_morph=True,export_morph_normal=True)
    report['objects']=len(parts);report['shape_keys']=list(KEYS);report['glb']=str(OUT)
    (ROOT/'qa/freeboard-blender-build.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    # Keep the visible Blender window playing the three authored transformations.
    for area in bpy.context.screen.areas:
        if area.type=='VIEW_3D':
            with bpy.context.temp_override(area=area):bpy.ops.screen.animation_play()
            break

stages=[setup,hull,fittings,building,forecastle,finish]
def step():
    try:
        if stages:
            fn=stages.pop(0);fn()
            for area in bpy.context.screen.areas:area.tag_redraw()
            return 2.0 if stages else None
    except Exception:
        (ROOT/'qa/freeboard-blender-error.txt').write_text(traceback.format_exc())
    return None
bpy.app.timers.register(step,first_interval=2)
