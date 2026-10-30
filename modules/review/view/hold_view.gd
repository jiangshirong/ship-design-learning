extends SubViewportContainer
# Net stowage envelope: x[-4,4], y[0,2], z[-1,1], metres.
# One rigid crate + packing clearance occupies one 1 m³ cell and weighs 1 t.
var viewport:SubViewport
var world:Node3D
var camera:Camera3D
var crates:Array[Node3D]=[]
var reference:Node3D
var empty_floor:MeshInstance3D
var rails:Array[MeshInstance3D]=[]
var mass_label:Label
var volume_label:Label
var item_label:Label
var limit_label:Label
var loaded:=0.0
var height:=2.0
var lesson_id:="Q14"
var walls:Array[MeshInstance3D]=[]
var ribs:Array[MeshInstance3D]=[]
var deck_edges:Array[MeshInstance3D]=[]
var depth_guides:Node3D
var water_guides:Node3D
var height_line:MeshInstance3D
var height_top:MeshInstance3D
var h_label:Label
var t_label:Label
var water_label:Label
var last_height:=-1.0
var phase:="goal"
var language:="zh"
var camera_target:=Vector3(0,1,0)
var camera_span:=8.4
var yaw:=.18
var pitch:=.58
var dragging:=false
var camera_tween:Tween
var camera_motion:=false
var reference_material:StandardMaterial3D
var normal_rail:StandardMaterial3D
var warning_rail:StandardMaterial3D
var deck_material:StandardMaterial3D
var detailed:Node3D
var inspection=preload("res://view/inspection_cut.gd").new()

func tr2(zh:String,ru:String)->String:return zh if language=="zh" else ru
func material(color:Color)->StandardMaterial3D:
	var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=.75
	return m
func box(dim:Vector3,point:Vector3,color:Color,parent:Node=null)->MeshInstance3D:
	var n:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=dim;n.mesh=mesh;n.position=point;n.material_override=material(color)
	(parent if parent else world).add_child(n);return n
func new_label(fs:int)->Label:
	var n:=Label.new();n.add_theme_font_size_override("font_size",fs);n.mouse_filter=Control.MOUSE_FILTER_IGNORE
	n.add_theme_color_override("font_shadow_color",Color("102332"));n.add_theme_constant_override("shadow_offset_x",1);n.add_theme_constant_override("shadow_offset_y",2)
	add_child(n);return n
func _ready()->void:
	stretch=true;clip_contents=true;mouse_filter=Control.MOUSE_FILTER_STOP
	viewport=SubViewport.new();viewport.own_world_3d=true;viewport.msaa_3d=Viewport.MSAA_8X;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport)
	world=Node3D.new();viewport.add_child(world)
	var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("132b3b")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("c4dcec");env.environment.ambient_light_energy=.7;world.add_child(env)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-35,0);sun.light_energy=1.1;world.add_child(sun)
	var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-20,140,0);fill.light_energy=.65;world.add_child(fill)
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.far=100;world.add_child(camera)
	# Outer structure is outside the defined net cargo envelope. The near side
	# is cut away, leaving the sill and exposed section edges visible.
	box(Vector3(8.32,.18,2.32),Vector3(0,-.09,0),Color("385c6c"))
	walls.append(box(Vector3(8.3,2.16,.14),Vector3(0,1.0,-1.14),Color("34586a")))
	walls.append(box(Vector3(.14,2.16,2.3),Vector3(-4.14,1,0),Color("34586a")))
	walls.append(box(Vector3(.14,2.16,2.3),Vector3(4.14,1,0),Color("34586a")))
	box(Vector3(8.3,.18,.14),Vector3(0,.09,1.14),Color("456778"))
	for x in range(9):
		ribs.append(box(Vector3(.07,2.25,.07),Vector3(x-4,1.0,-1.24),Color("82a2b0")))
		box(Vector3(.04,.025,2),Vector3(x-4,.012,0),Color("63828b"))
	for y in [.6,1.3,2.0]:box(Vector3(8.3,.045,.06),Vector3(0,y,-1.04),Color("7094a3"))
	for z in [-1.14,1.14]:deck_edges.append(box(Vector3(8.45,.10,.18),Vector3(0,2,z),Color("a2b5bd")))
	for x in [-4.14,4.14]:deck_edges.append(box(Vector3(.18,.10,2.3),Vector3(x,2,0),Color("a2b5bd")))
	# Replace the old box structure with an authored whole ship, not extra boxes.
	for old in world.get_children():
		if old is MeshInstance3D:old.hide()
	detailed=load("res://assets/study_cargo_inspection.glb").instantiate();world.add_child(detailed);inspection.attach(detailed)
	normal_rail=material(Color("eec980"));warning_rail=material(Color("f47f68"))
	deck_material=material(Color("a2b5bd"))
	for z in [-1.06,1.06]:rails.append(box(Vector3(8.12,.055,.055),Vector3(0,.025,z),Color.WHITE))
	for x in [-4.06,4.06]:rails.append(box(Vector3(.055,.055,2.12),Vector3(x,.025,0),Color.WHITE))
	for rail in rails:rail.material_override=normal_rail
	var source:PackedScene=load("res://modules/review/assets/freight_first.glb")
	for i in range(48):
		var item:Node3D=source.instantiate();world.add_child(item);crates.append(item);item.hide()
	reference=Node3D.new();world.add_child(reference)
	for x in [-4.0,-2.0]:
		for z in [-1.0,0.0]:box(Vector3(.025,1,.025),Vector3(x,.5,z),Color("ffd073"),reference)
	for y in [0.03,1.0]:
		for z in [-1.0,0.0]:box(Vector3(2,.025,.025),Vector3(-3,y,z),Color("ffd073"),reference)
		for x in [-4.0,-2.0]:box(Vector3(.025,.025,1),Vector3(x,y,-.5),Color("ffd073"),reference)
	empty_floor=box(Vector3(4,.028,2),Vector3(2,.03,0),Color("40606b"))
	mass_label=new_label(22);volume_label=new_label(22);item_label=new_label(20);limit_label=new_label(21)
	depth_guides=Node3D.new();world.add_child(depth_guides)
	height_line=box(Vector3(.025,2.18,.025),Vector3(4.6,.91,1.25),Color("ffd073"),depth_guides)
	box(Vector3(.38,.025,.025),Vector3(4.6,-.18,1.25),Color("ffd073"),depth_guides)
	height_top=box(Vector3(.38,.025,.025),Vector3(4.6,2,1.25),Color("ffd073"),depth_guides)
	box(Vector3(9.2,.025,.025),Vector3(0,-.18,1.3),Color("e197b9"),depth_guides)
	water_guides=Node3D.new();world.add_child(water_guides)
	for z in [-1.65,1.65]:box(Vector3(9.8,.016,.75),Vector3(0,1,z),Color("326d89"),water_guides)
	for x in [-4.6,4.6]:box(Vector3(.8,.016,2.6),Vector3(x,1,0),Color("326d89"),water_guides)
	box(Vector3(8.5,.028,.028),Vector3(0,1,1.23),Color("80dfff"),water_guides)
	box(Vector3(.025,1.18,.025),Vector3(-4.6,.41,1.25),Color("80dfff"),water_guides)
	for y in [-.18,1.0]:box(Vector3(.38,.025,.025),Vector3(-4.6,y,1.25),Color("80dfff"),water_guides)
	h_label=new_label(22);t_label=new_label(22);water_label=new_label(20)
	resized.connect(update_camera);update_camera();apply({"loaded":0},"goal","zh")

static func cell(index:int)->Vector3:
	if index>=32:return Vector3(-3.5+int((index-32)/2),2,-.5+index%2)
	return Vector3(-3.5+int(index/4),int(index/2)%2,-.5+index%2)
func mass()->int:return clampi(int(floor(loaded+.000001)),0,48)
func capacity()->float:return 16.0*height
func resize_hold()->void:
	if is_equal_approx(last_height,height):return
	last_height=height
	for wall in walls:
		var dim:Vector3=wall.mesh.size;dim.y=height+.16;wall.mesh.size=dim;wall.position.y=height*.5
	for rib in ribs:rib.mesh.size=Vector3(.07,height+.25,.07);rib.position.y=height*.5
	for edge in deck_edges:edge.position.y=height
	height_line.mesh.size=Vector3(.025,height+.18,.025);height_line.position.y=(height-.18)*.5
	height_top.position.y=height
func apply(state:Dictionary,focus:String,lang:String)->void:
	loaded=clampf(float(state.get("loaded",0)),0,48);height=clampf(float(state.get("height",2)),2,3);phase=focus;language=lang
	resize_hold()
	inspection.raise_deck(height-2.0)
	inspection.window(1.0,0,4.22,-.35,1.98,.95)
	var landed:=mass()
	for i in range(crates.size()):
		crates[i].visible=i<landed or (i==landed and loaded-landed>.00001)
		crates[i].position=cell(i)
		if i==landed:crates[i].position.y+=(1-(loaded-landed))*3.5
	# Highlight empty half only after that relationship is introduced.
	empty_floor.visible=phase in ["limit","restore","general","answer"]
	reference.visible=phase in ["ship_ratio","cargo_ratio"]
	for rail in rails:rail.material_override=warning_rail if landed>16 else normal_rail
	mass_label.visible=phase!="goal";volume_label.visible=phase!="goal"
	mass_label.text=tr2("例：载货  %d / 16 t","Приме́р: груз  %d / 16 т")%landed
	volume_label.text=tr2("占用舱容  %d / 32 m³","Объём гру́за  %d / 32 м³")%landed
	mass_label.modulate=Color("ff957e") if landed>16 else Color("f5d496") if landed==16 else Color("e3edf3")
	volume_label.modulate=Color("79d8c8")
	item_label.visible=phase in ["ship_ratio","cargo_ratio"]
	item_label.text=tr2("每吨可用  2 m³","На то́нну — 2 м³") if phase=="ship_ratio" else tr2("1 t 货物占 1 m³","1 т гру́за — 1 м³")
	limit_label.visible=phase in ["limit","general","answer","over_limit"]
	limit_label.text=tr2("还有一半空位","Полови́на трю́ма пуста́") if landed<=16 else tr2("超过质量上限","Преде́л ма́ссы превы́шен")
	depth_guides.visible=lesson_id in ["Q11","Q15"]
	water_guides.visible=lesson_id=="Q11"
	h_label.visible=depth_guides.visible;t_label.visible=water_guides.visible;water_label.visible=water_guides.visible
	h_label.text=tr2("型深 H","Высота́ H");t_label.text=tr2("吃水 T","Оса́дка T");water_label.text=tr2("水线不变","Ватерли́ния та же")
	h_label.modulate=Color("ffdb8b");t_label.modulate=Color("80dfff");water_label.modulate=Color("80dfff")
	if lesson_id=="Q02":
		mass_label.text=tr2("例：货物  %d t","Приме́р: груз  %d т")%landed
		volume_label.text=tr2("货舱容积  32 m³ · 不变","Объём трю́ма  32 м³ · тот же")
		mass_label.modulate=Color("e3edf3");limit_label.visible=false
	elif lesson_id=="Q11":
		mass_label.text=tr2("水下体积 V · 不变","Подво́дный объём V · тот же")
		volume_label.text=tr2("型深 H · 增大","Высота́ H · бо́льше") if height>2.01 else tr2("型深 H · 原高度","Высота́ H · до измене́ния")
		mass_label.modulate=Color("80dfff");limit_label.visible=false
	elif lesson_id=="Q15":
		mass_label.text=tr2("例：装入  %d / 48 t","Приме́р: груз  %d / 48 т")%landed
		volume_label.text=tr2("舱容  %.0f m³ · 需要 48 m³","Объём  %.0f м³ · ну́жно 48 м³")%capacity()
		mass_label.modulate=Color("ffdb8b");limit_label.visible=true
		limit_label.text=tr2("舱满了，还有货没装下","Трюм по́лон. Весь груз не вхо́дит.") if height<2.01 else (tr2("48 吨全部装下","Все 48 тонн помести́лись") if landed==48 else tr2("新增的空间","До́полнительное ме́сто"))
	for rail in rails:rail.material_override=warning_rail if lesson_id=="Q14" and landed>16 else normal_rail
	for edge in deck_edges:edge.material_override=normal_rail if phase in ["capacity","raise","depth_done","space_done"] else deck_material
	update_labels()

func teach(focus:String)->void:
	var close:bool=focus in ["ship_ratio","cargo_ratio"]
	var target:Vector3=Vector3(-2.6,.7,0) if close else Vector3(0,1,0)
	var span:float=5.5 if close else 8.4
	var desired_pitch:=.58
	if lesson_id in ["Q11","Q15"]:target=Vector3(0,1.3,0);span=9.4;desired_pitch=.42
	if camera_tween and camera_tween.is_valid():camera_tween.kill()
	if camera_target.is_equal_approx(target) and is_equal_approx(camera_span,span) and is_equal_approx(yaw,.18) and is_equal_approx(pitch,desired_pitch):camera_motion=false;return
	camera_motion=true;camera_tween=create_tween().set_parallel(true)
	camera_tween.tween_property(self,"camera_target",target,.55).set_trans(Tween.TRANS_SINE)
	camera_tween.tween_property(self,"camera_span",span,.55)
	camera_tween.tween_property(self,"yaw",.18,.55);camera_tween.tween_property(self,"pitch",desired_pitch,.55)
	camera_tween.finished.connect(func():camera_motion=false;update_camera())
func _process(_dt:float)->void:
	if camera_motion:update_camera()
func cancel()->void:
	if camera_tween and camera_tween.is_valid():camera_tween.kill()
	camera_motion=false;dragging=false
func update_camera()->void:
	if not camera:return
	# Keep the full 8m hold in narrow windows; zoom is constant within a beat.
	camera.size=maxf(camera_span,10.8/maxf(size.x/maxf(size.y,1),.4)) if camera_span>6 else maxf(camera_span,6.0/maxf(size.x/maxf(size.y,1),.4))
	camera.position=camera_target+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*18
	camera.look_at(camera_target,Vector3.UP);update_labels()
func project(point:Vector3)->Vector2:return camera.unproject_position(point)*size/Vector2(viewport.size)
func update_labels()->void:
	if not mass_label:return
	mass_label.position=Vector2(20,20);volume_label.position=Vector2(20,53)
	item_label.position=project(Vector3(-3,1.6,-.5))-Vector2(item_label.get_minimum_size().x*.5,32)
	limit_label.position=project(Vector3(2,.05,.5))+Vector2(-limit_label.get_minimum_size().x*.5,28)
	if lesson_id=="Q15":limit_label.position=project(Vector3(0,height+.25,0))-Vector2(limit_label.get_minimum_size().x*.5,32)
	for l in [item_label,limit_label]:l.position=l.position.clamp(Vector2(12,95),size-l.get_minimum_size()-Vector2(12,12))
	if h_label:
		h_label.position=project(Vector3(4.6,height*.55,1.25))+Vector2(10,-12)
		t_label.position=project(Vector3(-4.6,.41,1.25))-Vector2(t_label.get_minimum_size().x+10,12)
		water_label.position=project(Vector3(-2.6,1,1.8))+Vector2(-water_label.get_minimum_size().x*.5,14)
		for l in [h_label,t_label,water_label]:l.position=l.position.clamp(Vector2(12,95),size-l.get_minimum_size()-Vector2(12,12))
func anchor()->Vector2:
	if lesson_id=="Q11":return project(Vector3(-2,1,1.22)) if phase=="underwater" else project(Vector3(1,height,-1.14))
	if lesson_id=="Q15":return project(Vector3(1,height,-1.14)) if phase=="raise" else project(Vector3(-1,2.5 if height>2.5 else 1.7,1))
	if lesson_id=="Q02" and phase=="capacity":return project(Vector3(1,height,-1.14))
	if phase in ["ship_ratio","cargo_ratio"]:return project(Vector3(-3,1,-.5))
	if phase in ["limit","restore","general","answer"]:return project(Vector3(2,.04,.4))
	if phase in ["overload","over_limit"]:return project(Vector3(2,1.8,.5))
	return project(Vector3(-1,1,0))
func obstacles()->Array:
	var first:=true;var rect:=Rect2()
	for x in [-4.2,4.2]:
		for y in [-.2,height+.2]:
			for z in [-1.2,1.2]:
				var p:=project(Vector3(x,y,z))
				if first:rect=Rect2(p,Vector2.ZERO);first=false
				else:rect=rect.expand(p)
	var result:Array=[rect.grow(10)]
	for l in [mass_label,volume_label,item_label,limit_label,h_label,t_label,water_label]:
		if l.visible:result.append(Rect2(l.position,l.get_minimum_size()).grow(8))
	return result
func _gui_input(event:InputEvent)->void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:cancel()
			dragging=event.pressed;accept_event()
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			camera_span=clampf(camera_span*(.9 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.1),4,12);update_camera();accept_event()
	elif event is InputEventMouseMotion and dragging and not camera_motion:
		yaw-=event.relative.x*.005;pitch=clampf(pitch+event.relative.y*.005,-1.52,1.52);update_camera();accept_event()
