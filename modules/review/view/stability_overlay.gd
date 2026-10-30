extends Control
var owner_view
const GOLD=Color("ffd078")
const TEAL=Color("70ecdb")
const INK=Color("e5f5fb")
func _ready()->void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func label(text:String,p:Vector2,color:Color=INK)->void:
	var font:=get_theme_default_font();var fs:=21
	var extent:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs)
	var r:=Rect2(p+Vector2(-4,-23),extent+Vector2(8,8));draw_style_box(background(),r);draw_string(font,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,color)
	owner_view.labels_bounds.append(r)
func background()->StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=Color(.04,.1,.14,.88);s.set_corner_radius_all(3);return s
func arrow(a:Vector2,b:Vector2,color:Color)->void:
	draw_line(a,b,color,3,true);var d:Vector2=(b-a).normalized();var n:=Vector2(-d.y,d.x);draw_colored_polygon(PackedVector2Array([b,b-d*13+n*5,b-d*13-n*5]),color)
func dot(point:Vector3,name_:String,color:Color)->void:
	var p:Vector2=owner_view.project(point);draw_circle(p,5,color);label(name_,p+Vector2(9,-7),color)
func _draw()->void:
	var v=owner_view
	if v.overlay_points.is_empty():return
	v.labels_bounds.clear();var p:Dictionary=v.overlay_points;var mode:String=v.state.get("show","hull")
	if mode=="hull":return
	label("θ = %.1f°"%v.metrics.angle,Vector2(size.x-125,size.y-20))
	var g:Vector2=v.project(p.G);var c:Vector2=v.project(p.C)
	if mode=="baseline":
		var a:Vector2=v.project(v.bodies[0].to_global(Vector3(0,0,-18)));var b:Vector2=v.project(v.bodies[0].to_global(Vector3(0,0,18)))
		draw_line(a,b,Color("f49bc5"),3,true);label("z = 0",a+Vector2(6,25),Color("f49bc5"))
		var bottom:Vector2=v.project(p.baseline);draw_line(bottom,g,GOLD,2,true);dot(p.G,"G",GOLD)
		label(v.tr2("重心高度 ","Высота́ G ")+"%.2f m"%v.metrics.zg,bottom.lerp(g,.5)+Vector2(12,0),GOLD);return
	if mode=="waterplane":
		var outline:=PackedVector2Array()
		for at in v.waterplane_boundary:outline.append(v.project(at))
		if outline.size()>2:
			outline.append(outline[0]);draw_polyline(outline,TEAL,2,true)
			var protected:=Rect2(outline[0],Vector2.ZERO)
			for at in outline:protected=protected.expand(at)
			v.labels_bounds.append(protected.grow(10))
		label("r = %.2f m"%v.metrics.r,Vector2(20,140))
		for side in [-1,1]:
			var a:Vector2=v.project(Vector3(-35,0,side*v.metrics.B*.46));var b:Vector2=v.project(Vector3(35,0,side*v.metrics.B*.46));draw_line(a,b,GOLD,8,true)
		return
	if mode=="roll":
		dot(p.deck,"●",GOLD)
		if v.state.get("compare",false):
			label(v.tr2("原状态","До"),Vector2(25,140),TEAL)
			label(v.tr2("改变后","По́сле"),Vector2(size.x*.40,140),GOLD)
			label("τ = %.2f s"%v.reference.period,Vector2(25,168),TEAL)
			label("τ = %.2f s"%v.metrics.period,Vector2(size.x*.40,168),GOLD)
		else:label("θ = %.1f°   τ = %.2f s"%[v.metrics.angle,v.metrics.period],Vector2(20,140))
		return
	if mode=="wet":return
	if mode not in ["M_guides","M_definition"]:dot(p.G,"G",GOLD);arrow(g,v.project(p.G+Vector3(0,-9,0)),GOLD)
	if mode=="G":return
	dot(p.C,"C",TEAL);arrow(c,v.project(p.C+Vector3(0,9,0)),TEAL)
	if mode in ["lines","arm","M","limit","waterplane","M_guides","M_definition"]:
		for q in ([p.C] if mode in ["M_guides","M_definition"] else [p.G,p.C]):draw_dashed_line(v.project(q+Vector3(0,-13,0)),v.project(q+Vector3(0,18,0)),GOLD if q==p.G else TEAL,1.4,6,true)
	if mode in ["M_guides","M_definition"]:
		var base:Vector3=v.bodies[0].to_global(Vector3(v.metrics.xc0,0,0))
		var top:Vector3=v.bodies[0].to_global(Vector3(v.metrics.xc0,v.metrics.km+10,0))
		draw_dashed_line(v.project(base),v.project(top),INK,2,6,true)
		var inset:=Rect2(20,112,310,205);draw_style_box(background(),inset);v.labels_bounds.append(inset)
		label(v.tr2("交点局部放大","Пересече́ние: увели́чение"),inset.position+Vector2(12,26))
		var middle:=inset.position+Vector2(155,112)
		var initial_direction:Vector2=(v.project(top)-v.project(base)).normalized()
		var current_direction:Vector2=(v.project(p.C+Vector3.UP)-v.project(p.C)).normalized()
		draw_line(middle-initial_direction*72,middle+initial_direction*72,INK,2,true)
		draw_line(middle-current_direction*72,middle+current_direction*72,TEAL,3,true)
		if absf(v.metrics.angle)>.1:draw_circle(middle,7,INK,false,1.5,true)
		label(v.tr2("原线","Пре́жняя"),inset.position+Vector2(8,185),INK)
		label(v.tr2("新线","Но́вая"),inset.position+Vector2(210,185),TEAL)
		if mode=="M_definition":dot(p.M,"M",INK);draw_circle(middle,4,INK);label("M",middle+Vector2(10,0))
	if mode in ["arm","lines"]:
		var a:Vector2=v.project(Vector3(v.metrics.xc0,p.line_y,p.G.z));var b:Vector2=v.project(Vector3(v.metrics.xc0,p.line_y,p.C.z))
		draw_line(a,b,INK,3,true);draw_line(a-Vector2(0,6),a+Vector2(0,6),INK,2);draw_line(b-Vector2(0,6),b+Vector2(0,6),INK,2)
		# Small physical levers remain to scale on the ship; enlarge a separate
		# explicitly labelled view instead of stretching the distance on the hull.
		var inset:=Rect2(20,112,310,170);draw_style_box(background(),inset);v.labels_bounds.append(inset)
		var zoom:=12.0;var separation:float=(b.x-a.x)*zoom
		if absf(separation)>200:zoom=200/maxf(absf(b.x-a.x),.001);separation=(b.x-a.x)*zoom
		label(v.tr2("作用线放大 ×","Ли́нии сил ×")+"%.1f"%zoom,inset.position+Vector2(12,28))
		var xa:float=inset.get_center().x-separation*.5;var xb:float=inset.get_center().x+separation*.5
		arrow(Vector2(xa,inset.position.y+52),Vector2(xa,inset.position.y+113),GOLD);arrow(Vector2(xb,inset.position.y+113),Vector2(xb,inset.position.y+52),TEAL)
		draw_line(Vector2(xa,inset.position.y+125),Vector2(xb,inset.position.y+125),INK,2)
		label("G",Vector2(xa-24,inset.position.y+82),GOLD);label("C",Vector2(xb+8,inset.position.y+82),TEAL)
		label("l = %.3f m"%(0.0 if absf(v.metrics.arm)<.0005 else v.metrics.arm),inset.position+Vector2(12,158))
		var centre:Vector2=v.project(v.bodies[0].to_global(Vector3(0,5,0)))
		var sign_:float=signf(v.metrics.arm)
		if absf(v.metrics.arm)>.01:
			var pts:=PackedVector2Array()
			for i in 20:pts.append(centre+Vector2(cos(-.9+i*.06),sin(-.9+i*.06))*80)
			draw_polyline(pts,TEAL if sign_>0 else Color("ef8982"),2,true)
			if sign_>0:arrow(pts[3],pts[0],TEAL)
			else:arrow(pts[-4],pts[-1],Color("ef8982"))
	if mode in ["M","limit","waterplane","radius"]:
		dot(p.M,"M",INK);var m:Vector2=v.project(p.M)
		draw_line(g,m,INK,3,true);label("h = %.2f m"%v.metrics.h,m+Vector2(45,-12))
		# Upright buoyancy axis and small-heel buoyancy line in the moving body frame.
		var origin:Vector3=v.bodies[0].to_global(Vector3(v.metrics.xc0,v.metrics.zc,0))
		draw_dashed_line(v.project(origin),v.project(v.bodies[0].to_global(Vector3(v.metrics.xc0,v.metrics.km+6,0))),INK,1,4,true)
		if mode=="radius":
			draw_line(c,m,TEAL,3,true);label("r = %.2f m"%v.metrics.r,c.lerp(m,.5)+Vector2(55,0),TEAL)
	if mode=="limit":
		var at:Vector2=v.project(p.limit);draw_dashed_line(at-Vector2(75,0),at+Vector2(75,0),Color("f49bc5"),2,6,true)
		label(v.tr2("允许上限 ","Пре́дел ")+"%.2f m"%v.metrics.allowed,at+Vector2(80,5),Color("f49bc5"))
	var route:String=v.state.get("route","base")
	if route!="base" and absf(v.metrics.angle)<.1:
		var left:Vector2=v.project(v.bodies[0].to_global(Vector3(0,v.metrics.H+2,-v.metrics.B/2)))
		var right:Vector2=v.project(v.bodies[0].to_global(Vector3(0,v.metrics.H+2,v.metrics.B/2)))
		draw_line(left,right,GOLD,2,true);label("B = %.2f m"%v.metrics.B,(left+right)*.5+Vector2(-60,-10),GOLD)
		label("T = %.2f m"%v.metrics.T,Vector2(20,size.y-20),TEAL)
	if route=="lower" and v.focus=="deck":
		var a:Vector2=v.project(v.bodies[0].to_global(Vector3(0,0,-v.metrics.B/2-2)))
		var b:Vector2=v.project(v.bodies[0].to_global(Vector3(0,v.metrics.H,-v.metrics.B/2-2)))
		draw_line(a,b,GOLD,2,true);label("H = %.2f m"%v.metrics.H,(a+b)*.5+Vector2(10,0),GOLD)
