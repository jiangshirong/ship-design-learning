extends ColorRect
# A scene-only layer; sibling dialogue and controls are rendered afterwards.
var speech:Control
var last_values:Array=[]
func _ready()->void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 var m:=ShaderMaterial.new();m.shader=preload("res://view/lesson_spotlight.gdshader");material=m
func _process(_dt:float)->void:
 if not is_instance_valid(speech):hide();return
 visible=speech.is_visible_in_tree() and speech.anchored
 if not visible:return
 position=speech.position;size=speech.size
 var host=speech.get_parent()
 var data:Dictionary=host.get("beat") if host.get("beat") is Dictionary else {}
 var key:=str(data.get("anchor","ship"))
 # Introductions and whole-ship comparisons need their full context.
 var state:Dictionary=host.get("current_state") if host.get("current_state") is Dictionary else {}
 var phase:=str(state.get("phase", ""))
 if key in ["overview","intro","goal"] or phase in ["intro","goal","overview"] or str(data.get("id", "")).ends_with(":goal"):hide();return
 if key=="ship" or key.is_empty():key=phase
 var provider=host.get("ship")
 if is_instance_valid(provider) and provider.get("active")!=null:provider=provider.active
 var radius:=size.y*.20
 if is_instance_valid(provider) and provider.get("camera") is Camera3D:
  var cam:Camera3D=provider.camera
  var world_radius:float=float(data.get("spotlight_radius",0))
  if world_radius<=0:
   world_radius=2.6 if cam.size<48 else 18.0
   if key in ["bow","bow_waves","forepeak","forecastle","superstructure","stern","bulkheads","frames"]:world_radius=24.0
   if key in ["G","C","M","centre","load","limit"]:world_radius=7.0 if cam.size>48 else 1.8
   if key in ["arm","water","baseline","base_plane"]:world_radius=25.0
  radius=world_radius*size.y/maxf(cam.size,1.0)
  if cam.projection==Camera3D.PROJECTION_PERSPECTIVE:
   radius=world_radius*size.y/(2.0*maxf(cam.position.distance_to(provider.get("turn_target") if provider.get("turn_target") is Vector3 else Vector3.ZERO),1.0)*tan(deg_to_rad(cam.fov*.5)))
 var radii:=Vector2.ONE*clampf(radius,65.0,size.y*.46)
 if data.get("spotlight_radii") is Array:
  var a:Array=data.spotlight_radii
  if a.size()==2:radii=Vector2(float(a[0]),float(a[1]))
 if is_instance_valid(provider) and provider.get("engine_open")==true and provider.get("detail_rect") is Rect2:
  var rect:Rect2=provider.detail_rect
  radii=rect.size*.53
 var values:Array=[size,speech.anchor,radii]
 if values==last_values:return
 last_values=values
 material.set_shader_parameter("logical_size",size)
 material.set_shader_parameter("centre",speech.anchor)
 material.set_shader_parameter("radii",radii)
