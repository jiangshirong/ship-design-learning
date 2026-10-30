extends "res://modules/review/view/stability_ship.gd"
# Qualitative damage scenes. Intact hull geometry is reused, not damage hydrostatics.
const Detailed=preload("res://modules/review/view/damage_cutaway.gd")
var detailed_ship
var liquids:Array=[]
var liquid_keys:Array=[]
var freeboard_ship:Node3D
var morph_parts:Array=[]
var opening:MeshInstance3D
var marker:MeshInstance3D
var source_state:Dictionary={}
var ink:Control
var ring_data:Dictionary={}
var overlay_node:Control
var last_morph:Dictionary={}
var module11_ink:Control
var ocean_medium:Node
func material(color:Color)->StandardMaterial3D:
	var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=.75;m.cull_mode=BaseMaterial3D.CULL_DISABLED
	if color.a<1:m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	return m
func box(dim:Vector3,point:Vector3,color:Color)->MeshInstance3D:
	var n:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=dim;n.mesh=mesh;n.position=point;n.material_override=material(color);bodies[0].add_child(n);return n
func _ready()->void:
	setup_world()
	var body:=Node3D.new();world.add_child(body);bodies.append(body)
	water=preload("res://view/ocean.gd").create();world.add_child(water)
	ocean_medium=preload("res://modules/review/view/ocean_medium.gd").new();add_child(ocean_medium);ocean_medium.setup(self,water)
	set_camera("overview",true)
	ring_data=Hydro.pair({}).a
	for i in 13:
		var liquid:=MeshInstance3D.new();liquid.material_override=material(Color(.12,.65,.95,.78));bodies[0].add_child(liquid);liquids.append(liquid);liquid_keys.append("")
	opening=box(Vector3(5,2,.3),Vector3(22,13,-12),Color("ff907d"))
	marker=box(Vector3(1,1,1),Vector3(0,10,0),Color("ffd078"))
	ink=Control.new();ink.set_script(preload("res://modules/review/view/topic_marine_overlay.gd"));ink.view=self;add_child(ink);ink.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	module11_ink=Control.new();module11_ink.set_script(preload("res://modules/review/view/module11_overlay.gd"));module11_ink.view=self;add_child(module11_ink);module11_ink.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func collect_morphs(node:Node)->void:
	if node is MeshInstance3D:
		morph_parts.append(node)
		# The authored steel/coating materials belong to the deforming ship.
		# Do not paint the whole detailed model with the hydro teaching shader.
	for child in node.get_children():collect_morphs(child)
func update_morphs(value:Dictionary)->void:
	var values:Dictionary={"Sheer":float(value.get("sheer",0)),"Superstructure":float(value.get("superstructure",0)),"Forecastle":float(value.get("forecastle",0)),"Flare":float(value.get("flare",0))}
	if values==last_morph:return
	last_morph=values
	for part:MeshInstance3D in morph_parts:
		for i in part.mesh.get_blend_shape_count():
			part.set_blend_shape_value(i,values.get(str(part.mesh.get_blend_shape_name(i)),0))
		var name_:String=str(part.name)
		if name_.begins_with("Continuous") or name_.begins_with("Original") or name_.begins_with("M11"):
			part.show()
		else:
			part.visible=values.Forecastle>.001 if name_.begins_with("Forecastle") else values.Superstructure>.001
func ring_at(x:float)->Array:
	var n:int=ring_data.ring_size
	var lo:=0
	for i in range(int(ring_data.ring_count)-1):
		if float(ring_data.vertices[i*n][0])<=x:lo=i
	var ax:float=ring_data.vertices[lo*n][0];var bx:float=ring_data.vertices[(lo+1)*n][0]
	var t:float=clampf((x-ax)/maxf(.0001,bx-ax),0,1);var result:Array=[]
	for j in n:result.append(vector(ring_data.vertices[lo*n+j]).lerp(vector(ring_data.vertices[(lo+1)*n+j]),t))
	return result
func update_overlay()->void:
	# Override the intact G/C/GM overlay. These scenes have no numerical damage model.
	if ink:ink.queue_redraw()
	if module11_ink:module11_ink.queue_redraw()
func set_camera(_preset:String,instant:=false)->void:
	if not camera:return
	var key:=("damage_peak" if source_state.get("phase","")=="forepeak" else "damage") if source_state.get("topic","damage")=="damage" else str(source_state.get("phase","freeboard"))
	if source_state.get("topic","damage")=="damage" and source_state.get("phase","") in ["frames","bulkheads"]:
		key="damage_"+str(source_state.phase)
	
	last_camera_key=key;last_camera="topic"
	if camera_tween and camera_tween.is_valid():camera_tween.kill()
	# Freeboard dimensions and their explanation anchor are on the -Z side.
	var eye:=Vector3(100,95,170) if key=="damage" else Vector3(0,30,-220)
	turn_target=Vector3(0,3,0);camera_span=155
	if key=="damage":
		eye=Vector3(48,75,175);turn_target=Vector3(5,2,0);camera_span=145
	elif key=="damage_peak":
		eye=Vector3(115,58,125);turn_target=Vector3(80,3,0);camera_span=70
	elif key=="damage_frames":
		eye=Vector3(28,24,65);turn_target=Vector3(6,-4,5);camera_span=55
	elif key=="damage_bulkheads":
		eye=Vector3(45,52,90);turn_target=Vector3(6,1,0);camera_span=95
	if key=="superstructure":
		eye=Vector3(70,75,-170);turn_target=Vector3(-8,9,0);camera_span=115
	elif key in ["bow","bow_waves","flare"]:
		eye=Vector3(100,43,-155);turn_target=Vector3(55,9,0);camera_span=92
	if key=="flare":eye=Vector3(125,38,-45);turn_target=Vector3(78,8,0);camera_span=55
	var dest:=Transform3D(Basis.looking_at(turn_target-eye,Vector3.UP),eye)
	user_camera=false
	if instant:camera.transform=dest;camera.size=camera_span;camera_motion=false;return
	var start:=camera.transform;var span:=camera.size;camera_motion=true
	camera_tween=create_tween();camera_tween.tween_method(func(t:float):camera.transform=start.interpolate_with(dest,t);camera.size=lerpf(span,camera_span,t),0.0,1.0,.65)
	camera_tween.finished.connect(func():camera_motion=false)
func clip(poly:Array,axis:int,limit:float,greater:bool)->Array:
	var result:Array=[]
	if poly.is_empty():return result
	var a:Vector3=poly[-1];var da:float=(a[axis]-limit)*(1 if greater else -1)
	for point in poly:
		var b:Vector3=point;var db:float=(b[axis]-limit)*(1 if greater else -1)
		if (da>=0)!=(db>=0):result.append(a.lerp(b,da/(da-db)))
		if db>=0:result.append(b)
		a=b;da=db
	return result
func horizontal_surface(poly:Array,height:float)->Array:
	var result:Array=[]
	if poly.is_empty():return result
	var normal:Vector3=bodies[0].basis.transposed()*Vector3.UP
	var a:Vector3=poly[-1];var da:float=height-normal.dot(a)
	for point in poly:
		var b:Vector3=point;var db:float=height-normal.dot(b)
		if (da>=0)!=(db>=0):result.append(a.lerp(b,da/(da-db)))
		if db>=0:result.append(b)
		a=b;da=db
	return result
func liquid_mesh(bay:int,fill:float,side:float)->ArrayMesh:
	# Twelve cargo cells share the authored tank boundaries; the last cell is
	# the forward narrow region. This remains a qualitative flooding scene.
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var previous:Array=[];var levels:Array=[]
	var forepeak:bool=bay==12
	var pair_index:int=bay/2
	var low:float=80.0 if forepeak else Detailed.CARGO_EDGES[pair_index]+.09
	var high:float=94.7 if forepeak else Detailed.CARGO_EDGES[pair_index+1]-.09
	var n:int=ring_data.ring_size
	var stations:Array=[low]
	for ring in int(ring_data.ring_count):
		var x:float=ring_data.vertices[ring*n][0]
		if x>low and x<high:stations.append(x)
	stations.append(high)
	for x in stations:
		var poly:Array=[]
		if forepeak:
			poly=ring_at(x);poly=clip(poly,1,.4,true)
		else:
			var z0:float=.09 if bay%2==0 else -Detailed.HALF_WIDTH
			var z1:float=Detailed.HALF_WIDTH if bay%2==0 else -.09
			poly=[Vector3(x,Detailed.FLOOR,z0),Vector3(x,Detailed.ROOF,z0),Vector3(x,Detailed.ROOF,z1),Vector3(x,Detailed.FLOOR,z1)]
		poly=horizontal_surface(poly,(.4 if forepeak else Detailed.FLOOR)+fill*8.0)
		if poly.size()<3:continue
		if not previous.is_empty():
			# Clip yields a stable ring cardinality except at the tapered end.
			var count:int=mini(poly.size(),previous.size())
			for j in count:
				for v in [previous[j],poly[j],poly[(j+1)%count],previous[j],poly[(j+1)%count],previous[(j+1)%count]]:st.add_vertex(v)
		else:cap(st,poly)
		previous=poly;levels=poly
	if not levels.is_empty():cap(st,levels)
	st.generate_normals();return st.commit()
func cap(st:SurfaceTool,poly:Array)->void:
	for j in range(1,poly.size()-1):
		st.add_vertex(poly[0]);st.add_vertex(poly[j]);st.add_vertex(poly[j+1])
func apply(value:Dictionary,lang:String,_evaluation:Dictionary={})->void:
	source_state=value.duplicate(true);language=lang
	water.visible=true
	var damage:bool=value.get("topic","damage")=="damage"
	if damage and not detailed_ship:detailed_ship=Detailed.new();bodies[0].add_child(detailed_ship)
	if not damage and not freeboard_ship:
		freeboard_ship=load("res://modules/review/assets/module11_ship.glb").instantiate();bodies[0].add_child(freeboard_ship);collect_morphs(freeboard_ship)
	if freeboard_ship:freeboard_ship.visible=not damage
	if detailed_ship:detailed_ship.visible=damage
	if damage:detailed_ship.apply(value)
	if not damage:update_morphs(value)
	var tilt:float=float(value.get("heel_demo",0))
	bodies[0].rotation=Vector3(-deg_to_rad(tilt),0,-deg_to_rad(float(value.get("trim_demo",0))))
	bodies[0].position=Vector3(0,-float(value.get("draft",8))-float(value.get("sink",0)),0)
	var exterior:bool=value.get("phase","")=="exterior"
	water.teaching(200.0,26.6,float(value.get("cutaway",1.0)) if damage and not exterior else 0.0)
	var active_bay:int=12 if value.get("phase","")=="forepeak" else clampi(int(value.get("bay",2))*2,0,10)
	for i in liquids.size():
		var fill:float=float(value.get("flood",0))
		var visible_fill:float=fill if i==active_bay else (fill*float(value.get("spread",0)) if i<12 and active_bay!=12 else 0.0)
		liquids[i].visible=damage and visible_fill>.01
		if liquids[i].visible:
			var key:=str(snappedf(visible_fill,.04))+":"+str(snappedf(float(value.get("side",0)),.05))+":"+str(tilt)+":"+str(float(value.get("trim_demo",0)))
			if liquid_keys[i]!=key:
				liquid_keys[i]=key;liquids[i].mesh=liquid_mesh(i,snappedf(visible_fill,.04),float(value.get("side",0)))
	opening.visible=value.get("phase","")=="opening"
	marker.visible=value.get("phase","")=="G";marker.position.y=float(value.get("demo_zg",10))
	ink.queue_redraw()
	module11_ink.queue_redraw()
func anchor()->Vector2:
	var local:=Vector3.ZERO
	match source_state.get("phase",""):
		"freeboard":local=Vector3(0,12,-13)
		"reserve":local=Vector3(0,12,0)
		"superstructure":local=Vector3(-10,14.89+6*float(source_state.get("superstructure",0)),-12.9)
		"bow":local=bow_deck_point()
		"bow_waves":local=Vector3(75,16+5*float(source_state.get("forecastle",0)),-7)
		"flare":local=Vector3(79,14,-9*(1+.65*float(source_state.get("flare",0))))
		"G":local=marker.position
		"opening":local=opening.position
		"forepeak":local=Vector3(87,7,0)
		"bulkheads":local=Vector3(6,9,5)
		"frames":local=Vector3(6,1,8)
		_:local=Vector3(-44+20*clampi(int(source_state.get("bay",2)),0,5),7,5.4)
	if source_state.get("qid","")=="N10" and source_state.get("phase","")!="G":local=Vector3(6,9,5)
	return project(bodies[0].to_global(local)).clamp(Vector2(25,25),size-Vector2(25,25))
func obstacles()->Array:
	var bounds:Array=[Rect2(size*Vector2(.12,.24),size*Vector2(.76,.40))]
	if source_state.get("phase","")=="bow":
		var top3:Vector3=bodies[0].to_global(bow_deck_point())
		var top:Vector2=project(top3)
		var level:Vector2=project(Vector3(top3.x,0,top3.z))
		bounds.append(Rect2(top,Vector2.ZERO).expand(level).grow(60))
	return bounds

func bow_deck_point()->Vector3:
	var best:=Vector3(-INF,0,0)
	for row in ring_data.vertices:
		var p:Vector3=vector(row)
		if p.x>best.x or (is_equal_approx(p.x,best.x) and p.y>best.y):best=p
	var t:float=clampf((best.x-38.0)/62.0,0.0,1.0)
	best.y+=5*t*t*(3-2*t)*float(source_state.get("sheer",0))
	best.y+=5*float(source_state.get("forecastle",0))
	return best
