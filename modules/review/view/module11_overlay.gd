extends Control
var view
var bounds:Array=[]
var elapsed:=0.0
var last_shape:Dictionary={}
var source_image:Texture2D
var label_lookup=preload("res://modules/review/view/drawn_term_lookup.gd").new()
var label_context:=""
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(label_lookup)
	source_image=load("res://modules/review/assets/module11/lines.png")
func _process(dt:float)->void:
	if not is_visible_in_tree() or not view:return
	if view.source_state.get("topic","")=="hullform" and float(view.source_state.get("wave",0))>0:
		elapsed+=dt;queue_redraw()
func point(p:Vector3)->Vector2:return view.project(view.bodies[0].to_global(p))
func label(text:String,position_:Vector2,color:Color)->void:
	var width:=get_theme_default_font().get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x
	var at:=position_.clamp(Vector2(10,26),size-Vector2(width+12,12))
	draw_string(get_theme_default_font(),at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,20,color)
	label_lookup.add_label(text,at,get_theme_default_font(),20)
	bounds.append(Rect2(at-Vector2(0,23),Vector2(width,28)))
func _draw()->void:
	bounds.clear()
	if not view or view.source_state.is_empty():return
	var s:Dictionary=view.source_state;var phase:String=s.get("phase","");var free:bool=s.get("topic","")=="freeboard"
	var context:String=phase+view.language
	if label_context!=context:label_context=context;label_lookup.clear_labels()
	else:label_lookup.regions.clear()
	var teal:=Color("76ded0");var gold:=Color("ffd078")
	if phase=="drawing" and source_image:
		# Project this exact detailed hull, not the unrelated example ship in Fig.17.
		var rect:=Rect2(Vector2(20,125),Vector2(size.x-40,minf(size.y*.43,290)))
		draw_style_box(get_theme_stylebox("panel","Panel"),rect)
		var geo=preload("res://modules/review/core/module11_math.gd")
		var vertices:Array=geo.vertices(s);var n:int=geo.geometry().ring_size
		for projection in 3:
			var box:=Rect2(rect.position+Vector2(8+projection*rect.size.x/3,30),Vector2(rect.size.x/3-16,rect.size.y-50))
			var caption:String=(["侧视","俯视","横剖"] if view.language=="zh" else ["Бок","Полуширота́","Ко́рпус"])[projection]
			label(caption,box.position-Vector2(0,5),gold)
			for idx in [8,16,24,32,40,44]:
				var poly:=PackedVector2Array()
				for j in n+1:
					var v:Vector3=vertices[idx*n+j%n]
					var xy:=Vector2((v.x+100)/205,1-v.y/18) if projection==0 else (Vector2((v.x+100)/205,(v.z+15)/30) if projection==1 else Vector2((v.z+15)/30,1-v.y/18))
					poly.append(box.position+xy*box.size)
				draw_polyline(poly,teal,1.6,true)
			for j in ([1,6,11,18] if projection<2 else []):
				var poly:=PackedVector2Array()
				for idx in int(geo.geometry().ring_count):
					var v:Vector3=vertices[idx*n+j]
					var xy:=Vector2((v.x+100)/205,1-v.y/18) if projection==0 else Vector2((v.x+100)/205,(v.z+15)/30)
					poly.append(box.position+xy*box.size)
				draw_polyline(poly,gold,1.5,true)
		bounds.append(rect)
	if phase in ["midship","bowsection"]:
		label(view.tr2("水线","Ватерли́ния"),point(Vector3(-1.59 if phase=="midship" else 70,10.88,-13))+Vector2(8,-12),teal)
	if phase=="waterline":
		var names:=["凸形水线","直线过渡","略凹水线"] if view.language=="zh" else ["Вы́пуклая","Пряма́я","Сле́гка во́гнутая"]
		var idx:int=0 if float(s.get("waterline",0))<.25 else (1 if float(s.get("waterline",0))<.75 else 2)
		label(names[idx],point(Vector3(58,11,-12)),gold)
	if phase=="affine":
		var m:Dictionary=preload("res://modules/review/core/module11_math.gd").values(s)
		for text in ["L · "+m.m11_l+" m","B · "+m.m11_b+" m","T · "+m.m11_t+" m"]:
			var i:int=["L","B","T"].find(text[0]);label(text,Vector2(25,150+i*29),gold)
	if phase in ["bow_waves","flare"]:
		label(view.tr2("艏楼" if phase=="bow_waves" else "水线上方的外飘","Бак" if phase=="bow_waves" else "Разва́л вы́ше воды́"),point(Vector3(75,17,-7))+Vector2(8,-8),gold)
	if float(s.get("wave",0))<=0:return
	if phase=="bulb":
		# Two qualitative wave traces, no CFD pressure or resistance output.
		for k in 2:
			var poly:=PackedVector2Array()
			for j in 65:
				var x:float=62+j*.7;var a:float=(x-62)*.35-elapsed*2.+k*PI
				poly.append(point(Vector3(x,10.88+sin(a)*.55,-7.-k*2)))
			draw_polyline(poly,teal if k==0 else gold,2.5,true)
	elif phase=="stern":
		for z in [-2.,2.]:
			var line:=PackedVector2Array()
			for j in 25:line.append(point(Vector3(-75-j*1.4,4+sin(j*.22)*.25,z)))
			draw_polyline(line,teal,2.5,true)
