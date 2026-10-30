extends "res://modules/review/view/stability_ship.gd"
const Yacht=preload("res://modules/review/core/yacht_math.gd")
var detailed:Node3D
var parts:Array=[]
var propellers:Array=[]
var material_states:Array=[]
var inspection_shader:Shader
var ink:Control
var ocean_medium:Node
var tick:=0.
var engine_open:=false
var highlight_key:=""
var arrow_specs:Array=[]
var last_apply:Dictionary={}
var hatch:Node3D
var hatch_hinge:Node3D
var bay_opening:=0.
var detail_container:SubViewportContainer
var detail_viewport:SubViewport
var detail_camera:Camera3D
var detail_rect:=Rect2()
func _ready()->void:
	setup_world()
	for light in world.find_children("*","DirectionalLight3D",true,false):light.light_energy=.65
	var body:=Node3D.new();world.add_child(body);bodies.append(body)
	detailed=load("res://modules/review/assets/planing_yacht.glb").instantiate();body.add_child(detailed)
	collect(detailed)
	hatch=detailed.find_child("Deck_EngineCover",true,false)
	hatch_hinge=Node3D.new();hatch_hinge.position=Vector3(-4.55,1.72,-1);body.add_child(hatch_hinge);hatch.reparent(hatch_hinge,true)
	water=preload("res://view/ocean.gd").create();world.add_child(water)
	ocean_medium=preload("res://modules/review/view/ocean_medium.gd").new();add_child(ocean_medium);ocean_medium.setup(self,water,true)
	detail_container=SubViewportContainer.new();detail_container.stretch=true;detail_container.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(detail_container)
	detail_viewport=SubViewport.new();detail_viewport.world_3d=viewport.find_world_3d();detail_viewport.msaa_3d=Viewport.MSAA_8X;detail_container.add_child(detail_viewport)
	detail_camera=Camera3D.new();detail_camera.projection=Camera3D.PROJECTION_ORTHOGONAL;detail_camera.cull_mask=2;detail_camera.near=-100;detail_camera.far=100;detail_viewport.add_child(detail_camera)
	ink=preload("res://modules/review/view/propulsion_overlay.gd").new();ink.view=self;add_child(ink);ink.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(update_overlay);set_camera("overview",true)
func collect(node:Node)->void:
	if str(node.name) in ["Propeller_-1","Propeller_1"]:propellers.append(node)
	if node is MeshInstance3D:
		node.layers=2
		parts.append(node)
		for i in node.mesh.get_surface_count():
			var original=node.get_active_material(i) as StandardMaterial3D
			if original==null:continue
			var mat:=ShaderMaterial.new()
			if inspection_shader==null:
				inspection_shader=Shader.new()
				inspection_shader.code="""shader_type spatial;
render_mode cull_disabled;
uniform vec4 paint : source_color;
uniform float metal=0.2;
uniform float rough=0.4;
uniform bool shell=false;
uniform bool cockpit=false;
uniform bool open_bay=false;
uniform bool wet=false;
uniform bool glow=false;
uniform float cut_side=1.0;
varying vec3 local_p;
varying vec3 world_p;
void vertex(){world_p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;local_p=VERTEX;}
void fragment(){
 if(open_bay){
  if(shell && local_p.x>-5.95 && local_p.x< -2.3 && (local_p.z*cut_side>0.0 || local_p.y>1.48))discard;
  if(cockpit && world_p.x>-5.85 && world_p.x< -3.35 && abs(world_p.z)<1.12)discard;
 }
 vec3 c=paint.rgb;
 if(wet && shell && world_p.y<0.0)c=mix(c,vec3(.08,.68,.62),.70);
 if(wet && shell && abs(world_p.y)<.018)c=vec3(.94,.90,.60);
 ALBEDO=c;METALLIC=metal;ROUGHNESS=rough;
 if(glow)EMISSION=c*.35+vec3(.05,.20,.16)*(.6+.3*sin(TIME*3.0));
}"""
			mat.shader=inspection_shader;mat.set_shader_parameter("paint",original.albedo_color);mat.set_shader_parameter("metal",original.metallic);mat.set_shader_parameter("rough",original.roughness)
			mat.set_shader_parameter("shell",str(node.name)=="Yacht_Hull_Closed");mat.set_shader_parameter("cockpit",str(node.name)=="Deck_Cockpit")
			node.set_surface_override_material(i,mat);material_states.append({"node":node,"mat":mat})
	for child in node.get_children():collect(child)
func apply(value:Dictionary,lang:String,_evaluation:Dictionary={})->void:
	state=value.duplicate(true);language=lang;metrics=Yacht.values(state)
	bodies[0].rotation.z=deg_to_rad(metrics.trim);bodies[0].position.y=metrics.heave
	var scene:String=state.get("scene","overview");var p:float=float(state.get("p",0))
	engine_open=scene in ["engine","loss","components","eta","wake"]
	bay_opening=clampf(p/.25,0,1) if scene=="engine" else (1. if engine_open else 0.)
	hatch_hinge.rotation.x=-deg_to_rad(100.)*bay_opening
	var segment:int=0 if p<.34 else (1 if p<.67 else 2)
	var key:String=scene+str(engine_open)+str(segment)+str(bay_opening>.01)
	if key!=highlight_key:
		highlight_key=key
		for item in material_states:
			var name_:String=str(item.node.name).replace(" ","_")
			item.mat.set_shader_parameter("open_bay",engine_open and bay_opening>.01)
			item.mat.set_shader_parameter("wet",scene in ["froude","regimes","planing"])
			var glow:bool=(name_.begins_with("Engine_") and p<.34) or ((name_.begins_with("Shaft_") or name_.begins_with("Gearbox_")) and p>=.34 and p<.67) or (name_.begins_with("Propeller_") and p>=.67)
			item.mat.set_shader_parameter("glow",engine_open and glow)
		for part in parts:
			var n:=str(part.name).replace(" ","_")
			part.visible=not(engine_open and (n in ["Cockpit_table","Table_pedestal","Helm_seat"] or n.begins_with("Cockpit_teak_seam") or n.begins_with("Cockpit_bench") or n.begins_with("Cockpit_backrest")))
	water.teaching(12.8,3.8,1. if engine_open or scene in ["regimes","planing","froude"] else 0.)
	water.material_override.set_shader_parameter("lesson_centre",Vector2(-1,0));water.material_override.set_shader_parameter("lesson_size",Vector2(9,4))
	update_overlay()
func set_camera(_preset:String,instant:=false)->void:
	if "--qa" in OS.get_cmdline_user_args():set_meta("last_camera_request",get_stack())
	if camera_tween and camera_tween.is_valid():camera_tween.kill()
	var target:=Vector3(-.4,.6,0);var eye:=Vector3(-11,7,14);var span:=15.
	if engine_open:target=Vector3(-4,.4,0);eye=Vector3(-9,5,7);span=10.
	turn_target=target;camera_span=span;last_camera="overview";user_camera=false
	var dest:=Transform3D(Basis.looking_at(target-eye,Vector3.UP),eye)
	if instant:camera.transform=dest;camera.size=span;camera_motion=false;return
	var initial:=camera.transform;var old:=camera.size;camera_motion=true
	camera_tween=create_tween();camera_tween.tween_method(func(t:float):camera.transform=initial.interpolate_with(dest,t);camera.size=lerpf(old,span,t);update_overlay(),0.,1.,.65)
	camera_tween.finished.connect(func():camera_motion=false)
func point(v:Vector3)->Vector3:return bodies[0].to_global(v)
func update_overlay()->void:
	if not is_instance_valid(ink) or state.is_empty():return
	var scene:String=state.get("scene","overview");var p:float=float(state.get("p",0))
	overlay_points={"ship":point(Vector3(1,1,1.6)),"wet":point(Vector3(1,.4,1.2)),"engine":point(Vector3(-3.5,1.35,.78)),"shaft":point(Vector3(-5.4,.55,.78)),"propeller":point(Vector3(-6.4,.2,.78)),"bow":point(Vector3(5,1.1,0))}
	var selected:String="ship"
	if engine_open:selected="engine" if p<.34 else ("shaft" if p<.67 else "propeller")
	elif scene in ["regimes","planing","froude"]:selected="wet"
	elif scene=="tow":selected="bow"
	overlay_points.focus=overlay_points[selected]
	var detail_on:bool=engine_open or scene in ["regimes","planing"]
	detail_container.visible=detail_on;detail_viewport.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE if detail_on else SubViewport.UPDATE_DISABLED
	if detail_on:
		detail_rect=Rect2(Vector2(size.x*.035,size.y*.59),Vector2(maxf(280,size.x*.45),size.y*.27))
		detail_container.position=detail_rect.position;detail_container.size=detail_rect.size
		if engine_open:
			var t1:float=smoothstep(.25,.5,p);var t2:float=smoothstep(.5,1.,p)
			var centre:Vector3=point(Vector3(-3.6,1.15,0)).lerp(point(Vector3(-5.2,.55,0)),t1).lerp(point(Vector3(-6.4,.2,0)),t2)
			detail_camera.position=centre+Vector3(-2.5,3.1,5).lerp(Vector3(-2,1.3,4),t2);detail_camera.look_at(centre);detail_camera.size=lerpf(3.6,2.3,t2)
		else:
			var centre:=Vector3(-.3,-.2,0);detail_camera.position=centre+Vector3(-2,-6,10);detail_camera.look_at(centre);detail_camera.size=9.
	# Cut the side nearest the current observer; orbiting cannot hide the engines again.
	var side:float=signf(bodies[0].to_local(camera.global_position).z)
	for item in material_states:
		if str(item.node.name)=="Yacht_Hull_Closed":item.mat.set_shader_parameter("cut_side",side)
	ink.queue_redraw()
func detail_project(v:Vector3)->Vector2:return detail_rect.position+detail_camera.unproject_position(v)
func anchor()->Vector2:
	if engine_open:return detail_project(overlay_points.get("focus",Vector3.ZERO)).clamp(Vector2(30,30),size-Vector2(30,30))
	return project(overlay_points.get("focus",Vector3.ZERO)).clamp(Vector2(30,30),size-Vector2(30,30))
func obstacles()->Array:
	var bounds:=Rect2(project(point(Vector3(-7,0,-2))),Vector2.ZERO)
	for x in [-7.,6.5]:
		for y in [0.,3.5]:
			for z in [-2.,2.]:bounds=bounds.expand(project(point(Vector3(x,y,z))))
	return labels_bounds+[bounds]+([detail_rect] if detail_container.visible else [])
func _process(dt:float)->void:
	if not is_visible_in_tree() or state.is_empty():return
	tick+=dt
	for i in propellers.size():propellers[i].rotation.x=tick*(7. if i==0 else -7.)
	if camera.transform!=projected_camera or camera.size!=projected_span or size!=projected_size:
		projected_camera=camera.transform;projected_span=camera.size;projected_size=size;update_overlay()
func _gui_input(event:InputEvent)->void:
	if "--qa" in OS.get_cmdline_user_args():set_meta("last_camera_input",str(event))
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		camera.size=clampf(camera.size*(.9 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.1),4,45);user_camera=true;accept_event();return
	super._gui_input(event)
