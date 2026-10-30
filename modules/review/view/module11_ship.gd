extends "res://modules/review/view/stability_ship.gd"
const Geometry=preload("res://modules/review/core/module11_math.gd")
var detailed:Node3D
var parts:Array=[]
var cuts
var lines_mesh:MeshInstance3D
var cap_mesh:MeshInstance3D
var source_state:Dictionary={}
var last_shape:Dictionary={}
var line_key:Dictionary={}
var ink:Control
var ocean_medium:Node
func model_path()->String:return "res://modules/review/assets/module11_ship.glb"
func _ready()->void:
	setup_world()
	var body:=Node3D.new();world.add_child(body);bodies.append(body)
	detailed=load(model_path()).instantiate();body.add_child(detailed);collect(detailed)
	cuts=preload("res://view/inspection_cut.gd").new();cuts.attach(detailed)
	var inspection_shader:=Shader.new();inspection_shader.code=cuts.materials[0].shader.code.replace("uniform bool lesson_highlight", "uniform bool m11_stern=false;\nuniform bool lesson_highlight").replace("bool window=cut", "if(m11_stern && p.y>7.3)discard;\n bool window=cut")
	inspection_shader.code=inspection_shader.code.replace("uniform bool lesson_highlight", "uniform bool show_bulb=false;\nuniform bool lesson_highlight").replace("if(lesson_highlight)","if(lesson_highlight || (show_bulb && p.x>80.0 && p.y<6.8))")
	for mat in cuts.materials:mat.shader=inspection_shader
	lines_mesh=MeshInstance3D.new();body.add_child(lines_mesh)
	var m:=StandardMaterial3D.new();m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;m.albedo_color=Color("ffd078");m.no_depth_test=true;lines_mesh.material_override=m
	cap_mesh=MeshInstance3D.new();body.add_child(cap_mesh)
	var cm:=StandardMaterial3D.new();cm.albedo_color=Color(.75,.57,.28,.74);cm.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;cm.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;cm.cull_mode=BaseMaterial3D.CULL_DISABLED;cap_mesh.material_override=cm
	water=preload("res://view/ocean.gd").create();world.add_child(water)
	ocean_medium=preload("res://modules/review/view/ocean_medium.gd").new();add_child(ocean_medium);ocean_medium.setup(self,water,true)
	ink=Control.new();ink.set_script(preload("res://modules/review/view/module11_overlay.gd"));ink.view=self;add_child(ink);ink.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_camera("overview",true)
func collect(node:Node)->void:
	if node is MeshInstance3D:parts.append(node)
	for child in node.get_children():collect(child)
func apply(value:Dictionary,lang:String,_evaluation:Dictionary={})->void:
	source_state=value.duplicate(true);language=lang
	var shape:Dictionary={}
	for pair in [["bilge","Bilge"],["waterline","Waterline"],["bow_v","BowV"],["flare","Flare"],["bulb","Bulb"],["closed_stern","ClosedStern"]]:shape[pair[1]]=float(value.get(pair[0],0))
	shape.WaterlineStraight=clampf(1.-absf(2.*float(value.get("waterline",0))-1.),0.,1.)
	shape.Waterline=maxf(0.,2.*float(value.get("waterline",0))-1.)
	if shape!=last_shape:
		last_shape=shape
		for part:MeshInstance3D in parts:
			for i in part.mesh.get_blend_shape_count():part.set_blend_shape_value(i,shape.get(str(part.mesh.get_blend_shape_name(i)),0.0))
	for p:MeshInstance3D in parts:
		var n:=str(p.name)
		p.visible=n.begins_with("Continuous") or n.begins_with("Original") or n.begins_with("M11")
	bodies[0].scale=Vector3(float(value.get("scale_l",1)),float(value.get("scale_t",1)),float(value.get("scale_b",1)))
	bodies[0].position=Vector3(0,-10.88*float(value.get("scale_t",1)),0)
	# Small detailed equipment is retained at installation points; the authored model
	# shapes keep compact objects rigid under local deformation.
	var phase:String=value.get("phase","overview")
	var section_mode:bool=phase in ["midship","bowsection","stern"]
	var centre:float=-1.59 if phase=="midship" else (-78. if phase=="stern" else 70.)
	cuts.parameters({"section_view":section_mode,"centre":centre,"section_depth":26. if phase=="stern" else 12.,"m11_stern":phase=="stern","show_bulb":phase=="bulb" and float(value.get("bulb",0))>0.01})
	water.teaching(210.,35.,1.0 if phase in ["midship","bowsection","bulb","stern"] else 0.)
	water.material_override.set_shader_parameter("lesson_centre",Vector2(centre if phase in ["midship","bowsection"] else (-95. if phase=="stern" else 90.),0))
	water.material_override.set_shader_parameter("lesson_size",Vector2(20,25))
	update_lines();ink.queue_redraw()
func update_lines()->void:
	if line_key==source_state:return
	line_key=source_state.duplicate(true)
	var s:=source_state.duplicate(true);s.scale_l=1.;s.scale_b=1.;s.scale_t=1.
	var phase:String=s.get("phase","");var d:=Geometry.geometry();var v:=Geometry.vertices(s);var n:int=d.ring_size
	var array:=PackedVector3Array()
	if float(s.get("lines",0))>0:
		for level in [3.,6.,10.88,14.]:
			for side in [-1,1]:
				var prev:=Vector3.ZERO;var found:=false
				for i in int(d.ring_count):
					var r:Array=v.slice(i*n,(i+1)*n)
					for j in n:
						var a:Vector3=r[j];var b:Vector3=r[(j+1)%n]
						if (a.y<level)!=(b.y<level):
							var p:Vector3=a.lerp(b,(level-a.y)/(b.y-a.y))
							if p.z*side<0:continue
							if found:array.append(prev);array.append(p)
							prev=p;found=true
	var idx:=24 if phase=="midship" else 42
	if float(s.get("station",0))>0 or phase in ["lines","drawing","affine"]:
		for ring_idx in ([idx] if phase in ["midship","bowsection"] else [8,16,24,32,40,44]):
			var poly:Array=Geometry.section(s,-1.59 if phase=="midship" else 70.) if phase in ["midship","bowsection"] else v.slice(ring_idx*n,(ring_idx+1)*n)
			for j in poly.size():array.append(poly[j]);array.append(poly[(j+1)%poly.size()])
	lines_mesh.visible=not array.is_empty()
	if not array.is_empty():
		var a:Array=[];a.resize(Mesh.ARRAY_MAX);a[Mesh.ARRAY_VERTEX]=array;var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES,a);lines_mesh.mesh=mesh
	cap_mesh.visible=phase in ["midship","bowsection"]
	if cap_mesh.visible:
		var poly:Array=Geometry.submerged(Geometry.section(s,-1.59 if phase=="midship" else 70.),10.88)
		var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		# Ring 42 is projected to the actual clipping plane for the observation window.
		var centre:float=-1.59 if phase=="midship" else 70.
		var middle:=Vector3(centre+.015,5,0)
		for j in poly.size():
			st.add_vertex(middle)
			for k in [j,(j+1)%poly.size()]:var p:Vector3=poly[k];p.x=centre+.015;st.add_vertex(p)
		st.generate_normals();cap_mesh.mesh=st.commit()
func set_camera(_preset:String,instant:=false)->void:
	var phase:String=source_state.get("phase","overview")
	var target:=Vector3(0,0,0);var eye:=Vector3(135,95,-170);var span:=170.;var up:=Vector3.UP
	if phase=="midship":target=Vector3(-1.59,-4,0);eye=target+Vector3(120,8,-5);span=37.
	elif phase=="bowsection":target=Vector3(70,-4,0);eye=target+Vector3(120,8,-5);span=38.
	elif phase=="waterline":target=Vector3(58,-4,0);eye=target+Vector3(0,170,.01);up=Vector3(1,0,0);span=105.
	elif phase=="bulb":target=Vector3(83,-4,0);eye=target+Vector3(50,22,-65);span=55.
	elif phase=="stern":target=Vector3(-86,-4,0);eye=target+Vector3(-35,18,-65);span=48.
	turn_target=target;camera_span=span;last_camera=phase;user_camera=false
	if camera_tween and camera_tween.is_valid():camera_tween.kill()
	var dest:=Transform3D(Basis.looking_at(target-eye,up),eye)
	if instant:camera.transform=dest;camera.size=span;camera_motion=false;return
	var from:=camera.transform;var old_span:=camera.size;camera_motion=true
	camera_tween=create_tween();camera_tween.tween_method(func(t:float):camera.transform=from.interpolate_with(dest,t);camera.size=lerpf(old_span,span,t),0.,1.,.6)
	camera_tween.finished.connect(func():camera_motion=false)
func update_overlay()->void:
	if ink:ink.queue_redraw()
func anchor()->Vector2:
	var p:=Vector3(0,7,0)
	match source_state.get("phase",""):
		"midship":p=Vector3(-1.59,4,-8)
		"bowsection":p=Vector3(70,4,-5)
		"waterline":p=Vector3(78,10.88,-4)
		"bulb":p=Vector3(94,3.4,0)
		"stern":p=Vector3(-95,3.,0)
	return project(bodies[0].to_global(p)).clamp(Vector2(20,20),size-Vector2(20,20))
func obstacles()->Array:
	var result:Array=ink.bounds.duplicate() if ink else []
	var phase:String=source_state.get("phase","")
	var low:=Vector3.ZERO;var high:=Vector3.ZERO
	if phase in ["midship","bowsection"]:
		var x:float=-1.59 if phase=="midship" else 70.
		low=Vector3(x,0,-15);high=Vector3(x,15.8,15)
	elif phase=="stern":low=Vector3(-103,.2,-4);high=Vector3(-85,7.3,4)
	elif phase=="bulb":low=Vector3(82,0,-4);high=Vector3(102,8,4)
	elif phase=="waterline":low=Vector3(58,10.88,-12);high=Vector3(99,10.88,12)
	else:return result
	var rect:=Rect2(project(bodies[0].to_global(low)),Vector2.ZERO)
	for x in [low.x,high.x]:
		for y in [low.y,high.y]:
			for z in [low.z,high.z]:rect=rect.expand(project(bodies[0].to_global(Vector3(x,y,z))))
	result.append(rect.grow(16));return result
