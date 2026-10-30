extends Control
const Hydro=preload("res://modules/review/core/stability_math.gd")
var state:Dictionary={}
var language:="zh"
var current_points:Array=[]
var reference_points:Array=[]
var metrics:Dictionary={}
var last_shape:=""
var plot_rect:=Rect2()
signal angle_requested(value:float)
func _ready()->void:
	custom_minimum_size.y=230;mouse_filter=Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
func update(value:Dictionary,lang:String,evaluation:Dictionary={})->void:
	state=value.duplicate(true);language=lang;metrics=evaluation.base if evaluation.has("base") else Hydro.values(state)
	var shape:String=Hydro.curve_key(state)
	if shape!=last_shape:
		last_shape=shape;current_points=Hydro.curve(state);reference_points=Hydro.curve({})
	visible=state.get("plot","")!="";queue_redraw()
func tr2(a:String,b:String)->String:return a if language=="zh" else b
func text_(value:String,p:Vector2,color:=Color("cfdfeb"),font_size:=17)->void:draw_string(get_theme_default_font(),p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
func _draw()->void:
	if current_points.is_empty():return
	var rect:=Rect2(42,35,maxf(80,size.x-65),size.y-76);plot_rect=rect
	var mode:String=state.get("plot","")
	if mode=="time":
		text_(tr2("横倾角—时间","Крен — вре́мя"),Vector2(10,20))
		var limit:=24.0;var clock:float=float(state.get("clock",0));var ref:Dictionary=Hydro.values({"zg":state.get("reference_zg",8.7)})
		for i in (2 if state.get("compare",false) else 1):
			var period:float=metrics.period if i==0 else ref.period;var color:=Color("ffd078") if i==0 else Color("6bc7c8")
			var pts:=PackedVector2Array()
			for j in 241:
				var t:float=j*.1
				if t>clock:break
				pts.append(Vector2(rect.position.x+t/limit*rect.size.x,rect.get_center().y-cos(TAU*t/period)*rect.size.y*.4))
			if pts.size()>1:draw_polyline(pts,color,2,true)
			draw_circle(Vector2(rect.position.x+minf(clock,limit)/limit*rect.size.x,rect.get_center().y-cos(TAU*clock/period)*rect.size.y*.4),4,color)
			if clock>=period:
				var y:float=rect.end.y+8+i*17;var end:float=rect.position.x+period/limit*rect.size.x
				draw_line(Vector2(rect.position.x,y),Vector2(end,y),color,2);text_("τ = %.2f s"%period,Vector2(rect.position.x+5,y-3),color,15)
		text_("+6°",Vector2(3,rect.position.y+15));text_("−6°",Vector2(3,rect.end.y));text_("24 s",Vector2(rect.end.x-35,rect.end.y+36))
		draw_line(Vector2(rect.position.x,rect.get_center().y),Vector2(rect.end.x,rect.get_center().y),Color("517486"),1)
		return
	text_(tr2("复原力臂—倾角","Плечо́ — у́гол кре́на"),Vector2(10,20))
	var ymin:=-2.5;var ymax:=2.5
	for p in current_points:ymin=minf(ymin,p.y-.2);ymax=maxf(ymax,p.y+.2)
	var xy:Callable=func(p:Vector2)->Vector2:return Vector2(rect.position.x+p.x/180*rect.size.x,rect.end.y-(p.y-ymin)/(ymax-ymin)*rect.size.y)
	var zero:Vector2=xy.call(Vector2.ZERO)
	draw_line(Vector2(rect.position.x,zero.y),Vector2(rect.end.x,zero.y),Color("658395"),1)
	draw_line(rect.position,Vector2(rect.position.x,rect.end.y),Color("658395"),1)
	text_("l / m",Vector2(0,50));text_("0",zero+Vector2(-17,5));text_("θ / °",Vector2(rect.end.x-24,rect.end.y+35))
	for x in [0,45,90,135,180]:text_(str(x),Vector2(rect.position.x+float(x)/180*rect.size.x-8,rect.end.y+18),Color("9eb8c9"),14)
	for i in (2 if state.get("compare",false) else 1):
		var data:Array=current_points if i==0 else reference_points;var pts:=PackedVector2Array()
		for p in data:
			if state.get("sweep",false) and p.x>float(state.get("heel",0)):break
			pts.append(xy.call(p))
		if pts.size()>1:draw_polyline(pts,Color("ffd078") if i==0 else Color("628f9e"),2.5,true)
	var active:Vector2=xy.call(Vector2(absf(metrics.heel),absf(metrics.arm) if metrics.heel<0 else metrics.arm));draw_circle(active,5,Color("ffd078"))
	if not state.get("sweep",false):
		var ext:=Hydro.curve_extrema(state)
		if mode=="peak":
			var p:Vector2=xy.call(ext.peak);draw_circle(p,4,Color("7ee5cb"));text_("l_max = %.2f m"%ext.peak.y,Vector2(rect.position.x+5,42),Color("7ee5cb"))
		elif ext.zero>=0:
			var p:Vector2=xy.call(Vector2(ext.zero,0));draw_circle(p,4,Color("7ee5cb"));text_("θ = %.1f°"%ext.zero,p+Vector2(-30,-12),Color("7ee5cb"))
func _gui_input(event:InputEvent)->void:
	# Chart dragging is available only when the course exposes its heel control.
	if not get_meta("interactive",false) or state.get("plot","")=="time":return
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and plot_rect.has_point(event.position):angle_requested.emit(clampf((event.position.x-plot_rect.position.x)/plot_rect.size.x*180,0,150))
	if event is InputEventMouseMotion and event.button_mask&MOUSE_BUTTON_MASK_LEFT and plot_rect.has_point(event.position):angle_requested.emit(clampf((event.position.x-plot_rect.position.x)/plot_rect.size.x*180,0,150))
