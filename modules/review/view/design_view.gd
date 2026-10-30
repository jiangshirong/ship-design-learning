extends Control
var label_lookup=preload("res://modules/review/view/drawn_term_lookup.gd").new()
var lesson_id:="Q01"
var language:="zh"
var phase:="requirements"
var progress:=0.0
var camera_motion:=false
var camera_tween:Tween
var camera_target:=Vector3.ZERO
var camera_span:=8.4
func _ready()->void:
	add_child(label_lookup)
	mouse_filter=Control.MOUSE_FILTER_IGNORE;resized.connect(queue_redraw)
func tr2(zh:String,ru:String)->String:return zh if language=="zh" else ru
func apply(state:Dictionary,focus:String,lang:String)->void:
	progress=float(state.get("progress",0));phase=focus;language=lang;queue_redraw()
func teach(_focus:String)->void:pass
func cancel()->void:pass
func mass()->int:return 0
func capacity()->float:return 1
func panel_rect(i:int)->Rect2:return Rect2(30,90+i*150,size.x-60,126)
func anchor()->Vector2:
	if lesson_id=="Q04":return Vector2(70+(size.x-140)*(.35 if phase=="plan" else lerpf(.35,.65,progress)),169 if phase=="plan" else 319)
	return panel_rect(1 if phase in ["handoff","record","compare"] else 0).get_center()+Vector2(0,25)
func obstacles()->Array:return [panel_rect(0),panel_rect(1),Rect2(20,20,size.x-40,45)]
func text_at(value:String,pos:Vector2,color:=Color("dce7ee"),fs:=22)->void:
	draw_string(get_theme_font("font"),pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,color)
	label_lookup.add_label(value,pos,get_theme_font("font"),fs)
func ship(origin:Vector2,width:float,color:Color)->void:
	var points:=PackedVector2Array([origin,origin+Vector2(width,0),origin+Vector2(width*.82,28),origin+Vector2(16,28)])
	draw_colored_polygon(points,color);draw_rect(Rect2(origin+Vector2(18,-18),Vector2(27,18)),color)
func _draw()->void:
	label_lookup.clear_labels()
	draw_rect(Rect2(Vector2.ZERO,size),Color("122735"))
	var teal:=Color("72d4c7");var gold:=Color("f3cc7c")
	for i in 2:
		var rect:=panel_rect(i);draw_rect(rect,Color("1b394a"));draw_rect(rect,gold if (i==0 and progress<.5) or (i==1 and progress>=.5) else Color("547080"),false,2)
	var a:=panel_rect(0).position;var b:=panel_rect(1).position
	if lesson_id=="Q01":
		text_at(tr2("订船方：提出任务","Зака́зчик: тре́бования"),a+Vector2(18,32),gold)
		text_at(tr2("载什么 · 载多少 · 跑多快","Груз · ма́сса · ско́рость"),a+Vector2(18,76))
		text_at(tr2("设计方：实现要求","Проекта́нт: реше́ние"),b+Vector2(18,32),teal)
		ship(b+Vector2(25,78),150,teal)
		text_at(tr2("尺寸 · 船型 · 设备","Разме́ры · фо́рма"),b+Vector2(195,85))
		var y:=lerpf(a.y+108,b.y+10,progress)
		draw_rect(Rect2(size.x*.5-12,y-14,24,28),gold)
		for i in 3:draw_line(Vector2(size.x*.5-7,y-7+i*7),Vector2(size.x*.5+7,y-7+i*7),Color("1b394a"),2)
	elif lesson_id=="Q04":
		text_at(tr2("设计图：原计划","Прое́кт: план"),a+Vector2(18,32),gold)
		text_at(tr2("实船 → 竣工资料","Су́дно → документа́ция"),b+Vector2(18,32),teal)
		var w:=size.x-140
		for i in 2:
			var r:=Rect2(Vector2(70,145+i*150),Vector2(w,48));draw_rect(r,teal,false,2)
			var f:=.35 if i==0 else lerpf(.35,.65,progress)
			draw_line(r.position+Vector2(w*f,0),r.position+Vector2(w*f,48),gold,4)
	elif lesson_id=="Q05":
		text_at(tr2("新船：DW = 1 000 t","Но́вый та́нкер: DW = 1 000 т"),a+Vector2(18,32),teal)
		text_at(tr2("候选母型：DW = 10 000 t","Прототи́п: DW = 10 000 т"),b+Vector2(18,32),gold)
		var w:=size.x-100
		draw_rect(Rect2(a+Vector2(18,65),Vector2(w*.1,25)),teal)
		draw_rect(Rect2(b+Vector2(18,65),Vector2(lerpf(w*.1,w,progress),25)),gold)
		text_at(tr2("载重量相差10倍","Дедве́йт отлича́ется в 10 раз"),Vector2(36,55),gold)
