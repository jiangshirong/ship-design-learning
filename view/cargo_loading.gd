extends Node3D
# Aggregate stowage regions express the confirmed ratios, not measured hold dimensions.
var ship
var first:Array[Node3D]=[]
var second:Array[Node3D]=[]
var first_outline:MeshInstance3D
var free_outline:MeshInstance3D
var first_floor:MeshInstance3D
var free_floor:MeshInstance3D
var labels:Array[Label]=[]
var params:Dictionary={}
var values:Dictionary={}
var lang:="zh"
var phase:="goal"
var active_point:=Vector3.ZERO
var first_length:=0.0
var second_length:=0.0
const START=-40.0
const LENGTH=80.0
const WIDTH=16.0
const BASE=3.0
const HEIGHT=11.0
const TEAL=Color("70d2c4")
const GOLD=Color("ffc76b")
func setup(owner_view)->void:
	ship=owner_view
	for spec in [["first",first,14],["second",second,6]]:
		var scene:PackedScene=load("res://assets/freight_"+spec[0]+".glb")
		for col in range(spec[2]):
			for row in range(3):
				for layer in range(2):
					var item:Node3D=scene.instantiate();add_child(item);spec[1].append(item)
	finish_setup()
func setup_async(owner_view)->void:
	if not first.is_empty():return
	ship=owner_view
	for spec in [["first",first,14],["second",second,6]]:
		var scene:PackedScene=load("res://assets/freight_"+spec[0]+".glb")
		for col in range(spec[2]):
			for row in range(3):
				for layer in range(2):
					var item:Node3D=scene.instantiate();add_child(item);spec[1].append(item)
			if col%2==1:await get_tree().process_frame
	finish_setup()
func finish_setup()->void:
	first_outline=outline(TEAL);free_outline=outline(GOLD)
	first_floor=ship.box(Vector3.ONE,Color(.2,.8,.7,.18));add_child(first_floor)
	free_floor=ship.box(Vector3.ONE,Color(1,.65,.14,.20));add_child(free_floor)
	for i in range(4):
		var label:=Label.new();label.add_theme_font_size_override("font_size",20)
		label.add_theme_color_override("font_color",TEAL if i==2 else GOLD if i==3 else Color("ecf3f7"))
		label.add_theme_color_override("font_shadow_color",Color("102331"));label.add_theme_constant_override("shadow_offset_x",1);label.add_theme_constant_override("shadow_offset_y",2)
		label.mouse_filter=Control.MOUSE_FILTER_IGNORE;ship.add_child(label);labels.append(label);label.hide()
func outline(color:Color)->MeshInstance3D:
	var mesh:=ImmediateMesh.new();mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var bounds:=AABB(Vector3(0,0,-.5),Vector3(1,1,1))
	for i in range(8):
		for bit in [1,2,4]:
			if (i & bit)==0:
				mesh.surface_add_vertex(bounds.get_endpoint(i));mesh.surface_add_vertex(bounds.get_endpoint(i|bit))
	mesh.surface_end()
	var node:=MeshInstance3D.new();node.mesh=mesh
	var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.albedo_color=color
	node.material_override=mat;add_child(node);return node
func tr2(zh:String,ru:String)->String:return zh if lang=="zh" else ru
func region(node:Node3D,x:float,length:float)->void:
	node.position=Vector3(x,BASE,0);node.scale=Vector3(maxf(.001,length),HEIGHT,WIDTH)
func arrange_crates(items:Array[Node3D],cols:int,x:float,length:float)->void:
	var cell:float=length/cols
	for i in range(items.size()):
		var col:int=i/6;var row:int=(i/2)%3;var layer:int=i%2
		var item:Node3D=items[i];item.visible=length>.03
		item.position=Vector3(x+(col+.5)*cell,BASE+layer*HEIGHT/2,(row-1)*WIDTH/3)
		item.scale=Vector3(maxf(.001,cell*.97),HEIGHT/2*.98,WIDTH/3*.97)
func apply(p:Dictionary,v:Dictionary,language:String)->void:
	params=p;values=v;lang=language;phase=str(p.get("cargo_phase","goal"));visible=p.get("cargo_lesson",false)
	for label in labels:label.visible=visible
	if not visible:return
	if first.is_empty():setup(ship)
	first_length=LENGTH*v.b02_first_volume_m3/v.b02_capacity_volume_m3
	second_length=LENGTH*(v.b02_used_m3-v.b02_first_volume_m3)/v.b02_capacity_volume_m3
	arrange_crates(first,14,START,first_length)
	arrange_crates(second,6,START+first_length,second_length)
	# Fixed-size crates arrive in successive columns; the stowage boundary below
	# remains the exact aggregate volume throughout this illustrative movement.
	var full_second:float=LENGTH*v.b02_second_port_mass_t*v.b02_second_port_stowage_m3_t/v.b02_capacity_volume_m3
	var loaded:float=v.b02_added_t/v.b02_second_port_mass_t
	for i in range(second.size()):
		var col:int=i/6;var row:int=(i/2)%3;var layer:int=i%2
		var arrival:float=clampf(loaded*6-col,0,1)
		second[i].visible=arrival>0
		second[i].position=Vector3(START+first_length+(col+.5)*full_second/6,BASE+layer*HEIGHT/2+(1-arrival)*12,(row-1)*WIDTH/3)
		second[i].scale=Vector3(full_second/6*.97,HEIGHT/2*.98,WIDTH/3*.97)*maxf(.01,arrival)
	var free_start:float=START+first_length+second_length
	region(first_outline,START,first_length)
	region(free_outline,free_start,LENGTH-first_length-second_length)
	first_floor.position=Vector3(START+first_length*.5,BASE+.02,0);first_floor.scale=Vector3(first_length,.05,WIDTH)
	free_floor.position=Vector3((free_start+START+LENGTH)*.5,BASE+.03,0);free_floor.scale=Vector3(maxf(.01,LENGTH-first_length-second_length),.06,WIDTH)
	first_outline.visible=phase in ["given","factor1","volume1"]
	free_outline.visible=phase in ["goal","volume2","factor2","bound","answer","check"]
	first_floor.visible=first_outline.visible;free_floor.visible=free_outline.visible
	var reveal:float=float(p.get("cargo_progress",0))
	labels[0].text=tr2("载货上限  %.0f t","Преде́л ма́ссы  %.0f т")%v.b02_capacity_mass_t
	labels[1].text=tr2("货舱容积  %.0f m³","Вмести́мость  %.0f м³")%v.b02_capacity_volume_m3
	if phase not in ["goal"]:labels[0].text=tr2("货物质量  %.0f / %.0f t","Ма́сса  %.0f / %.0f т")%[v.b02_total_t,v.b02_capacity_mass_t]
	labels[2].text=tr2("第一港货物","Груз пе́рвого по́рта")
	if phase!="goal":labels[2].text+="\n%.0f t"%v.b02_first_port_mass_t
	if reveal>=1.999:labels[2].text+=" · %.0f m³"%v.b02_first_volume_m3
	labels[3].text=tr2("空余舱容","Свобо́дный объём")
	if reveal>=2.999:labels[3].text+="\n%.0f m³"%v.b02_free_m3
	if phase=="mass" and reveal>=.999:labels[3].text=tr2("还能承载\n%.0f t","По ма́ссе ещё\n%.0f т")%v.b02_remaining_mass_t
	if phase=="bound" and reveal>=3.999:labels[3].text=tr2("按舱容可装\n%.2f t","По объёму\n%.2f т")%v.b02_volume_limited_mass_t
	if phase=="answer":labels[3].text=tr2("第二港装入\n%.0f t","Второ́й порт\n%.0f т")%v.b02_added_t
	if lang=="ru":
		for label in labels:label.text=label.text.replace(" t"," т").replace("m³","м³").replace(".",",")
	active_point=Vector3(START+first_length*.5,BASE+HEIGHT*.75,WIDTH*.45)
	if phase in ["goal","volume2","factor2","bound","check"]:active_point=Vector3((free_start+START+LENGTH)*.5,BASE+HEIGHT*.6,0)
	if phase=="answer":active_point=Vector3(START+first_length+maxf(second_length*.5,1),BASE+HEIGHT*.6,0)
	update_overlay()
func project(point:Vector3)->Vector2:return ship.camera.unproject_position(to_global(point))
func update_overlay()->void:
	if not visible or labels.is_empty():return
	labels[0].position=Vector2(22,20);labels[1].position=Vector2(22,52)
	for i in [2,3]:
		var x:float=START+first_length*.5 if i==2 else START+first_length+(LENGTH-first_length)*.5
		var pt:=project(Vector3(x,BASE+HEIGHT+2,-WIDTH*.5))
		var extent:Vector2=labels[i].get_minimum_size()
		labels[i].position=(pt-Vector2(extent.x*.5,extent.y+12)).clamp(Vector2(12,95),ship.size-extent-Vector2(12,12))
	var first_rect:=Rect2(labels[2].position,labels[2].get_minimum_size()).grow(10)
	if first_rect.intersects(Rect2(labels[3].position,labels[3].get_minimum_size())):
		labels[3].position.y=maxf(95,first_rect.position.y-labels[3].get_minimum_size().y-10)
func obstacles()->Array:
	var out:Array=[]
	for label in labels:
		if label.visible:out.append(Rect2(label.position,label.get_minimum_size()).grow(10))
	out.append(ship.projected_box(AABB(Vector3(START,BASE,-WIDTH*.5),Vector3(LENGTH,HEIGHT,WIDTH)),global_transform).grow(12))
	return out
