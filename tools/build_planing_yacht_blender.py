"""Build a detailed teaching planing yacht in a single VISIBLE Blender window.
Source geometry is independent of the tanker's hull and cached fluid assets.
"""
import bpy,bmesh,math,json,traceback,hashlib
from mathutils import Vector
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'modules/review/assets/planing_yacht.glb'
report={'stages':[],'kind':'12.8 m hard-chine motor yacht; educational geometry, not a commercial design'}
stage=0
M={}
def mat(name,color,metal=0.,rough=.4):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 n=m.node_tree.nodes.get('Principled BSDF');n.inputs['Base Color'].default_value=(*color,1);n.inputs['Metallic'].default_value=metal;n.inputs['Roughness'].default_value=rough
 M[name]=m;return m
def box(name,loc,dim,material,bevel=.04):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=dim;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(M[material])
 if bevel:
  b=o.modifiers.new('Rounded manufactured edges','BEVEL');b.width=bevel;b.segments=3
  o.modifiers.new('Weighted highlights','WEIGHTED_NORMAL')
 return o
def mesh(name,vs,fs,material):
 m=bpy.data.meshes.new(name);m.from_pydata(vs,[],fs);m.materials.append(M[material]);m.update();o=bpy.data.objects.new(name,m);bpy.context.scene.collection.objects.link(o);return o
def tube(name,points,r,material):
 c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.resolution_u=12;c.bevel_depth=r;c.bevel_resolution=3
 s=c.splines.new('POLY');s.points.add(len(points)-1)
 for q,p in zip(s.points,points):q.co=(*p,1)
 o=bpy.data.objects.new(name,c);bpy.context.scene.collection.objects.link(o);o.data.materials.append(M[material]);return o
def cylinder(name,a,b,r,material,vertices=24):
 a,b=Vector(a),Vector(b);v=b-a;bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=v.length,location=(a+b)/2);o=bpy.context.object;o.name=name;o.rotation_mode='QUATERNION';o.rotation_quaternion=v.to_track_quat('Z','Y');o.data.materials.append(M[material]);return o
def frame_view(target=(0,0,1),distance=20,eye=(1,-1,.6)):
 for area in bpy.context.window_manager.windows[0].screen.areas:
  if area.type=='VIEW_3D':
   area.spaces.active.shading.type='MATERIAL' if False else 'SOLID';area.spaces.active.shading.color_type='MATERIAL';area.spaces.active.overlay.show_overlays=False
   r=area.spaces.active.region_3d;r.view_location=target;r.view_distance=distance;r.view_rotation=Vector(eye).to_track_quat('Z','Y')
def setup():
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 (ROOT/'qa/yacht-blender-error.txt').unlink(missing_ok=True)
 bpy.context.scene.unit_settings.system='METRIC'
 mat('Pearl white',(.86,.89,.88),.12,.25);mat('Deep navy',(.026,.072,.10),.18,.3);mat('Red waterline',(.43,.12,.09),.1,.3)
 mat('Teak',(.43,.26,.12),0,.7);mat('Caulking',(.025,.029,.03),0,.8);mat('Glass',(.028,.10,.14),.45,.11);mat('Chrome',(.53,.62,.64),.88,.2);mat('Canvas',(.74,.77,.72),0,.8)
 mat('Engine blue',(.055,.17,.21),.45,.32);mat('Engine dark',(.04,.055,.06),.65,.3);mat('Bronze',(.55,.34,.10),.8,.26);mat('Shaft steel',(.24,.29,.31),.9,.2);mat('Rubber',(.016,.018,.02),.1,.75)
 frame_view()
def hull():
 # Closed deep-V shell, actual hard chines and rounded longitudinal entrance.
 xs=[-6.4+i*12.8/48 for i in range(49)];vs=[];faces=[]
 def width(x):
  u=(x+6.4)/12.8
  return 1.9*(.90+.1*min(u/.45,1))*(1-max(0,(u-.45)/.55)**2)
 for x in xs:
  u=(x+6.4)/12.8;w=width(x);k=.10+.48*max(0,(u-.7)/.3)**2;deck=1.65+.5*max(0,(u-.62)/.38)**2;ch=k+.52+.16*u
  half=[(0,k),(.46*w,k+(ch-k)*.46/.88),(.88*w,ch),(.97*w,deck*.84),(w,deck)]
  vs += [(x-.5*max(0,(u-.65)/.35)**2*(deck-z)/deck,y,z) for y,z in half]+[(x-.5*max(0,(u-.65)/.35)**2*(deck-z)/deck,-y,z) for y,z in half[:0:-1]]
 n=9;nr=len(xs);lookup={};mapping={}
 for i,p in enumerate(vs):mapping[i]=lookup.setdefault(tuple(round(v,9) for v in p),i)
 def add(f):
  f=tuple(dict.fromkeys(mapping[i] for i in f))
  if len(f)>=3:
   a=Vector(vs[f[0]]);area=sum((Vector(vs[f[j]])-a).cross(Vector(vs[f[j+1]])-a).length for j in range(1,len(f)-1))
   if area>1e-10:faces.append(f)
 for i in range(nr-1):
  for j in range(n):add((i*n+j,i*n+(j+1)%n,(i+1)*n+(j+1)%n,(i+1)*n+j))
 add(tuple(reversed(range(n))))
 o=mesh('Yacht_Hull_Closed',vs,faces,'Pearl white');o.data.materials.append(M['Deep navy'])
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_edges],context='VERTS');bm.to_mesh(o.data);bm.free()
 # Correct winding and keep chines crisp, longitudinal segments smooth.
 bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT')
 for p in o.data.polygons:
  p.material_index=1 if p.center.z<.63 else 0;p.use_smooth=True
 o.data.set_sharp_from_angle(angle=math.radians(35))
 # Triangulated, evaluated geometry is the calculation source too.
 o.data.calc_loop_triangles();v=[list(v.co) for v in o.data.vertices];f=[list(t.vertices) for t in o.data.loop_triangles]
 (ROOT/'modules/review/content/yacht_geometry.json').write_text(json.dumps(dict(vertices=v,faces=f,L=12.8,B=3.8,static_draft=.72,coordinate='Blender x forward / y port / z up; Godot x,z,-y'),separators=(',',':')),encoding='utf-8')
 frame_view((1,0,.9),18,(1,-1,.45))
def decks():
 # Cockpit deck / swim platform / side walks / foredeck real manufactured parts.
 box('Deck_Cockpit',(-4.7,0,1.67),(2.6,3.1,.12),'Teak',.08)
 box('Swim_platform',(-6.85,0,1.0),(.95,3.1,.14),'Teak',.12)
 for j in range(15):tube('Cockpit teak seam', [(-5.95,-1.4+j*.2,1.735),(-3.45,-1.4+j*.2,1.735)],.007,'Caulking')
 for side in [-1,1]:
  tube('Side teak walkway',[(-3.5,side*1.62,1.72),(1.7,side*1.57,1.73),(3.3,side*1.18,1.79)],.09,'Teak')
  box('Cockpit bench '+str(side),(-4.8,side*1.05,2.02),(1.9,.55,.38),'Canvas',.13)
  box('Cockpit backrest '+str(side),(-4.8,side*1.37,2.35),(1.9,.18,.55),'Canvas',.09)
 box('Cockpit table',(-4.6,0,2.1),(1.0,.7,.1),'Teak',.08);cylinder('Table pedestal',(-4.6,0,1.7),(-4.6,0,2.08),.06,'Chrome')
 box('Foredeck sunpad',(3.1,0,2.0),(2.1,1.35,.16),'Canvas',.13)
 for j in [-.38,0,.38]:tube('Sunpad stitching',[(2.15,j,2.09),(4.05,j,2.09)],.008,'Pearl white')
 # Swept deckhouse, raked windscreen, hard roof. Closed window frames.
 vs=[(-3.35,-1.25,1.7),(-3.35,1.25,1.7),(2.05,1.25,1.85),(2.05,-1.25,1.85),(-3.1,-1.1,3.2),(-3.1,1.1,3.2),(1.1,1.02,3.05),(1.1,-1.02,3.05)]
 mesh('Cabin_body',vs,[(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7),(4,5,6,7)],'Pearl white')
 for side in [-1,1]:
  mesh('Side_windscreen_'+str(side),[(-2.9,side*1.126,2.35),(-2.9,side*1.114,3.06),(.96,side*1.05,2.96),(1.55,side*1.19,2.35)],[(0,1,2,3)],'Glass')
  tube('Window frame',[(-2.92,side*1.135,2.32),(-2.92,side*1.12,3.09),(1.0,side*1.055,3.0),(1.6,side*1.20,2.32),(-2.92,side*1.135,2.32)],.025,'Chrome')
  for x in [-1.65,-.35]:tube('Window mullion',[(x,side*1.125,2.35),(x,side*1.08,3.03)],.045,'Pearl white')
 mesh('Raked_front_windscreen',[(2.06,-1.20,2.0),(2.06,1.20,2.0),(1.13,1.02,3.06),(1.13,-1.02,3.06)],[(0,1,2,3)],'Glass')
 tube('Windshield centre',[(2.07,0,2.02),(1.13,0,3.07)],.035,'Chrome')
 box('Cabin_roof',(-.95,0,3.21),(4.7,2.55,.13),'Pearl white',.15)
 box('Roof glass hatch',(-.1,0,3.285),(1.25,.95,.025),'Glass',.08)
 box('Helm console',(-2.8,-.45,2.12),(.75,1.15,.55),'Deep navy',.09)
 box('Helm seat',(-3.65,-.7,2.2),(.65,.6,.6),'Canvas',.12)
 box('Deck_EngineCover',(-4.55,0,1.72),(2.25,2.0,.08),'Teak',.05)
 frame_view((-1,0,1.7),18,(1,-1,.55))
def machinery():
 # Two fully modelled inboard diesels, gearboxes, shafts, P brackets, propellers and rudders.
 for side in [-1,1]:
  y=side*.78
  box('Engine_block_'+str(side),(-3.5,y,.75),(1.35,.65,.7),'Engine blue',.10)
  box('Engine_sump_'+str(side),(-3.5,y,.3),(1.32,.57,.17),'Engine dark',.04)
  box('Engine_head_'+str(side),(-3.5,y,1.17),(1.38,.69,.16),'Engine dark',.05)
  for i in range(6):
   x=-4.+i*.2;cylinder('Cylinder_'+str(side)+'_'+str(i),(x,y,.57),(x,y,1.12),.105,'Engine dark')
   cylinder('Valve_'+str(side)+'_'+str(i),(x,y,1.22),(x,y,1.30),.042,'Chrome',12)
  tube('Exhaust manifold '+str(side),[(-4.05,y+.29,.95),(-3.45,y+.29,1.15),(-2.85,y+.29,.95)],.075,'Chrome')
  tube('Engine fuel line '+str(side),[(-4.05,y-.3,1.1),(-3.4,y-.3,1.12),(-2.9,y-.3,.6)],.018,'Bronze')
  cylinder('Alternator '+str(side),(-2.77,y,.7),(-2.6,y,.7),.17,'Engine dark')
  box('Gearbox_'+str(side),(-4.4,y,.6),(.45,.49,.5),'Shaft steel',.07)
  cylinder('Shaft_'+str(side),(-4.45,y,.90),(-6.45,y,.22),.045,'Shaft steel')
  cylinder('Shaft_bearing_'+str(side),(-5.95,y,.26),(-6.15,y,.23),.09,'Bronze')
  tube('P_bracket_'+str(side),[(-6.05,y,1.0),(-6.05,y,.245)],.05,'Shaft steel')
  pivot=bpy.data.objects.new('Propeller_'+str(side),None);bpy.context.scene.collection.objects.link(pivot);pivot.location=(-6.4,y,.2);bpy.context.view_layer.update()
  hub=cylinder('Propeller_hub_'+str(side),(-6.55,y,.2),(-6.20,y,.2),.12,'Bronze');hub.parent=pivot;hub.matrix_parent_inverse=pivot.matrix_world.inverted()
  for blade in range(4):
   vs=[];fs=[];rows=12
   for k in range(rows):
    r=.10+.39*k/(rows-1);angle=blade*math.tau/4+.5*r
    for c in [-1,1]:vs.append((-.03+c*.07*r,math.cos(angle+c*.15)*r,math.sin(angle+c*.15)*r))
   for k in range(rows-1):fs.append((2*k,2*k+1,2*k+3,2*k+2))
   o=mesh('Propeller_blade_'+str(side)+'_'+str(blade),vs,fs,'Bronze');o.parent=pivot
   sol=o.modifiers.new('Blade thickness','SOLIDIFY');sol.thickness=.022
   bevel=o.modifiers.new('Blade rim','BEVEL');bevel.width=.012;bevel.segments=2
  rud=box('Rudder_'+str(side),(-6.87,y,.27),(.42,.06,.65),'Shaft steel',.03)
  tube('Rudder stock '+str(side),[(-6.83,y,.3),(-6.83,y,1.)],.035,'Chrome')
 # Real engine bay floor / bulkhead and removable cockpit cover.
 for o in bpy.context.scene.objects:
  if o.name.startswith(('Engine_block_','Engine_sump_','Engine_head_','Cylinder_','Valve_','Exhaust manifold','Engine fuel line','Alternator','Gearbox_')):o.location.z+=.35
 box('Engine_bay_floor',(-3.8,0,.54),(2.8,2.2,.05),'Pearl white',.02)
 box('Engine_bay_bulkhead',(-2.35,0,1.12),(.06,2.8,1.),'Pearl white',.01)
 bpy.data.objects['Deck_EngineCover'].hide_set(True)
 frame_view((-4.3,0,.6),7,(-.3,-1,.7))
def equipment():
 bpy.data.objects['Deck_EngineCover'].hide_set(False)
 for side in [-1,1]:
  pts=[(-6.0,side*1.55,2.27),(-3.4,side*1.69,2.28),(1.8,side*1.65,2.30),(3.8,side*1.1,2.50),(5.8,side*.26,2.65)]
  tube('Guardrail_'+str(side),pts,.022,'Chrome')
  for p in pts[:-1]:tube('Stanchion',[tuple(Vector(p)-Vector((0,0,.55))),p],.018,'Chrome')
  for x in [-5.2,0,4.5]:
   w=.6 if x>4 else 1.55
   box('Mooring cleat',(x,side*w,1.87 if x<4 else 2.03),(.18,.06,.06),'Chrome',.02)
  tube('Stainless grab rail '+str(side),[(-2.6,side*1.1,3.36),(-2.45,side*1.1,3.45),(.6,side*1.1,3.45),(.8,side*1.1,3.31)],.022,'Chrome')
  box('Portlight '+str(side),(-.8,side*1.88,1.18),(1.15,.035,.24),'Glass',.10)
 box('Radar arch',(-1.4,0,3.49),(.24,1.65,.25),'Pearl white',.08)
 cylinder('Radar radome',(-1.4,0,3.58),(-1.4,0,3.76),.34,'Pearl white')
 tube('VHF antenna',[(-2.2,.6,3.3),(-2.2,.6,4.25)],.014,'Chrome')
 box('Anchor windlass',(4.8,0,2.2),(.45,.36,.20),'Chrome',.05)
 tube('Anchor bow roller',[(5.0,0,2.2),(6.5,0,2.15)],.045,'Chrome')
 box('Transom door',(-6.41,0,1.6),(.04,.7,.6),'Pearl white',.04)
 for side in [-1,1]:box('Trim_tab_'+str(side),(-6.62,side*1.15,.24),(.42,.45,.03),'Shaft steel',.02)
 frame_view((0,0,1.5),19,(1,-1,.5))
def finish():
 # Convert decorative curves and modifier results so Godot needs no Blender installation.
 for obj in list(bpy.context.scene.objects):
  obj.hide_set(False)
  if obj.type in ['CURVE','MESH']:
   bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
   if obj.type=='CURVE' or obj.modifiers:bpy.ops.object.convert(target='MESH')
 # Make normals / linked external files deterministic and local.
 for obj in bpy.context.scene.objects:
  if obj.type=='MESH' and obj.name.startswith(('Side_windscreen_','Window frame','Window mullion')):
   for v in obj.data.vertices:
    if abs(v.co.y)>.5:v.co.y+=.10*(1 if v.co.y>0 else -1)
 bpy.context.scene.render.engine='CYCLES';bpy.context.scene.cycles.samples=24
 bpy.context.scene.world=bpy.data.worlds.new('Studio');bpy.context.scene.world.use_nodes=True;bpy.context.scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.12,.16,.20,1)
 for loc,energy,size in [((3,-7,11),1800,8),((-5,6,7),1300,6)]:
  bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.data.energy=energy;o.data.shape='DISK';o.data.size=size;o.rotation_euler=(Vector((0,0,1))-o.location).to_track_quat('-Z','Y').to_euler()
 bpy.ops.object.camera_add(location=(15,-18,12));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,1))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=19;bpy.context.scene.camera=cam
 for o in bpy.context.scene.objects:o.select_set(o.type in ['MESH','EMPTY'])
 bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'models/硬舭动力游艇.blend'))
 bpy.ops.export_scene.gltf(filepath=str(OUT),export_format='GLB',use_selection=True,export_animations=False,export_yup=True)
 report.update(objects=len(bpy.data.objects),meshes=sum(o.type=='MESH' for o in bpy.data.objects),glb=str(OUT),sha256=hashlib.sha256(OUT.read_bytes()).hexdigest())
 (ROOT/'qa/yacht-blender.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
 frame_view((0,0,1.4),19,(1,-1,.5));bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
def step():
 global stage
 stages=[setup,hull,decks,machinery,equipment,finish]
 try:
  stages[stage]();report['stages'].append(stages[stage].__name__);stage+=1
  for a in bpy.context.window_manager.windows[0].screen.areas:a.tag_redraw()
  return 9. if stage<len(stages) else None
 except Exception:
  (ROOT/'qa/yacht-blender-error.txt').write_text(traceback.format_exc(),encoding='utf-8');return None
bpy.app.timers.register(step,first_interval=4.)
