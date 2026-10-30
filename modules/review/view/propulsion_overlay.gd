extends Control
var view
const GOLD=Color("ffcf7b")
const TEAL=Color("77dfcc")
const RED=Color("ff9b91")
var font:Font
var lookup
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE;font=get_theme_default_font()
	lookup=preload("res://modules/review/view/drawn_term_lookup.gd").new();add_child(lookup)
func label_at(text:String,p:Vector2,color:Color)->void:
	var width:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x
	var rect:=Rect2(p+Vector2(-width*.5,-25),Vector2(width+12,31))
	view.labels_bounds.append(rect);draw_style_box(panel(),rect);draw_string(font,rect.position+Vector2(6,22),text,HORIZONTAL_ALIGNMENT_LEFT,-1,20,color)
	if lookup:lookup.add_label(text,rect.position+Vector2(6,22),font,20)
func panel()->StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=Color(.035,.10,.14,.9);s.set_corner_radius_all(5);return s
func arrow(a:Vector3,b:Vector3,color:Color,text:String)->void:
	var x:Vector2=view.project(a);var y:Vector2=view.project(b);var d:Vector2=(y-x).normalized()
	draw_line(x,y,Color(.02,.05,.08),7,true);draw_line(x,y,color,3,true)
	draw_colored_polygon(PackedVector2Array([y,y-d*13+d.orthogonal()*6,y-d*13-d.orthogonal()*6]),color)
	label_at(text,y+Vector2(0,-12),color)
func _draw()->void:
	if not view or view.state.is_empty():return
	if lookup:lookup.clear_labels()
	view.labels_bounds.clear()
	var scene:String=view.state.get("scene","overview");var p:float=float(view.state.get("p",0));var m:Dictionary=view.metrics
	if view.detail_container.visible:
		draw_rect(view.detail_rect,Color("658d98"),false,1)
		var note:String=view.tr2("机舱与轴系","Вал и ди́зели") if view.engine_open else view.tr2("从艇底看浸水范围","Смо́ченная часть сни́зу")
		label_at(note,view.detail_rect.position+Vector2(view.detail_rect.size.x*.5,28),TEAL)
	if scene in ["regimes","planing"]:
		var origin:Vector3=view.point(Vector3(0,1.,2.5))
		arrow(origin+Vector3(0,3,0),origin,RED,view.tr2("重力","Си́ла тя́жести"))
		var base:=Vector3(-1.5,-1.,2.5)
		arrow(base,base+Vector3.UP*3.*m.buoyancy,TEAL,view.tr2("浮力","Си́ла плаву́чести"))
		if m.lift>.015:arrow(base+Vector3(4,0,0),base+Vector3(4,3.*m.lift,0),GOLD,view.tr2("动升力","Подъёмная си́ла"))
		label_at(view.tr2("浸水艇壳","Смо́ченная пове́рхность"),view.project(view.point(Vector3(1,.4,1.5)))+Vector2(0,45),TEAL)
	elif scene=="froude":
		arrow(Vector3(2,1,2.8),Vector3(4+p*2,1,2.8),GOLD,view.tr2("航速 v","Ско́рость v"))
		var a:Vector2=view.project(view.point(Vector3(-6.4,0,0)))+Vector2(0,55);var b:Vector2=view.project(view.point(Vector3(6.4,0,0)))+Vector2(0,55)
		draw_line(a,b,TEAL,2,true);draw_line(a-Vector2(0,6),a+Vector2(0,6),TEAL,2);draw_line(b-Vector2(0,6),b+Vector2(0,6),TEAL,2);label_at("L = 12.8 m",(a+b)*.5,TEAL)
	elif scene=="tow":
		arrow(Vector3(-1,.8,2.7),Vector3(-4,.8,2.7),RED,view.tr2("阻力 R","Сопротивле́ние R"))
		arrow(Vector3(2,1.2,2.5),Vector3(5,1.2,2.5),GOLD,view.tr2("航速 v","Ско́рость v"))
	elif view.engine_open:
		var name_:String="engine" if p<.34 else ("shaft" if p<.67 else "propeller")
		var text:String={"engine":view.tr2("柴油机","Ди́зель"),"shaft":view.tr2("齿轮箱与轴系","Ре́дуктор и валопрово́д"),"propeller":view.tr2("螺旋桨","Винт")}[name_]
		var a:Vector2=view.detail_project(view.overlay_points[name_]);draw_circle(a,5,TEAL);label_at(text,a+Vector2(0,-40),TEAL);draw_line(a,a+Vector2(0,-36),TEAL,2,true)
		if scene=="wake":
			for z in [-.78,.78]:arrow(view.point(Vector3(-5.5,.35,z)),view.point(Vector3(-7.6,.35,z)),TEAL,view.tr2("来流","Пото́к"))
