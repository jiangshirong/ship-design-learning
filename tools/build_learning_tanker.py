"""Visible, staged Blender modelling. Load into the interactive Blender session.

Coordinates: +X forward, +Y port, +Z up. Metres. L is between perpendiculars.
Homework supplies principal dimensions, not hull lines or compartment geometry.
"""
import bpy, math, json, bmesh
from mathutils import Vector
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
L,B,H,T=189.64,26.60,14.89,10.88
M={}; COL={}; STAGES=[]
def material(name,hexcol,metal=0.0,rough=.45):
    rgb=tuple(int(hexcol[i:i+2],16)/255 for i in (0,2,4))
    c=tuple(v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in rgb)
    mat=bpy.data.materials.new(name);mat.diffuse_color=(*c,1);mat.use_nodes=True
    p=mat.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1)
    p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough;M[name]=mat;return mat
def collection(name):
    if name not in COL:
        c=bpy.data.collections.new(name);bpy.context.scene.collection.children.link(c);COL[name]=c
    return COL[name]
def mesh(name,verts,faces,mat='steel',group='Hull',near=False,cover=False,smooth=False):
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update()
    bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=bm.faces);bm.to_mesh(me);bm.free()
    o=bpy.data.objects.new(name,me);collection(group).objects.link(o);o.data.materials.append(M[mat])
    o['zone']=group;o['near_side']=near;o['cutaway_hide']=cover;o['part_id']=name
    for p in me.polygons:p.use_smooth=smooth
    return o
def box(name,loc,dims,mat='steel',group='Equipment',near=False,cover=False,bevel=0):
    x,y,z=loc;a,b,c=[v/2 for v in dims]
    v=[(x+sx*a,y+sy*b,z+sz*c) for sx,sy,sz in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    o=mesh(name,v,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],mat,group,near,cover)
    if bevel:
        mod=o.modifiers.new('Soft fabricated edges','BEVEL');mod.width=bevel;mod.segments=2
    return o
def tube(name,pts,r=.12,mat='pipe',group='Piping',segments=10,near=False,cover=False):
    pts=[Vector(p) for p in pts];v=[];f=[]
    # Rounded elbows; bridge crossings keep independent cargo routes separate.
    if len(pts)>2 and group=='Piping':
        rounded=[pts[0]]
        for i in range(1,len(pts)-1):
            a,b,c=pts[i-1:i+2];u=(a-b).normalized();w=(c-b).normalized()
            if abs(u.dot(w))>.999:rounded.append(b);continue
            d=min(r*2.5,(a-b).length*.3,(c-b).length*.3)
            p=b+u*d;q=b+w*d
            for k in range(7):
                t=k/6;rounded.append((1-t)**2*p+2*(1-t)*t*b+t*t*q)
        pts=rounded+[pts[-1]]
    for i,p in enumerate(pts):
        tangent=(pts[min(i+1,len(pts)-1)]-pts[max(0,i-1)]).normalized()
        side=tangent.cross(Vector((0,0,1)))
        if side.length<.01:side=tangent.cross(Vector((0,1,0)))
        side.normalize();up=tangent.cross(side).normalized()
        for j in range(segments):v.append(p+r*(side*math.cos(j*math.tau/segments)+up*math.sin(j*math.tau/segments)))
    for i in range(len(pts)-1):
        for j in range(segments):a=i*segments+j;b=i*segments+(j+1)%segments;f.append((a,b,b+segments,a+segments))
    f.extend([tuple(range(segments-1,-1,-1)),tuple((len(pts)-1)*segments+j for j in range(segments))])
    return mesh(name,v,f,mat,group,near,cover,True)
def cyl(name,loc,r,depth,mat='steel',group='Equipment',axis=(0,0,1),segments=20,near=False,cover=False):
    d=Vector(axis).normalized()*depth/2;p=Vector(loc)
    return tube(name,[p-d,p+d],r,mat,group,segments,near,cover)
def ring(name,centre,r,tube_r,mat='valve',group='Piping',axis='Z'):
    x,y,z=centre;pts=[]
    for j in range(25):
        a=j*math.tau/24
        pts.append((x+r*math.cos(a),y+r*math.sin(a),z) if axis=='Z' else (x+r*math.cos(a),y,z+r*math.sin(a)))
    return tube(name,pts,tube_r,mat,group,6)
def ellipsoid(name,loc,scale,mat,group='Hull'):
    v=[];f=[]
    for i in range(17):
        a=-math.pi/2+i*math.pi/16
        for j in range(32):
            b=j*math.tau/32;v.append((loc[0]+scale[0]*math.cos(a)*math.cos(b),loc[1]+scale[1]*math.cos(a)*math.sin(b),loc[2]+scale[2]*math.sin(a)))
    for i in range(16):
        for j in range(32):a=i*32+j;b=i*32+(j+1)%32;f.append((a,b,b+32,a+32))
    return mesh(name,v,f,mat,group,smooth=True)
def width(x):
    stations=[(-98,.42),(-92,.66),(-80,.88),(-64,1),(-44,1),(40,1),(58,.93),(72,.78),(82,.55),(90,.27),(L/2,.012)]
    for (a,wa),(b,wb) in zip(stations,stations[1:]):
        if a<=x<=b:
            t=(x-a)/(b-a);t=t*t*(3-2*t);return B/2*(wa+(wb-wa)*t)
    return .1
def sheer(x):return 1.1*max(0,(x-53)/(L/2-53))**2+.45*max(0,(-x-68)/30)**2
def raked_x(x,z):return x+max(0,(x-75)/(L/2-75))**3*(z-T)*5.18/(H-T)
def show(stage,focus=(0,0,6),distance=220):
    STAGES.append(stage);bpy.context.workspace.name=stage
    bpy.context.view_layer.update()
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type=='VIEW_3D':
                s=area.spaces.active;s.shading.type='SOLID';s.shading.color_type='MATERIAL';s.shading.light='STUDIO';s.shading.studiolight_rotate_z=.4
                s.shading.show_shadows=True;s.shading.show_cavity=True;s.shading.cavity_type='BOTH'
                s.overlay.show_floor=False;s.overlay.show_axis_x=False;s.overlay.show_axis_y=False
                s.region_3d.view_distance=distance;s.region_3d.view_location=Vector(focus)
                s.region_3d.view_rotation=Vector((.5,-1,.65)).to_track_quat('Z','Y');s.region_3d.view_perspective='ORTHO'
                s.clip_end=3000;area.header_text_set(stage);area.tag_redraw()
    bpy.ops.object.select_all(action='DESELECT')
    return {'stage':stage,'objects':len(bpy.context.scene.objects),'dimensions':{'Lpp':L,'B':B,'H':H,'T':T}}
def stage1():
    # Called only in the newly launched untitled scene, after inventory inspection.
    for o in list(bpy.context.scene.objects):bpy.data.objects.remove(o,do_unlink=True)
    bpy.context.scene.unit_settings.system='METRIC';bpy.context.scene.unit_settings.scale_length=1
    for n,c,m,r in [('hull','183b4b',.15,.42),('bottom','a44236',.05,.6),('boot','27313a',.1,.4),('deck','577c78',.1,.6),('steel','a4b4b8',.4,.36),('pipe','d5ded7',.35,.3),('white','e7ebe6',.1,.38),('glass','173845',.35,.18),('yellow','e1ac36',.2,.4),('valve','ac4436',.25,.35),('orange','eb6824',.05,.4),('brass','b68d48',.75,.3),('tank','718f9b',.15,.55),('ballast','407b93',.1,.5),('black','182127',.1,.5)]:material(n,c,m,r)
    xs=[-98+(98+L/2)*i/100 for i in range(101)]
    # Rounded bilge with a broad flat bottom. The waterline is not deck breadth.
    profile=[(0,0),(.70,0),(.79,.01),(.86,.03),(.92,.065),(.967,.11),(1,.18),(1,.40),(1,10.2/H),(1,11.35/H),(1,.92),(1,1)]
    for sign,side in [(-1,'starboard'),(1,'port')]:
        v=[];f=[];indices=[]
        for x in xs:
            w=width(x);rise=6.2*max(0,(-x-66)/32)**2
            for y,zf in profile:
                z=rise+(H+sheer(x)-rise)*zf
                v.append((raked_x(x,z),sign*w*y,z))
        n=len(profile)
        for i in range(len(xs)-1):
            for j in range(n-1):
                a=i*n+j;face=(a,a+n,a+n+1,a+1);f.append(face)
                z=sum(v[k][2] for k in face)/4;indices.append(1 if z<10.2 else 2 if z<11.35 else 0)
        o=mesh('Hull_'+side,v,f,'hull','Hull',near=sign<0,smooth=True)
        o.data.materials.append(M['bottom']);o.data.materials.append(M['boot'])
        for p,idx in zip(o.data.polygons,indices):p.material_index=idx
        sol=o.modifiers.new('Shell plating','SOLIDIFY');sol.thickness=.035
    # Transom closure, aft body clearance and a submerged bulbous bow.
    x=-98;w=width(x);mesh('Transom',[(-98,-w,6.2),(-98,w,6.2),(-98,w,H+.45),(-98,-w,H+.45)],[(0,1,2,3)],'hull','Hull')
    ellipsoid('Bulbous_bow',(88.6,0,3.65),(8.5,2.75,2.9),'bottom')
    return show('01 船体 · 圆舭、艏艉与水下外形')
def stage2():
    # Six paired compartments, double bottom, side ballast and cofferdams.
    # The layout is a teaching choice, not data from the Т2 homework.
    edges=[-54,-34,-14,6,26,46,66]
    box('Inner_bottom', (6,0,2.15),(120,21.8,.18),'tank','DoubleBottom')
    for sign in [-1,1]:
        box('Side_ballast_boundary_'+str(sign),(6,sign*10.9,8.45),(120,.16,12.5),'ballast','Ballast',near=sign<0)
    box('Centreline_longitudinal_bulkhead',(6,0,8.5),(120,.14,12.6),'tank','Bulkheads')
    for i,x in enumerate(edges):
        box('Transverse_bulkhead_%02d'%i,(x,0,8.5),(.16,21.8,12.6),'tank','Bulkheads')
        for y in [-8,-4,0,4,8]:box('Bulkhead_stiffener_%02d_%s'%(i,y),(x+.16,y,8.5),(.30,.15,12.6),'steel','Frames')
    for i,(a,b) in enumerate(zip(edges,edges[1:])):
        for side,sign in [('P',1),('S',-1)]:
            empty=bpy.data.objects.new('CargoTank_%02d%s'%(i+1,side),None);collection('TankReferences').objects.link(empty)
            empty.location=((a+b)/2,sign*5.45,8.5);empty.empty_display_type='CUBE';empty.empty_display_size=1
            empty['part_id']='cargo_tank_%02d_%s'%(i+1,side);empty['purpose']='liquid cargo';empty['layout_status']='teaching arrangement, not homework geometry'
            cyl('Suction_well_%02d%s'%(i,side),((a+b)/2,sign*6,2.7),.45,.5,'steel','Pumps')
            tube('Pump_column_%02d%s'%(i,side),[((a+b)/2,sign*6,2.45),((a+b)/2,sign*6,H+.8)],.22,'steel','Pumps')
    for x in [-58,70]:box('Cofferdam_'+str(x),(x,0,8.4),(.18,20,12.4),'yellow','Bulkheads')
    for x in range(-52,66,4):
        box('Double_bottom_floor_'+str(x),(x,0,1.1),(.16,21.6,1.9),'steel','DoubleBottom')
    for y in [-8,-4,0,4,8]:box('Bottom_girder_'+str(y),(6,y,1.1),(120,.14,1.9),'steel','DoubleBottom')
    # Visible cutaway during this construction stage.
    for o in COL['Hull'].objects:
        if o.get('near_side'):o.hide_set(True)
    return show('02 舱室 · 双层底、边舱与十二个液货舱',distance=210)
def deck_panel(name,xs,group='Decks',mat='deck',height=0):
    v=[];f=[]
    for x in xs:
        for y in [-width(x),width(x)]:v.append((raked_x(x,H+sheer(x)),y,H+sheer(x)+height))
    for i in range(len(xs)-1):a=i*2;f.append((a,a+2,a+3,a+1))
    o=mesh(name,v,f,mat,group,cover=True)
    sol=o.modifiers.new('Deck plating','SOLIDIFY');sol.thickness=.08;return o
def stage3():
    for o in COL['Hull'].objects:o.hide_set(False)
    deck_panel('Continuous_main_deck',[-98+(98+L/2)*i/100 for i in range(101)])
    # Aft accommodation; four storeys, forward-facing wheelhouse and bridge wings.
    for floor in range(4):
        z=H+1.55+floor*3.15;x=-77.5-floor*.55;dx=21-floor*1.0;dy=18-floor*.6
        box('Accommodation_level_%d'%floor,(x,0,z),(dx,dy,3.05),'white','Accommodation',bevel=.12)
        box('Accommodation_deck_%d'%floor,(x,0,z+1.54),(dx+1,dy+1,.18),'deck','Accommodation')
        for sign in [-1,1]:
            for j in range(6):box('Cabin_window_%d_%d_%d'%(floor,sign,j),(x-dx/2+2+j*(dx-4)/5,sign*(dy/2+.015),z+.25),(1.15,.05,.95),'glass','Windows',bevel=.04)
        for j in range(5):box('Front_window_%d_%d'%(floor,j),(x+dx/2+.02,-6+3*j,z+.25),(.04,1.5,.95),'glass','Windows')
    bridge_z=H+14.2
    box('Wheelhouse',(-79,0,bridge_z),(14.5,20.8,2.7),'white','Accommodation',bevel=.15)
    box('Bridge_roof',(-79,0,bridge_z+1.47),(15.5,22.1,.22),'white','Accommodation')
    for j in range(9):box('Bridge_front_glazing_%02d'%j,(-71.72,-9.2+j*2.3,bridge_z+.25),(.06,1.9,1.35),'glass','Windows')
    for sign in [-1,1]:
        box('Bridge_wing_'+str(sign),(-74,sign*11.7,bridge_z-1.2),(7.2,4.4,.30),'deck','Accommodation')
        for j in range(4):box('Bridge_side_glazing_%s_%d'%(sign,j),(-84+j*3,sign*10.42,bridge_z+.25),(2.4,.06,1.35),'glass','Windows')
    box('Funnel',(-85,0,H+17.4),(4.5,5.7,5.0),'hull','Funnel',bevel=.45)
    box('Funnel_cap',(-85,0,H+20),(4.7,5.9,.5),'black','Funnel',bevel=.2)
    for y in [-1.5,0,1.5]:cyl('Exhaust_'+str(y),(-85,y,H+20.7),.48,1.3,'black','Funnel')
    # Raised forecastle platform, supported by a bulkhead.
    deck_panel('Forecastle_deck',[79+(L/2-79)*i/20 for i in range(21)],height=2.45)
    box('Forecastle_aft_bulkhead',(79,0,H+2.1),(.18,2*width(79),3.1),'hull','Forecastle')
    return show('03 甲板与上层建筑 · 连续液货甲板和艉部驾驶台')
def valve(name,loc):
    x,y,z=loc;cyl(name+'_body',(x,y,z),.28,.5,'steel','Piping',axis=(0,1,0),segments=12)
    cyl(name+'_stem',(x,y,z+.35),.055,.6,'steel','Piping',segments=8)
    ring(name+'_wheel',(x,y,z+.68),.27,.045)
    tube(name+'_spoke',[(x-.27,y,z+.68),(x+.27,y,z+.68)],.025,'valve',segments=6)
def stage4():
    tank_x=[-44,-24,-4,16,36,56]
    for i,x in enumerate(tank_x):
        for side,sgn in [('S',-1),('P',1)]:
            y=sgn*6;lane=sgn*(.55+i*.43);z=H+.65
            cyl('Tank_dome_%d%s'%(i,side),(x,y,H+.22),.85,.40,'white','TankAccess',cover=True)
            cyl('Pump_motor_%d%s'%(i,side),(x,y,H+1.05),.35,.65,'hull','Pumps',segments=16)
            cyl('Access_hatch_%d%s'%(i,side),(x+3,y,H+.18),.62,.3,'steel','TankAccess',cover=True)
            ring('Hatch_rim_%d%s'%(i,side),(x+3,y,H+.34),.58,.04,'white','TankAccess')
            # Each tank has a separate deck route into its corresponding manifold.
            mx=-1.5+i*.75
            tube('Cargo_line_%d%s'%(i,side),[(x,y,z),(x,sgn*4.5,z),(x,sgn*4.5,H+1.45),(x,lane,H+1.45),(x,lane,z),(mx,lane,z),(mx,lane,H+1.45),(mx,sgn*5,H+1.45),(mx,sgn*5,z),(mx,sgn*10.8,z)],.145,'pipe','Piping',12)
            cyl('Manifold_flange_%d%s'%(i,side),(mx,sgn*10.85,z),.29,.16,'steel','Manifold',axis=(0,1,0),segments=20)
            cyl('Manifold_blank_%d%s'%(i,side),(mx,sgn*10.96,z),.23,.08,'yellow','Manifold',axis=(0,1,0),segments=20)
            for j in range(8):
                a=j*math.tau/8
                cyl('Flange_bolt_%d%s_%d'%(i,side,j),(mx+.245*math.cos(a),sgn*10.98,z+.245*math.sin(a)),.035,.12,'black','Manifold',axis=(0,1,0),segments=6)
            valve('Cargo_valve_%d%s'%(i,side),(mx,sgn*8.8,z))
            # Tank vent/pressure-vacuum head, separated from access opening.
            vx=x+5.5;vy=sgn*8.7
            tube('Tank_vent_%d%s'%(i,side),[(vx,vy,H),(vx,vy,H+3.0)],.12,'pipe','Vents',10)
            cyl('PV_head_%d%s'%(i,side),(vx,vy,H+3.1),.26,.28,'steel','Vents',segments=16)
    for sign in [-1,1]:
        box('Manifold_spill_tray_'+str(sign),(.35,sign*9.3,H+.16),(6.5,4.4,.12),'hull','Manifold')
        for x in [-2.9,3.6]:box('Tray_end_'+str(sign)+str(x),(x,sign*9.3,H+.34),(.1,4.4,.35),'yellow','Manifold')
        for y in [sign*7.1,sign*11.5]:box('Tray_side_'+str(y),(.35,y,H+.34),(6.5,.1,.35),'yellow','Manifold')
    for x in range(-52,67,5):
        box('Pipe_rack_'+str(x),(x,0,H+.22),(.20,6,.40),'steel','PipeSupports')
    # Raised clear passage alongside the pipe rack; deck markings along both sides.
    box('Raised_walkway',(5,3.7,H+2.1),(120,1.2,.12),'steel','Walkway',cover=True)
    for x in range(-53,65,6):box('Walkway_leg_'+str(x),(x,3.7,H+1.05),(.12,1,2.1),'steel','Walkway')
    for y in [-10.0,10.0]:box('Deck_access_lane_'+str(y),(2,y,H+.06),(112,.65,.025),'yellow','Markings',cover=True)
    # Small hose-handling cranes, not dry-cargo cranes.
    for sgn in [-1,1]:
        x=7;y=sgn*8.0
        cyl('Hose_crane_pedestal_'+str(sgn),(x,y,H+1.1),.65,2.2,'white','HoseCranes')
        tube('Hose_crane_boom_'+str(sgn),[(x,y,H+2),(x+2,y,H+5.6),(x-3,y,H+5.8)],.28,'yellow','HoseCranes',12)
        tube('Hose_crane_wire_'+str(sgn),[(x-3,y,H+5.8),(x-3,y,H+1.7)],.025,'black','HoseCranes',6)
    return show('04 液货系统 · 独立管路、阀门、通气与舷侧装卸接口')
def rail(name,pts,group='Railings',height=1.05):
    for z in [.5,height]:tube(name+'_rail'+str(z),[(x,y,h+z) for x,y,h in pts],.035,'white',group,6)
    for i,p in enumerate(pts):tube(name+'_post%03d'%i,[p,(p[0],p[1],p[2]+height)],.045,'white',group,6)
def stairs(name,x,y,z,rise=3.15,run=4.2):
    for i in range(13):box(name+'_tread%02d'%i,(x+run*i/12,y,z+rise*i/12),(.38,1.2,.09),'steel','Stairs')
    for sign in [-1,1]:
        tube(name+'_stringer'+str(sign),[(x,y+sign*.55,z-.1),(x+run,y+sign*.55,z+rise-.1)],.09,'steel','Stairs',6)
        rail(name+'_hand'+str(sign),[(x,y+sign*.58,z),(x+run/2,y+sign*.58,z+rise/2),(x+run,y+sign*.58,z+rise)],'Stairs')
def stage5():
    for sign in [-1,1]:
        pts=[]
        for i in range(78):
            x=-96+174*i/77;z=H+sheer(x);pts.append((raked_x(x,z),sign*(width(x)-.18),z))
        rail('Side_'+str(sign),pts)
        pts=[]
        for i in range(10):
            x=79+(L/2-79)*i/9;z=H+sheer(x)+2.45;pts.append((raked_x(x,H+sheer(x)),sign*max(.1,width(x)-.18),z))
        rail('Forecastle_'+str(sign),pts)
        stairs('Forecastle_stair_'+str(sign),74,sign*7.8,H+.3,2.45,4.8)
        # Twin bollards, fairleads, and mooring winches at each end.
        for x,z in [(-93,H+.4),(83,H+3.0)]:
            y=sign*(width(x)*.62)
            box('Winch_bed_%s_%s'%(x,sign),(x,y,z+.2),(3.5,2.2,.4),'hull','Mooring')
            cyl('Winch_drum_%s_%s'%(x,sign),(x,y,z+1.0),.7,1.7,'steel','Mooring',axis=(0,1,0),segments=20)
            for dy in [-.9,.9]:cyl('Winch_flange_%s_%s_%s'%(x,sign,dy),(x,y+dy,z+1.0),.88,.12,'hull','Mooring',axis=(0,1,0))
            for dx in [-.5,.5]:cyl('Bollard_%s_%s_%s'%(x,sign,dx),(x+4+dx,y,z+.55),.22,1.0,'black','Mooring')
            tube('Mooring_line_%s_%s'%(x,sign),[(x,y,z+1.0),(x+4,y,z+.5),(x+5,sign*(width(x)-.2),z+.4)],.055,'yellow','Mooring',6)
        # Anchor pocket and stockless anchor shank at bow.
        ax=87;ay=sign*(width(ax)+.03)
        box('Anchor_pocket_'+str(sign),(ax,ay,H-1.0),(2.3,.20,2.3),'black','Anchors',bevel=.15)
        tube('Anchor_shank_'+str(sign),[(ax,ay,H-1.0),(ax-.4,ay,H-3.0)],.16,'steel','Anchors',10)
        tube('Anchor_arms_'+str(sign),[(ax-1.2,ay,H-2.4),(ax-.4,ay,H-3.0),(ax+.5,ay,H-2.4)],.20,'steel','Anchors',10)
    for floor in range(3):stairs('Accommodation_stair_%d'%floor,-84,-9.45+floor*.3,H+3.15*floor)
    for floor in range(4):
        x=-77.5-floor*.55;dx=21-floor;dy=18-floor*.6;z=H+3.15*(floor+1)
        rail('Accommodation_guard_%d'%floor,[(x-dx/2-.4,-dy/2-.4,z),(x+dx/2+.4,-dy/2-.4,z),(x+dx/2+.4,dy/2+.4,z),(x-dx/2-.4,dy/2+.4,z)])
    for y in [3.12,4.28]:rail('Walkway_guard_'+str(y),[(x,y,H+2.16) for x in range(-53,66,4)],'Walkway')
    stairs('Walkway_access',-59.2,3.7,H,2.1,4.2)
    # Two enclosed survival craft on davits aft, plus life rafts.
    for sgn in [-1,1]:
        boat=ellipsoid('Enclosed_lifeboat_'+str(sgn),(-70,sgn*11.2,H+3.0),(4.8,1.35,1.5),'orange','Survival')
        box('Lifeboat_windows_'+str(sgn),(-69.4,sgn*12.45,H+3.5),(2.8,.08,.65),'glass','Survival',bevel=.12)
        for dx in [-3,3]:
            tube('Davit_%s_%s'%(sgn,dx),[(-70+dx,sgn*8.8,H),(-70+dx,sgn*9.3,H+5.5),(-70+dx,sgn*11.2,H+5.5)],.16,'white','Survival',10)
            tube('Lifeboat_fall_%s_%s'%(sgn,dx),[(-70+dx,sgn*11.2,H+5.5),(-70+dx,sgn*11.2,H+3.8)],.025,'black','Survival',6)
        for x in [-82,-78]:cyl('Life_raft_%s_%s'%(sgn,x),(x,sgn*10,H+4.0),.55,1.5,'white','Survival',axis=(1,0,0))
    # Navigation mast, radar scanners, aerials and running lights.
    tube('Main_mast',[(-77,0,H+15.8),(-77,0,H+24.5)],.18,'white','Navigation',12)
    for z,w in [(H+21,5),(H+24,3)]:tube('Radar_scanner_'+str(z),[(-77,-w/2,z),(-77,w/2,z)],.13,'white','Navigation',8)
    for y in [-4,4]:tube('Radio_aerial_'+str(y),[(-79,y,H+15.8),(-79,y,H+20)],.035,'white','Navigation',6)
    tube('Fore_mast',[(85,0,H+3.2),(85,0,H+11)],.16,'white','Navigation',12)
    tube('Fore_crossbar',[(85,-2,H+9),(85,2,H+9)],.09,'white','Navigation',8)
    # Propeller shaft, four pitched blades, rudder aft of propeller.
    cyl('Propeller_shaft',(-91,0,3.6),.38,10,'steel','Propulsion',axis=(1,0,0))
    cyl('Propeller_hub',(-94.8,0,3.6),.75,1.4,'brass','Propulsion',axis=(1,0,0))
    for j in range(4):
        a=j*math.tau/4;v=[]
        for radius,angle,offset in [(.55,-.23,-.3),(1.9,-.30,-.4),(3.25,.10,-.2),(3.4,.40,.2),(2.5,.65,.38),(.75,.45,.25)]:v.append((-94.8+offset,radius*math.sin(a+angle),3.6+radius*math.cos(a+angle)))
        o=mesh('Propeller_blade_%d'%j,v,[tuple(range(6))],'brass','Propulsion',smooth=True);m=o.modifiers.new('Blade thickness','SOLIDIFY');m.thickness=.12
    box('Rudder',(-97.4,0,3.7),(3.1,.42,6.6),'bottom','Propulsion',bevel=.3)
    # Bilge keels follow the parallel middle body.
    for s in [-1,1]:box('Bilge_keel_'+str(s),(-2,s*12.0,1.4),(92,.6,.13),'bottom','Hull')
    return show('05 细节 · 栏杆、梯道、系泊、救生和推进装置')

def stage6():
    # Raise the stern run to leave an actual propeller aperture. Keep the deck fixed.
    for name in ['Hull_port','Hull_starboard']:
        o=bpy.data.objects[name]
        for v in o.data.vertices:
            x=v.co.x
            if x < -66:
                u=max(0,(-x-66)/32)**2;old=6.2*u;new=11.0*u;top=H+sheer(x)
                v.co.z=new+(v.co.z-old)*(top-new)/(top-old)
        o.data.update()
    for v in bpy.data.objects['Transom'].data.vertices:
        if v.co.z<7:v.co.z=11.0
    cyl('Rudder_stock',(-97.4,0,8.7),.24,4,'steel','Propulsion')
    # Aft perpendicular is the rudder-stock axis, not the extremity of the stern.
    for o in COL['Propulsion'].objects:
        for v in o.data.vertices:v.co.x+=97.4-L/2
    # Forecastle side shell closes the space below the raised deck.
    for sign in [-1,1]:
        v=[];f=[]
        for i in range(31):
            x=79+(L/2-79)*i/30;z=H+sheer(x);xx=raked_x(x,z);y=sign*width(x)
            v.extend([(xx,y,z),(xx,y,z+2.45)])
        for i in range(30):f.append((i*2,i*2+2,i*2+3,i*2+1))
        o=mesh('Forecastle_shell_'+str(sign),v,f,'hull','Hull',near=sign<0,smooth=True)
        o.modifiers.new('Forecastle plating','SOLIDIFY').thickness=.06
    # Shaft line continues to the engine, entirely aft of the cargo cofferdam.
    cyl('Intermediate_shaft',(-82,0,3.6),.34,10,'steel','Machinery',axis=(1,0,0))
    box('Main_engine_foundation',(-73,0,2.4),(12,4.3,1.2),'steel','Machinery',bevel=.12)
    box('Diesel_crankcase',(-73,0,4.1),(10.8,3.5,2.3),'hull','Machinery',bevel=.18)
    for i in range(6):
        x=-77.3+i*1.7
        box('Engine_cylinder_'+str(i),(x,0,6.1),(1.4,2.6,2),'steel','Machinery',bevel=.12)
        cyl('Engine_head_'+str(i),(x,0,7.2),.65,.3,'hull','Machinery')
        tube('Exhaust_branch_'+str(i),[(x,0,7.2),(x,1.8,7.6)],.17,'steel','Machinery')
    tube('Engine_exhaust_collector',[(-78,1.8,7.6),(-68,1.8,7.6)],.35,'steel','Machinery')
    tube('Uptake_to_funnel',[(-78,1.8,7.6),(-85,1.8,7.6),(-85,1.8,H+18)],.4,'steel','Machinery')
    for y in [-6,6]:
        box('Generator_bed_'+str(y),(-72,y,3.1),(6,2.5,.5),'steel','Machinery')
        box('Generator_engine_'+str(y),(-72.8,y,4.1),(3.8,1.8,1.6),'hull','Machinery',bevel=.1)
        cyl('Alternator_'+str(y),(-70,y,4.1),.85,1.5,'steel','Machinery',axis=(1,0,0))
    # Deck fire main and hydrants are distinct from the cargo system.
    tube('Fire_main',[(-61,-11.3,H+.25),(62,-11.3,H+.25)],.075,'valve','FireSystem',10)
    for x in [-55,-30,-5,20,45,62]:
        tube('Fire_hydrant_'+str(x),[(x,-11.3,H+.25),(x,-11.3,H+.9),(x,-11,H+.9)],.075,'valve','FireSystem',10)
        box('Fire_hose_locker_'+str(x),(x+.8,-11.6,H+.75),(.6,.4,.9),'valve','FireSystem',bevel=.04)
    for sign in [-1,1]:
        rail('Bridge_wing_guard_'+str(sign),[(-77.6,sign*10.5,H+13.15),(-77.6,sign*13.9,H+13.15),(-70.4,sign*13.9,H+13.15),(-70.4,sign*10.5,H+13.15)],'Railings')
        # Liferafts rest on visible cradles attached to the deck.
        for x in [-82,-78]:
            box('Raft_platform_%s_%s'%(x,sign),(x,sign*9.7,H+3.2),(2.1,1.8,.15),'steel','Survival')
            for dx in [-.6,.6]:tube('Raft_cradle_%s_%s_%s'%(x,sign,dx),[(x+dx,sign*9.65,H+3.25),(x+dx,sign*10,H+3.65)],.08,'steel','Survival')
    return show('06 校核细节 · 艉部间隙、机舱与消防系统',distance=215)

def fit_bottom_floors():
    # Floors taper with the rounded bilge instead of rectangular corners protruding.
    for o in COL['DoubleBottom'].objects:
        if not o.name.startswith('Double_bottom_floor_'):continue
        x=float(o.name.removeprefix('Double_bottom_floor_'));w0=width(x)*.75;w1=min(10.8,width(x)*.95)
        vertices=[(xx,y,z) for xx in [x-.08,x+.08] for y,z in [(-w0,.15),(w0,.15),(w1,2.05),(-w1,2.05)]]
        me=bpy.data.meshes.new(o.name+'_fitted');me.from_pydata(vertices,[],[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]);me.materials.append(M['steel']);o.data=me

def presentation():
    fit_bottom_floors()
    # Close the stem and match the transom to the actual section outline.
    p=bpy.data.objects['Hull_port'];q=bpy.data.objects['Hull_starboard']
    for label,offset in [('Stem',1200),('Transom',0)]:
        verts=[tuple(v.co) for v in p.data.vertices[offset:offset+12]]
        verts+=list(reversed([tuple(v.co) for v in q.data.vertices[offset:offset+12]]))
        if label=='Transom':
            o=bpy.data.objects['Transom'];me=bpy.data.meshes.new('Transom_section');me.from_pydata(verts,[],[tuple(range(24))]);me.materials.append(M['hull']);o.data=me
        else:mesh(label,verts,[tuple(range(24))],'hull','Hull')
    scene=bpy.context.scene
    camdata=bpy.data.cameras.new('Model_overview');cam=bpy.data.objects.new('Model_overview',camdata);collection('Presentation').objects.link(cam)
    cam.location=(105,-200,150);target=Vector((0,0,11));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();camdata.type='ORTHO';camdata.ortho_scale=222;camdata.clip_end=2000;scene.camera=cam
    scene.render.engine='BLENDER_WORKBENCH';scene.render.resolution_x=1800;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
    scene.display.shading.light='STUDIO';scene.display.shading.color_type='MATERIAL';scene.display.shading.show_shadows=True;scene.display.shading.show_cavity=True;scene.display.shading.cavity_type='BOTH'
    scene.display.shading.background_type='WORLD';scene.world.color=(.055,.075,.095)
    scene.render.image_settings.file_format='PNG';scene.render.filepath=str(ROOT/'models/液货船学习模型-总览.png')
    # Named interior view layer keeps hull/deck editing reversible.
    main=bpy.context.view_layer;main.name='完整船舶'
    inside=scene.view_layers.new('液货舱与机舱');inside.use=False
    for o in scene.objects:
        if o.get('near_side') or o.get('cutaway_hide'):o.hide_set(True,view_layer=inside)
    return {'camera':cam.name,'view_layers':[v.name for v in scene.view_layers]}

def finalize():
    scene=bpy.context.scene
    # Reference-only objects are retained in the editable source, excluded from GLB.
    ref=collection('References')
    for name,pos in [('AP',(-L/2,0,0)),('FP',(L/2,0,0)),('BASELINE',(0,0,0)),('DESIGN_WATERLINE',(0,0,T))]:
        o=bpy.data.objects.get(name)
        if o is None:o=bpy.data.objects.new(name,None);ref.objects.link(o)
        o.location=pos;o.empty_display_size=2;o['not_exported']=True
    scene['model_type']='Conventional double-hull liquid-bulk teaching vessel'
    scene['homework_reference']='Т2: Lpp=189.64 m, B=26.60 m, H=14.89 m, T=10.88 m'
    scene['geometry_boundary']='Hull lines, compartment count and equipment arrangement are authored teaching geometry. No hydrostatic integration or class approval is implied.'
    # Save a source with each editable part intact. Export uses a temporary scene.
    show('液货船学习模型 · 完整模型',distance=225)
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'models/液货船学习模型.blend'))
    export_scene=bpy.data.scenes.new('GLB_export');objects=[];groups={}
    deps=bpy.context.evaluated_depsgraph_get()
    for o in list(scene.objects):
        if o.type!='MESH':continue
        data=bpy.data.meshes.new_from_object(o.evaluated_get(deps),depsgraph=deps)
        n=bpy.data.objects.new(o.name,data);export_scene.collection.objects.link(n);n.matrix_world=o.matrix_world.copy()
        key=(o['zone'],bool(o.get('near_side')),bool(o.get('cutaway_hide')))
        groups.setdefault(key,[]).append(n);objects.append(n)
    window=bpy.context.window;window.scene=export_scene
    for (zone,near,cover),items in groups.items():
        bpy.ops.object.select_all(action='DESELECT')
        for o in items:o.select_set(True)
        bpy.context.view_layer.objects.active=items[0]
        if len(items)>1:bpy.ops.object.join()
        o=items[0]
        o.name=f'{zone}_{"near" if near else "far"}_{"cover" if cover else "structure"}'
        o['zone']=zone;o['near_side']=near;o['cutaway_hide']=cover
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/tanker_learning.glb'),export_format='GLB',use_active_scene=True,export_extras=True,export_cameras=False,export_lights=False)
    export_stats={'mesh_groups':len(export_scene.objects),'triangles':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in export_scene.objects if o.type=='MESH')}
    window.scene=scene;bpy.data.scenes.remove(export_scene)
    report={'version':2,'created_in':bpy.app.version_string,'source':'models/液货船学习模型.blend','asset':'assets/tanker_learning.glb','reference_dimensions_m':{'length_between_perpendiculars':L,'beam':B,'main_deck':H,'draft':T},'objects':len(scene.objects),'export':export_stats,'stages':STAGES,'cargo_tanks':12,'coordinates':'Blender +X forward, +Y port, +Z up; Godot +X forward, +Y up, -Z port','source_facts':'Т2 adopted principal dimensions only','teaching_choices':['double hull','six pairs of integral liquid cargo tanks','independent tank piping and amidships manifolds','aft machinery and accommodation','conventional ambient-temperature liquid cargo; no specific cargo certification'],'boundary':scene['geometry_boundary'],'references':['https://www.wartsila.com/encyclopedia/term/tankers','https://www.wartsila.com/encyclopedia/term/cargo-manifold','https://www.damen.com/vessels/cargo/combi-tankers/combi-tanker-8800']}
    (ROOT/'assets/tanker-learning-provenance.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),'utf8')
    return report
