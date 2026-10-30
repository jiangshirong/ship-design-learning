extends Control
const Hydro=preload("res://modules/review/core/stability_math.gd")
var container:SubViewportContainer
var viewport:SubViewport
var world:Node3D
var camera:Camera3D
var bodies:Array=[]
var shells:Array=[]
var fittings:Array=[]
var state:Dictionary={}
var metrics:Dictionary={}
var reference:Dictionary={}
var language:="zh"
var focus:="ship"
var camera_motion:=false
var camera_tween:Tween
var last_geometry:=""
var last_camera:=""
var last_camera_key:=""
var dragging:=false
var camera_span:=55.0
var turn_target:=Vector3(0,4,0)
var overlay_points:Dictionary={}
var shell_material:ShaderMaterial
var water:MeshInstance3D
var section:MeshInstance3D
var waterplane_fill:MeshInstance3D
var waterplane_boundary:Array=[]
var surface_key:=""
var labels_bounds:Array=[]
var observation:Transform3D
var observation_span:=55.0
var user_camera:=false
var projected_camera:Transform3D
var projected_size:=Vector2.ZERO
var projected_span:=-1.0
var visibility_decision:="initial"
var interior_models:Array=[]
var interior_cuts:Array=[]
var fitting_cuts:Array=[]
func tr2(a:String,b:String)->String:return a if language=="zh" else b
func _ready()->void:
	setup_world()
	var shader:=Shader.new();shader.code="""shader_type spatial;
render_mode cull_disabled;
uniform float opacity=1.0;
uniform bool inspect=false;
uniform bool front_cut=false;
uniform float metre_scale=1.0;
varying vec3 p;
void vertex(){p=VERTEX/metre_scale;}
void fragment(){
 if(inspect){
  if(front_cut && p.x>0.08)discard;
  if(!front_cut && abs(p.x)<32.0 && ((p.z>0.0 && p.y>0.2)||p.y>14.65))discard;
 }
 vec3 steel=p.y<10.4?vec3(.34,.075,.055):vec3(.10,.15,.17);
 float seam=min(abs(mod(p.x+1.5,3.0)-1.5),abs(mod(p.y+.9,1.8)-.9));
 float edge=1.0-smoothstep(.018,.018+fwidth(seam),seam);
 ALBEDO=mix(steel,steel*.82,edge*.45);ROUGHNESS=.6;METALLIC=.15;
}"""
	shell_material=ShaderMaterial.new();shell_material.shader=shader
	create_body(0)
	water=preload("res://view/ocean.gd").create();world.add_child(water)
	section=MeshInstance3D.new();bodies[0].add_child(section)
	var sm:=StandardMaterial3D.new();sm.albedo_color=Color(.3,.85,.78,.40);sm.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;sm.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;sm.cull_mode=BaseMaterial3D.CULL_DISABLED;section.material_override=sm
	waterplane_fill=MeshInstance3D.new();waterplane_fill.material_override=sm;world.add_child(waterplane_fill);waterplane_fill.hide()
	# Overlay is a sibling after the viewport, so projected arrows are never behind it.
	var ink:=Control.new();ink.set_script(preload("res://modules/review/view/stability_overlay.gd"));ink.owner_view=self;add_child(ink);ink.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(func():if not state.is_empty():update_overlay())
	set_camera("overview",true)
func create_body(i:int)->void:
	var packed:PackedScene=load("res://modules/review/assets/stability_fittings.glb")
	var body:=Node3D.new();world.add_child(body);bodies.append(body)
	var shell:=MeshInstance3D.new();shell.material_override=shell_material;body.add_child(shell);shells.append(shell)
	var detail:Node3D=packed.instantiate();body.add_child(detail);fittings.append(detail)
	var fc=preload("res://view/inspection_cut.gd").new();fc.attach(detail);fitting_cuts.append(fc)
	var inner=load("res://assets/damage_tanker.glb").instantiate() if i==0 else Node3D.new();body.add_child(inner);interior_models.append(inner)
	var ic=preload("res://view/inspection_cut.gd").new();ic.attach(inner);interior_cuts.append(ic)
	for mesh in ic.nodes:
		mesh.visible=str(mesh.name).get_slice("_",0) in ["Bulkheads","Frames","DoubleBottom","Ballast","PeakBulkhead","PeakFrame"]
	for child in detail.get_children():
		if child is Node3D:child.set_meta("original",child.position)
	if i==1:shells[1].mesh=mesh_from(Hydro.pair({}))
func setup_world()->void:
	clip_contents=true;mouse_filter=Control.MOUSE_FILTER_STOP
	container=SubViewportContainer.new();container.stretch=true;container.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(container)
	viewport=SubViewport.new();viewport.own_world_3d=true;viewport.msaa_3d=Viewport.MSAA_8X;container.add_child(viewport)
	resized.connect(sync_viewport_size)
	sync_viewport_size()
	world=Node3D.new();viewport.add_child(world)
	var environment:=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("102735");environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color("c9e2e9");environment.environment.ambient_light_energy=.85;world.add_child(environment)
	for direction in [Vector3(-50,-25,0),Vector3(-25,145,0)]:
		var light:=DirectionalLight3D.new();light.rotation_degrees=direction;light.light_energy=1.1;world.add_child(light)
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.far=1000;world.add_child(camera)
func sync_viewport_size()->void:
	if not is_instance_valid(container) or not is_instance_valid(viewport):return
	container.position=Vector2.ZERO;container.size=size
	# The stretching container owns the render target size.
func vector(v:Array)->Vector3:return Vector3(v[0],v[2],-v[1])
func mesh_from(p:Dictionary)->ArrayMesh:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in p.a.faces:
		# Source is right-handed x/y/z, Godot mapping is a proper rotation;
		# Godot front winding is clockwise.
		for j in [2,1,0]:
			var i:int=face[j];st.add_vertex(vector(p.a.vertices[i]).lerp(vector(p.b.vertices[i]),p.t)*float(state.get("display_scale",1)))
	st.generate_normals();return st.commit()
func geometry()->void:
	var key:String=str(state.get("route","base"))+var_to_bytes(float(state.get("morph",0))).hex_encode()+":"+str(state.get("display_scale",1))
	if key==last_geometry:return
	last_geometry=key;var p:=Hydro.pair(state);shells[0].mesh=mesh_from(p)
	if shells.size()>1 and shells[1].mesh==null:shells[1].mesh=mesh_from(Hydro.pair({}))
	for child in fittings[0].get_children():
		if not child is Node3D:continue
		var original:Vector3=child.get_meta("original");var next:=original*float(state.get("display_scale",1))
		next.z=original.z*metrics.B/26.60
		if original.y>10.88:next.y=original.y*float(state.get("display_scale",1))+(metrics.H-14.89*float(state.get("display_scale",1)))
		child.position=next;child.scale=Vector3.ONE*float(state.get("display_scale",1))
	# Actual midship ring (not the buoyancy-centre calculation).
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n:int=p.a.get("ring_size",23);var ring:=24*n;var centre:=Vector3(0,7,0)*float(state.get("display_scale",1))
	for i in n:
		st.add_vertex(centre)
		st.add_vertex(vector(p.a.vertices[ring+i]).lerp(vector(p.b.vertices[ring+i]),p.t)*float(state.get("display_scale",1)))
		st.add_vertex(vector(p.a.vertices[ring+(i+1)%n]).lerp(vector(p.b.vertices[ring+(i+1)%n]),p.t)*float(state.get("display_scale",1)))
	st.generate_normals();section.mesh=st.commit()
func apply(value:Dictionary,lang:String,evaluation:Dictionary={})->void:
	state=value.duplicate(true);language=lang
	if evaluation.is_empty():evaluation=preload("res://modules/review/core/stability_evaluation.gd").evaluate(state)
	metrics=evaluation.actual;reference=evaluation.reference
	geometry()
	var roll:bool=state.get("show","")=="roll";var comparison:bool=roll and state.get("compare",false)
	bodies[0].rotation.x=-deg_to_rad(metrics.angle);bodies[0].position=Vector3(0,-metrics.level,-25 if comparison else 0)
	if comparison and bodies.size()==1:create_body(1)
	if bodies.size()>1:bodies[1].visible=comparison
	if comparison:
		bodies[1].rotation.x=-deg_to_rad(reference.angle);bodies[1].position=Vector3(0,-reference.level,25)
	var concept:bool=state.get("show","hull") not in ["hull","roll"]
	water.teaching(200.0,float(metrics.B),1.0 if concept else 0.0,comparison)
	shell_material.set_shader_parameter("inspect",concept)
	shell_material.set_shader_parameter("front_cut",last_camera.begins_with("front"))
	shell_material.set_shader_parameter("metre_scale",float(state.get("display_scale",1)))
	# The authored section structure is visible through the cut; no green
	# filled sheet covers it. Waterplane area remains a separate calculation aid.
	section.hide();water.visible=true
	waterplane_fill.visible=state.get("show","")=="waterplane"
	if waterplane_fill.visible:update_waterplane()
	for i in (2 if comparison else 1):
		fittings[i].show()
		interior_models[i].visible=concept
		var m:Dictionary=metrics if i==0 else reference
		interior_models[i].scale=Vector3(float(state.get("display_scale",1)) if i==0 else 1.0,m.H/14.89,m.B/26.6)
		interior_cuts[i].window(1.0 if concept else 0.0,0,32,.2,14.65,0,concept and last_camera.begins_with("front"))
		fitting_cuts[i].window(1.0 if concept else 0.0,0,32,.2,14.65,0,concept and last_camera.begins_with("front"))
	if roll and not camera_motion and not user_camera:
		camera.size=80 if comparison else 55
	update_overlay()
func update_waterplane()->void:
	var key:String=last_geometry+str(metrics.angle)
	if key==surface_key:return
	surface_key=key;var p:=Hydro.pair(state);var n:int=p.a.ring_size;var left:Array=[];var right:Array=[]
	for ring in int(p.a.ring_count):
		var hits:Array=[]
		for j in n:
			var i:int=ring*n+j;var k:int=ring*n+(j+1)%n
			var a:Vector3=bodies[0].to_global(vector(p.a.vertices[i]).lerp(vector(p.b.vertices[i]),p.t))
			var b:Vector3=bodies[0].to_global(vector(p.a.vertices[k]).lerp(vector(p.b.vertices[k]),p.t))
			if (a.y<0)!=(b.y<0):hits.append(a.lerp(b,-a.y/(b.y-a.y)))
		if hits.size()>=2:
			hits.sort_custom(func(a:Vector3,b:Vector3):return a.z<b.z);left.append(hits[0]+Vector3(0,.03,0));right.append(hits[-1]+Vector3(0,.03,0))
	right.reverse();waterplane_boundary=left+right
	if waterplane_boundary.size()<3:return
	var centre:=Vector3.ZERO
	for v in waterplane_boundary:centre+=v
	centre/=waterplane_boundary.size()
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in waterplane_boundary.size():
		st.add_vertex(centre);st.add_vertex(waterplane_boundary[i]);st.add_vertex(waterplane_boundary[(i+1)%waterplane_boundary.size()])
	st.generate_normals();waterplane_fill.mesh=st.commit()
func merge_state(patch:Dictionary)->Dictionary:
	var result:=state.duplicate(true);result.merge(patch,true);return result
func set_camera(preset:String,instant:=false)->void:
	var key:String=preset+str(state.get("show","")=="roll")+str(state.get("compare",false))
	
	last_camera_key=key
	last_camera=preset
	if camera_tween and camera_tween.is_valid():camera_tween.kill()
	var eye:=Vector3(220,-2.5,0);var target:=Vector3(0,-2.5,0);var span:=38.0;var up:=Vector3.UP
	if state.get("show","")=="roll":span=55
	if preset=="front_scale":span=78
	if preset=="overview":eye=Vector3(145,92,155);target=Vector3(0,0,0);span=155
	elif preset=="top":eye=Vector3(0,220,.1);target=Vector3.ZERO;span=205;up=Vector3(-1,0,0)
	if state.get("show","")=="roll" and state.get("compare",false):span=80
	turn_target=target;camera_span=span
	var dest:=Transform3D(Basis.looking_at(target-eye,up),eye)
	user_camera=false
	if instant:camera.transform=dest;camera.size=span;camera_motion=false;return
	var start:=camera.transform;var original_span:=camera.size;camera_motion=true
	camera_tween=create_tween();camera_tween.tween_method(func(t:float):camera.transform=start.interpolate_with(dest,t);camera.size=lerpf(original_span,span,t),0.0,1.0,.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	camera_tween.finished.connect(func():camera_motion=false)
func project(point:Vector3)->Vector2:return camera.unproject_position(point)
func update_overlay()->void:
	if metrics.is_empty():return
	var body:Node3D=bodies[0];var a:float=deg_to_rad(metrics.angle)
	var g:=body.to_global(Vector3(metrics.xc0,metrics.zg,0))
	var c:=Vector3(metrics.cx,metrics.cz-metrics.level,-metrics.cy)+Vector3(0,0,body.position.z)
	var m:=body.to_global(Vector3(metrics.xc0,metrics.km,0))
	var deck:=body.to_global(Vector3(0,metrics.H,-metrics.B/2))
	var line_y:float=minf(g.y,c.y)-3
	overlay_points={"G":g,"C":c,"M":m,"baseline":body.to_global(Vector3(metrics.xc0,0,0)),"limit":body.to_global(Vector3(metrics.xc0,metrics.allowed,0)),"deck":deck,"water":Vector3(0,0,0),"ship":body.to_global(Vector3(0,7,0)),"arm":Vector3(metrics.xc0,line_y,(g.z+c.z)*.5),"line_y":line_y}
	get_child(get_child_count()-1).queue_redraw()
func anchor()->Vector2:
	if overlay_points.is_empty():return size*.5
	return project(overlay_points.get(focus,overlay_points.G)).clamp(Vector2(20,20),size-Vector2(20,20))
func obstacles()->Array:
	var result:Array=labels_bounds.duplicate()
	if last_camera=="overview" and bodies.size()>0:
		var bounds:=Rect2(project(bodies[0].to_global(Vector3(-98,0,-14))),Vector2.ZERO)
		for x in [-98,100]:
			for y in [0,31]:
				for z in [-14,14]:bounds=bounds.expand(project(bodies[0].to_global(Vector3(x,y,z))))
		result.append(bounds)
	return result
func cancel()->void:
	if camera_tween and camera_tween.is_valid():camera_tween.kill()
	camera_motion=false;dragging=false
func _process(_dt:float)->void:
	if not is_visible_in_tree() or not camera:return
	if camera.transform!=projected_camera or camera.size!=projected_span or size!=projected_size:
		projected_camera=camera.transform;projected_span=camera.size;projected_size=size
		update_overlay()
func _gui_input(event:InputEvent)->void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_LEFT:
			dragging=event.pressed
			if dragging:cancel();dragging=true;user_camera=true;observation=camera.transform;observation_span=camera.size
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:camera.size=clampf(camera.size*(.9 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.1),30,240);user_camera=true
	if event is InputEventMouseMotion and dragging:
		var offset:=camera.position-turn_target
		var radius:float=maxf(offset.length(),1)
		var yaw:float=atan2(offset.x,offset.z)-event.relative.x*.005
		var pitch:float=clampf(asin(clampf(offset.y/radius,-1,1))+event.relative.y*.005,-1.52,1.52)
		camera.position=turn_target+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*radius
		camera.look_at(turn_target);accept_event()
func _notification(what:int)->void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:dragging=false
