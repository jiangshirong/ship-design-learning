extends Control
signal changed
signal navigated
signal field_created(field:TextEdit)
signal animation_requested(id:String)
signal topic_requested(id:String)
var bank_id:="legacy"
var content_root:="res://modules/review/content/"
var topics:Array=JSON.parse_string(FileAccess.get_file_as_string("res://modules/review/content/topics.json"))
var topic_selected:=""
var topic_button:Button
var tree_items:Dictionary={}
var rebuilding:=false
const Text=preload("res://modules/review/view/notation_text.gd")
const UI=preload("res://modules/review/mobile_ui/theme.gd")
const MobileIcons=preload("res://modules/review/mobile_ui/ui_icons.gd")
const Choice=preload("res://modules/review/mobile_ui/choice_button.gd")
const Icons=preload("res://modules/review/view/review_icons.gd")
const Alphabet=preload("res://modules/review/core/question_alphabet.gd")
var grouping:="topic"
var grouping_button:Button
var alphabet_info:Dictionary={}
var store=preload("res://modules/review/core/reading_store.gd").new()
var entries:Array=[]
var filtered:Array[int]=[]
var index:=0
var revealed:=false
var exercise:=""
var picture_panel
var listing:Tree
var panel:PanelContainer
var scroll:ScrollContainer
var column:VBoxContainer
var heading:Label
var question
var translation
var details:VBoxContainer
var notice:Label
var reveal_button:Button
var known_button:Button
var review_button:Button
var animation_button:Button
var example_button:Button
var variant_button:Button
var original_button:Button
var previous_button:Button
var next_button:Button
var footer:VBoxContainer
var formula_panels:Array=[]
var words
var nav_button:Button
var nav_open:=true
var answer_panel:PanelContainer
var answer_scroll:ScrollContainer
var action_row:HBoxContainer
var page_title:Label
var badge
var topic_select:Button
var font_minus:Button
var font_plus:Button
var chinese_button:Button
var chinese_visible:=false
var topic_open:=false
var sidebar_style_mode:=-1
var topic_shade:ColorRect
var secondary_row:HBoxContainer
var bank_filter:Button
var source_label:Label
func _ready()->void:
	theme=UI.make()
	topics=JSON.parse_string(FileAccess.get_file_as_string(content_root+"topics.json"))
	entries=JSON.parse_string(FileAccess.get_file_as_string(content_root+"reading.json"))
	store.catalog_path=content_root+"reading.json"
	if bank_id in ["exam12","exams"]:
		store.data.selected=entries[0].id
		if not "--qa" in OS.get_cmdline_user_args():store.path="user://review/"+bank_id+"-reading.json"
	store.migration_bank=bank_id
	if bank_id=="exams" and not "--qa" in OS.get_cmdline_user_args():store.migration_source_path="user://review/exam12-reading.json"
	store.read_file()
	if bank_id in ["exam12","exams"]:
		grouping=str(store.data.get("grouping","topic"))
		for entry in entries:alphabet_info[entry.id]=Alphabet.info(entry)
	listing=Tree.new();listing.hide_root=true;listing.columns=2;listing.set_column_expand(1,false);listing.set_column_custom_minimum_width(1,40);listing.add_theme_font_size_override("font_size",19);listing.add_theme_constant_override("v_separation",10);add_child(listing)
	listing.add_theme_stylebox_override("panel",UI.box("f6f4ee","f6f4ee",12))
	listing.add_theme_stylebox_override("selected",UI.box("e3ece1","d4ddce",10));listing.add_theme_stylebox_override("selected_focus",UI.box("e3ece1","d4ddce",10))
	listing.add_theme_color_override("font_selected_color",Color("273d36"));listing.add_theme_color_override("font_color",Color("273d36"));listing.add_theme_constant_override("outline_size",0)
	listing.item_selected.connect(tree_selected)
	listing.item_collapsed.connect(func(item:TreeItem):
		if not rebuilding:
			var id:String=str(item.get_metadata(0))
			if id.begins_with("topic:"):store.data.expanded[id.substr(6)]=not item.collapsed;save()
			elif bank_id in ["exam12","exams"] and id.begins_with("letter:"):store.data.expanded[id]=not item.collapsed;save())
	panel=PanelContainer.new();panel.add_theme_stylebox_override("panel",StyleBoxEmpty.new());add_child(panel)
	scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;panel.add_child(scroll)
	column=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",12);scroll.add_child(column)
	heading=Label.new();heading.add_theme_font_size_override("font_size",22);column.add_child(heading)
	question=make_text(column,32)
	translation=make_text(column,23);translation.hide()
	answer_panel=PanelContainer.new();answer_panel.add_theme_stylebox_override("panel",get_parent().style("1a3543"));add_child(answer_panel)
	answer_scroll=ScrollContainer.new();answer_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;answer_panel.add_child(answer_scroll)
	details=VBoxContainer.new();details.size_flags_horizontal=SIZE_EXPAND_FILL;details.add_theme_constant_override("separation",23);answer_scroll.add_child(details)
	notice=Label.new();notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;notice.add_theme_font_size_override("font_size",17);column.add_child(notice)
	footer=VBoxContainer.new();footer.add_theme_constant_override("separation",8);add_child(footer)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);footer.add_child(row)
	previous_button=button(row,"上一题 · Q",func():move(-1));next_button=button(row,"下一题 · E",func():move(1))
	reveal_button=button(row,"揭晓 · F",reveal);known_button=button(row,"会了",func():mark("known"));review_button=button(row,"稍后再看",func():mark("review"))
	var more:=HBoxContainer.new();more.add_theme_constant_override("separation",8);footer.add_child(more)
	animation_button=button(more,"看动画 · V",request_animation)
	topic_button=button(more,"学习专题",func():topic_requested.emit(topic_selected));topic_button.hide()
	example_button=button(more,"计算示例",func():open_exercise("example"));variant_button=button(more,"练变式",func():open_exercise("variant"));original_button=button(more,"回原题",func():select_question(index))
	page_title=Label.new();page_title.text="题目";page_title.position=Vector2(32,24);page_title.add_theme_font_size_override("font_size",22);add_child(page_title);page_title.hide()
	nav_button=Button.new();add_child(nav_button);nav_button.hide()
	nav_button.icon=Icons.icon("sidebar");nav_button.tooltip_text="题目导航"
	nav_button.toggle_mode=true
	heading.reparent(self)
	for b in [previous_button,next_button,reveal_button,animation_button,topic_button]:b.reparent(self)
	action_row=HBoxContainer.new();action_row.add_theme_constant_override("separation",12);add_child(action_row)
	for b in [known_button,review_button,example_button,variant_button,original_button]:b.reparent(action_row)
	footer.hide()
	move_child(listing,get_child_count()-1)
	resized.connect(arrange)
	for i in entries.size():
		if entries[i].id==store.data.selected:index=i
	get_parent().font_scale=float(store.data.get("desktop_ui",{}).get("font_scale",1.0))
	panel.add_theme_stylebox_override("panel",UI.box("fffdf8","e3dfd3",18))
	column.add_theme_constant_override("separation",20)
	column.minimum_size_changed.connect(func():arrange.call_deferred())
	answer_scroll.remove_child(details);answer_panel.remove_child(answer_scroll);answer_scroll.queue_free();answer_scroll=scroll;answer_panel.add_child(details);answer_panel.reparent(column)
	action_row.reparent(column)
	secondary_row=HBoxContainer.new();secondary_row.add_theme_constant_override("separation",10);column.add_child(secondary_row)
	for b in [animation_button,example_button,variant_button,original_button]:b.reparent(secondary_row)
	badge=preload("res://modules/review/mobile_ui/progress_badge.gd").new();add_child(badge)
	topic_select=button(self,"专题",func():topic_open=not topic_open;arrange())
	if bank_id in ["exam12","exams"]:
		grouping_button=button(self,"分类：专题",toggle_grouping)
		grouping_button.toggle_mode=true
		grouping_button.tooltip_text="按专题或俄语首字母分类；开头的Почему不计入。"
		source_label=Label.new();source_label.add_theme_font_size_override("font_size",19);source_label.add_theme_color_override("font_color",Color("345b50"));add_child(source_label)
		bank_filter=button(self,"全部",func():
			store.data.filter="pending" if store.data.filter=="all" else "all";rebuild_filter();save();revealed=false;refresh())
	font_minus=button(self,"字号-",func():get_parent().adjust_font(-1));font_plus=button(self,"字号+",func():get_parent().adjust_font(1))
	chinese_button=button(self,"中",func():chinese_visible=not chinese_visible;refresh());chinese_button.toggle_mode=true
	chinese_button.tooltip_text="显示或收起中文题意"
	topic_shade=ColorRect.new();topic_shade.color=Color(.1,.15,.12,.35);topic_shade.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(topic_shade);topic_shade.z_index=12
	topic_shade.gui_input.connect(func(e):
		if (e is InputEventMouseButton or e is InputEventScreenTouch) and not e.pressed:topic_open=false;arrange())
	var answer_style:=UI.box("fffdf8","fffdf8",0);answer_style.content_margin_left=0;answer_style.content_margin_right=0;answer_style.set_border_width_all(0);answer_style.border_width_top=1;answer_style.border_color=Color("e5e1d7");answer_style.content_margin_top=22
	answer_panel.add_theme_stylebox_override("panel",answer_style)
	UI.primary(reveal_button)
	words=preload("res://modules/review/view/reading_words.gd").new();words.page=self;add_child(words)
	rebuild_filter();refresh();arrange()
func button(parent:Node,text:String,call:Callable)->Button:
	var b:Button
	if text in ["会了","稍后再看"]:
		b=Choice.new();b.caption=text;b.icon_name="badge-check" if text=="会了" else "clock-3";b.ink=Color("1f514a" if text=="会了" else "996d30");b.fill=Color("e8efe5" if text=="会了" else "f6eddd");b.pill=true;b.compact=true
	else:b=Button.new();b.text=text
	b.custom_minimum_size.y=48;parent.add_child(b);b.pressed.connect(call);return b
func make_text(parent:Node,font_size:int=23):
	var t=Text.new();t.add_theme_font_size_override("font_size",font_size);parent.add_child(t);t.add_theme_color_override("font_readonly_color",Color("273d36"));t.add_theme_color_override("selection_color",Color("dce9dd"));t.add_theme_color_override("font_selected_color",Color("1f514a"));t.add_theme_constant_override("line_spacing",8);field_created.emit(t);return t
func add_text(value:String,size_:int=23):
	var t=make_text(details,size_);t.set_content(value);return t
func arrange()->void:
	if not is_instance_valid(badge):return
	var wide:=size.x>=1280
	var nav_width:=280.0
	var left:float=340.0 if wide else 32.0
	var width:float=minf(920,size.x-left-32)
	var margin:float=left+(size.x-left-32-width)*.5
	var scale:float=get_parent().font_scale
	question.add_theme_font_size_override("font_size",roundi(30*scale));translation.add_theme_font_size_override("font_size",roundi(21*scale));question.measure();translation.measure()
	badge.position=Vector2(margin,26)
	if grouping_button:
		grouping_button.position=Vector2(24 if wide else margin,26)
		grouping_button.size=Vector2(280 if wide else 160,46)
		grouping_button.text="分类：字母" if grouping=="alphabet" else "分类：专题"
		grouping_button.set_pressed_no_signal(grouping=="alphabet")
		if not wide:badge.position.x=margin+176
	if bank_filter:
		source_label.position=Vector2(margin+(276 if grouping_button and not wide else 100),39);source_label.text=" / ".join(entries[index].sources) if index>=0 and topic_selected.is_empty() else "专题"
		bank_filter.position=Vector2(margin+(396 if grouping_button and not wide else 220),26);bank_filter.size=Vector2(100,46);bank_filter.text="待复习" if store.data.filter=="pending" else "全部"
	font_plus.position=Vector2(margin+width-82,26);font_plus.size=Vector2(82,46)
	font_minus.position=Vector2(margin+width-172,26);font_minus.size=Vector2(82,46)
	topic_select.position=Vector2(margin+width-254,26);topic_select.size=Vector2(74,46)
	topic_select.text="字母" if grouping=="alphabet" else "专题"
	font_minus.disabled=scale<=.8; font_plus.disabled=scale>=1.6
	panel.position=Vector2(margin,96);panel.size=Vector2(width,minf(maxf(170,column.get_combined_minimum_size().y+88),maxf(170,size.y-192)))
	panel.get_theme_stylebox("panel").content_margin_top=66
	chinese_button.position=Vector2(margin+width-64,108);chinese_button.size=Vector2(44,40);chinese_button.set_pressed_no_signal(chinese_visible)
	translation.visible=chinese_visible and index>=0
	answer_panel.visible=revealed and index>=0
	action_row.visible=revealed;secondary_row.visible=revealed
	for child in details.get_children():
		if child is TextEdit:child.add_theme_font_size_override("font_size",roundi((26 if child==details.get_child(0) else 20)*scale));child.measure()
	heading.hide();nav_button.hide()
	listing.z_index=13 if not wide and topic_open else 0
	listing.position=Vector2(24,100);listing.size=Vector2(nav_width,size.y-130);listing.visible=wide or topic_open
	if sidebar_style_mode!=int(wide):
		sidebar_style_mode=int(wide);listing.add_theme_stylebox_override("panel",UI.box("fffdf8" if not wide else "f6f4ee","e3dfd3" if not wide else "f6f4ee",16))
	topic_shade.visible=not wide and topic_open;topic_shade.position=Vector2.ZERO;topic_shade.size=size
	var middle:float=margin+width*.5
	previous_button.position=Vector2(middle-350,size.y-76);previous_button.size=Vector2(150,50)
	reveal_button.position=Vector2(middle-190,size.y-76);reveal_button.size=Vector2(380,50);reveal_button.visible=index>=0;reveal_button.disabled=index<0;reveal_button.text="收起答案 · F" if revealed else "揭晓答案 · F"
	next_button.position=Vector2(middle+200,size.y-76);next_button.size=Vector2(150,50)
	topic_button.visible=bank_id in ["exam12","exams"] and not topic_selected.is_empty() and topic_has_animation(topic_selected)
	if topic_button.visible:
		topic_button.position=Vector2(middle-190,size.y-76);topic_button.size=Vector2(380,50)
		previous_button.hide();next_button.hide();reveal_button.hide();answer_panel.hide();action_row.hide();secondary_row.hide()
	else:previous_button.show();next_button.show()
func current_question()->String:
	if index<0:return ""
	return entries[index].question_ru if exercise.is_empty() else entries[index].calculation[exercise].question_ru
func current_answer()->String:
	return entries[index].answer.ru if index>=0 and revealed and exercise.is_empty() else ""
func toggle_grouping()->void:
	if bank_id not in ["exam12","exams"]:return
	grouping="alphabet" if grouping=="topic" else "topic"
	topic_selected="";store.data.grouping=grouping
	var reading_y:=scroll.scroll_vertical
	rebuild_filter();save();refresh()
	scroll.set_deferred("scroll_vertical",reading_y)
func category(i:int)->String:
	return alphabet_info[entries[i].id].letter if grouping=="alphabet" else str(entries[i].topic)
func group_indices(filtered_only:=false)->Array:
	var result:Array=[]
	if index<0:return result
	for i in entries.size():
		if category(i)==category(index) and (not filtered_only or bank_id not in ["exam12","exams"] or i in filtered):result.append(i)
	if grouping=="alphabet":result.sort_custom(alphabet_less)
	return result
func alphabet_less(a:int,b:int)->bool:
	var left:String=alphabet_info[entries[a].id].sort
	var right:String=alphabet_info[entries[b].id].sort
	return a<b if left==right else left<right
func topic_has_animation(id:String)->bool:
	for topic in topics:
		if topic.id==id:return topic.get("animation_available",true)
	return false
func request_animation()->void:
	if index>=0 and topic_selected.is_empty() and entries[index].get("animation_available",true):animation_requested.emit(entries[index].id)
func tree_selected()->void:
	if rebuilding:return
	var item:=listing.get_selected()
	if not item:return
	var id:String=str(item.get_metadata(0))
	if id.begins_with("letter:"):
		for i in filtered:
			if category(i)==id.substr(7):topic_open=false;select_question(i);return
		return
	if id.begins_with("topic:"):
		var topic_id:String=id.substr(6)
		if not topic_has_animation(topic_id):
			for i in filtered:
				if entries[i].topic==topic_id:topic_open=false;select_question(i);return
			return
		if bank_id in ["exam12","exams"]:topic_selected=topic_id;revealed=false;topic_open=false;refresh();scroll.scroll_vertical=0;return
		for i in entries.size():
			if entries[i].topic==topic_id:topic_open=false;select_question(i);return
		return
	for i in entries.size():
		if entries[i].id==id:select_question(i);return
func rebuild_filter()->void:
	rebuilding=true;filtered.clear();listing.clear();tree_items.clear()
	var root:=listing.create_item()
	var groups:Array=[]
	if grouping=="alphabet":
		var letters:Array=[]
		for i in entries.size():
			if category(i) not in letters:letters.append(category(i))
		letters.sort_custom(func(a,b):return a<b if Alphabet.rank(a)==Alphabet.rank(b) else Alphabet.rank(a)<Alphabet.rank(b))
		for letter in letters:
			var indices:Array=[]
			for i in entries.size():
				if category(i)==letter:indices.append(i)
			indices.sort_custom(alphabet_less)
			groups.append({"id":"letter:"+letter,"title":letter,"indices":indices})
	else:
		for topic in topics:
			var indices:Array=[]
			for qid in topic.questions:
				for i in entries.size():
					if entries[i].id==qid:indices.append(i);break
			groups.append({"id":"topic:"+topic.id,"title":topic.title.zh,"indices":indices})
	for spec in groups:
		var group:=listing.create_item(root);group.set_text(0,spec.title);group.set_expand_right(0,true);group.set_metadata(0,spec.id)
		var key:String=spec.id if grouping=="alphabet" else spec.id.substr(6)
		group.collapsed=not store.data.get("expanded",{}).get(key,category(index)==(spec.title if grouping=="alphabet" else key) if index>=0 else false)
		for i in spec.indices:
			var qid:String=entries[i].id;var state:String=store.data.marks.get(qid,"")
			if bank_id in ["exam12","exams"] and store.data.filter=="pending" and state=="known":continue
			filtered.append(i)
			var item:=listing.create_item(group);item.set_metadata(0,qid)
			var caption:String=" / ".join(entries[i].sources)
			if grouping=="alphabet" and entries[i].get("kind","")!="figure":caption+=" · "+str(alphabet_info[qid].tail)
			item.set_text(0,caption)
			if grouping=="alphabet":item.set_text_overrun_behavior(0,TextServer.OVERRUN_TRIM_ELLIPSIS)
			if grouping=="alphabet":item.set_tooltip_text(0,entries[i].question_ru)
			item.set_icon(1,MobileIcons.texture({"known":"badge-check","review":"clock-3","":"circle-dashed"}[state]));item.set_icon_modulate(1,Color({"known":"558575","review":"996d30","":"7c897e"}[state]));item.set_icon_max_width(1,24)
			item.set_text_alignment(1,HORIZONTAL_ALIGNMENT_CENTER);item.set_selectable(1,false)
			item.set_tooltip_text(1,{"known":"会了","review":"稍后再看","":"未标记"}[state])
			tree_items[qid]=item
	if index not in filtered:index=filtered[0] if not filtered.is_empty() else -1
	if index>=0:tree_items[entries[index].id].select(0)
	rebuilding=false
func sync_selection()->void:
	if index<0 or not tree_items.has(entries[index].id):return
	rebuilding=true;var item:TreeItem=tree_items[entries[index].id];item.get_parent().collapsed=false;item.select(0);listing.ensure_cursor_is_visible();
	var local:=group_indices(true)
	if not local.is_empty() and index==local[0] and listing.has_method("scroll_to_item"):listing.call_deferred("scroll_to_item",item.get_parent(),false)
	rebuilding=false
func save()->void:
	if index>=0:store.data.selected=entries[index].id
	if not store.write_file() and not store.blocked:notice.text="复习进度未能保存。"
func select_question(i:int)->void:
	navigated.emit();topic_selected="";index=i;exercise="";revealed=false;chinese_visible=false;words.cursor=0;save();refresh();scroll.scroll_vertical=0
func move(direction:int)->void:
	if index<0:return
	var local:=group_indices(true)
	if local.is_empty():return
	select_question(local[posmod(local.find(index)+direction,local.size())])
func mark(state:String)->void:
	if index<0 or not revealed:return
	store.data.marks[entries[index].id]=state;var before:=index;rebuild_filter()
	if index!=before:select_question(index)
	else:save();refresh()
func open_exercise(kind:String)->void:
	if index<0:return
	navigated.emit();exercise=kind;revealed=false;words.cursor=0;refresh();scroll.scroll_vertical=0
func reveal()->void:
	if index<0 or not topic_selected.is_empty():return
	revealed=not revealed;answer_scroll.scroll_vertical=0;refresh()
func refresh()->void:
	if is_instance_valid(picture_panel):picture_panel.hide();picture_panel.queue_free();picture_panel=null
	arrange.call_deferred()
	if words:words.schedule()
	changed.emit()
	for child in details.get_children():child.hide();child.queue_free()
	formula_panels.clear();details.visible=revealed and index>=0 and topic_selected.is_empty()
	var valid:=index>=0 and topic_selected.is_empty()
	translation.visible=valid and chinese_visible
	question.visible=valid;reveal_button.disabled=not valid
	known_button.disabled=not valid or not revealed;review_button.disabled=not valid or not revealed
	animation_button.disabled=not valid or not entries[index].get("animation_available",true)
	animation_button.visible=valid and revealed and not animation_button.disabled;previous_button.disabled=not valid;next_button.disabled=not valid
	example_button.visible=valid and entries[index].has("calculation");variant_button.visible=example_button.visible and entries[index].calculation.has("variant")
	original_button.visible=not exercise.is_empty()
	notice.text="复习存档损坏，原文件已保留，本次不覆盖。" if store.blocked else ("复习进度未能保存。" if not store.issue.is_empty() else "")
	notice.visible=not notice.text.is_empty()
	topic_button.visible=not topic_selected.is_empty() and topic_has_animation(topic_selected)
	if not topic_selected.is_empty():
		for topic in topics:
			if topic.id==topic_selected:
				heading.text=topic.title.zh;question.visible=true;question.set_content(topic.goal.zh)
		return
	if not valid:heading.text="待复习题目已完成，可切换到全部题目。";question.set_content("");return
	sync_selection()
	heading.text="%s · %s"%[" / ".join(entries[index].sources),("识图辅助" if entries[index].get("kind","")=="figure" else {"":"原题","example":"计算示例","variant":"练习变式"}[exercise])]
	var local:=group_indices()
	badge.set_progress(local.find(index)+1,local.size())
	known_button.selected=store.data.marks.get(entries[index].id,"")=="known";known_button.update_style()
	review_button.selected=store.data.marks.get(entries[index].id,"")=="review";review_button.update_style()
	question.set_content(current_question())
	translation.set_content((entries[index].translation if exercise.is_empty() else entries[index].calculation[exercise].translation) if chinese_visible else "")
	if valid and entries[index].has("images"):
		picture_panel=preload("res://modules/review/view/exam_picture.gd").new();column.add_child(picture_panel);column.move_child(picture_panel,1);picture_panel.setup(entries[index].images)
	if not revealed:return
	if exercise.is_empty():
		var e:Dictionary=entries[index]
		add_text(e.answer.ru,29)
		var zh=add_text(e.answer.zh,23);zh.add_theme_color_override("font_readonly_color",Color("526c5c"))
		if e.has("condition"):
			add_text(e.condition.zh,18)
			if e.condition.has("ru"):add_text(e.condition.ru,19)
		if e.has("formula_id"):add_formula(e.formula_id)
	else:
		var e:Dictionary=entries[index].calculation[exercise]
		add_text(e.steps[0],22);add_text(e.steps[1],22)
		add_formula(e.formula_id)
		for step_index in range(2,e.steps.size()):add_text(e.steps[step_index],22)
func add_formula(id:String)->void:
	var math=preload("res://modules/review/view/latex_panel.gd").new();math.light_mode=true;details.add_child(math);math.set_beat(id,{},"zh");formula_panels.append(math)

