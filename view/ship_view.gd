extends SubViewportContainer
var viewport:SubViewport
var world:Node3D
var body:Node3D
var camera:Camera3D
var hull:MeshInstance3D
var deck:MeshInstance3D
var section_plane:MeshInstance3D
var base_plane:MeshInstance3D
var water:MeshInstance3D
var centre:MeshInstance3D
var points:Array[MeshInstance3D]=[]
var labels:Array[Label]=[]
var coordinate_labels:Array[Label]=[]
var label_points:Array[Vector3]=[]
var yaw:=.12
var pitch:=.45
var zoom:=1.0
var dragging:=false
var dims:=Vector3.ZERO
var current:Dictionary={}
var lang:="zh"
var font:SystemFont
var cargo_model:Node3D
var tanker_model:Node3D
var cargo_items:Array[Node3D]=[]
var cargo:Node3D
var cargo_lesson
var model_meshes:Array[MeshInstance3D]=[]
var highlight_material:StandardMaterial3D
var leaders:Control
var reading_space:=0.0
var dim_material:StandardMaterial3D
var camera_motion:=false
var camera_tween:Tween
var camera_mode:="overview"
var visibility_decision:="initial"
var camera_shift:=Vector3.ZERO
var highlight_clock:=0.0
var annotation_chunks:Dictionary={}
var model_environment:Environment
var key_light:DirectionalLight3D
var fill_light:DirectionalLight3D
var fuel_locations
var load_model:Node3D
var fuel_layout:Array=[]
var fuel_pair
var inspection_cuts:Array=[]
var loaded_model:=-1
var last_focus_zone:="__none"
var wet_material:ShaderMaterial
var approximation_flow
func _ready()->void:
	stretch=true;mouse_filter=Control.MOUSE_FILTER_STOP;clip_contents=true
	viewport=SubViewport.new();viewport.own_world_3d=true;viewport.transparent_bg=false;viewport.msaa_3d=Viewport.MSAA_8X;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport)
	world=Node3D.new();viewport.add_child(world);body=Node3D.new();world.add_child(body)
	var env:=WorldEnvironment.new();var e:=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("152c3e");e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color("ccdfea");e.ambient_light_energy=.65;e.tonemap_mode=Environment.TONE_MAPPER_FILMIC;env.environment=e;world.add_child(env)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-55,-25,0);light.light_energy=1.2;world.add_child(light)
	var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-25,140,0);fill.light_energy=.7;world.add_child(fill)
	model_environment=e;key_light=light;fill_light=fill
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.far=2000;world.add_child(camera)
	cargo_model=Node3D.new();body.add_child(cargo_model)
	tanker_model=Node3D.new();body.add_child(tanker_model)
	load_model=Node3D.new();body.add_child(load_model)
	fuel_layout=JSON.parse_string(FileAccess.get_file_as_string("res://assets/fuel-tanks.json")).fuel_tanks
	for i in 3:inspection_cuts.append(preload("res://view/inspection_cut.gd").new())
	highlight_material=material(Color(1,.70,.08));highlight_material.emission_enabled=true;highlight_material.emission=Color(.3,.12,.01)
	dim_material=material(Color(.09,.17,.23))
	water=preload("res://view/ocean.gd").create();world.add_child(water)
	section_plane=box(Vector3(.35,1,1),Color(1,.68,.1,.5));body.add_child(section_plane)
	base_plane=box(Vector3(1,.05,1),Color(.85,.25,.65,.45));body.add_child(base_plane)
	centre=sphere(1.4,Color("ffca72"));body.add_child(centre)
	font=SystemFont.new();font.font_names=PackedStringArray(["Segoe UI","Microsoft YaHei"])
	leaders=preload("res://view/annotation_lines.gd").new();add_child(leaders)
	approximation_flow=preload("res://view/approximation_flow.gd").new();approximation_flow.ship=self;add_child(approximation_flow)
	for i in range(13):
		var p:=sphere(.8,Color("79d4cb"));body.add_child(p);points.append(p)
	var cargo_scene:PackedScene=load("res://assets/steel_cargo.glb")
	for i in range(5):
		var item:Node3D=cargo_scene.instantiate();body.add_child(item);cargo_items.append(item)
	cargo=cargo_items[4]
	cargo_lesson=preload("res://view/cargo_loading.gd").new();body.add_child(cargo_lesson);cargo_lesson.ship=self;cargo_lesson.hide()
	for i in range(13):
		var label:=Label.new();label.add_theme_font_override("font",font);label.add_theme_font_size_override("font_size",18);label.add_theme_color_override("font_color",Color("dcecf3"));label.add_theme_color_override("font_shadow_color",Color("102331"));label.add_theme_constant_override("shadow_offset_x",1);label.add_theme_constant_override("shadow_offset_y",1);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(label);labels.append(label);label_points.append(Vector3.ZERO)
	resized.connect(update_camera)
	for i in range(3):
		var label:=Label.new();label.add_theme_font_size_override("font_size",18);label.add_theme_color_override("font_color",Color("ffe095"));label.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(label);coordinate_labels.append(label);label.hide()
		var background:=StyleBoxFlat.new();background.bg_color=Color("12313e");background.content_margin_left=4;background.content_margin_right=4;background.content_margin_top=2;background.content_margin_bottom=2;label.add_theme_stylebox_override("normal",background)
	fuel_locations=preload("res://view/fuel_locations.gd").new();add_child(fuel_locations);fuel_locations.ship=self
	fuel_pair=preload("res://view/fuel_pair.gd").new();add_child(fuel_pair);fuel_pair.ship=self
func ensure_model(index:int)->void:
	if loaded_model==index:return
	var models:Array=[cargo_model,tanker_model,load_model]
	if loaded_model>=0:
		for child in models[loaded_model].get_children():models[loaded_model].remove_child(child);child.queue_free()
		inspection_cuts[loaded_model]=preload("res://view/inspection_cut.gd").new()
	model_meshes.clear();annotation_chunks.clear();last_focus_zone="__none"
	var paths:Array=["res://assets/cargo_ship.glb","res://assets/tanker_learning.glb","res://assets/load_fuel_ship.glb"]
	var model=load(paths[index]).instantiate();models[index].add_child(model);collect_meshes(model)
	inspection_cuts[index].attach(models[index]);loaded_model=index
func collect_meshes(node:Node)->void:
	if node is MeshInstance3D:
		model_meshes.append(node)
		# glTF extras are not consistently promoted to Godot node metadata.
		# These stable names are authored by adapt_ship.py before export.
		node.set_meta("zone",str(node.name).get_slice("_",0))
		node.set_meta("near_side","_near_" in str(node.name))
		node.set_meta("cutaway_hide","_cover" in str(node.name))
		node.set_meta("rest_position",node.position)
		# Exported meshes combine distant parts (e.g. every crane). Split their
		# triangles into local cells so a single AABB cannot mask empty sky.
		var chunks:Dictionary={}
		for surface in range(node.mesh.get_surface_count()):
			var arrays:Array=node.mesh.surface_get_arrays(surface)
			var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			var count:int=indices.size() if not indices.is_empty() else vertices.size()
			for j in range(0,count,3):
				var a:Vector3=vertices[indices[j] if not indices.is_empty() else j]
				var b:Vector3=vertices[indices[j+1] if not indices.is_empty() else j+1]
				var c:Vector3=vertices[indices[j+2] if not indices.is_empty() else j+2]
				var cell:=Vector3i(((a+b+c)/6).floor())
				var bounds:=AABB(a,Vector3.ZERO).expand(b).expand(c)
				chunks[cell]=chunks[cell].merge(bounds) if chunks.has(cell) else bounds
		annotation_chunks[node]=chunks.values()
	for child in node.get_children():collect_meshes(child)
func material(c:Color)->StandardMaterial3D:
	var m:=StandardMaterial3D.new();m.albedo_color=c;m.roughness=.8;m.cull_mode=BaseMaterial3D.CULL_DISABLED
	if c.a<1:m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	return m
func box(size3:Vector3,c:Color)->MeshInstance3D:
	var node:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=size3;node.mesh=mesh;node.material_override=material(c);return node
func sphere(radius:float,c:Color)->MeshInstance3D:
	var node:=MeshInstance3D.new();var mesh:=SphereMesh.new();mesh.radius=radius;mesh.height=radius*2;node.mesh=mesh;node.material_override=material(c);node.material_override.no_depth_test=true;node.material_override.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;node.material_override.render_priority=10;return node
func hull_shape(length:float,beam:float,height:float)->ArrayMesh:
	# Open near side exposes mass locations. Illustrative shell, never a hydrostatic solver.
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(24):
		var u:=float(i)/24;var v:=float(i+1)/24
		var w1:=pow(sin(PI*u),.35)*beam*.5;var w2:=pow(sin(PI*v),.35)*beam*.5
		var x1:=(u-.5)*length;var x2:=(v-.5)*length
		var a:=Vector3(x1,height,-w1);var b:=Vector3(x2,height,-w2);var c:=Vector3(x2,0,0);var d:=Vector3(x1,0,0)
		for vertex in [a,b,c,a,c,d]:st.add_vertex(vertex)
		var aa:=Vector3(x1,height*.12,w1*.4);var bb:=Vector3(x2,height*.12,w2*.4)
		for vertex in [d,c,bb,d,bb,aa]:st.add_vertex(vertex)
	st.generate_normals();return st.commit()
func set_state(params:Dictionary,values:Dictionary,language:String)->void:
	if not is_node_ready():return
	current=params;lang=language
	var tanker:bool=params.get("scene","load")=="tanker"
	ensure_model(2 if params.get("load_vessel",false) else (1 if tanker else 0))
	# Keep the tanker's deck pipes readable instead of washing out their materials.
	model_environment.ambient_light_energy=.3 if tanker else .65
	key_light.light_energy=.7 if tanker else 1.2
	fill_light.light_energy=.3 if tanker else .7
	var length:float=values.L if tanker else 150.0;var beam:float=values.B if tanker else 25.0;var height:float=values.H if tanker else 17.0
	var draft:float=values.T if tanker else float(params.get("draft",10.0))
	var dimensions:=Vector3(length,beam,height)
	if dimensions.distance_to(dims)>.00001:
		dims=dimensions
		cargo_model.scale=Vector3(length/78.0,height/7.5,beam/12.6)
		# The tanker is authored in metres at the adopted Т2 dimensions.
		tanker_model.scale=Vector3(length/189.64,height/14.89,beam/26.60)
		water.set_extent(length*2.1,beam*8.0)
	section_plane.visible=params.get("section_plane",false)
	base_plane.visible=params.get("base_plane",false);base_plane.scale=Vector3(length*1.15,1,beam*1.65)
	var section_height:float=height*1.15*clampf(float(params.get("b01_reveal",1)),.01,1)
	section_plane.scale=Vector3(1,section_height,beam*1.25);section_plane.position=Vector3(0,section_height*.5,0)
	var load_vessel:bool=params.get("load_vessel",false)
	cargo_model.visible=not tanker and not load_vessel;tanker_model.visible=tanker;load_model.visible=load_vessel
	var cut:float=float(params.get("cutaway_amount",1.0 if params.get("show_load",false) else 0.0))
	water.teaching(length,beam,cut)
	var focus_zone:String=params.get("part_focus","")
	if focus_zone=="Wet":
		water.teaching(length,beam,1.0)
		if wet_material==null:
			wet_material=ShaderMaterial.new();wet_material.shader=preload("res://view/wet_surface.gdshader")
		wet_material.set_shader_parameter("water_height",draft)
		wet_material.set_shader_parameter("reveal",float(params.get("approx_reveal",1)))
	inspection_cuts[0].window(cut,0,23,.10,7.35)
	inspection_cuts[1].window(cut,6,44,.15,14.7)
	var fuel_x:=0.0;var fuel_span:=48.0
	if params.get("fuel_detail",false):
		var idx:int=clampi(int(params.get("fuel_index",0)),0,8)
		fuel_x=float(fuel_layout[idx].x_m)-75.0 if fuel_layout[idx].has("x_m") else float(values.display_rows[idx][3])-75.0
		fuel_span=14.0
	inspection_cuts[2].window(cut,fuel_x,fuel_span,.05,10.0)
	if focus_zone!=last_focus_zone:
		last_focus_zone=focus_zone
		var zones:Array=[]
		if focus_zone=="Steel":zones=["Hull","Decks","Bulkheads","Frames","DoubleBottom","Forecastle"]
		if focus_zone=="Equipment":zones=["Piping","Pumps","Manifold","FireSystem","HoseCranes","Mooring","Vents","Survival"]
		inspection_cuts[loaded_model].highlight_zones(zones)
		for mesh in model_meshes:
			var zone:String=mesh.get_meta("zone","")
			var selected:bool=zone==focus_zone and focus_zone in ["Hull","Decks","Bulkheads"]
			mesh.material_overlay=wet_material if focus_zone=="Wet" and zone=="Hull" else (highlight_material if selected else null)
	water.position.y=draft;water.visible=params.get("water",true)
	var show_load:bool=params.get("show_load",false)
	for i in range(points.size()):
		points[i].visible=show_load and i<values.display_rows.size()
		if params.get("focus_only",false) and i!=int(params.get("focus",-1)):points[i].visible=false
		if i>=values.display_rows.size():continue
		var row:Array=values.display_rows[i];points[i].position=Vector3(row[3]-length*.5,row[2],0)
		if params.get("show_fuel",false) and load_vessel:points[i].position.z=-float(fuel_layout[i].y_display_m)
		var focused:int=int(params.get("fuel_index",-1)) if params.get("show_fuel",false) else int(params.get("focus",-1))
		points[i].scale=Vector3.ONE*(1.6 if focused==i else 1.0)
	for i in range(5):
		var row_index:int=i+1
		var item:Node3D=cargo_items[i]
		item.visible=show_load and not params.get("show_fuel",false) and points[row_index].visible and values.display_rows[row_index][1]>0
		item.position=points[row_index].position
		if not params.get("show_fuel",false):points[row_index].hide()
	if params.get("show_fuel",false):
		# The overlay marks exact centres; large spheres obscure the shallow tanks.
		for p in points:p.hide()
	centre.position=Vector3(values.display_xG-length*.5,values.display_zG,0);centre.visible=show_load and params.get("show_centre",true)
	if params.get("merge_visible",false):centre.visible=false
	centre.scale=Vector3.ONE*(.35 if params.get("cargo_detail",false) else 1.0)
	var specs:Array=[
		["艉","Корма́",Vector3(-length*.49,height*.65,0)],
		["艏","Нос",Vector3(length*.49,height*.95,0)],
		["L","L",Vector3(0,-5,0)],
		["B","B",Vector3(length*.18,height+2,beam*.48)],
		["H","H",Vector3(-length*.42,height*.5,beam*.65)],
		["T","T",Vector3(length*.38,draft*.5,beam*.65)],
		["G","G",centre.position],
		["甲板","Па́луба",Vector3(-length*.10,height,beam*.38)],
		["水线","Ватерли́ния",Vector3(length*.27,draft,beam*.49)],
		["船壳","Обши́вка",Vector3(-length*.08,height*.4,beam*.49)],
		["舱壁","Перебо́рка",Vector3(-length*.5/78,height*.7,-beam*.1)],
		["100 t","100 т",points[5].position],
		["基线  z = 0","Основна́я ли́ния  z = 0",Vector3(-length*.30,0,beam*.65)]]
	for i in range(labels.size()):
		labels[i].text=specs[i][0 if lang=="zh" else 1];label_points[i]=specs[i][2];labels[i].visible=(i!=6 or centre.visible)
		if i in [2,3,4,5] and params.get("scene","")=="tanker":labels[i].text+="₁"
		if i in [2,3,4,5] and params.has("approximation"):
			var symbol:String=["L","B","H","T"][i-2]
			var value:float=[length,beam,height,draft][i-2]
			labels[i].text=symbol+("₃" if float(params.get("approx_scale",0))>0 else "₂")+" = %.2f m"%value
		if i in [2,3,4,5]:labels[i].visible=params.get("dimensions",false)
		if i==7:labels[i].visible=not show_load
		var focus:String=params.get("part_focus","")
		if not focus.is_empty() and i in [7,8]:labels[i].visible=i==7 and focus=="Decks"
		if i==9:labels[i].visible=focus=="Hull"
		if i==10:labels[i].visible=focus=="Bulkheads"
		if i==11:labels[i].visible=show_load and params.get("focus_only",false) and not params.get("show_fuel",false) and int(params.get("focus",-1))==5
		if i==8 and show_load:labels[i].visible=false
		if params.get("cargo_detail",false) and i in [0,1,7,8,9,10]:labels[i].hide()
		if i==12:labels[i].visible=params.get("baseline_mode",false)
		if params.get("baseline_mode",false):labels[i].visible=i in [8,12]
		if params.get("cargo_lesson",false):labels[i].hide()
		if params.get("plane_focus",false):labels[i].hide()
		if params.get("show_fuel",false) and i not in [6]:labels[i].hide()
		if params.get("liquid_focus",false):labels[i].hide()
	body.rotation.x=deg_to_rad(float(params.get("roll",0)))
	cargo_lesson.apply(params,values,language)
	update_camera()
func set_reading_space(value:float)->void:
	if absf(reading_space-value)<.5:return
	reading_space=value;update_camera()
func lesson_anchor(kind:String)->Vector2:
	if current.get("cargo_lesson",false):return cargo_lesson.project(cargo_lesson.active_point)
	return camera.unproject_position(body.to_global(lesson_point(kind)))*size/Vector2(viewport.size)
func lesson_point(kind:String)->Vector3:
	var point:=Vector3(0,dims.z,0)
	match kind:
		# Mark the exposed near-side part of z=0, not the deck or a hidden
		# point beneath the opaque hull. Godot y is the ship's vertical z.
		"base_plane":point=Vector3(-dims.x*.12,0,dims.y*.72)
		"bow":point=label_points[1]
		"stern":point=label_points[0]
		"hull":point=label_points[9]
		"deck":point=label_points[7]
		"bulkheads":point=label_points[10]
		"water":point=label_points[8]
		"liquid":point=Vector3(0,6.55,5.45)
		"centre":point=centre.position
		"pair":point=pair_centre()
		"load":
			var index:int=int(current.get("fuel_index",0)) if current.get("show_fuel",false) else int(current.get("focus",5))
			point=points[clampi(index,0,points.size()-1)].position
	if current.get("baseline_mode",false):
		var level:String=current.get("measure_kind","")
		point=Vector3(-dims.x*.27,0,dims.y*.65)
		if not level.is_empty():point=Vector3(dims.x*.30,(water.position.y if level=="T" else dims.z)*.5,dims.y*.65)
	return point
func pair_centre()->Vector3:
	var p1:float=float(fuel_layout[0].mass_t);var p2:float=float(fuel_layout[1].mass_t)
	return (points[0].position*p1+points[1].position*p2)/(p1+p2)
func projected_box(bounds:AABB,transform3:Transform3D)->Rect2:
	var rect:=Rect2(camera.unproject_position(transform3*bounds.position),Vector2.ZERO)
	for i in range(8):rect=rect.expand(camera.unproject_position(transform3*bounds.get_endpoint(i)))
	return rect.intersection(Rect2(Vector2.ZERO,size))
func annotation_obstacles()->Array:
	var regions:Array=[]
	if fuel_locations!=null and fuel_locations.visible:regions.append_array(fuel_locations.occupied)
	if fuel_pair!=null and fuel_pair.visible:regions.append_array(fuel_pair.occupied)
	if current.get("cargo_lesson",false):regions.append_array(cargo_lesson.obstacles())
	# Mesh rectangles reserve the actual projected silhouette, including masts.
	for mesh in model_meshes:
		if not mesh.is_visible_in_tree():continue
		for bounds in annotation_chunks[mesh]:
			var rect:=projected_box(bounds,mesh.global_transform)
			if current.get("part_focus","")=="Bulkheads" and (mesh.get_meta("near_side",false) or mesh.get_meta("cutaway_hide",false)):
				var future:Transform3D=mesh.global_transform
				var lift:=Vector3(0,4,0) if mesh.get_meta("cutaway_hide",false) else Vector3(0,0,6)
				future.origin+=mesh.get_parent().global_transform.basis*lift
				rect=rect.merge(projected_box(bounds,future))
			if rect.has_area():regions.append(rect)
	for label in labels+coordinate_labels:
		if label.visible:regions.append(Rect2(label.position,label.get_minimum_size()).grow(10))
	for segment in leaders.segments:
		regions.append(Rect2(segment[0],Vector2.ZERO).expand(segment[1]).grow(5))
	# Future measurement endpoints are reserved before line-reveal starts.
	if current.get("baseline_mode",false):
		for height in [0.0,water.position.y,dims.z]:
			var a:=Vector3(-dims.x*.52,height,dims.y*.65)
			var b:=Vector3(dims.x*.52,height,dims.y*.65)
			regions.append(projected_box(AABB(a,b-a),body.global_transform).grow(12))
		var base:=camera.unproject_position(Vector3(dims.x*.30,0,dims.y*.65))
		var top:=camera.unproject_position(Vector3(dims.x*.30,dims.z,dims.y*.65))
		regions.append(Rect2(base,Vector2.ZERO).expand(top).grow(45))
		var baseline_label:=camera.unproject_position(Vector3(-dims.x*.27,0,dims.y*.65))+Vector2(-145,12)
		regions.append(Rect2(baseline_label,Vector2(290,48)))
	if current.get("dimensions",false):
		var endpoints:Array=[
			[Vector3(-dims.x*.5,-2,dims.y*.65),Vector3(dims.x*.5,-2,dims.y*.65)],
			[Vector3(dims.x*.22,dims.z+2,-dims.y*.5),Vector3(dims.x*.22,dims.z+2,dims.y*.5)],
			[Vector3(-dims.x*.53,0,dims.y*.65),Vector3(-dims.x*.53,dims.z,dims.y*.65)],
			[Vector3(dims.x*.53,0,dims.y*.65),Vector3(dims.x*.53,water.position.y,dims.y*.65)]]
		for line in endpoints:
			var a:=camera.unproject_position(body.to_global(line[0]))
			var b:=camera.unproject_position(body.to_global(line[1]))
			regions.append(Rect2(a,Vector2.ZERO).expand(b).grow(30))
	if current.get("cargo_detail",false):
		# Entire cargo travel (x: 0..12 m, z: 0..-6 m) plus the G marker.
		var rest:Vector3=cargo.position-Vector3(float(current.get("move_x",0)),float(current.get("move_z",0)),0)
		regions.append(projected_box(AABB(rest+Vector3(-6,-7,-3),Vector3(25,11,6)),body.global_transform).grow(14))
	return regions
func update_camera()->void:
	if approximation_flow:approximation_flow.size=size;approximation_flow.queue_redraw()
	if camera==null or dims==Vector3.ZERO:return
	var target:=Vector3(0,dims.z*.85,0)
	if current.get("show_fuel",false):target=Vector3(0,dims.z*.35,0)
	var detail:bool=current.get("cargo_detail",false)
	if detail:target=Vector3(cargo.position.x-float(current.get("move_x",0)),dims.z*1.13,0)
	var fuel_detail:bool=current.get("show_fuel",false) and current.get("fuel_detail",false)
	var fuel_point:Vector3=points[clampi(int(current.get("fuel_index",0)),0,8)].position
	if fuel_detail:target=fuel_point+Vector3(0,2,0)
	if current.get("pair_lesson",false):target=Vector3(0,0,0)
	camera.position=target+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*300
	camera.look_at(target,Vector3.UP)
	camera.position+=camera_shift
	var aspect:float=maxf(size.x,1)/maxf(size.y,1)
	var fraction:float=maxf(.28,(size.y-reading_space-12)/maxf(size.y,1))
	camera.size=maxf(dims.x/maxf(aspect,.4)*1.14,dims.z*3.0/fraction)/zoom
	if detail:camera.size=maxf(52/maxf(aspect,.4),38/fraction)/zoom
	if fuel_detail:camera.size=maxf((53 if int(current.get("fuel_index",0))<5 else 32)/maxf(aspect,.4),32/fraction)/zoom
	if current.get("pair_lesson",false):camera.size=maxf(174/maxf(aspect,.4),62/fraction)/zoom
	camera.v_offset=camera.size*reading_space/(2*maxf(size.y,1))
	leaders.size=size;leaders.segments.clear();leaders.measures.clear();leaders.reference_lines.clear()
	for label in coordinate_labels:label.hide()
	if current.get("coordinate_lines",false):
		var index:int=int(current.get("fuel_index",0)) if current.get("show_fuel",false) else int(current.get("focus",0))
		var point:Vector3=points[clampi(index,0,points.size()-1)].position
		var origin:=Vector3(-dims.x*.5,0,point.z);var foot:=Vector3(point.x,0,point.z)
		var projected:Array=[camera.unproject_position(body.to_global(origin)),camera.unproject_position(body.to_global(foot)),camera.unproject_position(body.to_global(point))]
		leaders.reference_lines.append([projected[0],projected[1],Color("ffe095"),3.0])
		leaders.reference_lines.append([projected[1],projected[2],Color("ff8dc8"),3.0])
		var names:Array=["O",("x = %.2f m"%(point.x+dims.x*.5)),("z = %.2f m"%point.y)]
		var anchors:Array=[projected[0]+Vector2(-10,14),(projected[0]+projected[1])*.5+Vector2(0,16),projected[2]+Vector2(14,-30)]
		if current.get("show_fuel",false):anchors[2]=(projected[1]+projected[2])*.5+Vector2(18,36 if point.y<2 else -8)
		for i in range(3):
			coordinate_labels[i].show();coordinate_labels[i].text=names[i].replace(".",",") if lang=="ru" else names[i]
			coordinate_labels[i].position=anchors[i].clamp(Vector2(8,8),size-Vector2(120,36))
		if fuel_detail:
			# The AP can be outside a close-up. Never clamp an O label to a false origin.
			coordinate_labels[0].hide();leaders.reference_lines.pop_front()
			coordinate_labels[1].position=(projected[1]+Vector2(-118,18)).clamp(Vector2(8,8),size-Vector2(120,36))
			coordinate_labels[1].hide() # Full source x span is retained in the locator.
	if current.get("dimensions",false):
		var length:float=dims.x;var beam:float=dims.y;var height:float=dims.z;var draft:float=water.position.y
		var endpoints:Array=[
			[Vector3(-length*.5,-2,beam*.65),Vector3(length*.5,-2,beam*.65)],
			[Vector3(length*.22,height+2,-beam*.5),Vector3(length*.22,height+2,beam*.5)],
			[Vector3(-length*.53,0,beam*.65),Vector3(-length*.53,height,beam*.65)],
			[Vector3(length*.53,0,beam*.65),Vector3(length*.53,draft,beam*.65)]]
		# Reserve room for the complete dimension lines, even before their reveal.
		var screen_centre:=Vector2(size.x*.5,(size.y+reading_space)*.5)
		var room:=Vector2(maxf(size.x*.5-36,1),maxf((size.y-reading_space)*.5-36,1))
		var fit_scale:float=1.0
		for pair in endpoints:
			for endpoint in pair:
				var distance:Vector2=(camera.unproject_position(body.to_global(endpoint))-screen_centre).abs()
				fit_scale=maxf(fit_scale,maxf(distance.x/room.x,distance.y/room.y))
		camera.size*=fit_scale
		camera.v_offset=camera.size*reading_space/(2*maxf(size.y,1))
		var reveal:float=float(current.get("dimension_reveal",1.0))
		for i in range(4):
			if not current.get("dimension_kind","").is_empty() and current.dimension_kind!=["L","B","H","T"][i]:labels[i+2].hide();continue
			var a:Vector3=endpoints[i][0];var b:Vector3=endpoints[i][1]
			label_points[i+2]=(a+b)*.5;labels[i+2].visible=reveal>.95
			leaders.measures.append([camera.unproject_position(body.to_global(a)),camera.unproject_position(body.to_global(a.lerp(b,reveal)))])
	if current.get("baseline_mode",false):
		var a:=Vector3(-dims.x*.52,0,dims.y*.65);var b:=Vector3(dims.x*.52,0,dims.y*.65)
		var progress:float=float(current.get("baseline_reveal",0))
		leaders.reference_lines.append([camera.unproject_position(a),camera.unproject_position(a.lerp(b,progress)),Color("ff8dc8"),4.5])
		labels[12].visible=progress>.05;label_points[12]=a.lerp(b,.24)
		var level:String=current.get("measure_kind","")
		var measure:float=float(current.get("draft_measure" if level=="T" else "depth_measure",0))
		if not level.is_empty():
			var base:=Vector3(dims.x*.30,0,dims.y*.65)
			var end:=Vector3(base.x,water.position.y if level=="T" else dims.z,base.z)
			leaders.reference_lines.append([camera.unproject_position(base),camera.unproject_position(base.lerp(end,measure)),Color("ffe26c"),4.5])
			var li:int=5 if level=="T" else 4;labels[li].visible=measure>.05;label_points[li]=base.lerp(end,measure*.5)
			var left:=Vector3(-dims.x*.48,end.y,base.z);var right:=Vector3(dims.x*.48,end.y,base.z)
			leaders.reference_lines.append([camera.unproject_position(left),camera.unproject_position(right),Color("77dfde"),2.5])
	for i in range(labels.size()):
		var screen:Vector2=camera.unproject_position(body.to_global(label_points[i]))
		var offset:=Vector2(0,-42)
		if i in [8,9]:offset=Vector2(20,34)
		if i==6:offset=Vector2(-42,28)
		if i==11:offset=Vector2(38,-28)
		if current.get("baseline_mode",false):
			if i==12:offset=Vector2(0,32)
			elif i in [4,5]:offset=Vector2(34,0)
			elif i==8:offset=Vector2(-80,-32)
		labels[i].position=(screen+offset-Vector2(labels[i].get_minimum_size().x*.5,16)).clamp(Vector2(8,8),Vector2(maxf(size.x-labels[i].get_minimum_size().x-8,8),maxf(size.y-30,8)))
		if labels[i].visible:leaders.segments.append([screen,labels[i].position+labels[i].get_minimum_size()*.5])
	leaders.queue_redraw()
	if cargo_lesson!=null:cargo_lesson.update_overlay()
	if fuel_locations!=null:fuel_locations.refresh()
	if fuel_pair!=null:fuel_pair.refresh()
func snapshot()->Dictionary:return {"yaw":yaw,"pitch":pitch,"zoom":zoom,"shift":camera_shift}
func cancel_camera()->void:
	if camera_tween and camera_tween.is_valid():camera_tween.kill()
	camera_motion=false
func teach_view(view:String,done:Callable=Callable())->void:
	cancel_camera();camera_mode=view
	var presets:Dictionary={"overview":Vector3(-.48,.40,1),"hull":Vector3(0,.17,1),"deck":Vector3(-.15,1.02,1),"cutaway":Vector3(.48,.48,1),"base_plane":Vector3(.20,.38,.9),"baseline":Vector3(0,.025,1),"cargo":Vector3(-.32,.30,1),"cargo_loading":Vector3(-.30,.65,1.05),"dimensions":Vector3(-.30,.48,1)}
	presets["fuel"]=Vector3(.12,.66,1)
	presets["fuel_pair"]=Vector3(-.12,.44,1)
	var target:Vector3=presets.get(view,presets.overview);var start:=Vector3(yaw,pitch,zoom)
	camera_shift=Vector3.ZERO
	camera_motion=true;camera_tween=create_tween()
	camera_tween.tween_method(func(t:float):
		var v:Vector3=start.lerp(target,smoothstep(0,1,t));yaw=v.x;pitch=v.y;zoom=v.z;update_camera()
	,0.0,1.0,.65)
	camera_tween.finished.connect(func():
		camera_motion=false
		if done.is_valid():done.call())
func _process(delta:float)->void:
	highlight_clock+=delta
	if highlight_material!=null:highlight_material.emission_energy_multiplier=.7+.3*sin(highlight_clock*3)
func restore(value:Dictionary)->void:
	cancel_camera()
	camera_shift=value.get("shift",Vector3.ZERO);yaw=value.get("yaw",-.48);pitch=value.get("pitch",.40);zoom=value.get("zoom",1.0);dragging=false;update_camera()
func _gui_input(event:InputEvent)->void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:cancel_camera()
			dragging=event.pressed;accept_event()
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			zoom=clampf(zoom*(1.1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1/1.1),.6,2);update_camera();accept_event()
	if event is InputEventMouseMotion and dragging:
		yaw-=event.relative.x*.006;pitch=clampf(pitch+event.relative.y*.005,-1.52,1.52);update_camera();accept_event()
func _notification(what:int)->void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:dragging=false
