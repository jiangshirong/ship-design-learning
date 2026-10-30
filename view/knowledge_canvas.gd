extends Control
# Adapted from the design package knowledge_map_canvas.gd. Geometry is data-owned.
var graph:Dictionary={}
var cards:Dictionary={}
func edge_points(edge:Dictionary)->PackedVector2Array:
	if edge.has("route"):
		var points:=PackedVector2Array()
		for point in edge.route:points.append(Vector2(point[0],point[1]))
		return points
	var a:Rect2=cards[edge.from].get_rect()
	var b:Rect2=cards[edge.to].get_rect()
	return PackedVector2Array([Vector2(a.get_center().x,a.end.y+3),Vector2(b.get_center().x,b.position.y-5)])
func _draw()->void:
	for region in graph.get("groups",[]):
		var style:=StyleBoxFlat.new();style.bg_color=Color("101f2b");style.border_color=Color("29404f");style.set_border_width_all(1);style.set_corner_radius_all(12)
		draw_style_box(style,Rect2(region.rect[0],region.rect[1],region.rect[2],region.rect[3]))
	for edge in graph.get("edges",[]):
		var points:=edge_points(edge)
		if edge.kind=="chapter_branch":
			draw_polyline(points,Color("668fa6"),2,true);continue
		var recommended:bool=edge.kind=="recommended"
		var color:=Color("79928c") if recommended else Color("8ab6d0")
		if recommended:draw_dashes(points,color)
		else:draw_polyline(points,color,2,true)
		var end:=points[-1];var direction:Vector2=(end-points[-2]).normalized();var side:=Vector2(-direction.y,direction.x)*5
		draw_line(end,end-direction*9+side,color,2,true);draw_line(end,end-direction*9-side,color,2,true)
func draw_dashes(points:PackedVector2Array,color:Color)->void:
	var distance:=0.0
	for i in range(1,points.size()):
		var a:=points[i-1];var b:=points[i];var length:=a.distance_to(b);var direction:Vector2=(b-a).normalized();var cursor:=0.0
		while cursor<length:
			var phase:=fmod(distance+cursor,14.0);var amount:=minf(length-cursor,(8.0 if phase<8 else 14.0)-phase)
			if amount<.001:amount=minf(.001,length-cursor)
			if phase<8:draw_line(a+direction*cursor,a+direction*(cursor+amount),color,2,true)
			cursor+=amount
		distance+=length
