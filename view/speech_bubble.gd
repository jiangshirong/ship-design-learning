extends Control
signal focus_requested
var focus_press:=Vector2.ZERO
var focus_armed:=false
# Screen-space paragraph anchored to the lesson object. Placement is measured
# from the current complete sentence. Placement reserves both translations so
# changing language can resize the box without jumping to another location.
var spotlight:ColorRect
var panel:PanelContainer
var caption
var measurement
var anchor:=Vector2.ZERO
var anchored:=false
var pending:=true
var reserved_height:=160.0
var translations:Dictionary={}
var measured_size:=Vector2.ZERO
var measured_text:=""
var placement_size:=Vector2.ZERO
var measurements:Dictionary={}
var quiet_frames:=0
var protected_rects:Array=[]
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	spotlight=preload("res://view/lesson_spotlight.gd").new();spotlight.speech=self
	get_parent().add_child.call_deferred(spotlight)
	call_deferred("place_spotlight_layer")
	panel=PanelContainer.new();add_child(panel)
	panel.minimum_size_changed.connect(func():panel.set_deferred("size",panel.custom_minimum_size))
	var style:=StyleBoxFlat.new();style.bg_color=Color("f2f6f9");style.border_color=Color("b7cbd7");style.set_border_width_all(1);style.set_corner_radius_all(6);style.content_margin_left=16;style.content_margin_right=16;style.content_margin_top=10;style.content_margin_bottom=10;style.shadow_color=Color(0,0,0,.18);style.shadow_size=6
	panel.add_theme_stylebox_override("panel",style)
	caption=preload("res://modules/review/view/notation_text.gd").new();caption.fit_content=false;caption.add_theme_font_size_override("font_size",22);panel.add_child(caption)
	caption.gui_input.connect(focus_input.bind(caption))
	panel.gui_input.connect(focus_input.bind(panel))
	caption.scroll_fit_content_height=true
	caption.add_theme_color_override("font_readonly_color",Color("203f54"));caption.add_theme_color_override("selection_color",Color("b7d9e9"))
	measurement=preload("res://view/selectable_text.gd").new();measurement.fit_content=false;measurement.add_theme_font_size_override("font_size",22);add_child(measurement);measurement.hide()
	resized.connect(arrange)
func begin_beat(words:Dictionary)->void:
	translations=words;measured_size=Vector2.ZERO;invalidate();arrange()
func invalidate()->void:
	pending=true;quiet_frames=0;panel.hide();queue_redraw()
func arrange()->void:
	if panel==null:return
	if measured_size.is_equal_approx(size) and measured_text==caption.full_text:return
	if not measured_size.is_equal_approx(size):invalidate()
	measured_size=size;measured_text=caption.full_text
	placement_size=Vector2.ZERO
	for sentence in translations.values():placement_size=placement_size.max(sentence_size(str(sentence)))
	var fitted:=sentence_size(caption.full_text)
	placement_size=placement_size.max(fitted);reserved_height=placement_size.y
	caption.custom_minimum_size=Vector2(0,fitted.y-20)
	panel.custom_minimum_size=fitted;panel.size=fitted
	panel.reset_size.call_deferred()
	queue_redraw()
func sentence_size(sentence:String)->Vector2:
	var key:=str(size)+sentence+str(measurement.get_theme_font("font").get_instance_id())+str(measurement.get_theme_font_size("font_size"))
	if measurements.has(key):return measurements[key]
	var max_width:float=minf(minf(maxf(size.x*.45,340),420),maxf(100,size.x-32))
	# Measure with the same native text control (including font fallback and
	# wrap rules), rather than estimating TextEdit's rows with a Font helper.
	measurement.size=Vector2(max_width-32,4096);measurement.set_content(sentence)
	var rows:int=maxi(1,measurement.get_total_visible_line_count())
	# Find the narrowest box retaining this row count. This also avoids an
	# almost-empty final line without forcing every short sentence to 420 px.
	var low:=72.0;var high:=max_width
	for i in range(10):
		var trial:float=(low+high)*.5
		measurement.size=Vector2(trial-32,4096)
		if measurement.get_total_visible_line_count()<=rows:high=trial
		else:low=trial
	var width:float=minf(max_width,ceilf(high)+2)
	measurements[key]=Vector2(width,rows*measurement.get_line_height()+28)
	if measurements.size()>64:measurements.erase(measurements.keys()[0])
	return measurements[key]

func ready_to_place()->bool:
	quiet_frames+=1
	return quiet_frames>=3
func place_near_target(obstacles:Array)->void:
	protected_rects=obstacles
	var box_size:=placement_size
	var limit:=size-box_size-Vector2(16,16)
	var candidates:Array[Vector2]=[]
	# Prefer a nearby edge of the paragraph, never its centre over the object.
	for dx in [-1,0,1]:
		for dy in [-1,0,1]:
			if dx==0 and dy==0:continue
			var offset:=Vector2((box_size.x*.5+28)*dx,(box_size.y*.5+28)*dy)
			candidates.append(anchor+offset-box_size*.5)
	# Fallback empty spaces account for whole geometry and labels, not just anchor.
	for x in range(0,int(size.x),32):
		for y in range(0,int(size.y),32):candidates.append(Vector2(x,y))
	var best:=Vector2(16,16);var best_score:=INF
	for candidate in candidates:
		var pos:=candidate.clamp(Vector2(16,16),limit.max(Vector2(16,16)))
		var rect:=Rect2(pos,box_size)
		var closest:=anchor.clamp(rect.position,rect.end)
		var score:float=anchor.distance_to(closest)+anchor.distance_to(rect.get_center())*.12
		for obstacle in obstacles:
			var intersection:Rect2=rect.grow(12).intersection(obstacle)
			if intersection.has_area():score+=intersection.get_area()*8.0
		if rect.grow(18).has_point(anchor):score+=1000000
		if score<best_score:best_score=score;best=pos
	panel.position=best;pending=false;panel.show();queue_redraw()
func set_target_point(value:Vector2,enabled:=true)->void:
	if anchor==value and anchored==enabled:return
	anchor=value;anchored=enabled;queue_redraw()
func _draw()->void:
	if not anchored or panel==null or not panel.visible:return
	var rect:=panel.get_rect()
	if rect.grow(10).has_point(anchor):return
	var start:=anchor.clamp(rect.position+Vector2(9,9),rect.end-Vector2(9,9))
	var direction:Vector2=(anchor-start).normalized()
	var normal:=Vector2(-direction.y,direction.x)
	var tip:=start+direction*17
	draw_colored_polygon(PackedVector2Array([start-normal*7,start+normal*7,tip]),Color("72d6c2"))
	draw_line(tip,anchor,Color("72d6c2"),1.5,true)
	draw_circle(anchor,4,Color("72d6c2"))

func focus_input(event:InputEvent,source:Control)->void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		var point:Vector2=source.global_position+event.position
		if event.pressed:
			focus_press=point;focus_armed=not event.double_click
		else:
			var activate:bool=focus_armed and point.distance_to(focus_press)<5.0
			focus_armed=false
			if activate:focus_requested.emit()
	elif event is InputEventMouseMotion and focus_armed:
		if (source.global_position+event.position).distance_to(focus_press)>=5.0:focus_armed=false

func set_source(b:Dictionary,language:String)->void:
	var phrase:String=b.get("source_phrase",{}).get(language,"")
	caption.set_meta("source_phrase",phrase)
	caption.syntax_highlighter.clear_highlighting_cache();caption.queue_redraw()
	var style:StyleBoxFlat=panel.get_theme_stylebox("panel").duplicate()
	style.border_width_left=3 if not phrase.is_empty() else 1
	style.border_color=Color("bda5f5") if not phrase.is_empty() else Color("b7cbd7")
	panel.add_theme_stylebox_override("panel",style)

func place_spotlight_layer()->void:
	if is_instance_valid(spotlight) and spotlight.get_parent()==get_parent():get_parent().move_child(spotlight,get_index())
