extends Node
var host:Control
var sea:MeshInstance3D
var environment:Environment
var underwater:=false
var ocean_extent:=16000.0
func setup(view:Control,water:MeshInstance3D,local_inspection:=false)->void:
 host=view;sea=water
 var nodes=view.world.find_children("*","WorldEnvironment",true,false)
 environment=nodes[0].environment
 # Orthographic zoom changes the image span, not the eye distance. After a
 # free orbit, foreground sea (and even the stern) can lie behind the eye.
 # Keep the full finite ocean in the signed orthographic depth interval;
 # do not move the user's eye or change its angle/zoom to work around clipping.
 view.camera.near=-12000
 view.camera.far=12000
 # Preserve the authored detailed near sea, add a ring out to eight kilometres.
 var near_material:=water.material_override as ShaderMaterial
 near_material.shader=preload("res://view/ocean_open.gdshader")
 if local_inspection:
  var window_shader:=Shader.new()
  window_shader.code=near_material.shader.code.replace("render_mode unshaded, cull_disabled;", "render_mode unshaded, cull_disabled, depth_prepass_alpha;").replace("uniform float inspection", "uniform vec2 lesson_centre=vec2(0.0);\nuniform vec2 lesson_size=vec2(20.0,25.0);\nuniform float inspection").replace("if (inspection>0.001 && near_ship>0.25) discard;", "float window_edge=length(max(abs(sea_position.xz-lesson_centre)-lesson_size,vec2(0.0)));\n ALPHA=1.0-inspection*0.98*(1.0-smoothstep(0.0,6.0,window_edge));")
  near_material.shader=window_shader
 var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var e:=ocean_extent*.5
 for rect in [Rect2(-e,-e,e-210,2*e),Rect2(210,-e,e-210,2*e),Rect2(-210,-e,420,e-120),Rect2(-210,120,420,e-120)]:
  var a:=Vector3(rect.position.x,0,rect.position.y);var b:=Vector3(rect.end.x,0,rect.position.y);var c:=Vector3(rect.end.x,0,rect.end.y);var d:=Vector3(rect.position.x,0,rect.end.y)
  for p in [a,c,b,a,d,c]:st.add_vertex(p)
 st.generate_normals()
 var far_sea:=MeshInstance3D.new();far_sea.name="Open ocean to horizon";far_sea.mesh=st.commit()
 var material:=near_material.duplicate() as ShaderMaterial
 material.set_shader_parameter("extent",Vector2.ONE*ocean_extent);material.set_shader_parameter("inspection",0.0)
 far_sea.material_override=material;far_sea.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 view.world.add_child(far_sea)
 update_medium()
func _process(_dt:float)->void:
 if is_instance_valid(host) and host.is_visible_in_tree():update_medium()
func update_medium()->void:
 var y:float=host.camera.global_position.y
 underwater=y<-.08
 environment.fog_enabled=true
 if underwater:
  var depth:=maxf(0,-y);var deep:=1.0-exp(-depth/45.0)
  var color:=Color("06414d").lerp(Color("020d1c"),deep)
  environment.fog_light_color=color;environment.background_color=color
  environment.fog_density=.025+minf(depth,30)*.001
  environment.ambient_light_color=Color("77bcc9");environment.ambient_light_energy=.65
 else:
  environment.fog_light_color=Color("102735");environment.background_color=Color("102735")
  environment.fog_density=.0012
  environment.ambient_light_color=Color("c9e2e9");environment.ambient_light_energy=.85
