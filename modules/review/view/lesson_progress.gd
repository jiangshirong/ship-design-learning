extends Control
signal step_requested(index:int)
var steps:Array=[]
var current:=0
var hovered:=-1
var language:="zh"
var groups:Array=[]
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	resized.connect(queue_redraw)
	mouse_exited.connect(func():hovered=-1;queue_redraw())
func sync(beats:Array,index:int,lang:String,sections:Array)->void:
	steps=beats;current=index;language=lang;groups=sections;queue_redraw()
func point(index:int)->Vector2:
	return Vector2(78+(size.x-94)*float(index)/maxi(steps.size()-1,1),size.y*.5)
func hit(pos:Vector2)->int:
	if steps.is_empty() or absf(pos.y-size.y*.5)>18:return -1
	var index:int=roundi((pos.x-78)/maxf(size.x-94,1)*maxi(steps.size()-1,1))
	if index<0 or index>=steps.size():return -1
	var radius:float=minf(12,(size.x-94)/maxi(steps.size()-1,1)*.48)
	return index if absf(pos.x-point(index).x)<=radius else -1
func _draw()->void:
	if steps.is_empty():return
	var font:Font=get_theme_default_font()
	draw_string(font,Vector2(0,size.y*.5+6),"%d / %d"%[current+1,steps.size()],HORIZONTAL_ALIGNMENT_LEFT,70,16,Color("a9c2cd"))
	draw_line(point(0),point(steps.size()-1),Color("34505e"),2,true)
	if current>0:draw_line(point(0),point(current),Color("71cec5"),2,true)
	for i in range(steps.size()):
		var color:=Color("f5c879") if i==current else Color("71cec5") if i<current else Color("6e8795")
		var radius:=6.0 if i==current or i==hovered else 4.0
		draw_circle(point(i),radius,color,true,-1,true)
		if i==current:draw_arc(point(i),9,0,TAU,32,Color("f5c879"),1,true)
func _gui_input(event:InputEvent)->void:
	if event is InputEventMouseMotion:
		var index:=hit(event.position)
		if index!=hovered:hovered=index;queue_redraw()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		var index:=hit(event.position)
		if index>=0:step_requested.emit(index);accept_event()
func _get_tooltip(at_position:Vector2)->String:
	var index:=hit(at_position)
	if index<0:return ""
	var title:Variant=groups[int(steps[index].group)].get("title",{})
	var text:String=str(title.get(language,title.get("zh",""))) if title is Dictionary else str(title)
	return "%d / %d · %s"%[index+1,steps.size(),text]
