extends Control
# x/z are source coordinates; transverse positions follow authored Blender tanks.
var ship
var markers:Array=[]
var occupied:Array=[]
var locator:=Rect2()
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
func refresh()->void:
	markers.clear();occupied.clear()
	if ship==null:return
	if ship.size.x<200 or ship.size.y<200:hide();return
	visible=ship.current.get("show_fuel",false) and float(ship.current.get("cutaway_amount",0))>.85 and not ship.current.get("pair_lesson",false)
	if not visible:return
	size=ship.size
	locator=Rect2(16,16,size.x-32,142)
	occupied.append(locator)
	var focused:bool=ship.current.get("focus_only",false)
	var index:int=int(ship.current.get("fuel_index",0))
	var grouped:Dictionary={}
	for i in range(9):
		if focused and i!=index:continue
		var p:Vector3=ship.points[i].position
		var key:Vector3=p
		if not grouped.has(key):grouped[key]=[]
		grouped[key].append(i)
	var font:Font=get_theme_default_font()
	for key in grouped:
		var ids:Array=grouped[key];var i:int=ids[0]
		var p:Vector2=ship.camera.unproject_position(ship.body.to_global(ship.points[i].position))
		var text_:String=("油舱 " if ship.lang=="zh" else "Танк ")+" / ".join(ids.map(func(n):return str(n+1)))
		if focused:text_+=(" · 油体重心" if ship.lang=="zh" else " · Центр ма́ссы")
		else:text_=str(i+1)
		var extent:Vector2=font.get_string_size(text_,HORIZONTAL_ALIGNMENT_LEFT,-1,18)+Vector2(16,12)
		var offset:=Vector2(16,-54)
		if not focused and i>=5:offset=Vector2(-extent.x-22,-76+float(i-5)*34)
		var rect:=Rect2((p+offset).clamp(Vector2(8,8),size-extent-Vector2(8,8)),extent)
		for used in occupied:
			if rect.grow(4).intersects(used):rect.position.y=used.end.y+6
		rect.position=rect.position.clamp(Vector2(8,8),size-extent-Vector2(8,8))
		occupied.append(rect)
		markers.append({"point":p,"rect":rect,"text":text_,"active":focused})
	queue_redraw()
func _draw()->void:
	var font:Font=get_theme_default_font()
	draw_locator(font)
	var merge:bool=ship.current.get("merge_visible",false)
	var t:float=clampf(float(ship.current.get("fuel_merge",0)),0,1)
	var combined:Vector2=ship.camera.unproject_position(ship.body.to_global(ship.centre.position))
	for marker in markers:
		var p:Vector2=marker.point;var rect:Rect2=marker.rect
		var color:=Color("ffcd70") if marker.active else Color("74ded0")
		draw_line(p,rect.get_center(),color,1.5,true)
		draw_circle(p,8,color,false,2,true)
		draw_line(p-Vector2(12,0),p+Vector2(12,0),color,1,true)
		draw_line(p-Vector2(0,12),p+Vector2(0,12),color,1,true)
		draw_rect(rect,Color("12313e"));draw_rect(rect,color,false,1)
		draw_string(font,rect.position+Vector2(8,rect.size.y-9),marker.text,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("eaf5f5"))
		if merge:
			# Lines indicate aggregation, not movement of fuel or tank geometry.
			draw_line(p,p.lerp(combined,t),Color("ffcd70"),2,true)
	if merge and t>.98:
		draw_circle(combined,9,Color("ffcd70"));draw_string(font,combined+Vector2(15,-14),"G",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("ffcd70"))

func draw_locator(font:Font)->void:
	var zh:bool=ship.lang=="zh"
	var focused:bool=ship.current.get("focus_only",false)
	var selected:int=int(ship.current.get("fuel_index",0))
	draw_rect(locator,Color("102330"));draw_rect(locator,Color("446775"),false,1)
	var origin:=locator.position+Vector2(24,105)
	var width:float=locator.size.x*(.60 if focused else .88)
	var project:=func(x:float,z:float)->Vector2:return origin+Vector2(x/150*width,-z/17*68)
	draw_line(origin,origin+Vector2(width,0),Color("86aab7"),2,true)
	draw_line(origin,origin-Vector2(0,76),Color("86aab7"),2,true)
	draw_string(font,locator.position+Vector2(12,23),"整船位置 · 侧视" if zh else "Положе́ние · вид сбо́ку",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("dcecf3"))
	draw_string(font,origin+Vector2(-8,23),"艉 x=0" if zh else "Корма́ x=0",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("afc6d1"))
	draw_string(font,origin+Vector2(width-40,23),"艏 →" if zh else "Нос →",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("afc6d1"))
	for i in range(9):
		var tank:Dictionary=ship.fuel_layout[i];var p:Vector2=project.call(float(tank.x_m),float(tank.z_m))
		var active:bool=focused and selected==i
		draw_circle(p,5 if active else 3,Color("ffcd70") if active else Color("658492"))
		if active:
			draw_dashed_line(p,Vector2(p.x,origin.y),Color("ffcd70"),1.5,4,true)
			draw_line(origin+Vector2(0,7),Vector2(p.x,origin.y+7),Color("ffcd70"),2,true)
			draw_string(font,p+Vector2(7,-9),"%d · x=%.2f m"%[i+1,float(tank.x_m)],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("ffcd70"))
	if focused:
		# Enlarged local section, no invented numerical depth or capacity label.
		var box:=Rect2(locator.end.x-145,locator.position.y+40,48,68)
		draw_rect(box,Color("79502f"));draw_line(box.position,Vector2(box.end.x,box.position.y),Color("efc15d"),3,true)
		var cg:=box.get_center();draw_circle(cg,5,Color("74ded0"))
		draw_string(font,Vector2(box.end.x+8,box.position.y+5),"液面" if zh else "У́ровень",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("efc15d"))
		draw_string(font,Vector2(box.end.x+8,cg.y+6),"重心" if zh else "Центр",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("74ded0"))
