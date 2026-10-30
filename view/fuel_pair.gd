extends Control
# Dimensions terminate at the oil centroids, never at compartment boundaries.
var ship
var occupied:Array=[]
var dimensions:Array=[]
var tags:Array=[]
var origin:=Vector2.ZERO
var combined:=Vector2.ZERO
var combined_world:=Vector3.ZERO
var given_points:Array=[]
func _ready()->void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func project(p:Vector3)->Vector2:return ship.camera.unproject_position(ship.body.to_global(p))
func label_box(text_:String,point:Vector2,offset:Vector2,color:Color)->void:
	var font:Font=get_theme_default_font()
	var extent:Vector2=font.get_string_size(text_,HORIZONTAL_ALIGNMENT_LEFT,-1,18)+Vector2(16,12)
	var rect:=Rect2((point+offset).clamp(Vector2(8,8),size-extent-Vector2(8,8)),extent)
	occupied.append(rect);tags.append({"text":text_,"point":point,"rect":rect,"color":color})
func refresh()->void:
	occupied.clear();dimensions.clear();tags.clear();given_points.clear()
	if ship==null:return
	visible=ship.current.get("pair_lesson",false)
	if not visible:return
	size=ship.size
	if size.x<200 or size.y<200:return
	var zh:bool=ship.lang=="zh"
	var colors:Array=[Color("74ded0"),Color("ffd07a")]
	combined_world=ship.pair_centre()
	combined=project(combined_world)
	origin=project(Vector3(-75,0,19))
	label_box("艉垂线 x = 0" if zh else "Кормово́й перпендикуля́р: x = 0",origin,Vector2(-10,-158),Color("ccdce5"))
	for i in range(2):
		var p:Vector3=ship.points[i].position
		var screen:Vector2=project(p);given_points.append(screen)
		var name_:String=("1号舱 · G₁ · 250 t" if i==0 else "2号舱 · G₂ · 160 t") if zh else ("Танк 1 · G₁ · 250 т" if i==0 else "Танк 2 · G₂ · 160 т")
		label_box(name_,screen,Vector2(12,-64) if i==0 else Vector2(-185,-70),colors[i])
		# Parallel dimension lanes in the same ship coordinate system.
		var level:float=-4.0-i*12.0
		var a:=project(Vector3(-75,level,19));var b:=project(Vector3(p.x,level,19))
		dimensions.append({"a":a,"b":b,"centre":screen,"x":p.x+75,"color":colors[i]})
		occupied.append(Rect2(a,Vector2.ZERO).expand(b).grow(24))
	# Reserve the future result and connector before the animation starts.
	occupied.append(Rect2(given_points[0],Vector2.ZERO).expand(given_points[1]).grow(12))
	var merge:float=float(ship.current.get("pair_merge",0))
	if merge>.98:
		var name_:String=("合成重心" if zh else "О́бщий центр")+" · x = %.4f m"%(combined_world.x+75)
		label_box(name_,combined,Vector2(-105,-150),Color("f4f5fa"))
	queue_redraw()
func _draw()->void:
	if not visible or given_points.size()!=2:return
	var font:Font=get_theme_default_font()
	var amount:float=clampf(float(ship.current.get("pair_measure",0)),0,1)
	var merge:float=clampf(float(ship.current.get("pair_merge",0)),0,1)
	for line in dimensions:
		if amount<=0:continue
		var a:Vector2=line.a;var b:Vector2=line.b;var head:Vector2=a.lerp(b,amount)
		draw_line(a,head,line.color,2.5,true)
		draw_line(a-Vector2(0,5),a+Vector2(0,5),line.color,2,true)
		draw_dashed_line(origin,a,Color("9ab4c3"),1,5,true)
		if amount>.98:
			draw_line(b-Vector2(0,5),b+Vector2(0,5),line.color,2,true)
			draw_dashed_line(line.centre,b,line.color,1.5,5,true)
			draw_string(font,(a+b)*.5+Vector2(-52,24),"x = %.0f m"%line.x,HORIZONTAL_ALIGNMENT_LEFT,-1,20,line.color)
	if merge>0:
		for p in given_points:draw_dashed_line(p,p.lerp(combined,merge),Color("f4f5fa"),2,6,true)
	if merge>.98:draw_circle(combined,7,Color("f4f5fa"))
	for tag in tags:
		var p:Vector2=tag.point;var rect:Rect2=tag.rect
		draw_line(p,rect.get_center(),tag.color,1.5,true)
		draw_circle(p,6,tag.color,false,2,true)
		draw_rect(rect,Color("102b3b"))
		draw_string(font,rect.position+Vector2(8,rect.size.y-9),tag.text,HORIZONTAL_ALIGNMENT_LEFT,-1,18,tag.color)
