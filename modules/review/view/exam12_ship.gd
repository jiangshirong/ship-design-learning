extends "res://modules/review/view/module11_ship.gd"
const Calc=preload("res://modules/review/core/exam12_math.gd")
var exam_ink:Control
var structures:Node3D
var cargo:Node3D
var rooms:Node3D
var machinery:Node3D
var liquids:Array=[]
var room_panels:Array=[]
var room_materials:Array=[]
var chairs:Array=[]
var cargo_items:Array=[]
var bulkhead_nodes:Array=[]
var frame_nodes:Array=[]
var near_structure:Array=[]
var capacity_demo:Node3D
var shaft_part:MeshInstance3D
var centre_marker:MeshInstance3D
var clip_shader:Shader
var calculation:Dictionary={}
var elapsed:=0.0
var room_target:=Vector3(-68,18,0)
var material_cache:Dictionary={}
func material(hex:String)->StandardMaterial3D:
 if material_cache.has(hex):return material_cache[hex]
 var m:=StandardMaterial3D.new();m.albedo_color=Color(hex);m.roughness=.65;m.metallic=.12
 if m.albedo_color.a<1.:m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 material_cache[hex]=m;return m
func box(parent:Node3D,at:Vector3,extent:Vector3,hex:String)->MeshInstance3D:
 var node:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=extent;node.mesh=mesh;node.material_override=material(hex);parent.add_child(node);node.position=at;return node
func tube(parent:Node3D,at:Vector3,radius:float,height:float,hex:String)->MeshInstance3D:
 var n:=MeshInstance3D.new();var mesh:=CylinderMesh.new();mesh.top_radius=radius;mesh.bottom_radius=radius;mesh.height=height;mesh.radial_segments=20;n.mesh=mesh;n.material_override=material(hex);parent.add_child(n);n.position=at;return n
func _ready()->void:
 super._ready();ink.hide()
 clip_shader=Shader.new();clip_shader.code=cuts.materials[0].shader.code.replace("uniform bool m11_stern", "uniform float exam_cut=0.;\nuniform bool room_cut=false;\nuniform float depth_rise=0.;\nuniform bool m11_stern").replace("float rise=deck_rise", "float rise=depth_rise*smoothstep(10.88,14.7,p.y)+deck_rise").replace("bool window=cut", "if(exam_cut>0.001 && abs(p.x)<75.0 && ((p.z<0.0 && p.y>1.3) || p.y>14.5))discard;\n if(room_cut && p.x< -50.0 && p.y>16.1)discard;\n bool window=cut")
 clip_shader.code=clip_shader.code.replace("uniform float depth_rise", "uniform float lcb_shift=0.;\nuniform float depth_rise").replace("float rise=depth_rise", "VERTEX+=(inverse(mat3(to_ship))*vec3(0.,0.,p.z*lcb_shift*p.x/95.*0.18));\n float rise=depth_rise")
 clip_shader.code=clip_shader.code.replace("uniform float lcb_shift", "uniform bool drawing=false;\nuniform float lcb_norm=1.;\nuniform bool reserve_light=false;\nuniform float lcb_shift").replace("p.z*lcb_shift*p.x/95.*0.18", "p.z*((1.+lcb_shift*p.x/95.*0.18)*lcb_norm-1.)").replace("float rise=depth_rise", "if(drawing){float nx=p.x< -49.79?mix(-75.,-15.,(p.x+98.)/48.21):(p.x<30.55?mix(-15.,22.5,(p.x+49.79)/80.34):mix(22.5,75.,(p.x-30.55)/70.871));VERTEX+=inverse(mat3(to_ship))*vec3(nx-p.x,0.,0.); }\n float rise=depth_rise").replace("if(lesson_highlight ||", "if((reserve_light && p.y>10.88 && p.y<14.89) || lesson_highlight ||")
 for m in cuts.materials:m.shader=clip_shader
 structures=Node3D.new();bodies[0].add_child(structures)
 # Authored outer shell remains visible; actual steel floors, web frames and walls are exposed.
 box(structures,Vector3(0,1.25,0),Vector3(139,.22,23.6),"78858a")
 for z in [-11.8,11.8]:
  var wall:=box(structures,Vector3(0,7.9,z),Vector3(139,13.2,.18),"8c999a")
  if z<0:near_structure.append(wall)
 for x in range(-66,70,6):
  var f:=Node3D.new();structures.add_child(f);frame_nodes.append(f)
  for z in [-11.5,11.5]:
   var frame:=box(f,Vector3(x,7.8,z),Vector3(.24,13.2,.45),"58696d")
   if z<0:near_structure.append(frame)
  box(f,Vector3(x,1.6,0),Vector3(.24,.4,23),"58696d")
 for x in [-52.,-28.,-4.,20.,44.,68.]:
  bulkhead_nodes.append(box(structures,Vector3(x,7.9,0),Vector3(.18,13.2,23.6),"9da8a6"))
 for x in [-40.,-16.,8.,32.,56.]:
  var l:=box(structures,Vector3(x,1.8,5.9),Vector3(23,.1,11.4),"305c81b0");liquids.append(l)
 capacity_demo=Node3D.new();bodies[0].add_child(capacity_demo)
 for y in [-2.,2.]:box(capacity_demo,Vector3(0,y,0),Vector3(10,.12,6),"a6b1a9")
 for x in [-5.,5.]:box(capacity_demo,Vector3(x,0,0),Vector3(.12,4,6),"a6b1a9")
 box(capacity_demo,Vector3(0,0,3),Vector3(10,4,.12),"a6b1a9")
 cargo=Node3D.new();bodies[0].add_child(cargo)
 for i in 6:
  var crate:=Node3D.new();cargo.add_child(crate);cargo_items.append(crate)
  box(crate,Vector3.ZERO,Vector3(4,2.6,3),"b08a53")
  for x in [-1.85,0.,1.85]:box(crate,Vector3(x,0,0),Vector3(.16,2.72,3.1),"6b5136")
  for y in [-1.2,1.2]:box(crate,Vector3(0,y,0),Vector3(4.12,.15,3.12),"6b5136")
 centre_marker=tube(bodies[0],Vector3.ZERO,.5,.12,"fff5c4")
 rooms=Node3D.new();bodies[0].add_child(rooms)
 box(rooms,Vector3(-68,16,0),Vector3(29,.2,22),"919c91")
 # Full small-room layout with a longitudinal central corridor and door openings.
 for z in [-10.8,10.8]:box(rooms,Vector3(-68,17.4,z),Vector3(29,2.8,.12),"a6b1a9")
 for x in [-82.5,-74.,-64.,-53.5]:
  for z in [-6.1,6.1]:box(rooms,Vector3(x,17.4,z),Vector3(.12,2.8,9.4),"a6b1a9")
 for x in [-78.,-69.,-59.]:
  for z in [-1.4,1.4]:
   box(rooms,Vector3(x-2.3,17.4,z),Vector3(3.1,2.8,.12),"a6b1a9")
   box(rooms,Vector3(x+2.3,17.4,z),Vector3(3.1,2.8,.12),"a6b1a9")
   box(rooms,Vector3(x,18.55,z),Vector3(1.6,.5,.12),"a6b1a9")
 # Twelve real seats around three dining tables.
 for tx in [-72.,-69.,-66.]:
  box(rooms,Vector3(tx,16.85,-6.5),Vector3(2.1,.12,3.2),"aa8054")
  for ox in [-.8,.8]:
   for oz in [-1.3,1.3]:tube(rooms,Vector3(tx+ox,16.4,-6.5+oz),.055,.8,"697476")
  for cz in [-8.7,-4.3]:
   for cx in [tx-.6,tx+.6]:
    var chair:=Node3D.new();rooms.add_child(chair);chairs.append(chair)
    box(chair,Vector3(cx,16.5,cz),Vector3(.72,.14,.72),"647f7c")
    box(chair,Vector3(cx,16.95,cz+(.33 if cz< -6 else -.33)),Vector3(.72,.9,.10),"647f7c")
    for dx in [-.26,.26]:
     for dz in [-.26,.26]:tube(chair,Vector3(cx+dx,16.22,cz+dz),.04,.44,"697476")
 # Galley: worktop, sink, stove, ventilation hood, food-store racks; sanitary fixtures separate.
 box(rooms,Vector3(-59,16.48,-9.8),Vector3(8,.96,1.4),"a1afb0")
 for x in [-61.,-58.]:
  for z in [-10.,-9.5]:tube(rooms,Vector3(x,17,-9.5 if z== -9.5 else -10),.22,.04,"353d3c")
 box(rooms,Vector3(-60,18.15,-9.5),Vector3(4,.22,1.8),"a8afb0")
 for x in [-81.,-75.]:
  for y in [16.5,17.2,17.9]:
   box(rooms,Vector3(x,y,-7),Vector3(1.1,.12,6),"718080")
   for z in [-9.,-7.,-5.]:box(rooms,Vector3(x,y+.28,z),Vector3(.65,.45,.7),"bd9564")
 for x in [-80.,-77.5]:
  tube(rooms,Vector3(x,16.35,8.8),.38,.6,"e4e3dc");box(rooms,Vector3(x,16.8,9.1),Vector3(.7,.75,.3),"e4e3dc")
 for x in [-70.,-66.]:
  box(rooms,Vector3(x,16.35,7),Vector3(1.8,.5,3.5),"6c7c82");box(rooms,Vector3(x,16.68,7),Vector3(1.7,.2,3.4),"efebe0");box(rooms,Vector3(x,16.85,8.1),Vector3(1.5,.18,.65),"f6f4ef")
 for fixture in rooms.find_children("*","MeshInstance3D",true,false):
  var m:StandardMaterial3D=fixture.material_override.duplicate();fixture.material_override=m
  var p:Vector3=fixture.position
  var zone:String=("food" if p.x< -74 else ("mess" if p.x< -64 else "galley")) if p.z< -2 else ("sanitary" if p.x< -74 else "rest")
  room_materials.append({"material":m,"zone":zone,"inside":absf(p.z)>2 and absf(p.z)<10.6 and p.y<18.4})
 machinery=Node3D.new();bodies[0].add_child(machinery)
 box(machinery,Vector3(-64,3,0),Vector3(18,1.2,6),"59666b")
 for x in range(-71,-56,2):
  box(machinery,Vector3(x,5,0),Vector3(1.4,3,4.5),"487f72");tube(machinery,Vector3(x,7,0),.8,1,"9baba8")
 shaft_part=tube(machinery,Vector3(-82,3,0),.35,28,"b8b9ae");shaft_part.rotation.z=PI/2
 exam_ink=preload("res://modules/review/view/exam12_overlay.gd").new();exam_ink.view=self;add_child(exam_ink);exam_ink.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func apply(value:Dictionary,lang:String,evaluation:Dictionary={})->void:
 super.apply(value,lang,evaluation);ink.hide()
 var concept:String=value.get("concept","prototype");var open:float=float(value.get("cut",0));var living:bool=concept in ["rooms","hygiene"]
 cuts.parameters({"drawing":value.get("drawing",false),"reserve_light":concept=="reserve","lcb_norm":Calc.lcb(float(value.get("shift",0))).norm if concept=="lcb" else 1.,"exam_cut":open,"room_cut":living and float(value.get("roof",0))>.2,"lcb_shift":float(value.get("shift",0)) if concept=="lcb" else 0.,"depth_rise":float(value.get("depth",0)),"section_view":false})
 for part:MeshInstance3D in parts:
  var n:=str(part.name)
  if n.begins_with("Forecastle"):part.visible=float(value.get("forecastle",0))>0
  if living and float(value.get("roof",0))>.2 and n.begins_with("OriginalAftHouse"):part.hide()
  for i in part.mesh.get_blend_shape_count():
   if str(part.mesh.get_blend_shape_name(i))=="Forecastle":part.set_blend_shape_value(i,float(value.get("forecastle",0)))
 structures.visible=concept in ["load","longitudinal","tank","double","flood","damage","waterplane","engine","sections","lightship"]
 rooms.visible=living;machinery.visible=concept in ["engine","lightship"]
 if living:
  var qid:String=value.get("qid","");var zones:Array=[]
  if qid in ["P12_T06","P12_F03"]:zones=["galley","sanitary"]
  elif qid=="P12_T30":zones=["food","sanitary"]
  elif qid=="P12_T29":zones=["rest","mess"]
  elif qid=="P12_C04":zones=["mess"]
  else:zones=["food","galley","mess"]
  for fixture in room_materials:
   var selected:bool=fixture.inside and fixture.zone in zones
   fixture.material.emission_enabled=selected
   if selected:fixture.material.emission=Color("b9d9ad");fixture.material.emission_energy_multiplier=.10+.22*clampf(float(value.get("room",0)),0.,1.)
 for node in near_structure:node.visible=open<.1
 if concept in ["engine","lightship"]:
  var move:float=34.*(1.-clampf(float(value.get("room",0))/3.,0.,1.));machinery.position.x=move;shaft_part.position.x=-82.-move*.5;shaft_part.scale.y=1.+move/28.
 for b in bulkhead_nodes:b.visible=concept not in ["load","longitudinal","sections","engine"]
 capacity_demo.visible=concept=="sections" and float(value.get("section_height",-1))>=0;capacity_demo.position=Vector3(0,3.+6.*float(value.get("section_height",0)),-3.)
 calculation=Calc.values(value)
 cargo.visible=concept in ["load","longitudinal"]
 centre_marker.visible=cargo.visible and calculation.D>0
 centre_marker.position=Vector3(calculation.xg-95,calculation.zg,0)
 for i in cargo_items.size():
  var c:Node3D=cargo_items[i];c.visible=cargo.visible and i<calculation.rows.size() and calculation.rows[i][1]>0
  if c.visible:
   var r:Array=calculation.rows[i];c.position=Vector3(float(r[2])-95,float(r[3]),-4.+float(i%2)*8.)
   # Empty ship is an extended body; never represent it by a cargo crate.
   if i==0:c.hide()
 for i in liquids.size():
  var l:MeshInstance3D=liquids[i];l.visible=concept in ["flood","damage","waterplane","double"] and float(value.get("flood",0))>.001
  var which:int=mini(4,int(float(value.get("shift",0))*4))
  l.visible=l.visible and (i==which or (concept=="double" and i==1))
  var h:float=maxf(.06,float(value.get("flood",0))*7.)
  l.scale.y=h/.1;l.position.y=1.5+h*.5
 for i in chairs.size():chairs[i].visible=not str(value.get("qid","")).begins_with("P12_C04") or i<ceili(12.*float(value.get("load",0)))
 if concept in ["load","longitudinal","lightship","double","tank","engine","rooms","hygiene","sections","damage","flood","waterplane"]:water.teaching(210.,38.,1.)
 else:water.teaching(210.,38.,0.)
 water.material_override.set_shader_parameter("lesson_centre",Vector2.ZERO);water.material_override.set_shader_parameter("lesson_size",Vector2(200,40))
 if value.get("drawing",false):lines_mesh.hide()
 exam_ink.queue_redraw()
func set_camera(_preset:String,instant:=false)->void:
 if source_state.is_empty():super.set_camera("overview",instant);return
 var c:String=source_state.get("concept","");var target:=Vector3(0,0,0);var offset:=Vector3(115,105,-180);var span:=165.
 if c in ["rooms","hygiene"]:target=Vector3(-68,7,0);offset=Vector3(8,40,-25);span=42.
 elif c=="engine":target=Vector3(-64,-4,0);offset=Vector3(-20,28,-50);span=53.
 elif c=="bulb":super.set_camera("bulb",instant);return
 elif c in ["tank","double","waterplane"]:target=Vector3(6,-3,0);offset=Vector3(35,45,-65);span=78.
 turn_target=target;camera_span=span;user_camera=false
 if camera_tween and camera_tween.is_valid():camera_tween.kill()
 var dest:=Transform3D(Basis.looking_at(-offset,Vector3.UP),target+offset)
 if instant:camera.transform=dest;camera.size=span;camera_motion=false;return
 var start:=camera.transform;var old_span:=camera.size;camera_motion=true
 camera_tween=create_tween();camera_tween.tween_method(func(t:float):camera.transform=start.interpolate_with(dest,t);camera.size=lerpf(old_span,span,t),0.,1.,.6);camera_tween.finished.connect(func():camera_motion=false)
func anchor()->Vector2:
 var c:String=source_state.get("concept","");var p:=Vector3(10,8,-5)
 if c in ["rooms","hygiene"]:p=Vector3(-68,17,-6)
 elif c=="engine":p=Vector3(-64,6,0)
 elif c in ["load","longitudinal"] and not calculation.is_empty():p=centre_marker.position
 elif c in ["forecastle","bulb"]:p=Vector3(84,15 if c=="forecastle" else 4,0)
 return project(bodies[0].to_global(p)).clamp(Vector2(20,20),size-Vector2(20,20))
func obstacles()->Array:
 var result:Array=exam_ink.bounds.duplicate() if is_instance_valid(exam_ink) else []
 if source_state.get("concept","") in ["rooms","hygiene"]:
  var rect:=Rect2(project(bodies[0].to_global(Vector3(-73,16,-9.5))),Vector2.ZERO)
  for p in [Vector3(-64,16,-9.5),Vector3(-73,19,-3.5),Vector3(-64,19,-3.5)]:rect=rect.expand(project(bodies[0].to_global(p)))
  result.append(rect.grow(20))
 return result
func update_overlay()->void:
 if is_instance_valid(exam_ink):exam_ink.queue_redraw()
func _process(dt:float)->void:
 super._process(dt)
 if is_visible_in_tree() and is_instance_valid(exam_ink) and float(source_state.get("speed",0))>0:elapsed+=dt;exam_ink.queue_redraw()
