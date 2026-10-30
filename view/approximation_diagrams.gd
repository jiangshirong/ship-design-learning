extends RefCounted
# Views consume the same compiled adoption chain as domain.gd and bulkhead_math.gd.
var results:Dictionary={}
var textures:Dictionary={}
var h
var area:=Rect2()
var anchor:=Vector2.ZERO
var chart_zoom:=1.0
var chart_id:=""
const WHITE=Color("dbe8ef")
const MUTED=Color("9ab8c8")
const GOLD=Color("ffd079")
const TEAL=Color("6ad6c7")
const PURPLE=Color("c3acf5")
func tr2(a:String,b:String)->String:return a if h.language=="zh" else b
func text(p:Vector2,s:String,c:Color=WHITE,fs:int=22)->void:h.draw_string(h.font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,c)
func line(a:Vector2,b:Vector2,c:Color=TEAL,width:float=3)->void:h.draw_line(a,b,c,width,true)
func arrow(a:Vector2,b:Vector2,c:Color=TEAL)->void:
	line(a,b,c);var dir:Vector2=(b-a).normalized();line(b,b-dir.rotated(.5)*13,c);line(b,b-dir.rotated(-.5)*13,c)
func draw(host)->void:
	h=host
	if results.is_empty():results=JSON.parse_string(FileAccess.get_file_as_string("res://content/approximation_calculated.json"))
	area=Rect2(22,28,h.size.x-44,h.size.y*.66-28);anchor=Vector2(h.size.x*.55,h.size.y*.47)
	match h.visual:
		"approx_table":table()
		"approx_decision":decision()
		"approx_chart":chart()
		"approx_lookup":lookup()
		"approx_power":power()
func phase()->String:return str(h.data.get("approx_focus",""))
func table()->void:
	var s:Dictionary=results.second;var t:Dictionary=results.third
	var first:Array=results.first_table
	var from:Array=first;var to:Array=first
	match phase():
		"second_raw":to=first.duplicate();to[0]=s.hull
		"second":to=s.table
		"third_raw":from=s.table;to=from.duplicate();to[1]=t.Pe;to[2]=t.Pf
		"third_updated":from=s.table;to=from.duplicate();to[0]=t.hull;to[1]=t.Pe;to[2]=t.Pf
		"preliminary":from=s.table;to=t.preliminary_table
		"final":from=s.table;to=t.table
	var names:Array=[tr2("船体与设备","Ко́рпус и обору́дование"),tr2("动力装置","Энергети́ческая устано́вка"),tr2("能源储备","Энергети́ческие запа́сы"),tr2("质量裕量","Запа́с водоизмеще́ния"),tr2("供应品","Снабже́ние"),tr2("货物","Груз")]
	var row:int=int(h.data.get("approx_row",-1));var shown:int=int(h.data.get("approx_rows",6))
	to=to.duplicate()
	if row>=0 and h.beat.has("action"):
		to[row]=lerpf(float(from[row]),float(to[row]),clampf(float(h.data.get("approx_reveal",1)),0,1))
	var spacing:float=minf(48,(area.size.y-65)/6)
	var number_x:float=area.position.x+area.size.x*.63
	text(Vector2(number_x,area.position.y+20),tr2("原值 → 本轮 / t","До → сейча́с / т"),MUTED,20)
	for i in range(shown):
		var y:float=area.position.y+55+i*spacing
		if i==row:h.draw_rect(Rect2(area.position.x,y-24,area.size.x,spacing-3),Color("294750"))
		var color:Color=GOLD if float(from[i])!=float(to[i]) else WHITE
		text(Vector2(area.position.x+10,y),names[i],color,19 if h.language=="ru" else 22)
		text(Vector2(number_x,y),"%.0f → %.2f"%[from[i],to[i]],color,21)
		if i==row:anchor=Vector2(number_x+60,y)
	if row<0:anchor=Vector2(number_x+60,area.position.y+55+5*spacing)
func decision()->void:
	var s:Dictionary=results.second if phase()=="second" else results.third
	var limit:float=s.limit;var gap:float=absf(s.gap)
	var left:float=area.position.x+25;var width:float=area.size.x-70;var max_value:float=maxf(gap,limit)*1.25
	var y:float=area.position.y+95
	text(Vector2(left,y-45),tr2("质量差额的绝对值","Абсолю́тная ра́зность масс"),WHITE,23)
	line(Vector2(left,y+35),Vector2(left+width,y+35),MUTED,2)
	var amount:float=float(h.data.get("approx_reveal",1)) if h.beat.has("action") else 1.0
	h.draw_rect(Rect2(left,y,width*gap/max_value*amount,24),TEAL)
	var x:float=left+width*limit/max_value
	line(Vector2(x,y-22),Vector2(x,y+52),PURPLE,4)
	text(Vector2(left,y+85),"%.2f t"%gap,TEAL,27)
	text(Vector2(clampf(x-80,left,left+width-170),y-32),tr2("允许 ","Преде́л ")+"%.2f t"%limit,PURPLE,23)
	text(Vector2(left,y+145),tr2("只调整质量裕量","Меня́ем то́лько запа́с") if gap<=limit else tr2("需要修正排水量","Уточня́ем водоизмеще́ние"),GOLD,24)
	anchor=Vector2(x,y+45)
func lookup()->void:
	var rows:Array=[["50–150","0.4 … 0.3"],["150–210","0.20"],["210–250","0.10"],["250–300","0"]] if phase()=="roughness" else [["50–130","0.15"],["130–200","0.10"],["200–400","0.05"]]
	text(area.position+Vector2(10,25),tr2("船长 / m","Длина́ / м"),WHITE,24)
	text(area.position+Vector2(area.size.x*.5,25),tr2("系数 × 10⁻³","Коэффицие́нт × 10⁻³"),WHITE,23)
	for i in rows.size():
		var p:Vector2=area.position+Vector2(0,45+i*48)
		if i==1:h.draw_rect(Rect2(p,Vector2(area.size.x,43)),Color("34304e"))
		text(p+Vector2(15,30),rows[i][0],PURPLE if i==1 else MUTED,25)
		text(p+Vector2(area.size.x*.5+25,30),rows[i][1],PURPLE if i==1 else MUTED,25)
	anchor=area.position+Vector2(area.size.x*.7,123)
func texture(id:int)->Texture2D:
	if not textures.has(id):textures[id]=load("res://assets/approximation/chart%d.png"%id)
	return textures[id]
func chart()->void:
	if chart_id!=str(h.beat.id):chart_id=str(h.beat.id);chart_zoom=1.0
	var id:int=10 if phase()=="friction" else 42 if phase()=="psi" else 43 if phase()=="beam" else 41
	var tex:Texture2D=texture(id)
	var box:=area
	box.position.y+=25;box.size.y-=25
	var base_crop:=Rect2(.05,.57,.94,.41) if phase()=="friction" else Rect2(0,0,1,1)
	var extent:Vector2=tex.get_size()*base_crop.size
	var scale:float=minf(box.size.x/extent.x,box.size.y/extent.y)
	var target:=Rect2(box.position+Vector2((box.size.x-extent.x*scale)*.5,0),extent*scale)
	# These coordinates are on the original teacher plots, not invented curves.
	var p:=Vector2.ZERO;var q:=Vector2.ZERO;var r:=Vector2.ZERO
	match phase():
		"friction":
			p=Vector2(.887,.90);q=Vector2(.887,.862);r=Vector2(.11,.862)
		"residual","standard":
			var x:float=lerpf(.039,.916,(float(results.inputs.delta)-.6)/.2)
			var y:float=lerpf(.937,.029,float(results.inputs.residual_base)*1000/4) if phase()=="residual" else lerpf(.937,.029,(float(results.inputs.psi_standard)-5.5)/.5)
			p=Vector2(x,.937);q=Vector2(x,y);r=Vector2(.039 if phase()=="residual" else .960,y)
		"psi":
			var x:float=lerpf(.037,.965,(float(results.third.psi)-5)/2.6)
			var y:float=lerpf(.030,.920,(1.5-float(results.inputs.alpha_psi))/.9)
			p=Vector2(x,.920);q=Vector2(x,y);r=Vector2(.037,y)
		"beam":
			var x:float=lerpf(.05,.962,(float(results.inputs.B)/float(results.inputs.T)-2)/3)
			p=Vector2(x,.920);q=Vector2(x,.055);r=q
	var crop_size:Vector2=base_crop.size/chart_zoom
	var crop_origin:Vector2=base_crop.position if chart_zoom==1 else (q-crop_size*.5).clamp(Vector2.ZERO,Vector2.ONE-crop_size)
	h.draw_texture_rect_region(tex,target,Rect2(crop_origin*tex.get_size(),crop_size*tex.get_size()))
	if phase()=="friction":
		# Floating scale labels in the Word source are ambiguous. Do not invent
		# a Re axis or project a falsely exact lookup onto that incomplete scale.
		anchor=Vector2(target.get_center().x,target.end.y);return
	var amount:float=clampf(float(h.data.get("approx_reveal",1)),0,1)
	var a:Vector2=target.position+((p-crop_origin)/crop_size).clamp(Vector2.ZERO,Vector2.ONE)*target.size
	var b:Vector2=target.position+(q-crop_origin)/crop_size*target.size
	var c:Vector2=target.position+((r-crop_origin)/crop_size).clamp(Vector2.ZERO,Vector2.ONE)*target.size
	line(a,a.lerp(b,minf(amount*2,1)),Color("c14d15"),3)
	if amount>.5:line(b,b.lerp(c,(amount-.5)*2),Color("c14d15"),3)
	if phase()!="beam":h.draw_circle(b,5,Color("c14d15"))
	anchor=a if phase()=="beam" else b
	if phase()=="psi" and amount>.65:
		var x:float=lerpf(.037,.965,(float(results.inputs.psi_standard)-5)/2.6)
		var y:float=lerpf(.030,.920,(1.5-float(results.inputs.alpha_standard))/.9)
		var point:Vector2=(Vector2(x,y)-crop_origin)/crop_size
		if Rect2(Vector2.ZERO,Vector2.ONE).has_point(point):
			var b2:Vector2=target.position+point*target.size
			line(target.position+((Vector2(x,.920)-crop_origin)/crop_size).clamp(Vector2.ZERO,Vector2.ONE)*target.size,b2,Color("3355b0"),3)
			h.draw_circle(b2,5,Color("3355b0"))
func chart_input(event:InputEvent)->bool:
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		chart_zoom=clampf(chart_zoom*(1.25 if event.button_index==MOUSE_BUTTON_WHEEL_UP else .8),1,4)
		h.queue_redraw();return true
	return false
func power()->void:
	var t:Dictionary=results.third;var p:=area.position+Vector2(20,70);var width:float=area.size.x-40
	if phase() in ["velocity","drag","resistance"]:
		var middle:=p+Vector2(width*.5,60)
		arrow(middle,middle+Vector2(width*.4,0),TEAL)
		text(middle+Vector2(15,-20),tr2("航行方向","Движе́ние"),TEAL,23)
		if phase()!="velocity":
			arrow(middle+Vector2(0,65),middle+Vector2(-width*.4,65),GOLD)
			text(middle+Vector2(-width*.4,108),tr2("水的阻力","Сопротивле́ние воды́"),GOLD,22)
		anchor=middle;return
	var steps:Array=[[tr2("拖曳功率","Буксиро́вочная"),t.EPS],[tr2("所需主机功率","Тре́буемая"),t.required],[tr2("含15%余量","С запа́сом 15%"),t.minimum],[tr2("采用主机","Вы́бранный дви́гатель"),t.engine]]
	var counts:Dictionary={"eps":1,"required":2,"margin":3,"catalog":4,"check":4}
	var count:int=counts.get(phase(),1)
	for i in range(count):
		var pos:Vector2=p+Vector2(0,i*62)
		text(pos,steps[i][0],WHITE,21)
		var amount:float=float(h.data.get("approx_reveal",1)) if i==count-1 and h.beat.has("action") else 1.0
		h.draw_rect(Rect2(pos+Vector2(0,8),Vector2(width*float(steps[i][1])/14000*amount,14)),GOLD if i==count-1 else TEAL)
		text(pos+Vector2(width*.62,-2),"%.2f kW"%steps[i][1],GOLD,21)
		anchor=pos+Vector2(width*float(steps[i][1])/14000,15)
