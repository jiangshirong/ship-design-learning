extends Control
var label_lookup=preload("res://modules/review/view/drawn_term_lookup.gd").new()
const M=preload("res://modules/review/core/teaching_math.gd")
var lesson_id:="Q03"
var language:="zh"
var phase:="intro"
var progress:=0.0
var camera_motion:=false
var camera_tween:Tween
var math_panel
var metrics:Dictionary={}
var teal:=Color("75d7c8")
var gold:=Color("f4cb7d")
var blue:=Color("73c8f3")
var ink:=Color("dce7ee")
var red:=Color("f28d84")
func _ready()->void:
	add_child(label_lookup)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	math_panel=preload("res://modules/review/view/latex_panel.gd").new();add_child(math_panel)
	resized.connect(arrange);arrange()
func tr2(zh:String,ru:String)->String:return zh if language=="zh" else ru
func apply(state:Dictionary,focus:String,lang:String)->void:
	progress=clampf(float(state.get("progress",0)),0,1);phase=focus;language=lang;metrics=M.values(lesson_id,progress)
	var shown:=phase
	if phase=="change" and progress>=.999 and lesson_id in ["Q07","Q08","Q09","Q10"]:shown="result"
	math_panel.set_beat(lesson_id+":"+shown,{"xg":"%.2f"%float(metrics.get("xg",0)),"zg":"%.2f"%float(metrics.get("zg",0))},language)
	arrange();queue_redraw()
func arrange()->void:
	if math_panel:math_panel.position=Vector2(24,44);math_panel.size.x=maxf(150,size.x-48)
	queue_redraw()
func teach(_focus:String)->void:pass
func cancel()->void:pass
func mass()->int:return 0
func capacity()->float:return 1
func anchor()->Vector2:
	match lesson_id:
		"Q03":return Vector2(size.x*.72,245)
		"Q06":return Vector2(px(float(metrics.get("xg",4))/10),375-float(metrics.get("zg",1))*42)
		"Q07":return Vector2(50+(size.x-100)*.2*progress,275)
		"Q08":return Vector2(137,283) if phase=="intro" else Vector2(280,330)
		"Q09":return Vector2(lerpf(90,size.x-90,progress),275)
		"Q10":return Vector2(size.x*.75,330)
		"Q12":return Vector2(size.x*.5,295)
		"Q13":return Vector2(size.x*.72,330)
		"Q16":return Vector2(size.x*.5,380-float(metrics.get("zg",2))*45)
		"Q17":return Vector2(size.x*.5,380-(.5+float(metrics.get("r",.333)))*100)
		"Q18":return Vector2(55+(size.x-110)*float(metrics.get("angle_after",110))/180,365)
		"Q19":
			var theta:=0;var peak:=-INF
			for angle in 181:
				var value:=M.arm(lesson_id,deg_to_rad(angle),progress)
				if value>peak:peak=value;theta=angle
			return Vector2(55+(size.x-110)*theta/180.0,365-130*peak)
		"Q20","Q21":return Vector2(size.x*.73,285)
		"Q22":return Vector2(size.x*.58,280+17*progress)
		"Q23":return Vector2(size.x*.6,190 if phase=="intro" else 330)
		"Q24":return Vector2(size.x*.74,285)
		"Q25":return Vector2(size.x*.75,245)
	return Vector2(size.x*.55,330)
func obstacles()->Array:
	var result:Array=[Rect2(20,175,size.x-40,245)]
	if lesson_id=="Q24":result.append(Rect2(20,130,size.x-40,45))
	if math_panel and not math_panel.rows.is_empty():result.append(Rect2(math_panel.position,Vector2(size.x-48,math_panel.custom_minimum_size.y)))
	return result
func px(f:float)->float:return 50+(size.x-100)*f
func txt(s:String,p:Vector2,color:=Color("dce7ee"),fs:=21)->void:
	draw_string(get_theme_font("font"),p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,color)
	label_lookup.add_label(s,p,get_theme_font("font"),fs)
func line(a:Vector2,b:Vector2,color:Color=Color("73c8f3"),width:=2.0)->void:draw_line(a,b,color,width,true)
func arrow(a:Vector2,b:Vector2,color:Color)->void:
	line(a,b,color,3);var u:Vector2=(b-a).normalized();var n:=Vector2(-u.y,u.x)
	draw_colored_polygon(PackedVector2Array([b,b-u*10+n*5,b-u*10-n*5]),color)
func dot(p:Vector2,name_:String,color:Color)->void:
	draw_circle(p,6,color);txt(name_,p+Vector2(10,-9),color,22)
func vessel(center:Vector2,width:float,angle:=0.0,color:Color=Color("75d7c8"))->void:
	var pts:=PackedVector2Array()
	for p in [Vector2(-width*.5,-18),Vector2(width*.5,-18),Vector2(width*.36,28),Vector2(-width*.38,28)]:pts.append(center+p.rotated(angle))
	draw_colored_polygon(pts,color)
	line(center+Vector2(-width*.5,-18).rotated(angle),center+Vector2(width*.5,-18).rotated(angle),ink)
func block(rect:Rect2,color:Color)->void:
	draw_rect(rect,color);draw_rect(rect,ink,false,1)
	line(rect.position+Vector2(rect.size.x*.2,0),rect.position+Vector2(rect.size.x*.2,rect.size.y),gold)
	line(rect.position+Vector2(rect.size.x*.8,0),rect.position+Vector2(rect.size.x*.8,rect.size.y),gold)
func axis(y:=380.0)->void:
	arrow(Vector2(45,y),Vector2(size.x-35,y),ink)
	arrow(Vector2(50,y+8),Vector2(50,205),ink)
func _draw()->void:
	label_lookup.clear_labels()
	draw_rect(Rect2(Vector2.ZERO,size),Color("122735"))
	match lesson_id:
		"Q03":draw_stages()
		"Q06":draw_weights()
		"Q07","Q08":draw_mass_calculation()
		"Q09":draw_voyage()
		"Q10":draw_water()
		"Q12":draw_double_bottom()
		"Q13":draw_tanks()
		"Q16":draw_metacentre()
		"Q17":draw_shape()
		"Q18","Q19":draw_curve()
		"Q20","Q21":draw_roll()
		"Q22","Q23","Q24","Q25":draw_damage()
func draw_stages()->void:
	var w:float=(size.x-100)*.43
	for i in 2:
		var r:=Rect2(50+i*(size.x-100-w),205,w,115)
		draw_rect(r,Color("1c3b4c"));draw_rect(r,gold if i==0 else ink,false,2)
		txt(tr2("草图设计","Эски́зный") if i==0 else tr2("技术设计","Техни́ческий"),r.position+Vector2(14,33),ink)
		if i==0 and progress>0:
			var amount:=clampf(progress,0,1)
			line(r.position+Vector2(20,73),r.position+Vector2(20+40*amount,73),teal,7)
			txt(tr2("检查稳性","Прове́рка"),r.position+Vector2(14,102),teal)
		elif i==1:txt(tr2("规范复核","Тре́бования"),r.position+Vector2(14,102),ink)
	arrow(Vector2(50+w+8,250),Vector2(size.x-50-w-8,250),gold)
func draw_weights()->void:
	axis(375);txt("x / m",Vector2(size.x-90,407));txt("z / m",Vector2(15,198))
	var a:=Vector2(px(.2),333);var b:=Vector2(px(float(metrics.x2)/10),375-float(metrics.z2)*42)
	block(Rect2(a-Vector2(23,12.5),Vector2(46,25)),teal);block(Rect2(b-Vector2(23,12.5),Vector2(46,25)),gold)
	draw_circle(a,3,ink);draw_circle(b,3,ink)
	txt("100 t",a+Vector2(-28,-36),teal);txt("100 t",b+Vector2(-28,-36),gold)
	txt("(2, 1)",a+Vector2(-25,31),teal,17);txt("(%.1f, %.1f)"%[float(metrics.x2),float(metrics.z2)],b+Vector2(-38,31),gold,17)
	dot(Vector2(px(float(metrics.xg)/10),375-float(metrics.zg)*42),"G",red)
	for i in [2,4,6,8]:txt(str(i),Vector2(px(i/10.0)-5,400),ink,17)
	for i in [1,2,3]:txt(str(i),Vector2(29,380-i*42),ink,17)
func draw_mass_calculation()->void:
	txt(tr2("教学例子","Приме́р"),Vector2(28,28),gold,18)
	var w:float=size.x-100
	if lesson_id=="Q07":
		txt("D = 1000 t",Vector2(50,220));draw_rect(Rect2(50,245,w,62),Color("2d4e60"))
		draw_rect(Rect2(50,245,w*.4*progress,62),teal);txt(tr2("船体占40%","Ко́рпус: 40%"),Vector2(50,342),teal)
		if progress>=.999:txt("400 t",Vector2(50+w*.4+12,283),gold,26)
	else:
		var r:=Rect2(60,235,155,96);draw_rect(r,Color("36586a"));draw_rect(r,teal,false,3)
		for i in 4:draw_circle(Vector2(82+i*36,258),12,gold)
		txt("100 t",Vector2(95,306),ink,25);arrow(Vector2(230,280),Vector2(size.x-65,280),gold)
		draw_circle(Vector2(lerpf(235,size.x-70,progress),280),7,teal)
		txt("0.02 t / kW",Vector2(235,245),ink,22)
		if progress>=.999:txt("5000 kW",Vector2(235,330),gold,25)
func draw_voyage()->void:
	txt(tr2("例：120海里，12节，1000 kW","Приме́р: 120 миль, 12 узло́в, 1000 kW"),Vector2(24,28),gold,18)
	line(Vector2(55,300),Vector2(size.x-55,300),blue,3)
	vessel(Vector2(lerpf(90,size.x-90,progress),275),65,0,teal)
	txt("0",Vector2(50,328));txt("120",Vector2(size.x-85,328))
	txt("t = %.1f h"%float(metrics.time),Vector2(50,365),gold)
	txt("%.0f kg"%float(metrics.fuel_kg),Vector2(size.x*.55,365),teal)
func draw_water()->void:
	txt(tr2("例：5人 × 2天 × 150 L","Приме́р: 5 × 2 × 150 L"),Vector2(24,28),gold,20)
	for i in 5:
		var x:=60+i*44;draw_circle(Vector2(x,244),9,ink);line(Vector2(x,254),Vector2(x,285),ink,4)
	txt(tr2("2天","2 дня"),Vector2(70,320),gold)
	var r:=Rect2(size.x*.6,220,size.x*.29,140);draw_rect(r,ink,false,2)
	draw_rect(Rect2(r.position+Vector2(2,r.size.y*(1-progress)+2),Vector2(r.size.x-4,maxf(0,r.size.y*progress-4))),blue)
	txt("%.0f L"%float(metrics.litres),Vector2(r.position.x,391),blue)
func draw_double_bottom()->void:
	txt(tr2("横剖面","Попере́чное сече́ние"),Vector2(40,150),ink)
	var outer:=PackedVector2Array([Vector2(60,180),Vector2(size.x-60,180),Vector2(size.x-120,305),Vector2(120,305),Vector2(60,180)])
	draw_polyline(outer,ink,3,true)
	var inner_y:=265.0
	var fill:=PackedVector2Array([Vector2(101,inner_y),Vector2(size.x-101,inner_y),Vector2(size.x-120,305),Vector2(120,305)])
	draw_colored_polygon(fill,teal*Color(1,1,1,.65));line(Vector2(101,inner_y),Vector2(size.x-101,inner_y),gold,3)
	txt(tr2("内底","Вну́треннее дно"),Vector2(110,250),gold,20)
	txt(tr2("外底","Нару́жное дно"),Vector2(120,335),ink,20)
	if progress>0:
		for i in 7:
			var x:=px(i/6.0);line(Vector2(x,366),Vector2(x,405),gold if i<=int(progress*6) else ink)
		line(Vector2(50,366),Vector2(size.x-50,366),teal);line(Vector2(50,405),Vector2(size.x-50,405),teal)
func draw_tanks()->void:
	var w:float=(size.x-130)*.5
	for i in 2:
		var r:=Rect2(45+i*(w+40),180,w,190);draw_rect(r,ink,false,2)
		if i==0:
			for col in 3:
				for row in 3:block(Rect2(r.position+Vector2(17+col*(w-34)/3,45+row*43),Vector2((w-40)/3,36)),Color("4b8b8b"))
		else:
			var level:=r.size.y*.78*progress
			draw_rect(Rect2(r.position+Vector2(3,r.size.y-level),Vector2(w-6,level-3 if level>3 else 0)),Color("d8ad56"))
			for j in [1,2]:draw_rect(Rect2(r.position+Vector2(j*w/3,65),Vector2(12,125)),Color("476273"))
		txt(tr2("件装货物","Я́щики") if i==0 else tr2("液货舱","Цисте́рна"),r.position+Vector2(5,-18),teal if i==0 else gold,21)
func draw_metacentre()->void:
	txt(tr2("例：M高度4 m，要求h≥1 m","Приме́р: M = 4 m, h ≥ 1 m"),Vector2(24,28),gold,19)
	var x:=size.x*.5;line(Vector2(x,185),Vector2(x,390),ink)
	for key in ["zc","zm","zg"]:
		var name_:String={"zc":"C","zm":"M","zg":"G"}[key]
		dot(Vector2(x,380-float(metrics[key])*45),name_,red if key=="zg" else teal)
	line(Vector2(x-45,200),Vector2(x-45,380-float(metrics.zg)*45),gold,4)
	txt("h = %.1f m"%float(metrics.h),Vector2(x-190,232),gold)
	line(Vector2(60,380),Vector2(size.x-60,380),Color("dca4c5"));txt(tr2("基本平面","Основна́я пло́скость"),Vector2(60,407),ink,18)
func draw_shape()->void:
	txt(tr2("矩形船型：T、G高度不变","Прямоуго́льная фо́рма: T и G те же"),Vector2(24,28),gold,18)
	var w:float=float(metrics.B)*100;var x:=size.x*.5
	draw_rect(Rect2(x-w*.5,230,w,150),Color("355d70"));draw_rect(Rect2(x-w*.5,230,w,150),teal,false,2)
	line(Vector2(40,280),Vector2(size.x-40,280),blue)
	line(Vector2(x,220),Vector2(x,380),ink)
	dot(Vector2(x,330),"C",blue);dot(Vector2(x,310),"G",red)
	var m:=Vector2(x,380-(.5+float(metrics.r))*100);dot(m,"M",gold)
	line(Vector2(x-40,330),Vector2(x-40,m.y),gold,3);txt("r",Vector2(x-60,(330+m.y)*.5),gold)
	txt("B = %.1f m"%float(metrics.B),Vector2(55,411),teal)
func draw_curve()->void:
	var origin:=Vector2(55,365);var w:=size.x-110;var scale:=130.0
	line(origin,origin+Vector2(w+15,0),ink);line(origin+Vector2(0,35),origin-Vector2(0,155),ink)
	txt(tr2("复原力臂","Плечо́"),Vector2(60,190),ink,20);txt("θ",origin+Vector2(w+4,24),ink,22)
	var peak:=Vector2.ZERO;var peak_l:=-INF
	for which in 2:
		var pts:=PackedVector2Array()
		for i in 181:
			var l:=M.arm(lesson_id,deg_to_rad(i),0.0 if which==0 else progress)
			var point:=origin+Vector2(w*i/180.0,-scale*l);pts.append(point)
			if which==1 and l>peak_l:peak_l=l;peak=point
		draw_polyline(pts,Color("7a929e") if which==0 else teal,2 if which==0 else 3,true)
	if lesson_id=="Q18":
		var a:float=metrics.angle_after;var pt:=origin+Vector2(w*a/180,0)
		dot(pt,tr2("消失角","Зака́т"),gold)
	else:dot(peak,tr2("峰值","Ма́ксимум"),gold)
	txt(tr2("灰：原状态　绿：改变后","Се́рый: до　Зелёный: по́сле"),Vector2(55,414),ink,18)
func draw_roll()->void:
	var c1:=Vector2(size.x*.28,285);var c2:=Vector2(size.x*.73,285);var w:=size.x*.30
	line(Vector2(30,285),Vector2(size.x-30,285),blue)
	vessel(c1,w,float(metrics.angle_a));vessel(c2,w*.82 if lesson_id=="Q20" else w,float(metrics.angle_b),gold)
	txt(tr2("原状态","До"),c1+Vector2(-50,-65),teal)
	txt(tr2("h较小","h ме́ньше") if lesson_id=="Q20" else tr2("h过大","h сли́шком большо́е"),c2+Vector2(-75,-65),gold,20)
	# Equal-amplitude time traces reveal period independently from snapshot angle.
	for i in 2:
		var pts:=PackedVector2Array();var freq:=1.0 if i==0 else (1.0/sqrt(2.0) if lesson_id=="Q20" else 2.0)
		for j in range(int(progress*150)+1):pts.append(Vector2(50+(size.x-100)*j/150.0,365+i*36-12*sin(j/150.0*4*PI*freq)))
		if pts.size()>1:draw_polyline(pts,teal if i==0 else gold,2,true)
func draw_damage()->void:
	if lesson_id=="Q23":
		txt(tr2("绿色：尚存的储备浮力空间","Зелёный: запа́с плаву́чести"),Vector2(24,85),teal,19)
		for row in 2:
			txt(tr2("水密舱壁完好","Перебо́рки це́лы") if row==0 else tr2("水密边界失效","Грани́цы нару́шены"),Vector2(50,160+row*120),ink,18)
			for col in 3:
				var r:=Rect2(50+col*(size.x-100)/3,175+row*120,(size.x-100)/3,85)
				draw_rect(r,Color("253d4a"));draw_rect(Rect2(r.position,Vector2(r.size.x,35)),Color("325a48"))
				var fill:=1.0 if col==0 else (clampf(progress*2-(col-1),0,1) if row==1 else 0.0)
				draw_rect(Rect2(r.position,Vector2(r.size.x*fill,85)),Color("356e8c"));draw_rect(r,ink,false,2)
			line(Vector2(35,210+row*120),Vector2(size.x-35,210+row*120),blue)
		return
	if lesson_id=="Q25":
		var cy:=250.0;var nose:=Vector2(size.x-55,cy);var stern:=50.0
		var hull:=PackedVector2Array([Vector2(stern,cy-75),Vector2(size.x-160,cy-75),nose,Vector2(size.x-160,cy+75),Vector2(stern,cy+75),Vector2(stern,cy-75)])
		draw_polyline(hull,ink,3,true);line(Vector2(40,cy),nose,gold)
		line(Vector2(size.x-160,cy-75),Vector2(size.x-160,cy+75),teal,4)
		var wet:=PackedVector2Array([Vector2(size.x-160,cy-75*progress),nose,Vector2(size.x-160,cy+75*progress)])
		if progress>0:draw_colored_polygon(wet,blue*Color(1,1,1,.7))
		txt(tr2("艏尖舱","Фо́рпик"),Vector2(size.x-220,150),teal)
		vessel(Vector2(size.x*.43,390),size.x*.5,.10*progress,teal)
		return
	line(Vector2(35,280),Vector2(size.x-35,280),blue,2)
	if lesson_id=="Q24":
		vessel(Vector2(size.x*.28,270+45*progress),size.x*.32,0,teal)
		vessel(Vector2(size.x*.74,285),size.x*.32,progress*1.45,gold)
		txt(tr2("失去浮性","Плаву́честь"),Vector2(45,155),teal)
		txt(tr2("失去稳性","Осто́йчивость"),Vector2(size.x*.58,155),gold)
	else:
		vessel(Vector2(size.x*.5,260+25*progress),size.x*.7,progress*.22,teal)
		var r:=Rect2(size.x*.48,280,size.x*.20,35*progress);draw_rect(r,blue)
		arrow(Vector2(size.x*.68,190),Vector2(size.x*.58,277),blue)
		txt(tr2("可能下沉与倾斜","Возмо́жны погруже́ние и крен"),Vector2(45,365),ink,20)
