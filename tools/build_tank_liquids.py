"""Run staged functions in visible Blender. Authored compartments, source fuel CGs."""
import bpy, json, importlib.util, struct
from pathlib import Path
from mathutils import Vector, Matrix
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('ship_parts',ROOT/'tools/build_learning_tanker.py')
parts=importlib.util.module_from_spec(spec);spec.loader.exec_module(parts)
ROWS=json.loads((ROOT/'content/confirmed/calculated.json').read_text('utf8'))['steps']['L01']['rows']

def setup_materials():
    parts.COL={};parts.M={m.name:m for m in bpy.data.materials}
    for name,color,metal,rough in [('fuel_wall','506a76',.3,.42),('fuel_edge','aab9bd',.5,.3),('fuel_oil','71431b',.15,.27),('fuel_surface','b88028',.4,.18),('fuel_pipe','baafb0',.4,.3),('fuel_valve','d55c35',.1,.4)]:
        if name not in parts.M:parts.material(name,color,metal,rough)

def display(title,focus=(0,0,6),distance=200):
    parts.show(title,focus,distance)
    for a in bpy.context.screen.areas:
        if a.type=='VIEW_3D':
            a.spaces.active.region_3d.view_rotation=Vector((.12,-1,.85)).to_track_quat('Z','Y')
    return {'stage':title,'objects':len(bpy.context.scene.objects)}

def liquid(name,centre,dimensions,group):
    x,y,z=centre;lx,ly,lz=dimensions
    oil=parts.box(name+'_oil',centre,dimensions,'fuel_oil',group+'Oil')
    # Distinct horizontal glossy surface, no waves that move the model CG.
    parts.box(name+'_surface',(x,y,z+lz/2+.003),(lx,ly,.006),'fuel_surface',group+'Surface')
    for side in [-1,1]:
        parts.tube(name+'_meniscus_'+str(side),[(x-lx/2+.05,y+side*(ly/2-.04),z+lz/2+.012),(x+lx/2-.05,y+side*(ly/2-.04),z+lz/2+.012)],.018,'fuel_surface',group+'Surface',segments=6)
    return oil

def tanker_liquid():
    assert len(bpy.data.collections['TankReferences'].objects)==12
    setup_materials()
    # Rebuilding replaces only this script's liquid objects.
    for o in list(bpy.context.scene.objects):
        if o.get('zone','').startswith('CargoLiquid'):bpy.data.objects.remove(o,do_unlink=True)
    for ref in bpy.data.collections['TankReferences'].objects:
        x,y,_=ref.location
        liquid(ref.name,(x,y,6.55),(19.65,10.52,8.5),'CargoLiquid')
    for o in bpy.context.scene.objects:
        if o.get('near_side') or o.get('cutaway_hide'):o.hide_set(True)
    return display('Т2 · 液货体与水平液面',(0,0,7),200)

def export_asset(asset):
    scene=bpy.context.scene;window=bpy.context.window;deps=bpy.context.evaluated_depsgraph_get()
    temporary=bpy.data.scenes.new('Liquid_export');groups={}
    for o in list(scene.objects):
        if o.type!='MESH':continue
        data=bpy.data.meshes.new_from_object(o.evaluated_get(deps),depsgraph=deps)
        n=bpy.data.objects.new(o.name,data);temporary.collection.objects.link(n);n.matrix_world=o.matrix_world.copy()
        groups.setdefault((o.get('zone','Equipment'),bool(o.get('near_side')),bool(o.get('cutaway_hide'))),[]).append(n)
    window.scene=temporary
    for (zone,near,cover),items in groups.items():
        bpy.ops.object.select_all(action='DESELECT')
        for o in items:o.select_set(True)
        bpy.context.view_layer.objects.active=items[0]
        if len(items)>1:bpy.ops.object.join()
        o=items[0];o.name=f'{zone}_{"near" if near else "far"}_{"cover" if cover else "structure"}'
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets'/asset),export_format='GLB',use_active_scene=True,export_extras=True,export_cameras=False,export_lights=False)
    count=len(temporary.objects);window.scene=scene
    for o in list(temporary.objects):bpy.data.objects.remove(o,do_unlink=True)
    bpy.data.scenes.remove(temporary)
    return count

def save_tanker():
    count=export_asset('tanker_learning.glb')
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'models/液货船学习模型.blend'))
    p=ROOT/'assets/tanker-learning-provenance.json';r=json.loads(p.read_text('utf8'))
    r['version']=3;r['export']['mesh_groups']=count;r['liquid_filled_cargo_tanks']=12
    blob=(ROOT/'assets/tanker_learning.glb').read_bytes();n=struct.unpack_from('<I',blob,12)[0];g=json.loads(blob[20:20+n])
    r['export']['triangles']=sum(g['accessors'][x['indices']]['count']//3 for m in g['meshes'] for x in m['primitives'])
    note='Visible cargo liquid and horizontal free surfaces; fill level is teaching geometry, not homework volume integration'
    if note not in r['teaching_choices']:r['teaching_choices'].append(note)
    p.write_text(json.dumps(r,ensure_ascii=False,indent=2),'utf8')
    return {'saved':True,'mesh_groups':count}

def open_load():
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/'models/cargo_ship.blend'))
    # Work in a distinct derived source; the reusable cargo asset stays unchanged.
    setup_materials()
    for o in bpy.context.scene.objects:
        if o.type=='MESH':
            o.matrix_world=Matrix.Diagonal((150/78,25/12.6,17/7.5,1)) @ o.matrix_world
            o['zone']=o.name.split('_')[0]
    bpy.context.view_layer.update()
    return {'bounds':[(o.name,[round(v,2) for v in o.dimensions]) for o in bpy.context.scene.objects if o.type=='MESH']}

def prepare_load():
    setup_materials()
    # Replace the old schematic inner bottom with actual fuel spaces; retain shell.
    for o in list(bpy.context.scene.objects):
        if o.type=='MESH':
            o.data.transform(o.matrix_world);o.matrix_world=Matrix.Identity(4)
        if o.get('zone') in ['DoubleBottom','Frames']:bpy.data.objects.remove(o,do_unlink=True)
        else:
            if o.get('zone')=='Hull':
                for v in o.data.vertices:
                    if v.co.z<2.0:v.co.z=max(0,(v.co.z-.8)*2/1.2)
            if o.get('zone')=='Machinery':
                # Narrow engine in centreline machinery space; side tanks remain separate.
                o.scale.y*=.55
            if o.get('near_side') or o.get('cutaway_hide'):o.hide_set(True)
    bpy.context.scene['reference']='Variant 5 multipurpose vessel, four dry holds and nine fuel tanks'
    bpy.context.scene['layout_boundary']='x,z and masses from source; tank dimensions, fill density 0.85 t/m3 and transverse layout are explicit teaching choices'
    return display('第5方案 · 四货舱船，准备双层底与艉部燃油舱',(0,0,7),180)

TANKS=[]
def tank(i):
    r=ROWS[i];j=i+1;x=r['x_m']-75;z=r['z_m'];p=r['mass_t']
    # Fuel centre is the centroid of the visible rectangular oil volume.
    # A demonstrative density gives relative volumes; no derived FSM is claimed.
    ys=[0,-5.55,0,5.55,0,-7,-7,7,7]
    lengths=[20,35,35,35,15,5,5,4.8,4.8]
    heights=[1,1,1,1,1,2.6,2.4,2.2,2.2]
    y=ys[i];lx=lengths[i];lz=heights[i];ly=p/(.85*lx*lz)
    bottom=z-lz/2;top=z+lz/2+.55;wall_h=top-bottom;mid=(bottom+top)/2
    zone=f'Fuel{j:02d}';name=f'Fuel_tank_{j:02d}'
    parts.box(name+'_bottom',(x,y,bottom-.035),(lx+.16,ly+.16,.07),'fuel_wall',zone+'Shell')
    for sign in [-1,1]:
        parts.box(name+'_end_'+str(sign),(x+sign*(lx/2+.04),y,mid),(.08,ly+.16,wall_h),'fuel_wall',zone+'Shell')
        parts.box(name+'_side_'+str(sign),(x,y+sign*(ly/2+.04),mid),(lx,.08,wall_h),'fuel_wall',zone+'Shell',near=sign<0)
        parts.tube(name+'_rim_'+str(sign),[(x-lx/2,y+sign*ly/2,top),(x+lx/2,y+sign*ly/2,top)],.045,'fuel_edge',zone+'Details')
    parts.box(name+'_top',(x,y,top+.04),(lx+.16,ly+.16,.08),'fuel_wall',zone+'Shell',cover=True)
    liquid(name,(x,y,z),(lx,ly,lz),zone)
    # Breather and fill/withdrawal branch; no vessel-specific fuel circuit claimed.
    parts.tube(name+'_vent',[(x-lx*.35,y+ly*.3,top),(x-lx*.35,y+ly*.3,top+.55),(x-lx*.35+.3,y+ly*.3,top+.55)],.055,'fuel_pipe',zone+'Details')
    parts.tube(name+'_pipe',[(x+lx*.36,y,top+.35),(x+lx*.36,y,top),(x+lx*.36,y,bottom+.18)],.065,'fuel_pipe',zone+'Details')
    parts.cyl(name+'_valve',(x+lx*.36,y,top+.35),.15,.14,'fuel_valve',zone+'Details')
    record={'id':j,'mass_t':p,'x_m':r['x_m'],'z_m':z,'y_display_m':y,'oil_dimensions_m':[lx,ly,lz],'oil_centre_blender':[x,y,z],'oil_centre_godot':[x,z,-y],'oil_volume_display_m3':p/.85,'geometry_status':'authored teaching geometry; only mass/x/z are source inputs'}
    TANKS.append(record)
    for o in bpy.context.scene.objects:
        if o.get('zone','').startswith(zone) and (o.get('near_side') or o.get('cutaway_hide')):o.hide_set(True)
    return record

def bottom_tanks():
    for i in range(5):tank(i)
    return display('第5方案 · 1—5号低位燃油舱：舱壁、油体、液面',(0,0,2),150)

def aft_tanks():
    for i in range(5,9):tank(i)
    racks()
    return display('第5方案 · 6—9号艉部燃油舱：分层布置与管口',(-49,0,8),45)

def racks():
    for idx,(x,y,dx,dy,levels,top) in enumerate([(-50,-7,9.5,6.6,[5.74,9.44],12.8),(-46.05,7,7.2,4.3,[5.59,8.74],12.0)]):
        for sx in [-1,1]:
            for sy in [-1,1]:parts.box(f'Fuel_rack_{idx}_post_{sx}_{sy}',(x+sx*dx/2,y+sy*dy/2,(top+2)/2),(.16,.16,top-2),'fuel_edge','RackPosts')
        for k,z in enumerate(levels):parts.box(f'Fuel_rack_{idx}_shelf_{k}',(x,y,z),(dx,dy,.12),'fuel_wall',f'Rack{6+idx*2+k:02d}')

def finish_load():
    # Retain inspection view in editable source. GLB exports all removable covers.
    count=export_asset('load_fuel_ship.glb')
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'models/第5方案九个燃油舱.blend'))
    report={'source_file':'1p/5. Нагрузка-2024.docx','case':'Variant 5, multipurpose ship with four holds','fuel_tanks':TANKS,'display_hull_dimensions_m':[150,25,17],'display_density_t_m3':.85,'density_and_geometry_are_teaching_choices':True,'source_coordinates':'x forward from aft perpendicular; z up from baseline','export_mesh_groups':count}
    (ROOT/'assets/fuel-tanks.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),'utf8')
    return display('第5方案 · 九个燃油舱建模完成',(0,0,6),180)
