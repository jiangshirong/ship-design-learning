extends Control
signal wall_moved(frame:float)
const M=preload("res://core/bulkhead_math.gd")
var viewport:SubViewport
var camera:Camera3D
var scene:Node3D
var near_shell:Node3D
var hull:Node3D
var section_outline:Node3D
var overlay:Control
var ribs:Array=[]
var walls:Array=[]
var temporary:MeshInstance3D
var bottom:Node3D
var sides:Array=[]
var longitudinal:Node3D
var fittings:Node3D
var deck:Node3D
var state:Dictionary={}
var beat:Dictionary={}
var language:="zh"
var camera_tween:Tween
var dragging:=false
var orbiting:=false
var preview_frame:=60
var interactive:=false
var focus:=Vector3(94.565,7,0)
var eye:=Vector3(180,120,190)
var extent:=220.0
var visibility_decision:="initial"
var candidates:Array=[58,60,61]
var detailed:Node3D
var inspection=preload("res://view/inspection_cut.gd").new()
var section_parts:Node3D
var region_preview:=false
var region_frames:=Vector2i(85,89)
var section_cut=preload("res://view/inspection_cut.gd").new()
func material(color:Color)->StandardMaterial3D:
	var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=.7;m.cull_mode=BaseMaterial3D.CULL_DISABLED
	return m
func box(parent:Node3D,at:Vector3,dimensions:Vector3,color:Color)->MeshInstance3D:
	var mesh:=BoxMesh.new();mesh.size=dimensions
	var node:=MeshInstance3D.new();node.mesh=mesh;node.material_override=material(color);node.name=str(parent.name)+"_detail_"+str(parent.get_child_count());parent.add_child(node);node.position=at;return node
func beam(parent:Node3D,a:Vector3,b:Vector3,width:float,color:Color)->void:
	var node:=box(parent,(a+b)*.5,Vector3(width,width,a.distance_to(b)),color)
	node.look_at_from_position((a+b)*.5,b,Vector3.UP if absf((b-a).normalized().y)<.98 else Vector3.RIGHT)
func half_width(x:float)->float:
	var local:float=(x-M.L*.5)*189.64/M.L
	var stations:Array=[[-98,.42],[-92,.66],[-80,.88],[-64,1],[-44,1],[40,1],[58,.93],[72,.78],[82,.55],[90,.27],[94.82,.012]]
	for i in range(stations.size()-1):
		if local>=stations[i][0] and local<=stations[i+1][0]:
			var t:float=(local-stations[i][0])/(stations[i+1][0]-stations[i][0]);t=t*t*(3-2*t)
			return M.B*.5*lerpf(stations[i][1],stations[i+1][1],t)
	return .1
func deck_height(x:float)->float:
	var local:float=(x-M.L*.5)*189.64/M.L
	return M.H+(1.1*pow(maxf(0,(local-53)/41.82),2)+.45*pow(maxf(0,(-local-68)/30),2))*M.H/14.89
func wall(x:float,color:Color)->MeshInstance3D:
	var points:=ring(x);var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [-.08,.08]:
		for j in range(1,points.size()-1):
			for index in [0,j,j+1]:st.add_vertex(points[index]-Vector3(x-side,0,0))
	for j in points.size():
		var a:Vector3=points[j]-Vector3(x,0,0);var b:Vector3=points[(j+1)%points.size()]-Vector3(x,0,0)
		for p in [a+Vector3(.08,0,0),b+Vector3(.08,0,0),b-Vector3(.08,0,0),a+Vector3(.08,0,0),b-Vector3(.08,0,0),a-Vector3(.08,0,0)]:st.add_vertex(p)
	st.generate_normals();var node:=MeshInstance3D.new();node.mesh=st.commit();node.material_override=material(color);scene.add_child(node);node.position.x=x
	for i in range(-4,5):
		var z:float=i*half_width(x)/5
		box(node,Vector3(.19,M.H*.55,z),Vector3(.22,M.H*.88,.10),Color("a1aaa5"))
	box(node,Vector3(0,deck_height(x),0),Vector3(.28,.18,2*half_width(x)),Color("c1cbc5"))
	return node
func ring(x:float)->PackedVector3Array:
	var w:=half_width(x);var h:=deck_height(x)
	var local:float=(x-M.L*.5)*189.64/M.L
	var rise:float=6.2*pow(maxf(0,(-local-66)/32),2)*M.H/14.89
	return PackedVector3Array([Vector3(x,h,-w),Vector3(x,rise+(h-rise)*.18,-w),Vector3(x,rise+(h-rise)*.065,-w*.92),Vector3(x,rise,-w*.70),Vector3(x,rise,w*.70),Vector3(x,rise+(h-rise)*.065,w*.92),Vector3(x,rise+(h-rise)*.18,w),Vector3(x,h,w)])
func shell(parent:Node3D,near:bool)->void:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 93:
		var a:=ring(M.L*i/93.0);var b:=ring(M.L*(i+1)/93.0)
		for j in range(3 if near else 0,5 if near else 3):
			for p in [a[j],b[j],b[j+1],a[j],b[j+1],a[j+1]]:st.add_vertex(p)
	st.generate_normals();var node:=MeshInstance3D.new();node.mesh=st.commit();node.material_override=material(Color("526a76"));parent.add_child(node)
func _ready()->void:
	clip_contents=true;mouse_filter=MOUSE_FILTER_STOP
	var container:=SubViewportContainer.new();container.set_anchors_and_offsets_preset(PRESET_FULL_RECT);container.stretch=true;container.mouse_filter=MOUSE_FILTER_IGNORE;container.show_behind_parent=true;add_child(container)
	viewport=SubViewport.new();viewport.msaa_3d=Viewport.MSAA_4X;viewport.own_world_3d=true;container.add_child(viewport)
	scene=Node3D.new();viewport.add_child(scene)
	var env:=WorldEnvironment.new();var e:=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("102530");e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color.WHITE;e.ambient_light_energy=.65;env.environment=e;scene.add_child(env)
	var light:=DirectionalLight3D.new();scene.add_child(light);light.rotation_degrees=Vector3(-55,-30,0);light.light_energy=1.5
	camera=Camera3D.new();scene.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.far=1000
	hull=Node3D.new();scene.add_child(hull);shell(hull,false);near_shell=Node3D.new();hull.add_child(near_shell);shell(near_shell,true)
	deck=Node3D.new();scene.add_child(deck)
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 93:
		var x1:=M.L*i/93.0;var x2:=M.L*(i+1)/93.0;var w1:=half_width(x1);var w2:=half_width(x2)
		for point in [Vector3(x1,M.H,-w1),Vector3(x2,M.H,w2),Vector3(x2,M.H,-w2),Vector3(x1,M.H,-w1),Vector3(x1,M.H,w1),Vector3(x2,M.H,w2)]:surface.add_vertex(point)
		if i%2==0:
			for sign_ in [-1,1]:beam(deck,Vector3(x1,M.H,w1*sign_),Vector3(x1,M.H+1.2,w1*sign_),.07,Color("e0e6e6"))
		for sign_ in [-1,1]:beam(deck,Vector3(x1,M.H+1.2,w1*sign_),Vector3(x2,M.H+1.2,w2*sign_),.07,Color("e0e6e6"))
	surface.generate_normals();var plate:=MeshInstance3D.new();plate.mesh=surface.commit();plate.material_override=material(Color("597a7a"));deck.add_child(plate)
	section_outline=Node3D.new();scene.add_child(section_outline)
	var cross:=ring(110)
	for j in 7:beam(section_outline,cross[j],cross[j+1],.3,Color("b4cbd5"))
	beam(section_outline,cross[0],cross[7],.25,Color("b4cbd5"))
	for n in range(244):
		var root:=Node3D.new();scene.add_child(root);var points:=ring(M.x(n))
		for j in 5:beam(root,points[j],points[j+1],.19,Color("8095a2"))
		ribs.append(root)
	for n in [24,221,185,181,60,85,109,133,157]:
		walls.append(wall(M.x(n),Color("59c5b4")))
	temporary=wall(90,Color("f1c575"))
	section_parts=Node3D.new();scene.add_child(section_parts)
	bottom=Node3D.new();bottom.name="DoubleBottom";section_parts.add_child(bottom)
	longitudinal=Node3D.new();longitudinal.name="SectionLongitudinal";section_parts.add_child(longitudinal)
	# Actual adopted inner surfaces over the six cargo groups; side plating follows the hull.
	var start:float=M.x(181);var finish:float=M.x(24)
	for i in 64:
		var x1:float=lerpf(start,finish,i/64.0);var x2:float=lerpf(start,finish,(i+1)/64.0);var mid:float=(x1+x2)*.5
		var w1:float=half_width(x1)-.35;var w2:float=half_width(x2)-.35
		plate_strip(bottom,[Vector3(x1,1.70,-w1),Vector3(x2,1.70,-w2),Vector3(x2,1.70,w2),Vector3(x1,1.70,w1)])
		if i%2==0:box(bottom,Vector3(mid,.85,0),Vector3(.12,1.55,minf(w1,w2)*2),Color("737e79"))
		for sign_ in [-1,1]:
			var side:=Node3D.new();side.name="InnerSide_%d_%d"%[i,sign_];section_parts.add_child(side);sides.append(side)
			plate_strip(side,[Vector3(x1,1.70,sign_*(half_width(x1)-2.2)),Vector3(x2,1.70,sign_*(half_width(x2)-2.2)),Vector3(x2,deck_height(x2),sign_*(half_width(x2)-2.2)),Vector3(x1,deck_height(x1),sign_*(half_width(x1)-2.2))])
			plate_strip(longitudinal,[Vector3(x1,1.70,sign_*4.415),Vector3(x2,1.70,sign_*4.415),Vector3(x2,deck_height(x2),sign_*4.415),Vector3(x1,deck_height(x1),sign_*4.415)])
			if i%2==0:box(longitudinal,Vector3(mid,8.1,sign_*4.415),Vector3(.12,12.6,.27),Color("a4aaa6"))
	for sign_ in [-1,1]:box(longitudinal,Vector3((start+finish)*.5,M.H,sign_*4.415),Vector3(finish-start,.18,.24),Color("c1cbc5"))
	var resource=load("res://modules/review/assets/stability_fittings.glb")
	if resource:
		fittings=resource.instantiate();scene.add_child(fittings)
		for child in fittings.get_children():
			var category:String=str(child.name).split("_far_")[0]
			child.visible=category in ["Accommodation","Windows","Funnel","Survival","Navigation","Anchors","Mooring"]
			var forward:bool=child.position.x>0
			child.position+=Vector3(44.7 if forward else 94.75,M.H-17.8,0)
	resized.connect(queue_redraw)
	detailed=load("res://assets/bulkhead_t2.glb").instantiate();scene.add_child(detailed);inspection.attach(detailed);inspection.parameters({"section_depth":3.0})
	section_cut.attach(section_parts);section_cut.parameters({"section_depth":3.0})
	for part in section_cut.nodes:part.material_override=null
func set_camera(kind:String)->void:
	orbiting=false
	var target:=Vector3(M.L*.5,7,0);var offset:=Vector3(125,125,215);var zoom:=220.0
	match kind:
		"side":offset=Vector3(65,135,220)
		"top":offset=Vector3(0,220,.01)
		"section":target=Vector3(110,7,0);offset=Vector3(200,0,.01);zoom=46
		"rib":target=Vector3(M.x(87),7,0);offset=Vector3(22,42,50);zoom=40
		"fore":target=Vector3(165,7,0);offset=Vector3(5,40,120);zoom=72
		"aft":target=Vector3(25,7,0);offset=Vector3(-15,38,100);zoom=60
		"wall":target=Vector3(90,6,0);offset=Vector3(32,35,65);zoom=65
		"drag":target=Vector3(M.x(60),7,0);offset=Vector3(25,65,120);zoom=84
	if camera_tween and camera_tween.is_valid():camera_tween.kill()
	camera_tween=create_tween().set_parallel(true);camera_tween.tween_property(self,"focus",target,.6);camera_tween.tween_property(self,"eye",target+offset,.6);camera_tween.tween_property(self,"extent",zoom,.6)
func apply(value:Dictionary,b:Dictionary,lang:String)->void:
	state=value;beat=b;language=lang
	region_preview=b.has("spacing_region")
	region_frames={"cargo":Vector2i(85,89),"engine":Vector2i(195,197),"transition":Vector2i(36,38),"fore":Vector2i(10,11),"aft":Vector2i(231,232)}.get(b.get("spacing_region",""),Vector2i(85,89))
	near_shell.hide()
	var section:bool=b.get("camera","")=="section"
	hull.hide();section_outline.visible=section;deck.hide()
	if fittings:fittings.hide()
	var centre:=110.0;var span:=66.0
	if b.get("camera","")=="fore":centre=165;span=26
	elif b.get("camera","")=="rib":centre=M.x(87);span=12
	elif b.get("camera","")=="aft":centre=28;span=27
	elif b.get("camera","") in ["wall","drag"]:centre=95;span=30
	if region_preview:centre=M.L*.5;span=M.L*.5
	inspection.window(0.0 if section else float(state.get("bh_cut",0)),centre,span,.15,M.H-.30,0,section)
	section_cut.window(0.0 if section else float(state.get("bh_cut",0)),centre if region_preview else 110,span if region_preview else 66,0,M.H,0,section)
	for n in ribs.size():
		var level:float=state.get("bh_frames",0)
		ribs[n].visible=not section and ((region_preview and n>=region_frames.x and n<=region_frames.y) or (level>=2.99 and is_web(n)) or (level>0 and n>=85 and n<=89))
		for part in ribs[n].get_children():
			part.visible=not (float(state.get("bh_cut",0))>0 and absf(part.position.x-centre)<span*float(state.get("bh_cut",0)) and part.position.z>0 and part.position.y>2)
			var strong:bool=(b.get("camera","")=="rib" and level>=2 and n in [85,89]) or (region_preview and n in [region_frames.x,region_frames.y])
			if region_preview and n in [region_frames.x,region_frames.y]:part.visible=true
			part.material_override.emission_enabled=region_preview and strong
			part.material_override.emission=Color("f5c879")
			part.material_override.emission_energy_multiplier=.4+float(state.get("bh_spacing_reveal",1))*.5
			part.material_override.albedo_color=Color("f5c879") if strong else Color("8095a2")
			part.scale.x=1.8 if strong else 1.0;part.scale.y=part.scale.x
	for i in walls.size():
		walls[i].visible=not section and (region_preview or float(state.get("bh_walls",0))>i)
		walls[i].scale.y=1.0 if region_preview else clampf(float(state.get("bh_walls",0))-i,.001,1)
		walls[i].position.y=M.H*(1.0-walls[i].scale.y)
		walls[i].material_override.albedo_color=Color("f5c879") if (i==4 and b.get("experiment",false)) else Color("858f8b")
	walls[4].position.x=M.x(float(state.get("bh_frame",60)))
	temporary.visible=not section and float(state.get("bh_insert",0))>0;temporary.scale.y=maxf(.001,float(state.get("bh_insert",0)))
	bottom.visible=region_preview or float(state.get("bh_bottom",0))>0;bottom.scale.z=1.0 if region_preview else maxf(.001,float(state.get("bh_bottom",0)))
	for side in sides:side.visible=region_preview or float(state.get("bh_side",0))>0;side.scale.y=1.0 if region_preview else maxf(.001,float(state.get("bh_side",0)))
	longitudinal.visible=region_preview or float(state.get("bh_long",0))>0;longitudinal.scale.y=1.0 if region_preview else maxf(.001,float(state.get("bh_long",0)))
	queue_redraw()
func _process(_dt:float)->void:
	if not is_visible_in_tree():return
	camera.position=eye;camera.look_at(focus);camera.size=extent;queue_redraw()
func project(p:Vector3)->Vector2:return camera.unproject_position(p)
func anchor()->Vector2:
	if region_preview:return project(Vector3((M.x(region_frames.x)+M.x(region_frames.y))*.5,18,0))
	var x:=110.0;var y:=8.0;var z:=0.0
	match str(beat.get("anchor","ship")):
		"fore":x=(M.L+M.x(24))*.5
		"aft":x=6.6
		"engine":x=28.5
		"pump":x=45.5
		"rib":x=M.x(87);z=half_width(x)
		"wall":x=M.x(float(state.get("bh_frame",60))) if beat.get("experiment",false) else 90
		"hold1":x=(M.x(24)+M.x(60))*.5
		"hold2":x=(M.x(60)+M.x(85))*.5
		"hold3":x=(M.x(85)+M.x(109))*.5
		"hold4":x=(M.x(109)+M.x(133))*.5
		"hold5":x=(M.x(133)+M.x(157))*.5
		"hold6":x=(M.x(157)+M.x(181))*.5
		"transition":x=M.x(61)
		"bottom":y=1.70;z=4
		"side":y=7;z=M.B*.5-2.2
		"long":y=8;z=4.415
	return project(Vector3(x,y,z))
func label(p:Vector3,text:String,color:=Color("e0ecf2"))->void:
	var font:=get_theme_default_font();var point:=project(p);point.x-=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x*.5
	draw_string(font,point,text,HORIZONTAL_ALIGNMENT_LEFT,-1,20,color)
func line(a:Vector3,b:Vector3,text:String)->void:
	var pa:=project(a);var pb:=project(b);draw_line(pa,pb,Color("f5c879"),2,true)
	for p in [pa,pb]:draw_line(p+Vector2(0,-5),p+Vector2(0,5),Color("f5c879"),2,true)
	label((a+b)*.5+Vector3(0,2,0),text,Color("f5c879"))
func _draw()->void:
	if not camera or beat.is_empty():return
	if region_preview:
		var region:String=beat.spacing_region
		var bounds:Vector2i={"cargo":Vector2i(61,181),"engine":Vector2i(185,221),"transition":Vector2i(24,61),"fore":Vector2i(0,24),"aft":Vector2i(221,243)}[region]
		var color:=Color("f5c879");color.a=.12+.15*float(state.get("bh_spacing_reveal",1))
		var polygon:=PackedVector2Array()
		for p in [Vector3(M.x(bounds.x),1.8,-9),Vector3(M.x(bounds.y),1.8,-9),Vector3(M.x(bounds.y),1.8,9),Vector3(M.x(bounds.x),1.8,9)]:polygon.append(project(p))
		draw_colored_polygon(polygon,color)
		for i in 4:draw_line(polygon[i],polygon[(i+1)%4],Color("f5c879"),2,true)
		var title:String={"cargo":"货油舱 · 普通肋距段","engine":"机舱","transition":"艏部过渡区","fore":"艏尖舱","aft":"艉尖舱"}[region] if language=="zh" else {"cargo":"Грузовы́е та́нки","engine":"МО","transition":"Перехо́дный райо́н","fore":"Фо́рпик","aft":"Ахте́рпик"}[region]
		line(Vector3(M.x(bounds.x),-5,16),Vector3(M.x(bounds.y),-5,16),title)
		var ordinary:float=absf(M.x(region_frames.x)-M.x(region_frames.x+1))
		var strong_spacing:float=absf(M.x(region_frames.x)-M.x(region_frames.y))
		var a:=project(Vector3(M.x(region_frames.x),20,0))
		var b:=project(Vector3(M.x(region_frames.x+1),20,0))
		var c:=project(Vector3(M.x(region_frames.y),20,0))
		var font:=get_theme_default_font()
		var strings:Array=[("普通肋距：%.2f m" if language=="zh" else "Обы́чная шпа́ция: %.2f м")%ordinary,("强肋骨间距：%.2f m" if language=="zh" else "Ра́мная шпа́ция: %.2f м")%strong_spacing]
		var width:=0.0
		for text_ in strings:width=maxf(width,font.get_string_size(text_,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x+24)
		var pos:Vector2=((a+c)*.5-Vector2(width*.5,120)).clamp(Vector2(12,115),Vector2(maxf(12,size.x-width-12),size.y-110))
		var box_style:=StyleBoxFlat.new();box_style.bg_color=Color("102530");box_style.set_corner_radius_all(6)
		draw_style_box(box_style,Rect2(pos,Vector2(width,40 if beat.get("spacing_stage","")=="ordinary" else 72)))
		for i in (1 if beat.get("spacing_stage","")=="ordinary" else 2):
			var ink:=Color("e0ecf2") if i==0 else Color("f5c879")
			draw_string(font,pos+Vector2(12,26+32*i),strings[i],HORIZONTAL_ALIGNMENT_LEFT,-1,20,ink)
			var start:=a+Vector2(0,-20+16*i);var end:Vector2=(b if i==0 else c)+Vector2(0,-20+16*i)
			draw_line(start,end,ink,2,true)
			for p in [start,end]:draw_line(p-Vector2(0,5),p+Vector2(0,5),ink,2,true)
			draw_line(pos+Vector2(width*.5,30+32*i),(start+end)*.5,ink,1,true)
	var dim:String=beat.get("dimension","")
	if dim in ["spacing","four"]:
		line(Vector3(M.x(85),16,10),Vector3(M.x(86 if dim=="spacing" else 89),16,10),"a = 0.85 m" if dim=="spacing" else "4 × 0.85 = 3.40 m")
		if dim=="four":
			for n in range(85,90):
				var p:=project(Vector3(M.x(n),16,10));draw_line(p-Vector2(0,6),p+Vector2(0,6),Color("f5c879"),2,true)
	if float(state.get("bh_walls",0))>=1:
		var count:=mini(10,int(beat.get("table_rows",0)))
		var rows:=M.rows(float(state.get("bh_frame",60)))
		if count>0:
			for i in count:
				if beat.get("experiment",false) and i not in [1,2]:continue
				var row:Dictionary=rows[i];var start:=M.x(row.start);var finish:=M.x(row.end)
				var dimension_z:float=-M.B*.5-(17 if i==7 else 8) if beat.get("camera","")=="top" else 0.0
				line(Vector3(start,19,dimension_z),Vector3(finish,19,dimension_z),"%.2f"%row.length)
				label(Vector3(finish,-3-3*(i%2),M.B*.5+8+5*(i%2) if beat.get("camera","")=="top" else 0.0),"%d"%row.end)
	if beat.get("camera","") in ["overview","side","top","cut"] and not beat.get("experiment",false):
		label(Vector3(0,29,M.B+14 if beat.get("camera","")=="top" else 0),"艉" if language=="zh" else "Корма́")
		label(Vector3(M.L,29,M.B+14 if beat.get("camera","")=="top" else 0),"艏" if language=="zh" else "Нос")
	if beat.id=="BH:fore_place":
		line(Vector3(M.x(24),18,0),Vector3(M.L,18,0),"24 × 0.6 = 14.40 m")
		label(Vector3(M.x(24),-3,0),"24")
	if state.get("bh_range",0)>0:
		var s1:=14.4 if state.bh_range>1.5 else 9.4565;var s2:=39.93 if state.bh_range>1.5 else 15.1304
		line(Vector3(M.L-s1,18,0),Vector3(M.L-s2,18,0),"25.53 m" if state.bh_range>1.5 else "9.46 … 15.13 m")
	if dim=="axis":line(Vector3(0,-6,0),Vector3(M.L,-6,0),"x →    189.13 m    ← s")
	if beat.get("camera","")=="section":
		if float(state.get("bh_db_value",0))>0.99:line(Vector3(110,0,15),Vector3(110,1.7,15),"1.70 m")
		if float(state.get("bh_side_value",0))>0.99:line(Vector3(110,18,11.065),Vector3(110,18,13.265),"2.20 m")
		if float(state.get("bh_width_value",0))>0.99:
			line(Vector3(110,17,-4.415),Vector3(110,17,4.415),"8.83 m")
			line(Vector3(110,17,-11.065),Vector3(110,17,-4.415),"6.65 m")
			label(Vector3(110,7,0),"中央舱" if language=="zh" else "Центра́льный")
			label(Vector3(110,7,-7.74),"边舱" if language=="zh" else "Бортово́й")
			label(Vector3(110,7,7.74),"边舱" if language=="zh" else "Бортово́й")
	if interactive:
		for n in candidates:
			var p:=project(Vector3(M.x(n),15,0));draw_circle(p,7,Color("f5c879"));label(Vector3(M.x(n),24+float(n-58)*.5,0),str(n))
		if dragging:
			var x:=M.x(preview_frame);draw_line(project(Vector3(x,0,0)),project(Vector3(x,15,0)),Color("f5c879"),4,true)
func obstacles()->Array:
	var result:Array=[]
	if beat.get("camera","")=="section":
		var a:=project(Vector3(110,23,-M.B*.5-3));var b:=project(Vector3(110,-2,M.B*.5+3))
		result.append(Rect2(a.min(b),abs(b-a)).grow(14))
	elif beat.get("camera","")=="rib":
		var a:=project(Vector3(M.x(85),16,10));var b:=project(Vector3(M.x(89),0,10))
		result.append(Rect2(a.min(b),abs(b-a)).grow(22))
	elif beat.get("camera","")=="top":
		var a:=project(Vector3(0,0,-M.B*.5-26));var b:=project(Vector3(M.L,0,M.B*.5+18))
		result.append(Rect2(a.min(b),abs(b-a)).grow(24))
	else:
		var a:=project(Vector3(0,22,0));var b:=project(Vector3(M.L,-3,0))
		result.append(Rect2(a.min(b),abs(b-a)).grow(24))
	return result
func candidate_point(n:int)->Vector2:return project(Vector3(M.x(n),15,0))
func _gui_input(event:InputEvent)->void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			if interactive and event.position.distance_to(candidate_point(int(state.get("bh_frame",60))))<45:
				dragging=true;preview_frame=int(state.get("bh_frame",60))
			else:
				if camera_tween and camera_tween.is_valid():camera_tween.kill()
				orbiting=true
		else:
			if dragging:dragging=false;wall_moved.emit(float(preview_frame))
			orbiting=false
		accept_event()
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		if camera_tween and camera_tween.is_valid():camera_tween.kill()
		extent=clampf(extent*(.9 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.1),25,300);accept_event()
	if event is InputEventMouseMotion and orbiting:
		var offset:=eye-focus
		var radius:float=maxf(offset.length(),1)
		var yaw:float=atan2(offset.x,offset.z)-event.relative.x*.005
		var pitch:float=clampf(asin(clampf(offset.y/radius,-1,1))+event.relative.y*.005,-1.52,1.52)
		eye=focus+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*radius
		accept_event()
	if event is InputEventMouseMotion and dragging:
		var nearest:=60;var distance:=INF
		for n in candidates:
			var d:float=event.position.distance_to(candidate_point(n))
			if d<distance:distance=d;nearest=n
		preview_frame=nearest;queue_redraw();accept_event()
func _notification(what:int)->void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:orbiting=false;dragging=false

func is_web(n:int)->bool:
	if n<=24 or n>=221:return true
	if n<=60:return (n-24)%2==0
	if n<=181:return (n-61)%4==0
	return (n-185)%2==0
func plate_strip(parent:Node3D,points:Array)->void:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var normal:Vector3=(points[1]-points[0]).cross(points[2]-points[0]).normalized()*.07
	for offset in [normal,-normal]:
		for i in [0,1,2,0,2,3]:st.add_vertex(points[i]+offset)
	for j in 4:
		var a:Vector3=points[j];var b:Vector3=points[(j+1)%4]
		for v in [a+normal,b+normal,b-normal,a+normal,b-normal,a-normal]:st.add_vertex(v)
	st.generate_normals();var node:=MeshInstance3D.new();node.mesh=st.commit();node.name=str(parent.name)+"_plate";node.material_override=material(Color("8e9691"));parent.add_child(node)
