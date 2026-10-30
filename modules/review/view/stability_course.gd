extends Control
const Lifecycle=preload("res://core/scene_lifecycle.gd")
const Hydro=preload("res://modules/review/core/stability_math.gd")
const Player=preload("res://modules/review/core/lesson_player.gd")
var player=Player.new()
var topic_store=preload("res://modules/review/core/topic_store.gd").new()
var courses:Array=JSON.parse_string(FileAccess.get_file_as_string("res://modules/review/content/topics.json"))
var original_ship
var topic_ship
var navigation_scroll:ScrollContainer
var qa:=false
var bank_id:="legacy"
var store=preload("res://modules/review/core/stability_store.gd").new()
var course:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://modules/review/content/stability_course.json"))
var ship
var bubble
var chart
var records
var scroll:ScrollContainer
var evidence_background:Panel
var evidence:VBoxContainer
var right:PanelContainer
var navigation:HBoxContainer
var phase_menu:ScrollContainer
var formula_toggle:Button
var drawer_open:=false
var animation_waiting:=false
var stage_buttons:Array=[]
var progress
var parameters:HBoxContainer
var sliders:Dictionary={}
var slider_labels:Dictionary={}
var reset_button:Button
var replay_button:Button
var condition
var notice:Label
var local_indices:Array=[]
var language:="zh"
var beat:Dictionary={}
var current_state:Dictionary={}
var active_group:=-1
var scroll_group:=-1
var updating:=false
var experiment:=false
var replay_tween:Tween
var last_record_tick:=0
var settled_records:Array=[]
var topic_records:Dictionary={}
var history_computations:=0
var evaluation:Dictionary={}
var paused_player_animation:=false
var paused_replay:=false
signal language_changed(value:String)
signal field_created(field:TextEdit)
func tr2(a:String,b:String)->String:return a if language=="zh" else b
func _ready()->void:
	add_child(player)
	qa="--qa" in OS.get_cmdline_user_args()
	if bank_id=="exam12":topic_store.path="user://review/exam12-topics.json"
	if qa:topic_store.path="user://review/qa-"+bank_id+"-topics-"+str(OS.get_process_id())+".json"
	topic_store.read_file()
	navigation_scroll=ScrollContainer.new();navigation_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO;navigation_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;add_child(navigation_scroll)
	navigation=HBoxContainer.new();navigation.add_theme_constant_override("separation",6);navigation_scroll.add_child(navigation)
	topic_ship=preload("res://modules/review/view/topic_view.gd").new();add_child(topic_ship);topic_ship.hide()
	bubble=preload("res://modules/review/view/speech_bubble.gd").new();add_child(bubble)
	bubble.focus_requested.connect(func():
		if not is_visible_in_tree() or beat.is_empty():return
		ship.set_camera(beat.get("camera","front"));bubble.invalidate())
	field_created.emit(bubble.caption)
	right=PanelContainer.new();var style:=StyleBoxFlat.new();style.bg_color=Color("162e3e");style.set_corner_radius_all(8);style.content_margin_left=14;style.content_margin_right=14;style.content_margin_top=12;style.content_margin_bottom=12;right.add_theme_stylebox_override("panel",style);add_child(right)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",10);right.add_child(column)
	condition=preload("res://modules/review/view/notation_text.gd").new();condition.add_theme_font_size_override("font_size",20);condition.add_theme_color_override("font_readonly_color",Color("a6cfda"));evidence_background=Panel.new();evidence_background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var evidence_style:=StyleBoxFlat.new();evidence_style.bg_color=Color(.04,.11,.15,.94);evidence_style.set_corner_radius_all(8);evidence_background.add_theme_stylebox_override("panel",evidence_style);add_child(evidence_background)
	evidence=VBoxContainer.new();evidence.add_theme_constant_override("separation",10);add_child(evidence);evidence.add_child(condition);field_created.emit(condition);condition.minimum_size_changed.connect(func():arrange.call_deferred())
	chart=preload("res://modules/review/view/stability_plot.gd").new();evidence.add_child(chart);chart.angle_requested.connect(func(v:float):experiment_value("heel",v))
	scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(scroll)
	records=preload("res://modules/review/view/calculation_record.gd").new();records.field_created.connect(func(field:TextEdit):field_created.emit(field));records.scroll=scroll;scroll.add_child(records)
	parameters=HBoxContainer.new();parameters.add_theme_constant_override("separation",12);add_child(parameters)
	for key in ["heel","zg"]:
		var col:=VBoxContainer.new();col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parameters.add_child(col)
		var text:=Label.new();text.add_theme_font_size_override("font_size",17);col.add_child(text);slider_labels[key]=text
		var slider:=HSlider.new();slider.step=.01 if key=="zg" else .1;slider.focus_mode=Control.FOCUS_NONE;slider.custom_minimum_size=Vector2(100,25);col.add_child(slider);sliders[key]=slider
		slider.value_changed.connect(func(v:float):if not updating:experiment_value(key,v))
	reset_button=Button.new();parameters.add_child(reset_button);reset_button.pressed.connect(reset_segment)
	replay_button=Button.new();parameters.add_child(replay_button);replay_button.pressed.connect(replay_roll)
	progress=preload("res://modules/review/view/lesson_progress.gd").new();add_child(progress);progress.step_requested.connect(func(i:int):goto_index(local_indices[i]))
	notice=Label.new();notice.add_theme_font_size_override("font_size",17);add_child(notice)
	player.prepared.connect(prepared);player.state_changed.connect(state_changed);player.characters.connect(func(n:int):bubble.caption.visible_characters=n)
	player.phase_changed.connect(func(_phase:String):refresh_controls();if not beat.is_empty():refresh_records())
	phase_menu=preload("res://view/stage_progress.gd").new();add_child(phase_menu);phase_menu.item_selected.connect(func(i:int):goto_group(i,true))
	formula_toggle=Button.new();add_child(formula_toggle);formula_toggle.pressed.connect(func():drawer_open=not drawer_open;arrange();bubble.begin_beat(beat.get("words",{})))
	resized.connect(arrange);arrange();labels()
func persist()->void:
	topic_store.put(store.data)
	store.blocked=topic_store.blocked
var initial_camera_pending:=false
func open_topic(id:String,question:="",lang:="zh",legacy_targets:Dictionary={},legacy_selected:="")->void:
	close();drawer_open=false;initial_camera_pending=true
	var host=get_parent().get_parent()
	var paths:Array=[]
	var resources:Array=[]
	if id=="stability":paths=["res://modules/review/assets/stability_fittings.glb","res://assets/damage_tanker.glb","res://assets/ocean/calm_ocean.glb"]
	elif id=="damage":paths=["res://assets/damage_tanker.glb","res://assets/ocean/calm_ocean.glb"]
	elif id=="propulsion":paths=["res://modules/review/assets/planing_yacht.glb","res://assets/ocean/calm_ocean.glb"]
	elif id in ["freeboard","hullform","arrangement"]:paths=["res://modules/review/assets/module11_ship.glb","res://assets/ocean/calm_ocean.glb"]
	elif id in ["cargo","loads"]:paths=["res://assets/study_cargo_inspection.glb","res://assets/damage_tanker.glb"]
	if bank_id=="exam12":paths=["res://modules/review/assets/module11_ship.glb","res://assets/ocean/calm_ocean.glb"]
	if not paths.is_empty():
		var token:int=host.begin_loading()
		resources=await preload("res://core/asset_loader.gd").warm(self,paths)
		if not host.end_loading(token):return
	if id=="stability" and not is_instance_valid(original_ship):
		original_ship=preload("res://modules/review/view/stability_ship.gd").new();add_child(original_ship);move_child(original_ship,0)
		Lifecycle.restore_camera("stability",original_ship)
	for c in courses:
		if c.id==id:course=c;break
	store.data=topic_store.select_topic(course,legacy_targets,qa,"",legacy_selected);store.blocked=topic_store.blocked
	language=store.data.language if question.is_empty() else lang
	store.data.language=language
	topic_ship.visible=id!="stability"
	ship=original_ship if id=="stability" else topic_ship
	if id=="stability" and ship.get_meta("camera_restored",false):
		initial_camera_pending=false;ship.set_meta("camera_restored",false)
	process_mode=Node.PROCESS_MODE_INHERIT
	if id=="stability":
		Lifecycle.use("stability",original_ship,func():
			var old=original_ship
			if ship==old:ship=null
			original_ship=null;remove_child(old);old.queue_free())
	for button_ in stage_buttons:navigation.remove_child(button_);button_.queue_free()
	stage_buttons.clear()
	for i in course.groups.size():
		var button_:=Button.new();navigation.add_child(button_);button_.custom_minimum_size.y=42
		button_.pressed.connect(func():goto_group(i,true));stage_buttons.append(button_)
	show();active_group=-1;beat={};records.clear_records()
	if not topic_records.has(course.id):topic_records[course.id]=[]
	settled_records=topic_records[course.id]
	var target:String=store.data.beat
	var foundation_ids:Array=[]
	for b in course.groups[0].beats:foundation_ids.append(b.id)
	if not question.is_empty():
		if store.data.foundation_done:target=course.question_targets[question];store.data.pending=""
		else:
			store.data.pending=question
			if target not in foundation_ids:target=foundation_ids[0]
	var valid_ids:Array=[]
	for group in course.groups:
		for b in group.beats:valid_ids.append(b.id)
	target=course.get("resume_aliases",{}).get(target,target)
	if target not in valid_ids:target=foundation_ids[0]
	player.open(course,target);labels();arrange();resources.clear()
func open_question(question:="",lang:="zh",old_target:="")->void:
	await open_topic("stability",question,lang,{question:old_target} if not old_target.is_empty() else {})
func is_roll()->bool:
	return course.id=="stability" and str(current_state.get("show",""))=="roll"
func close()->void:
	animation_waiting=false;stop_replay();player.close(false)
	if is_instance_valid(ship):ship.cancel()
	topic_ship.deactivate()
	if is_instance_valid(original_ship):Lifecycle.set_active(original_ship,false)
	hide();process_mode=Node.PROCESS_MODE_DISABLED
func pause_for_settings(paused:bool)->void:
	player.set_process(not paused)
	if paused:
		paused_player_animation=player.animation!=null and player.animation.is_valid() and player.animation.is_running()
		paused_replay=replay_tween!=null and replay_tween.is_valid() and replay_tween.is_running()
		if paused_player_animation:player.animation.pause()
		if paused_replay:replay_tween.pause()
	else:
		if paused_player_animation and player.animation and player.animation.is_valid():player.animation.play()
		if paused_replay and replay_tween and replay_tween.is_valid():replay_tween.play()
		paused_player_animation=false;paused_replay=false
func stop_replay()->void:
	if replay_tween and replay_tween.is_valid():replay_tween.kill()
func prepare_values(s:Dictionary)->Dictionary:
	if bank_id=="exam12":return preload("res://modules/review/core/exam12_math.gd").formatted(s)
	if course.id=="propulsion":return preload("res://modules/review/core/yacht_math.gd").formatted(s)
	if course.id=="hullform":
		var calculated:Dictionary=preload("res://modules/review/core/module11_math.gd").values(s);var display:Dictionary={}
		for key in calculated:
			if str(key).begins_with("m11_"):display[key]=calculated[key]
		return display
	if course.id!="stability":
		var values:Dictionary=preload("res://modules/review/core/teaching_math.gd").values(s.get("qid","Q01"),float(s.get("progress",0)))
		return {"loaded":str(int(s.get("loaded",0))),"used":str(int(s.get("loaded",0))),"xg":"%.2f"%float(values.get("xg",4)),"zg":"%.2f"%float(values.get("zg",1))}
	var m:=Hydro.values(s);var ex:=Hydro.curve_extrema(s);var out:Dictionary={}
	for key in ["arm","h","r","allowed","period","accel"]:out["st_"+key]="%.3f"%(0.0 if absf(m[key])<.0005 else m[key])
	out.st_ratio="%.3f"%(m.h/m.B)
	out.st_required="%.2f"%float(s.get("required",1));out.st_zero="%.2f"%ex.zero;out.st_peak="%.3f"%ex.peak.y
	return out
func prepared(b:Dictionary,_index:int)->void:
	animation_waiting=false;stop_replay();experiment=false;beat=b;ship.cancel();ship.focus=b.get("anchor","G")
	var group:int=b.group
	active_group=group
	local_indices.clear();var local_beats:Array=[]
	for i in player.beats.size():
		if player.beats[i].group==group:
			local_indices.append(i);local_beats.append(player.beats[i])
	progress.sync(local_beats,local_indices.find(player.current),language,course.groups)
	bubble.set_source(b,language);bubble.caption.set_content(b.words[language]);bubble.caption.visible_characters=0;player.set_display_text(bubble.caption.full_text);bubble.begin_beat(b.words)
	current_state=player.state.duplicate(true);state_changed(current_state)
	if initial_camera_pending:
		initial_camera_pending=false;ship.set_camera(b.get("camera","front"))
	store.data.beat=b.id;store.data.language=language;persist();labels()
	arrange()
func state_changed(s:Dictionary)->void:
	if beat.is_empty() or not is_visible_in_tree():return
	if player.current>=player.beats.size() or beat.id!=player.beats[player.current].id:return
	current_state=s.duplicate(true)
	if course.id=="stability":
		evaluation=preload("res://modules/review/core/stability_evaluation.gd").evaluate(current_state)
		ship.apply(current_state,language,evaluation)
	else:ship.apply(current_state,language)
	var old_chart_visible:bool=chart.visible
	var exam_hydro:bool=bank_id=="exam12" and current_state.get("concept","") in ["roll","stability"]
	chart.visible=(course.id=="stability" and not str(current_state.get("plot","")).is_empty()) or exam_hydro
	if chart.visible!=old_chart_visible:arrange.call_deferred()
	if chart.visible:
		var plot_state:Dictionary=preload("res://modules/review/view/exam12_stability.gd").hydro_state(current_state) if exam_hydro else current_state
		chart.update(plot_state,language,{} if exam_hydro else evaluation)
	var now:=Time.get_ticks_msec()
	if now-last_record_tick>80 or player.phase!="playing":refresh_records();last_record_tick=now
	refresh_controls()
	formula_toggle.visible=condition.visible or chart.visible or not records.last_record.is_empty()
func refresh_records()->void:
	if player.beats.is_empty() or player.current<0:return
	if records.current_id==beat.id and records.language==language:
		records.update_current(prepare_values(current_state));return
	while settled_records.size()<=player.current:
		var i:=settled_records.size()
		var b:Dictionary=player.beats[i].duplicate(true)
		b.record_values=prepare_values(player.after[i]);settled_records.append(b);history_computations+=1
	records.set_prefix(settled_records,player.current,prepare_values(current_state),language,beat.id)
func labels()->void:
	if phase_menu:
		phase_menu.clear()
		for g in course.groups:phase_menu.add_item(g.title[language])
		if active_group>=0:phase_menu.select(active_group)
	for i in stage_buttons.size():
		stage_buttons[i].text=course.groups[i].title[language];stage_buttons[i].add_theme_font_size_override("font_size",18);stage_buttons[i].modulate=Color("ffdc8d") if i==active_group else Color.WHITE
	if scroll_group!=active_group:
		scroll_group=active_group;follow_stage.call_deferred(active_group)
	reset_button.text=tr2("恢复本段","Сбро́с");replay_button.text=tr2("重新播放","Повтори́ть")
	notice.text=tr2("专题进度损坏，原文件已保留；本次不覆盖。","Файл прогре́сса повреждён; он сохране́н.") if store.blocked else ""
	var cond:Dictionary=beat.get("condition",{})
	if cond.is_empty() and is_roll():cond={"zh":"同初始摇幅、固定等效回转半径；自由小角度横摇","ru":"Одина́ковая нача́льная амплиту́да; эффекти́вный ра́диус ине́рции постоя́нен"}
	condition.visible=not cond.is_empty()
	if not cond.is_empty():condition.set_content(cond.get(language,""))
	arrange.call_deferred()
	if not beat.is_empty():
		var local_beats:Array=[]
		for i in local_indices:local_beats.append(player.beats[i])
		progress.sync(local_beats,local_indices.find(player.current),language,course.groups)
	refresh_controls()
func follow_stage(group:int)->void:
	await get_tree().process_frame
	if group<0 or group>=stage_buttons.size():return
	var button_:Button=stage_buttons[group]
	if button_.position.x<navigation_scroll.scroll_horizontal:navigation_scroll.scroll_horizontal=int(button_.position.x)
	elif button_.position.x+button_.size.x>navigation_scroll.scroll_horizontal+navigation_scroll.size.x:navigation_scroll.scroll_horizontal=int(button_.position.x+button_.size.x-navigation_scroll.size.x)
func arrange()->void:
	if not is_instance_valid(ship):return
	navigation_scroll.hide()
	var pane:float=clampf(size.x*.30,410,510)
	var has_evidence:bool=drawer_open and (condition.visible or chart.visible)
	var separate_hull_view:bool=(bank_id=="exam12" or course.id in ["hullform","propulsion","arrangement"] or str(current_state.get("qid","")).begins_with("R9")) and (drawer_open or has_evidence)
	# Navigation floats over the scene; it must not expose a blank footer.
	ship.position=Vector2.ZERO;ship.size=Vector2(size.x-(pane+48 if separate_hull_view else 0),size.y)
	bubble.position=ship.position;bubble.size=Vector2(ship.size.x-(pane+48 if (drawer_open or has_evidence) and not separate_hull_view else 0),ship.size.y);bubble.arrange()
	evidence.visible=has_evidence
	evidence.custom_minimum_size.x=pane
	evidence.position=Vector2(size.x-pane-24,112);evidence.size.x=pane
	evidence.reset_size()
	var evidence_height:float=evidence.get_combined_minimum_size().y if evidence.visible else 0.0
	evidence_background.visible=evidence.visible;evidence_background.position=evidence.position-Vector2(8,8);evidence_background.size=Vector2(pane+16,evidence_height+16)
	var history_top:float=112+evidence_height+(20 if evidence.visible else 0)
	right.visible=drawer_open;right.position=Vector2(size.x-pane-24,history_top);right.size=Vector2(pane,maxf(60,size.y-history_top-145))
	parameters.position=Vector2(size.x*.15,size.y-128);parameters.size=Vector2(size.x*.70,54)
	progress.position=Vector2(size.x*.12,size.y-60);progress.size=Vector2(size.x*.76,40)
	notice.position=Vector2(32,76)
	if phase_menu:phase_menu.position=Vector2(24,14);phase_menu.size=Vector2(size.x-250,94)
	if formula_toggle:
		formula_toggle.position=Vector2(size.x-210,24);formula_toggle.size=Vector2(180,48)
		formula_toggle.visible=condition.visible or chart.visible or not records.last_record.is_empty()
		formula_toggle.text=tr2("收起计算" if drawer_open else "公式与计算","Скрыть" if drawer_open else "Расчёт")
func refresh_controls()->void:
	if beat.is_empty() or sliders.is_empty():return
	updating=true
	var controls:Array=beat.get("controls",[])
	var stable:bool=player.phase in ["settled","complete"]
	parameters.visible=not controls.is_empty()
	for key in sliders:
		var slider:HSlider=sliders[key];slider.get_parent().visible=key in controls;slider.editable=stable
		if key=="heel":slider.min_value=-10 if active_group<=2 else 0;slider.max_value=10 if active_group<=2 else 150
		else:slider.min_value=6.0;slider.max_value=minf(10.3,float(evaluation.get("base",{}).get("km",10.5))-.2)
		slider.value=float(current_state.get(key,0))
		slider_labels[key].text=(tr2("倾角 θ","Крен θ")+"  %.1f°"%float(current_state.get(key,0))) if key=="heel" else (tr2("重心高度","Высота́ G")+"  %.2f m"%float(current_state.get(key,0)))
	reset_button.disabled=not stable;replay_button.visible=is_roll();replay_button.disabled=not stable
	chart.set_meta("interactive",stable and "heel" in controls);updating=false
func experiment_value(key:String,value:float)->void:
	if player.phase not in ["settled","complete"] or key not in beat.get("controls",[]):return
	stop_replay();experiment=true;var s:=current_state.duplicate(true);s[key]=value
	if is_roll():s.clock=0
	state_changed(s)
func reset_segment()->void:
	stop_replay();experiment=false;state_changed(player.after[player.current])
func replay_roll()->void:
	if not is_roll() or player.phase not in ["settled","complete"]:return
	stop_replay();var s:=current_state.duplicate(true);s.clock=0;state_changed(s)
	replay_tween=create_tween();replay_tween.tween_method(func(t:float):s.clock=t;state_changed(s),0.0,24.0,24.0)
func goto_group(index:int,manual:=false)->void:
	if manual:store.data.pending="";persist()
	stop_replay();player.jump(index)
func goto_index(index:int)->void:
	stop_replay();store.data.pending="";player.current=index;player.prepare()
func advance()->void:
	if animation_waiting:return
	stop_replay()
	if beat.id==course.foundation_end and player.phase in ["settled","complete"]:
		store.data.foundation_done=true
		var pending:String=store.data.pending;store.data.pending="";persist()
		if pending!="":
			for i in course.groups.size():
				if course.groups[i].id==pending:goto_group(i);return
	player.advance()
func retreat()->void:animation_waiting=false;ship.cancel();stop_replay();player.retreat()
func toggle_language()->void:
	language="ru" if language=="zh" else "zh";store.data.language=language;persist()
	bubble.set_source(beat,language);bubble.caption.set_content(beat.words[language]);bubble.caption.visible_characters=-1;player.set_display_text(bubble.caption.full_text,true);bubble.arrange();labels();state_changed(current_state);language_changed.emit(language)
func _process(_dt:float)->void:
	if not is_visible_in_tree() or not player.active:return
	if animation_waiting and not ship.camera_motion:animation_waiting=false;player.advance()
	bubble.set_target_point(ship.anchor(),true);player.presentation_ready=not bubble.pending
	if bubble.pending and not ship.camera_motion and bubble.ready_to_place():
		var obstacles:Array=ship.obstacles()
		if right.visible:obstacles.append(right.get_rect())
		if evidence.visible:obstacles.append(evidence.get_rect())
		obstacles.append(Rect2(0,0,size.x,112))
		obstacles.append(progress.get_rect().grow(12))
		if parameters.visible:obstacles.append(parameters.get_rect())
		bubble.place_near_target(obstacles)
