extends VBoxContainer
# One immutable identity per revealed beat; scrolling never responds to numeric ticks.
const Formula=preload("res://view/latex_panel.gd")
const Selectable=preload("res://view/selectable_text.gd")
var entries:Dictionary={}
var current_id:=""
var active_step_id:=""
var scroll:ScrollContainer
var language:="zh"
var generation:=0
var follow_pending:=false
var last_record:=""
var highlighted_id:=""
var history_style:StyleBoxFlat
var current_style:StyleBoxFlat
func _ready()->void:
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",20)
	history_style=record_style(false);current_style=record_style(true)
func record_style(selected:bool)->StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("2b414b") if selected else Color(0,0,0,0)
	style.border_color=Color("f5c879") if selected else Color(0,0,0,0)
	style.set_border_width_all(1);style.border_width_left=4;style.set_corner_radius_all(6)
	# Equal padding prevents formula reflow when a record becomes history.
	style.content_margin_left=8;style.content_margin_right=0
	style.content_margin_top=10;style.content_margin_bottom=0
	return style
func _input(event:InputEvent)->void:
	if not scroll or not is_visible_in_tree():return
	if event is InputEventMouseButton and event.pressed and scroll.get_global_rect().has_point(event.position):
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN,MOUSE_BUTTON_LEFT]:
			generation+=1;follow_pending=false
func clear_records()->void:
	for child in get_children():remove_child(child);child.queue_free()
	entries.clear();current_id="";active_step_id="";last_record="";highlighted_id="";follow_pending=false;generation+=1
func update_current(values:Dictionary)->void:
	if current_id==active_step_id and entries.has(current_id):
		var e:Dictionary=entries[current_id]
		if e.math.visible:e.math.set_beat(current_id,values,language)
func set_prefix(beats:Array,index:int,values:Dictionary,lang:String,active_id:String)->void:
	if current_id==str(beats[index].id) and language==lang and active_step_id==active_id:
		update_current(values);return
	var moving:bool=current_id!=str(beats[index].id)
	var changing:bool=language!=lang
	var old_y:int=scroll.scroll_vertical if scroll else 0
	var anchor_id:="";var anchor_offset:=0.0
	var anchor_row:=-1
	if changing and scroll:
		for id in entries:
			var node:Control=entries[id].box
			if node.visible and node.get_global_rect().end.y>=scroll.global_position.y:
				anchor_id=id;anchor_offset=node.global_position.y-scroll.global_position.y
				var math=entries[id].math
				for drawing in math.drawings:
					if math.global_position.y+drawing.rect.end.y>=scroll.global_position.y:
						anchor_row=int(drawing.row);anchor_offset=math.global_position.y+drawing.rect.position.y-scroll.global_position.y;break
				break
		# Preserve the current visible record across translation reflow. Anchoring
		# an older, much taller paragraph can otherwise push it below the viewport.
		if entries.has(active_id) and entries[active_id].box.get_global_rect().intersects(scroll.get_global_rect()):
			anchor_id=active_id;anchor_row=-1
			anchor_offset=entries[active_id].box.global_position.y-scroll.global_position.y
	var revealed:Dictionary={}
	var new_last:=""
	for i in range(index+1):
		var b:Dictionary=beats[i];var id:String=b.id
		var rows:Array=Formula.bundle.lessons.get(id,{}).get(lang,[])
		if rows.is_empty():continue
		revealed[id]=true
		new_last=id
		if not entries.has(id):
			var box:=PanelContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.add_theme_stylebox_override("panel",history_style);add_child(box)
			var content:=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",7);box.add_child(content)
			var note=Selectable.new();note.add_theme_font_size_override("font_size",22);note.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_child(note)
			var math=preload("res://view/course_source_latex.gd").new() if b.has("source_rule") else Formula.new()
			if b.has("source_rule"):math.source_rows=b.get("source_rows",{})
			content.add_child(math);entries[id]={"box":box,"note":note,"math":math,"active":false}
		var e:Dictionary=entries[id];e.box.show()
		var title:Dictionary=b.get("record_label",{})
		e.note.visible=not title.is_empty()
		if not title.is_empty():e.note.set_content(title.get(lang,title.get("zh","")))
		# Older records bind their own settled values, never the animated current row.
		var bound:Dictionary=b.get("record_values",values) if i<index or id!=active_id else values
		e.math.set_beat(id,bound,lang)
	highlighted_id=""
	for id in entries:
		var entry:Dictionary=entries[id]
		entry.box.visible=revealed.has(id)
		var selected:bool=id==active_id and revealed.has(id)
		if selected:highlighted_id=id
		if entry.active!=selected:
			entry.active=selected
			entry.box.add_theme_stylebox_override("panel",current_style if selected else history_style)
			entry.math.modulate=Color(1,.94,.75) if selected and entry.math.get_script()!=preload("res://view/course_source_latex.gd") else Color.WHITE
			entry.note.modulate=Color(1,.94,.75) if selected else Color.WHITE
	if new_last!=last_record:follow_pending=true
	last_record=new_last
	current_id=str(beats[index].id);active_step_id=active_id;language=lang
	if moving or changing:
		generation+=1;restore_scroll.call_deferred(generation,moving,anchor_id,anchor_offset,old_y,anchor_row)
func restore_scroll(token:int,moving:bool,anchor_id:String,offset:float,old_y:int,anchor_row:int)->void:
	# Native text wrapping can resize VBox rows over more than one layout pass.
	for i in range(5):await get_tree().process_frame
	if token!=generation or not scroll:return
	if follow_pending:
		if not last_record.is_empty():scroll.scroll_vertical+=int(entries[last_record].box.global_position.y-scroll.global_position.y)
		follow_pending=false
	elif not anchor_id.is_empty() and entries.has(anchor_id):
		var entry:Dictionary=entries[anchor_id]
		var target:float=entry.box.global_position.y
		if anchor_row>=0:
			for drawing in entry.math.drawings:
				if int(drawing.row)==anchor_row:target=entry.math.global_position.y+drawing.rect.position.y;break
		scroll.scroll_vertical+=int(roundf(target-scroll.global_position.y-offset))
	else:scroll.scroll_vertical=old_y
