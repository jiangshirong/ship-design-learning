extends Control
var ship
var regions:Array=[]
func _ready()->void:mouse_filter=Control.MOUSE_FILTER_PASS
func _get_tooltip(at:Vector2)->String:
	for r in regions:
		if r.rect.has_point(at):return r.text
	return ""
func _draw()->void:
	regions.clear()
	if ship==null or str(ship.current.get("approx_flow","")).is_empty():return
	var amount:float=clampf(float(ship.current.get("approx_reveal",1)),0,1)
	var l:float=ship.dims.x;var h:float=ship.dims.z;var b:float=ship.dims.y
	var specs:Array=[[Vector3(-l*.20,h+6,b*.65),Vector3(l*.13,h+6,b*.65),Color("70e1cf"),"航速","Ско́рость"]]
	if ship.current.approx_flow!="velocity":specs.append([Vector3(l*.13,h+2,b*.70),Vector3(-l*.20,h+2,b*.70),Color("ffd079"),"水的阻力","Сопротивле́ние воды́"])
	for s in specs:
		var a:Vector2=ship.camera.unproject_position(ship.body.to_global(s[0]));var end:Vector2=ship.camera.unproject_position(ship.body.to_global(s[1]));var p:Vector2=a.lerp(end,amount)
		draw_line(a,p,s[2],4,true)
		if amount>.05:
			var direction:Vector2=(p-a).normalized()
			draw_line(p,p-direction.rotated(.5)*16,s[2],4,true);draw_line(p,p-direction.rotated(-.5)*16,s[2],4,true)
		var label:String=s[3] if ship.lang=="zh" else s[4]
		var where:Vector2=a.lerp(end,.5)+Vector2(-40,-12)
		draw_string(get_theme_default_font(),where,label,HORIZONTAL_ALIGNMENT_LEFT,-1,22,s[2])
		regions.append({"rect":Rect2(where-Vector2(0,24),Vector2(230,30)),"text":str(s[4])+"\n"+str(s[3])})
