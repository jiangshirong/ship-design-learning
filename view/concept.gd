extends Control
var visual:=""
var beat:Dictionary={}
var data:Dictionary={}
var language:="zh"
var font:SystemFont
var latex_renderer
var hint_regions:Array=[]
var route_labels:Array[TextEdit]=[]
var approximation_diagrams=preload("res://view/approximation_diagrams.gd").new()
const WHITE=Color("dbe8ef")
const MUTE=Color("8daebb")
const TEAL=Color("70d2c4")
const GOLD=Color("f5c879")
func _ready()->void:
	latex_renderer=preload("res://view/latex_panel.gd").new();add_child(latex_renderer);latex_renderer.hide()
	font=SystemFont.new();font.font_names=PackedStringArray(["Arial","Microsoft YaHei"]);mouse_filter=Control.MOUSE_FILTER_PASS
func tr2(a:String,b:String)->String:return a if language=="zh" else b
func update_view(kind:String,b:Dictionary,v:Dictionary,lang:String)->void:
	visual=kind;beat=b;data=v;language=lang
	for label in route_labels:label.visible=kind=="roadmap"
	queue_redraw()
func annotation_anchor()->Vector2:
	if visual.begins_with("approx_"):return approximation_diagrams.anchor
	match visual:
		"roadmap":return Vector2(size.x*.49,size.y*.52)
		"free_surface":return Vector2(size.x*.5,size.y*.37)
		"dependencies":
			var reveal:float=float(data.get("dependency_reveal",3))
			var stage:int=1 if beat.id=="T03:dependencies" else 2 if beat.id=="T03:power_dependency" else 3
			var amount:float=clampf(reveal-stage+1,0,1)
			var start:=Vector2(size.x*(.75 if stage==3 else .5),size.y*(.37 if stage==3 else .16)+60)
			var end:=Vector2(size.x*(.25 if stage==1 else .75),size.y*(.59 if stage==3 else .37))
			return start.lerp(end,amount) if amount<1 else end+Vector2(0,30)
		"section":return Vector2(size.x*.5,size.y*.45)
		"trim":return Vector2(size.x*.8,size.y*.34+68+clampf(float(data.get("trim_progress",0)),0,1)*68*(6.3/3.5-1))
		"cargo_limits","interval":return Vector2(size.x*.5,size.y*.48)
		"fullness":return Vector2(size.x*.5,size.y*.65)
		"cargo":return Vector2(size.x*.55,size.y*.55+24)
		"stability":
			var s:float=minf(size.x*.32,size.y*.37)
			var centre:=Vector2(size.x*.5,size.y*.62)
			if beat.id=="T12:centres":return centre+Vector2(0,s*.2)
			if beat.id=="T12:metacentre":return centre+Vector2(0,-s*.9)
			return centre+Vector2(0,-s*.575)
		"ost":return Vector2(size.x*.5,size.y*.65)
		"mass","volume":return Vector2(size.x*.58,size.y*.65)
		"root":
			var x:float=beat.get("root_x",pow(data.D_exact,1.0/3.0))
			var y:float=data.a*x*x*x-data.b*x*x-data.c
			return Vector2(55+(x-33.5)/3.5*(size.x-85),65+(6000-y)/12000*(size.y-135))
	return size*.5
func annotation_obstacles()->Array:
	if visual.begins_with("approx_"):return [approximation_diagrams.area.grow(8)]
	if visual=="stability":
		var centre:=Vector2(size.x*.5,size.y*.62)
		var s:float=minf(size.x*.32,size.y*.37)
		return [Rect2(centre+Vector2(-12,-s*.9-20),Vector2(85,s*1.4+40))]
	if visual=="roadmap":return [Rect2(size.x*.05,size.y*.16,size.x*.44,size.y*.48)]
	if visual in ["free_surface"]:return [Rect2(16,size.y*.13,size.x-32,size.y*.47)]
	if visual in ["section","cargo_limits","trim","interval","dependencies"]:
		return [Rect2(0,0,size.x,50),Rect2(size.x*.10,size.y*.13,size.x*.87,size.y*.60)]
	if visual!="root":return [Rect2(Vector2.ZERO,size)]
	var regions:Array=[Rect2(0,0,size.x,48),Rect2(0,size.y-65,size.x,65),Rect2(45,60,20,size.y-120),Rect2(50,65+(size.y-135)*.5-6,size.x-75,12)]
	var previous:=Vector2.ZERO
	for i in range(101):
		var x:float=lerpf(33.5,37.0,float(i)/100)
		var y:float=data.a*x*x*x-data.b*x*x-data.c
		var point:=Vector2(55+(x-33.5)/3.5*(size.x-85),65+(6000-y)/12000*(size.y-135))
		if i>0:regions.append(Rect2(previous,Vector2.ZERO).expand(point).grow(10))
		previous=point
	regions.append(Rect2(annotation_anchor()-Vector2(12,12),Vector2(24,24)))
	return regions
func text(at:Vector2,value:String,color:Color=WHITE,sz:int=20,width:float=-1)->void:draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,width,sz,color)
func formula(at:Vector2,id:String,color:Color=WHITE,fs:int=24)->void:
	var source:Dictionary=latex_renderer.bundle.lessons["_concept/"+id].zh[0]
	var asset:Dictionary=latex_renderer.bundle.assets[source.full]
	var factor:float=minf(float(fs)/28,(size.x-at.x-25)/float(asset.width))
	var texture:Texture2D=latex_renderer.texture_for(source.full)
	var target:=Rect2(at-Vector2(0,asset.baseline*factor),Vector2(asset.width,asset.height)*factor)
	if texture:draw_texture_rect(texture,target,false,color)
	for hint in asset.get("hints",[]):
		var r:Array=hint.rect
		hint_regions.append({"rect":Rect2(target.position+Vector2(r[0],r[1])*factor,Vector2(r[2],r[3])*factor),"text":hint.text})
func _get_tooltip(at:Vector2)->String:
	for hint in hint_regions:
		if hint.rect.grow(2).has_point(at):return hint.text
	return ""
func _make_custom_tooltip(value:String)->Object:
	return latex_renderer._make_custom_tooltip(value)
func _gui_input(event:InputEvent)->void:
	if visual=="approx_chart" and approximation_diagrams.h!=null and approximation_diagrams.chart_input(event):accept_event()
func _draw()->void:
	hint_regions.clear()
	if data.is_empty() or size.x<200 or size.y<200:return
	draw_rect(Rect2(Vector2.ZERO,size),Color("112432"))
	if visual.begins_with("approx_"):
		approximation_diagrams.draw(self);return
	match visual:
		"roadmap":roadmap()
		"free_surface":free_surface()
		"section":section()
		"cargo_limits":cargo_limits()
		"trim":trim_diagram()
		"interval":interval()
		"dependencies":dependencies()
		"fullness":fullness()
		"cargo":cargo()
		"root":root_graph()
		"mass":masses()
		"ost":classification()
		"stability":stability()
		"volume":volume_bars()

func roadmap()->void:
	var nodes:Array=beat.get("roadmap",[])
	while route_labels.size()<nodes.size():
		var label=preload("res://view/selectable_text.gd").new();label.fit_content=false
		label.add_theme_font_override("font",font);label.add_theme_font_size_override("font_size",24)
		add_child(label);label.scroll_fit_content_height=true;route_labels.append(label)
	for i in range(nodes.size()):
		var box:=Rect2(size.x*.05,size.y*(.17+.16*i),size.x*.44,size.y*.115)
		var style:=StyleBoxFlat.new();style.bg_color=Color("203c4c");style.border_color=TEAL
		style.set_border_width_all(2);style.set_corner_radius_all(12);draw_style_box(style,box)
		var label=route_labels[i];label.show()
		label.position=box.position+Vector2(18,10);label.size=box.size-Vector2(36,20)
		label.set_content(str(i+1)+"  "+str(nodes[i][language]))
		if i<nodes.size()-1:
			var a:=Vector2(box.get_center().x,box.end.y+3);var b:=a+Vector2(0,size.y*.045-7)
			draw_line(a,b,TEAL,3,true);draw_line(b,b+Vector2(-7,-9),TEAL,3,true);draw_line(b,b+Vector2(7,-9),TEAL,3,true)

func free_surface()->void:
	# An isolated conceptual cross-section: no dimensions or source tank number.
	var angle:float=float(data.get("surface_roll",0))*.14
	var centre:=Vector2(size.x*.5,size.y*.37);var w:float=minf(size.x*.68,440);var h:=size.y*.24
	var corners:=PackedVector2Array()
	for p in [Vector2(-w/2,-h/2),Vector2(w/2,-h/2),Vector2(w/2,h/2),Vector2(-w/2,h/2)]:corners.append(centre+p.rotated(angle))
	# Intersect the rotated sidewalls with the world-horizontal liquid plane.
	var y:float=centre.y
	var l:Vector2=corners[0].lerp(corners[3],(y-corners[0].y)/(corners[3].y-corners[0].y))
	var r:Vector2=corners[1].lerp(corners[2],(y-corners[1].y)/(corners[2].y-corners[1].y))
	var liquid:=PackedVector2Array([l,r,corners[2],corners[3]])
	draw_colored_polygon(liquid,Color("96612f"));draw_polyline(PackedVector2Array([corners[0],corners[3],corners[2],corners[1]]),MUTE,5,true)
	draw_line(l,r,GOLD,4,true)
	text(Vector2(centre.x-w/2,centre.y-h/2-22),tr2("液面保持水平","Пове́рхность горизонта́льна"),GOLD,22)
	# Polygon centroid by area, so the marker follows the actual drawn liquid.
	var sum:=0.0;var moment:=Vector2.ZERO
	for i in range(liquid.size()):
		var p:Vector2=liquid[i];var q:Vector2=liquid[(i+1)%liquid.size()];var cross:float=p.cross(q)
		sum+=cross;moment+=(p+q)*cross
	var cg:Vector2=moment/(3*sum)
	draw_circle(cg,6,TEAL);text(cg+Vector2(12,6),tr2("液体重心","Центр жи́дкости"),TEAL,19)
func fullness()->void:
	text(Vector2(25,35),tr2("实际几何 / 参考几何","Реа́льная / опи́санная геоме́трия"))
	var r:=Rect2(Vector2(size.x*.15,size.y*.23),Vector2(size.x*.7,size.y*.48))
	draw_rect(r,Color("294757"));draw_rect(r,MUTE,false,2)
	var points:=PackedVector2Array([r.position,r.position+Vector2(r.size.x,0),r.position+r.size,r.position+Vector2(0,r.size.y)])
	for i in range(12):
		var x:float=r.position.x+r.size.x*i/11;var u:float=float(i)/11
		var height:float=r.size.y*sqrt(maxf(0,1-pow(2*u-1,2)))
		draw_line(Vector2(x,r.end.y),Vector2(x,r.end.y-height),TEAL,maxf(r.size.x/12-3,2))
	formula(r.position+Vector2(15,30),"area",TEAL,24)
	text(Vector2(r.position.x+r.size.x*.45,r.end.y+28),"B",WHITE)
	text(Vector2(r.end.x+12,r.position.y+r.size.y*.55),"T",WHITE)
	formula(Vector2(25,size.y-55),"fullness",GOLD,24)
func bar(y:float,label:String,ratio:float,value:String,color:Color)->void:
	text(Vector2(25,y),label,WHITE,18)
	var rect:=Rect2(25,y+12,size.x-50,24)
	draw_rect(rect,Color("284452"));draw_rect(Rect2(rect.position,Vector2(rect.size.x*clampf(ratio,0,1),rect.size.y)),color)
	text(Vector2(25,y+63),value,MUTE,17)
func cargo()->void:
	text(Vector2(25,35),tr2("两种限制，取较小值","Два ограни́чения — берём ми́нимум"))
	bar(size.y*.26,tr2("剩余质量","Оста́ток ма́ссы"),5000.0/6000,"5000 t",TEAL)
	bar(size.y*.55,tr2("剩余容积折合质量","Объём в пересчёте на ма́ссу"),5112.3967/6000,"",Color("729fc1"))
	formula(Vector2(25,size.y*.55+65),"cargo",MUTE,17)
	text(Vector2(25,size.y-26),tr2("可装 5000 t；容积仍剩 136 m³","Груз 5000 т; свобо́дный объём 136 м³"),GOLD,20)
func root_graph()->void:
	formula(Vector2(25,35),"root",WHITE,23)
	var area:=Rect2(55,65,size.x-85,size.y-135)
	var xmin:=33.5;var xmax:=37.0;var ymin:=-6000.0;var ymax:=6000.0
	var project:=func(x:float,y:float)->Vector2:return area.position+Vector2((x-xmin)/(xmax-xmin)*area.size.x,(ymax-y)/(ymax-ymin)*area.size.y)
	draw_line(project.call(xmin,0),project.call(xmax,0),MUTE,1.5)
	draw_line(area.position,area.position+Vector2(0,area.size.y),MUTE,1.5)
	var pts:=PackedVector2Array()
	for i in range(100):
		var x:float=lerpf(xmin,xmax,float(i)/99);pts.append(project.call(x,data.a*x*x*x-data.b*x*x-data.c))
	draw_polyline(pts,TEAL,3,true)
	var x:float=beat.get("root_x",pow(data.D_exact,1.0/3.0));var y:float=data.a*x*x*x-data.b*x*x-data.c
	var point:Vector2=project.call(x,y);draw_circle(point,7,GOLD);draw_line(point,project.call(x,0),GOLD,1.5)
	text(Vector2(25,size.y-38),"X = %.8f"%x,GOLD,21)
	text(Vector2(size.x*.5,size.y-38),"f = %.6f"%y,MUTE,18)
	text(Vector2(25,size.y-12),tr2("横轴：X；纵轴：质量方程残差","X по горизонта́ли; невя́зка по вертика́ли"),MUTE,15)
func masses()->void:
	text(Vector2(25,35),tr2("排水量由六项质量组成","Шесть ста́тей водоизмеще́ния"))
	var zh:=["船体设备","动力装置","燃料","设计余量","供应","货物"]
	var ru:=["Ко́рпус","Устано́вка","То́пливо","Запа́с","Снабже́ние","Груз"]
	var colors:=[TEAL,Color("719ac7"),GOLD,Color("b5a1d0"),Color("9fbc83"),Color("4e97aa")]
	var known:bool=beat.id.begins_with("t2-back")
	for i in range(6):
		var y:float=80+i*(size.y-120)/6
		text(Vector2(25,y),(zh if language=="zh" else ru)[i],WHITE,19)
		if known:
			var w:float=(size.x-230)*data.mass[i]/data.D
			draw_rect(Rect2(170,y-15,maxf(w,2),18),colors[i]);text(Vector2(175+w,y),"%.1f"%data.mass[i],MUTE,15)
		else:formula(Vector2(170,y),"mass%d"%i,colors[i],20)
	formula(Vector2(25,size.y-18),"mass_total",GOLD,20)
func classification()->void:
	text(Vector2(25,35),tr2("同名 ≠ 同用途","Одно́ назва́ние ≠ одно́ назначе́ние"))
	var labels:Array=[tr2("原始质量项","Исхо́дная ста́тья"),tr2("名称层级 + 备注","У́ровень + примеча́ние"),tr2("按实际用途判断","Реше́ние по назначе́нию")]
	for i in range(3):
		var rect:=Rect2(35,75+i*(size.y-150)/3,size.x-70,70)
		draw_rect(rect,Color("274657"));draw_rect(Rect2(rect.position,Vector2(4,70)),TEAL)
		text(rect.position+Vector2(20,43),labels[i],WHITE,22)
		if i<2:draw_line(Vector2(size.x*.5,rect.end.y+4),Vector2(size.x*.5,rect.end.y+20),TEAL,2)
	text(Vector2(25,size.y-28),tr2("43 项只累计一次 · 总计 16494.04 t","43 ста́тьи оди́н раз · 16494.04 т"),GOLD,20)
func stability()->void:
	text(Vector2(25,35),tr2("小角度初稳性示意","Схе́ма нача́льной осто́йчивости"))
	var c:=Vector2(size.x*.5,size.y*.62);var s:float=minf(size.x*.32,size.y*.37)
	var shape:=PackedVector2Array([c+Vector2(-s,-s*.5),c+Vector2(s,-s*.5),c+Vector2(s*.7,s*.5),c+Vector2(-s*.7,s*.5)])
	draw_colored_polygon(shape,Color("386075"));draw_line(Vector2(25,c.y),Vector2(size.x-25,c.y),Color("60b6dc"),2)
	var m:=c+Vector2(0,-s*.9);var g:=c+Vector2(0,-s*.25);var b:=c+Vector2(0,s*.2)
	draw_line(m,c+Vector2(0,s*.8),MUTE,1.5)
	var k:=c+Vector2(0,s*.5)
	for spec in [[m,"M",TEAL],[g,"G",GOLD],[b,"C",Color("74b5df")],[k,"K",MUTE]]:
		draw_circle(spec[0],6,spec[2]);text(spec[0]+Vector2(12,7),spec[1],spec[2],23)
	formula(Vector2(25,size.y-35),"stability",GOLD,24)
func volume_bars()->void:
	text(Vector2(25,35),tr2("空间需求逐项组成","Соста́в потре́бного объёма"))
	var names:Array=[tr2("液货","Груз"),tr2("机舱","Маши́нное"),tr2("燃油","То́пливо"),tr2("淡水","Вода́"),tr2("压载舱","Балла́ст")]
	var keys:=["Wcargo","Wpower","Wfuel","Wfresh","Wballast"]
	var current:int=int(data.get("volume_count",0))
	if current==0:current={"cargo":1,"engine":2,"fuelwater":4,"ballast":5,"total":5}.get(str(beat.id).get_slice(":",1),0)
	for i in range(current):
		var y:float=85+i*(size.y-130)/5;text(Vector2(25,y),names[i],WHITE,18)
		draw_rect(Rect2(165,y-16,(size.x-210)*data[keys[i]]/data.Wreq,20),TEAL)
	formula(Vector2(25,size.y-25),"volume",GOLD,24)

func section()->void:
	var r:=Rect2(size.x*.17,size.y*.23,size.x*.60,size.y*.32)
	var level:float=float(data.get("b01_reveal",1))
	var points:=PackedVector2Array([r.position,Vector2(r.end.x,r.position.y),r.position+r.size*Vector2(.6,1),r.position+r.size*Vector2(.4,1)])
	draw_colored_polygon(points,TEAL*Color(1,1,1,.6));draw_polyline(PackedVector2Array([points[0],points[3],points[2],points[1]]),TEAL,4,true)
	draw_line(Vector2(r.position.x-20,r.position.y),Vector2(r.end.x+20,r.position.y),Color("71bce8"),3,true)
	text(r.position+Vector2(r.size.x*.29,42),"45 m²",WHITE,26)
	text(Vector2(20,30),tr2("船中横剖面","Ми́дель"),MUTE,18)
	if level>1:
		var end:=Vector2(lerpf(r.position.x,r.end.x,minf(level-1,1)),r.position.y-25)
		draw_line(r.position-Vector2(0,25),end,GOLD,3,true)
		text(r.position+Vector2(r.size.x*.3,-40),"B = 15 m",GOLD,24)
	if level>2:
		var top:=Vector2(r.end.x+26,r.end.y);var end:=Vector2(top.x,lerpf(r.end.y,r.position.y,minf(level-2,1)))
		draw_line(top,end,GOLD,3,true);text(Vector2(r.end.x+32,r.position.y+r.size.y*.5),"T = 5 m",GOLD,22)
		draw_line(Vector2(r.position.x-20,r.end.y),Vector2(r.end.x+25,r.end.y),Color("ff8dc8"),2,true)
	if level>3:
		draw_rect(r,Color(1,.78,.4,minf(level-3,1)),false,3)
		text(Vector2(r.position.x,r.end.y+34),"B × T = 75 m²",GOLD,24)
	if level>=4.99:text(Vector2(size.x*.41,r.position.y+r.size.y*.72),"60%",WHITE,30)
func cargo_limits()->void:
	var level:float=data.get("cargo_progress",0)
	text(Vector2(24,36),tr2("质量上限 / 舱容上限","Преде́лы ма́ссы / объёма"),WHITE,22)
	bar(size.y*.24,tr2("载货质量","Ма́сса гру́за"),10950.0/15950,"10950 / 15950 t",TEAL)
	if level>=2:bar(size.y*.53,tr2("占用舱容","За́нятый объём"),14454.0/20640,"14454 / 20640 m³",Color("729fc1"))
	if level>=5:
		text(Vector2(24,size.y-52),tr2("再装 5000 t","Ещё 5000 т"),GOLD,26)
	if level>=6:text(Vector2(24,size.y-22),tr2("剩余 136 m³","Остаётся 136 м³"),WHITE,22)
func trim_diagram()->void:
	var level:float=data.get("trim_progress",0)
	var left:=Vector2(size.x*.17,size.y*.34);var right:=Vector2(size.x*.8,size.y*.34)
	var shift:float=clampf(level,0,1)*68*(6.3/3.5-1)
	var hull_points:=PackedVector2Array([left+Vector2(-25,-32),right+Vector2(25,shift-32),right+Vector2(-15,shift+68),left+Vector2(15,68)])
	draw_colored_polygon(hull_points,Color("386075"));draw_line(Vector2(20,left.y),Vector2(size.x-20,left.y),Color("71bce8"),3,true)
	text(left+Vector2(-10,115),tr2("艉","Корма́"),WHITE,23);text(right+Vector2(-10,shift+115),tr2("艏","Нос"),WHITE,23)
	draw_line(left,left+Vector2(0,68),GOLD,3,true);text(left+Vector2(8,45),"3.5 m",GOLD,22)
	if level>0 and level<2:
		draw_line(right,right+Vector2(0,shift+68),TEAL,4,true)
		draw_circle(right+Vector2(0,shift+68),5,TEAL,true,-1,true)
	if level>=2:
		draw_line(right,right+Vector2(0,shift+68),GOLD,3,true);text(right+Vector2(8,65),"6.3 m",GOLD,22)
	if level>=3:text(Vector2(size.x*.39,size.y*.78),"T = 4.9 m",WHITE,25)
func interval()->void:
	var trace:Dictionary=beat.get("solver_row",{})
	if trace.is_empty():return
	var y:=size.y*.44;var a:=Vector2(40,y);var b:=Vector2(size.x-40,y);var mid:=(a+b)*.5
	draw_line(a,b,TEAL,4,true)
	for point in [a,mid,b]:draw_circle(point,7,GOLD)
	text(Vector2(24,36),tr2("二分区间","Интерва́л бисе́кции"),WHITE,24)
	text(a+Vector2(-12,36),"%.5f"%trace.left,WHITE,18)
	text(mid+Vector2(-45,-24),"%.5f"%trace.mid,GOLD,22)
	text(b+Vector2(-82,36),"%.5f"%trace.right,WHITE,18)
	text(Vector2(24,y+85),"f = %.8f"%trace.residual,WHITE,22)

func dependencies()->void:
	var boxes:Array=[Rect2(size.x*.38,size.y*.16,size.x*.24,60),Rect2(size.x*.10,size.y*.37,size.x*.30,60),Rect2(size.x*.60,size.y*.37,size.x*.30,60),Rect2(size.x*.10,size.y*.59,size.x*.30,60),Rect2(size.x*.60,size.y*.59,size.x*.30,60)]
	var names:=["D",tr2("船体质量","Ко́рпус"),tr2("功率 N","Мо́щность N"),tr2("动力装置质量","Устано́вка"),tr2("燃油质量","То́пливо")]
	var reveal:float=float(data.get("dependency_reveal",3))
	for edge in [[0,1,1],[0,2,2],[2,3,3],[2,4,3]]:
		var amount:float=clampf(reveal-float(edge[2])+1,0,1)
		if amount<=0:continue
		var a:Vector2=boxes[edge[0]].get_center()+Vector2(0,30);var b:Vector2=boxes[edge[1]].get_center()-Vector2(0,30)
		draw_line(a,a.lerp(b,amount),TEAL,3,true);draw_circle(a.lerp(b,amount),4,TEAL)
	for i in range(boxes.size()):
		if i>0 and reveal<float([0,1,2,3,3][i]):continue
		draw_rect(boxes[i],Color("284757"));draw_rect(boxes[i],TEAL,false,2)
		text(boxes[i].position+Vector2(10,36),names[i],WHITE,20)
