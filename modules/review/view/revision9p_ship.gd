extends "res://modules/review/view/module11_ship.gd"
var revision_ink:Control
var architecture:Dictionary={}
var rest_transforms:Dictionary={}
func model_path()->String:return "res://modules/review/assets/arrangement_ship.glb"
func _ready()->void:
 super._ready()
 architecture=JSON.parse_string(FileAccess.get_file_as_string("res://modules/review/content/arrangement_geometry.json"))
 for part in parts:rest_transforms[part.get_instance_id()]=part.transform
 revision_ink=preload("res://modules/review/view/revision9p_overlay.gd").new();revision_ink.view=self;add_child(revision_ink);revision_ink.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func building_part(n:String)->bool:
 return n.begins_with("Enclosed") or n.begins_with("Superstructure") or n.begins_with("Weather") or n.begins_with("Roof")
func apply(value:Dictionary,lang:String,evaluation:Dictionary={})->void:
 super.apply(value,lang,evaluation)
 var scene:String=value.get("scene","");var p:float=float(value.get("p",0))
 var bridge:bool=scene=="bridge";var width:bool=scene=="width"
 var fc:float=clampf(p,0,1) if scene=="forecastle" else 0.0
 for part:MeshInstance3D in parts:
  var n:=str(part.name)
  part.transform=rest_transforms[part.get_instance_id()]
  part.visible=n.begins_with("Continuous") or n.begins_with("Original") or n.begins_with("M11")
  if n.begins_with("OriginalAftHouse"):part.visible=not bridge
  if n.begins_with("BridgeCabin"):
   part.visible=bridge;part.position.y-=(float(architecture.cabin_base)-float(architecture.deck))*(1.0-clampf(p,0,1))
  if n.begins_with("BridgeSupport"):
   part.visible=bridge and p>.001;part.scale.y=maxf(.001,p)
  if building_part(n):
   part.visible=width
   if n.begins_with("Enclosed") or n.begins_with("Roof_end_rail"):
    part.scale.z=lerpf(1.0,.62,p)
   else:
    # Equipment translates with the wall without shrinking windows or pipe diameters.
    var centre:Vector3=part.get_aabb().get_center()
    part.position.z+=centre.z*(lerpf(1.0,.62,p)-1.0)
  if n.begins_with("Forecastle"):part.visible=fc>.001
  for i in part.mesh.get_blend_shape_count():
   var key:=str(part.mesh.get_blend_shape_name(i))
   if key=="Superstructure":part.set_blend_shape_value(i,1.0 if width and building_part(n) else 0.0)
   if key=="Forecastle":part.set_blend_shape_value(i,fc)
 if scene.begins_with("free_"):bodies[0].position.y=-lerpf(8.0,12.0,clampf(p/3.,0,1))
 ink.hide();revision_ink.queue_redraw()
func bridge_eye()->Vector3:
 var eye:Array=architecture.bridge_eye
 return bodies[0].to_global(Vector3(eye[0],eye[2]-(float(architecture.cabin_base)-float(architecture.deck))*(1.-float(source_state.get("p",0))),0))
func set_camera(_preset:String,instant:=false)->void:
 if source_state.is_empty():super.set_camera(_preset,instant);return
 var scene:String=source_state.get("scene","")
 var target:=Vector3(0,0,0);var offset:=Vector3(100,80,-180);var span:=150.
 if scene=="bridge":target=Vector3(-67,12,0);offset=Vector3(50,30,-100);span=76.
 elif scene=="width":target=Vector3(-9,9,0);offset=Vector3(40,65,-80);span=78.
 elif scene=="forecastle":target=Vector3(76,7,0);offset=Vector3(50,30,-95);span=65.
 elif scene.begins_with("free_"):target=Vector3(0,1,0);offset=Vector3(0,30,-220);span=155.
 turn_target=target;camera_span=span;user_camera=false
 if camera_tween and camera_tween.is_valid():camera_tween.kill()
 var dest:=Transform3D(Basis.looking_at(-offset,Vector3.UP),target+offset)
 if instant:camera.transform=dest;camera.size=span;camera_motion=false;return
 var start:=camera.transform;var old_span:=camera.size;camera_motion=true
 camera_tween=create_tween();camera_tween.tween_method(func(t:float):camera.transform=start.interpolate_with(dest,t);camera.size=lerpf(old_span,span,t),0.,1.,.6)
 camera_tween.finished.connect(func():camera_motion=false)
func anchor()->Vector2:
 var scene:String=source_state.get("scene","")
 if scene=="bridge":return project(bridge_eye())
 var point:=Vector3(-10,20,0)
 if scene=="width":point=Vector3(-9,19,-12.9*lerpf(1.,.62,float(source_state.get("p",0))))
 elif scene=="forecastle":point=Vector3(75,16+5*float(source_state.get("p",0)),-7)
 elif scene.begins_with("free_"):point=Vector3(0,13,-13.4)
 return project(bodies[0].to_global(point))
func obstacles()->Array:
 return [Rect2(anchor()-Vector2(70,50),Vector2(140,100)),Rect2(24,110,size.x-48,80)]
