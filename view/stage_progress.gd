extends ScrollContainer
# Chapter stages share one connected horizontal track. The lower lesson bar
# remains responsible for individual beats inside the selected stage.
signal item_selected(index:int)
var titles:Array[String]=[]
var selected:=-1
var item_count:int:
	get:return titles.size()
var track:Control
var cell_width:=120.0
class Track extends Control:
	var owner_bar
	func _draw()->void:owner_bar.paint(self)
	func _gui_input(event:InputEvent)->void:
		if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
			var i:int=int(event.position.x/owner_bar.cell_width)
			if i>=0 and i<owner_bar.titles.size():owner_bar.item_selected.emit(i);accept_event()
	func _get_tooltip(point:Vector2)->String:
		var i:int=int(point.x/owner_bar.cell_width)
		return owner_bar.titles[i] if i>=0 and i<owner_bar.titles.size() else ""
func _ready()->void:
	horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	track=Track.new();track.owner_bar=self;track.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;add_child(track)
	resized.connect(func():rebuild();follow.call_deferred());rebuild()
func clear()->void:
	titles.clear();selected=-1;rebuild()
func add_item(title:String)->void:
	titles.append(title);rebuild()
func select(index:int)->void:
	selected=index;rebuild();follow.call_deferred()
func rebuild()->void:
	if not track:return
	cell_width=maxf(116,(size.x-2)/maxi(titles.size(),1))
	var font:Font=get_theme_font("font")
	for title in titles:
		cell_width=maxf(cell_width,ceilf(font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x)+24)
	track.custom_minimum_size=Vector2(cell_width*titles.size(),78)
	track.size=track.custom_minimum_size
	for child in track.get_children():track.remove_child(child);child.queue_free()
	for i in titles.size():
		var text:=Label.new();text.text=titles[i];text.mouse_filter=Control.MOUSE_FILTER_IGNORE
		text.position=Vector2(i*cell_width+5,29);text.size=Vector2(cell_width-10,45)
		text.clip_text=true;text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		text.add_theme_font_size_override("font_size",17)
		text.add_theme_color_override("font_color",Color("ecf1ef") if i==selected else Color("a0bac4"));track.add_child(text)
	track.queue_redraw()
func follow()->void:
	# The scroll range is updated by the container after the track's minimum size.
	for frame in 2:await get_tree().process_frame
	if selected<0:return
	var start:float=selected*cell_width
	if start<scroll_horizontal:scroll_horizontal=int(start)
	elif start+cell_width>scroll_horizontal+size.x:scroll_horizontal=int(start+cell_width-size.x)
func paint(surface:Control)->void:
	if titles.is_empty():return
	var first:=Vector2(cell_width*.5,15);var last:=Vector2(cell_width*(titles.size()-.5),15)
	surface.draw_line(first,last,Color("42606b"),2,true)
	if selected>0:surface.draw_line(first,Vector2(cell_width*(selected+.5),15),Color("b7dcc6"),2,true)
	for i in titles.size():
		var p:=Vector2(cell_width*(i+.5),15)
		surface.draw_circle(p,5,Color("b7dcc6") if i<=selected else Color("42606b"),true,-1,true)
		if i==selected:surface.draw_arc(p,9,0,TAU,40,Color("b7dcc6"),2,true)
