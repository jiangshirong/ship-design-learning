extends Control
const Domain=preload("res://core/domain.gd")
const Player=preload("res://core/lesson_player.gd")
const Store=preload("res://core/safe_store.gd")
const Selectable=preload("res://view/selectable_text.gd")
const Lifecycle=preload("res://core/scene_lifecycle.gd")
var loading:=false
var load_epoch:=0
var loading_label:Label
var review
var review_banks:Dictionary={}
var bulkheads
var review_buttons:HBoxContainer
var domain=Domain.new()
var player=Player.new()
var store=Store.new()
var courses:Array=[]
var lang:="zh"
var mode:="home"
var course:Dictionary={}
var beat:Dictionary={}
var state:Dictionary={}
var values:Dictionary={}
var home_map
var stage:Control
var ship
var concept
var speech
var caption
var equations
var right:PanelContainer
var right_scroll:ScrollContainer
var title:Label
var subtitle:Label
var progress
var record_heading:Label
var held:Dictionary={}
var formula_tab_held:=false
var layout_tween:Tween
var split_ratio:=.66
var calculation_visible:=true
var drawer_open:=false
var formula_toggle:Button
var phase_menu:ScrollContainer
var local_indices:Array=[]
var qa_mode:=false
var observation_snapshot:Dictionary={}
var initial_camera_pending:=false
var animation_waiting:=false
func tr2(zh:String,ru:String)->String:return zh if lang=="zh" else ru
func pair(value:Variant)->String:
	if value is Dictionary:return str(value.get(lang,value.get("zh","")))
	return str(value)
func panel(color:String)->StyleBoxFlat:
	var p:=StyleBoxFlat.new();p.bg_color=Color(color);p.set_corner_radius_all(10);p.content_margin_left=22;p.content_margin_right=22;p.content_margin_top=18;p.content_margin_bottom=18;return p
func label(fs:int)->Label:
	var l:=Label.new();l.add_theme_font_size_override("font_size",fs);return l
func _ready()->void:
	qa_mode="--qa" in OS.get_cmdline_user_args()
	if qa_mode:
		get_window().set_flag(Window.FLAG_NO_FOCUS,true);get_window().position=Vector2i(-6000,-6000);store.path="user://qa-progress.json"
		if "--continuity" in OS.get_cmdline_user_args():store.path="user://qa-continuity.json"
		if "--b02" in OS.get_cmdline_user_args():store.path="user://qa-b02.json"
		if "--source-check" in OS.get_cmdline_user_args():store.path="user://qa-source-styles.json"
		if "--approximations" in OS.get_cmdline_user_args():store.path="user://qa-approximations.json"
		if "--approx-home" in OS.get_cmdline_user_args():store.path="user://qa-approximation-home.json"
	store.read_file();store.migrate();lang=store.data.language
	courses=JSON.parse_string(FileAccess.get_file_as_string("res://content/courses.json"))
	var theme_=Theme.new();var font:=SystemFont.new();font.font_names=PackedStringArray(["Arial","Microsoft YaHei"]);theme_.default_font=font;theme_.default_font_size=20
	theme_.set_color("font_color","Label",Color("dce7ee"))
	# The custom tooltip paints its own single panel; remove the native outer frame.
	theme_.set_stylebox("panel","TooltipPanel",StyleBoxEmpty.new())
	for role in ["normal","hover","pressed"]:theme_.set_stylebox(role,"Button",panel("1c3547" if role=="normal" else "2a4c60"))
	theme=preload("res://view/focus_theme.gd").make();add_child(player)
	title=label(27);title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;add_child(title)
	subtitle=label(15);subtitle.modulate=Color("92afbe");subtitle.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;add_child(subtitle)
	home_map=preload("res://view/knowledge_map.gd").new();add_child(home_map);home_map.chapter_requested.connect(open_course)
	preload("res://modules/review/core/migration.gd").run(qa_mode)
	review=preload("res://modules/review/module.gd").new();add_child(review);review.exit_requested.connect(show_home);review_banks["legacy"]=review
	review_buttons=HBoxContainer.new();review_buttons.add_theme_constant_override("separation",12);add_child(review_buttons)
	for entry in [["课程题目","reading"],["考前题目","exam12"],["考试真题","exams"]]:
		var b:=Button.new();b.text=entry[0];b.custom_minimum_size=Vector2(150,48);review_buttons.add_child(b);b.pressed.connect(open_review.bind(entry[1]))
	resized.connect(layout);build_home();show_home();layout()
	if qa_mode:call_deferred("run_qa")
func ensure_lesson_ui()->void:
	if stage:
		ensure_ship();return
	stage=Control.new();add_child(stage)
	ship=preload("res://view/ship_view.gd").new();stage.add_child(ship)
	concept=preload("res://view/concept.gd").new();stage.add_child(concept);concept.hide()
	speech=preload("res://view/speech_bubble.gd").new();stage.add_child(speech);caption=speech.caption
	speech.focus_requested.connect(func():
		if mode!="lesson" or beat.is_empty() or concept.visible:return
		ship.teach_view(beat.get("camera","overview"));speech.invalidate())
	right=PanelContainer.new();right.add_theme_stylebox_override("panel",panel("152d3d"));stage.add_child(right)
	right_scroll=ScrollContainer.new();right_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;right.add_child(right_scroll)
	var content:=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",14);right_scroll.add_child(content)
	record_heading=label(20);record_heading.modulate=Color("edf5fb");content.add_child(record_heading)
	equations=preload("res://view/calculation_record.gd").new();content.add_child(equations);equations.scroll=right_scroll
	progress=preload("res://view/lesson_progress.gd").new();add_child(progress);progress.step_requested.connect(func(i:int):if i<local_indices.size():jump_to_step(local_indices[i]))
	player.prepared.connect(on_prepared);player.characters.connect(func(n:int):caption.visible_characters=n);player.state_changed.connect(on_state);player.phase_changed.connect(on_phase)
	formula_toggle=Button.new();formula_toggle.text="公式与计算";stage.add_child(formula_toggle)
	formula_toggle.pressed.connect(func():drawer_open=not drawer_open;layout();speech.begin_beat(beat.get("words",{})))
	phase_menu=preload("res://view/stage_progress.gd").new();stage.add_child(phase_menu);phase_menu.item_selected.connect(func(i:int):player.jump(i))
	layout()
func ensure_ship()->void:
	if is_instance_valid(ship):return
	ship=preload("res://view/ship_view.gd").new();stage.add_child(ship);stage.move_child(ship,0)
	Lifecycle.restore_camera("homework",ship)
func own_ship()->void:
	Lifecycle.use("homework",ship,func():
		var old=ship;ship=null;old.get_parent().remove_child(old);old.queue_free())
func begin_loading()->int:
	load_epoch+=1;loading=true;set_meta("loading",true)
	if not loading_label:
		loading_label=Label.new();loading_label.text="正在打开…";loading_label.add_theme_font_size_override("font_size",22);add_child(loading_label)
	loading_label.position=Vector2(28,68);loading_label.show();move_child(loading_label,get_child_count()-1)
	return load_epoch
func end_loading(token:int)->bool:
	if token!=load_epoch:return false
	loading=false;set_meta("loading",false);loading_label.hide();return true
func build_home()->void:
	home_map.set_language(lang)
func layout()->void:
	if bulkheads:bulkheads.size=size
	title.position=Vector2(28,23);title.size=Vector2(size.x-235,38)
	subtitle.position=Vector2(30,75);subtitle.size=Vector2(size.x-60,25)
	home_map.position=Vector2(20,92);home_map.size=Vector2(size.x-40,size.y-110)
	if review_buttons:review_buttons.position=Vector2(size.x-506,20);review_buttons.size=Vector2(474,48)
	if review:review.position=Vector2.ZERO;review.size=size
	if not stage or not is_instance_valid(ship):return
	stage.position=Vector2.ZERO;stage.size=size
	progress.position=Vector2(size.x*.12,size.y-64);progress.size=Vector2(size.x*.76,44)
	var speech_width:float=size.x-(clampf(size.x*.30,410,510)+48 if calculation_visible and drawer_open else 0)
	ship.position=Vector2.ZERO;ship.size=Vector2(speech_width,size.y-70)
	speech.position=Vector2.ZERO;speech.size=Vector2(speech_width,ship.size.y);speech.arrange()
	layout_concept()
	var pane:float=clampf(size.x*.30,410,510)
	right.position=Vector2(size.x-pane-24,90);right.size=Vector2(pane,size.y-170);right.visible=calculation_visible and drawer_open
	if formula_toggle:
		formula_toggle.position=Vector2(size.x-210,24);formula_toggle.size=Vector2(180,48);formula_toggle.visible=calculation_visible
		formula_toggle.text=tr2("收起计算" if drawer_open else "公式与计算","Скрыть" if drawer_open else "Расчёт")
	if phase_menu:phase_menu.position=Vector2(24,14);phase_menu.size=Vector2(size.x-250,94)
func layout_concept()->void:
	# Inline annotations overlay the diagram; never reserve a footer for them.
	concept.position=Vector2(0,112)
	concept.size=Vector2(ship.size.x,maxf(220,ship.size.y-112))
func set_split(target:float)->void:
	if layout_tween and layout_tween.is_valid():layout_tween.kill()
	if is_equal_approx(split_ratio,target):
		split_ratio=target;layout();return
	layout_tween=create_tween();layout_tween.tween_method(func(v:float):split_ratio=v;layout(),split_ratio,target,.3)
func show_home()->void:
	player.close(false);player.process_mode=Node.PROCESS_MODE_DISABLED
	if layout_tween and layout_tween.is_valid():layout_tween.kill()
	if is_instance_valid(ship):Lifecycle.set_active(ship,false)
	if bulkheads:bulkheads.suspend()
	if review:review.suspend()
	if review_buttons:review_buttons.show()
	Lifecycle.suspend_all()
	mode="home";home_map.show()
	if stage:Lifecycle.set_active(stage,false);progress.hide()
	refresh_chrome();build_home()
func refresh_chrome()->void:
	title.text=tr2("船舶原理学习","Проекти́рование судо́в") if mode=="home" else pair(course.title)
	title.visible=mode=="home"
	subtitle.hide();subtitle.text=""
	if store.blocked:subtitle.show();subtitle.text=tr2("存档损坏，已保留原文件。","Файл прогре́сса повреждён и сохранён.")
func open_course(id:String,start_id:String="")->void:
	if loading:return
	if review:review.suspend()
	if id=="bulkheads":await open_bulkheads(start_id);return
	if review_buttons:review_buttons.hide()
	var found:=false
	for item in courses:
		if item.id==id:course=item.duplicate(true);found=true;break
	if not found:return
	var model_index:int=2 if course.initial.get("load_vessel",false) else (1 if course.initial.get("scene","")=="tanker" else 0)
	var token:=begin_loading()
	var model_path:String=["res://assets/cargo_ship.glb","res://assets/tanker_learning.glb","res://assets/load_fuel_ship.glb"][model_index]
	var paths:Array=[model_path,"res://assets/steel_cargo.glb","res://assets/ocean/calm_ocean.glb"]
	if course.id=="foundation":paths.append_array(["res://assets/freight_first.glb","res://assets/freight_second.glb"])
	var resources:Array=await preload("res://core/asset_loader.gd").warm(self,paths)
	if token!=load_epoch:return
	ensure_lesson_ui();stage.hide();progress.hide()
	await get_tree().process_frame
	if token!=load_epoch:return
	ship.ensure_model(model_index)
	if course.id=="foundation":await ship.cargo_lesson.setup_async(ship)
	if not end_loading(token):return
	own_ship();resources.clear()
	drawer_open=false;animation_waiting=false;ship.cancel_camera();player.close(false)
	initial_camera_pending=not ship.get_meta("camera_restored",false);ship.set_meta("camera_restored",false)
	equations.clear_records();observation_snapshot=ship.snapshot();mode="lesson";home_map.hide();Lifecycle.set_active(stage,true);progress.show();refresh_chrome()
	player.process_mode=Node.PROCESS_MODE_INHERIT
	player.open(course,start_id if not start_id.is_empty() else store.data.targets.get(id,""));store.data.selected=id;save_progress()
func on_prepared(b:Dictionary,_index:int)->void:
	animation_waiting=false;beat=b
	phase_menu.clear()
	for g in course.groups:phase_menu.add_item(pair(g.title))
	phase_menu.select(int(b.group))
	sync_progress()
	for i in range(player.current):
		if not player.beats[i].has("record_values"):
			var snapshot:Dictionary=player.after[i].duplicate(true);snapshot.merge(player.beats[i].get("scene_params",{}),true)
			player.beats[i]["record_values"]=domain.display_values(domain.values(snapshot))
	home_map.mark_current(course.id,course.groups[int(beat.group)].id)
	caption.set_content(pair(beat.words));caption.visible_characters=0;player.set_display_text(caption.full_text)
	# Keep the pane absent until this chapter actually has a calculation.
	# Once introduced it stays put, including during explanatory beats.
	calculation_visible=false
	for i in range(player.current+1):
		if not player.beats[i].get("lines",[]).is_empty():calculation_visible=true;break
	speech.set_source(beat,lang);speech.begin_beat(beat.words)
	on_state(player.state)
	if initial_camera_pending:
		initial_camera_pending=false;ship.teach_view(beat.get("camera","overview"))
	set_split(.60)
	refresh_context();render_equations();store.data.targets[course.id]=beat.id;save_progress()
func refresh_context()->void:
	record_heading.text=tr2("公式与计算","Фо́рмулы и расчёт");speech.arrange()
func on_state(p:Dictionary)->void:
	if mode=="lesson" and player.active and not player.beats.is_empty() and str(beat.get("id",""))!=str(player.beats[player.current].id):return
	state=p.duplicate(true)
	if mode=="lesson":state.merge(beat.get("scene_params",{}),true)
	values=domain.values(state);values.merge(state,true)
	if not beat.get("opening",false):ship.set_state(state,values,lang)
	var visual:String=beat.get("visual","") if mode=="lesson" else ""
	concept.visible=not visual.is_empty();Lifecycle.set_active(ship,visual.is_empty())
	if concept.visible:
		concept.update_view(visual,beat,values,lang)
		layout_concept()
	if mode=="lesson" and not beat.is_empty():render_equations()
func _process(_delta:float)->void:
	if speech==null or mode!="lesson":return
	if animation_waiting and not ship.camera_motion:
		animation_waiting=false;player.advance()
	# Framing/layout finishes before typing. The paragraph is then locked for
	# this beat; only its leader follows the actual moving object.
	player.presentation_ready=not speech.pending
	if concept.visible:
		speech.set_target_point(concept.position+concept.annotation_anchor(),true)
	else:
		speech.set_target_point(ship.lesson_anchor(beat.get("anchor","ship")),true)
	if speech.pending and not ship.camera_motion and not (layout_tween and layout_tween.is_running()):
		if speech.ready_to_place():
			var obstacles:Array=(concept.annotation_obstacles() if concept.visible else ship.annotation_obstacles())
			if concept.visible:
				for i in obstacles.size():obstacles[i].position+=concept.position
			if right.visible:obstacles.append(right.get_rect())
			obstacles.append(Rect2(0,0,size.x,112))
			speech.place_near_target(obstacles)
			player.presentation_ready=true
func render_equations()->void:
	if player.beats.is_empty() or not player.active:return
	var upto:int=player.current
	if beat.get("defer_record",false) and player.state!=player.after[player.current]:upto-=1
	if upto>=0:equations.set_prefix(player.beats,upto,domain.display_values(values),lang,str(beat.id))
	else:equations.clear_records()
func on_phase(phase:String)->void:
	if equations==null or phase=="idle":return
	equations.visible=true;record_heading.visible=true
	if mode=="lesson" and not beat.is_empty():render_equations()
func advance()->void:
	if animation_waiting:return
	player.advance()
func toggle_language()->void:
	lang="ru" if lang=="zh" else "zh";store.data.language=lang;save_progress();refresh_chrome()
	if mode=="home":build_home()
	else:
		phase_menu.clear()
		for g in course.groups:phase_menu.add_item(pair(g.title))
		phase_menu.select(beat.group)
		sync_progress()
		speech.set_source(beat,lang);caption.set_content(pair(beat.words));player.set_display_text(caption.full_text,true);caption.visible_characters=-1;refresh_context();render_equations();on_state(state);on_phase(player.phase)
func jump_to_step(index:int)->void:
	if mode!="lesson" or not player.active or index<0 or index>=player.beats.size():return
	animation_waiting=false;ship.cancel_camera()
	if layout_tween and layout_tween.is_valid():layout_tween.kill()
	player.current=index;player.prepare()
func save_progress()->void:
	if not store.write_file() and not store.blocked:subtitle.show();subtitle.text=tr2("进度保存失败。","Не удало́сь сохрани́ть прогре́сс.")
func go_home()->void:
	if mode!="lesson":show_home();return
	drawer_open=false;animation_waiting=false;ship.cancel_camera();player.close(false);ship.restore(observation_snapshot);store.data.selected="";save_progress();show_home();build_home()
func _input(event:InputEvent)->void:
	if loading:
		if event is InputEventKey and event.pressed and (event.physical_keycode if event.physical_keycode else event.keycode)==KEY_ESCAPE:
			load_epoch+=1;loading=false;set_meta("loading",false);loading_label.hide();show_home()
		get_viewport().set_input_as_handled();return
	if event is InputEventKey and (event.physical_keycode if event.physical_keycode else event.keycode)==KEY_TAB:
		if not event.pressed:
			formula_tab_held=false
		elif not event.echo and not formula_tab_held and not (event.ctrl_pressed or event.alt_pressed or event.meta_pressed or event.shift_pressed):
			formula_tab_held=true
			var toggle:Button=null
			if mode=="lesson":toggle=formula_toggle
			elif mode=="bulkheads":toggle=bulkheads.formula_toggle
			elif mode=="review" and review.mode=="stability":toggle=review.stability.formula_toggle
			if toggle and toggle.is_visible_in_tree() and not toggle.disabled:toggle.pressed.emit()
		if mode in ["lesson","bulkheads"] or (mode=="review" and review.mode=="stability"):
			get_viewport().set_input_as_handled();return
	if mode=="bulkheads":bulkheads.handle_input(event);return
	if mode=="review":review.handle_input(event);return
	if not event is InputEventKey:return
	var key:int=event.physical_keycode if event.physical_keycode else event.keycode
	if not event.pressed:held.erase(key);return
	if event.echo or event.ctrl_pressed or event.alt_pressed or event.meta_pressed or event.shift_pressed or held.has(key):return
	if key not in [KEY_F2,KEY_ESCAPE,KEY_Q,KEY_E]:return
	held[key]=true
	if key==KEY_F2:toggle_language()
	elif key==KEY_ESCAPE:go_home()
	elif mode=="lesson":
		if key==KEY_E:advance()
		else:
			if animation_waiting:animation_waiting=false;ship.cancel_camera()
			player.retreat()
	get_viewport().set_input_as_handled()
func _notification(what:int)->void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:held.clear();formula_tab_held=false
	if what==NOTIFICATION_WM_CLOSE_REQUEST:player.close(false);save_progress();get_tree().quit()
func run_qa()->void:
	if "--exam-bank-routing" in OS.get_cmdline_user_args():
		await load("res://qa/exam_bank_routing.gd").new().run(self);return
	if "--subscript-zero" in OS.get_cmdline_user_args():
		await load("res://qa/subscript_zero_check.gd").new().run(self);return
	if "--alphabet" in OS.get_cmdline_user_args():
		await load("res://qa/alphabet_acceptance.gd").new().run(self);return
	if "--exam13" in OS.get_cmdline_user_args():
		await load("res://qa/exam13_acceptance.gd").new().run(self);return
	if "--exam12" in OS.get_cmdline_user_args():
		await load("res://qa/exam12_acceptance.gd").new().run(self);return
	if "--export-smoke" in OS.get_cmdline_user_args():
		var verifier=load("res://core/export_check.gd").new();add_child(verifier);verifier.start(self);return
	if "--desktop-mobile-ui" in OS.get_cmdline_user_args():
		var suite=load("res://qa/desktop_mobile_ui_check.gd").new();add_child(suite);suite.start(self);return
	if "--migration-only" in OS.get_cmdline_user_args():
		var suite=load("res://qa/migration_only_check.gd").new();add_child(suite);suite.start(self);return
	if "--chapter-repair" in OS.get_cmdline_user_args():
		var suite=load("res://qa/repair_check.gd").new();add_child(suite);suite.start(self);return
	if "--reading-words" in OS.get_cmdline_user_args():
		var suite=load("res://qa/reading_words_check.gd").new();add_child(suite);suite.start(self);return
	if "--word-picker" in OS.get_cmdline_user_args():
		var suite=load("res://qa/word_picker_check.gd").new();add_child(suite);suite.start(self);return
	if "--yacht" in OS.get_cmdline_user_args():
		var suite=load("res://qa/yacht_check.gd").new();add_child(suite);suite.start(self);return
	if "--q03-correction" in OS.get_cmdline_user_args():
		var suite=load("res://qa/q03_correction.gd").new();add_child(suite);suite.start(self);return
	if "--revision9p" in OS.get_cmdline_user_args():
		var suite=load("res://qa/revision9p_check.gd").new();add_child(suite);suite.start(self);return
	if "--sea-layout" in OS.get_cmdline_user_args():
		var suite=load("res://qa/sea_layout_check.gd").new();add_child(suite);suite.start(self);return
	if "--ocean-depth" in OS.get_cmdline_user_args():
		var suite=load("res://qa/ocean_depth_check.gd").new();add_child(suite);suite.start(self);return
	if "--module11" in OS.get_cmdline_user_args():
		var suite=load("res://modules/review/qa/module11_check.gd").new();add_child(suite);suite.start(self);return
	if "--approx-home" in OS.get_cmdline_user_args():
		var suite=load("res://qa/approximation_home_check.gd").new();add_child(suite);suite.start(self);return
	if "--approximations" in OS.get_cmdline_user_args():
		var suite=load("res://qa/approximations_check.gd").new();add_child(suite);suite.start(self);return
	if "--curriculum-repairs" in OS.get_cmdline_user_args():
		var suite=load("res://qa/curriculum_repairs_check.gd").new();add_child(suite);suite.start(self);return
	if "--spotlight" in OS.get_cmdline_user_args():
		var suite=load("res://qa/spotlight_check.gd").new();add_child(suite);suite.start(self);return
	if "--reading-sidebar" in OS.get_cmdline_user_args():
		var suite=load("res://qa/reading_sidebar.gd").new();add_child(suite);suite.start(self);return
	if "--lookup-review" in OS.get_cmdline_user_args():
		var suite=load("res://qa/lookup_review.gd").new();add_child(suite);suite.start(self);return
	if "--optimization" in OS.get_cmdline_user_args():
		var suite=load("res://qa/optimization_check.gd").new();add_child(suite);suite.start(self);return
	if "--perf" in OS.get_cmdline_user_args() or "--perf-stress" in OS.get_cmdline_user_args():
		var suite=load("res://qa/performance_check.gd").new();add_child(suite);suite.start(self);return
	if "--notation-bubble" in OS.get_cmdline_user_args():
		var suite=load("res://qa/notation_bubble.gd").new();add_child(suite);suite.start(self);return
	if "--bubble-focus" in OS.get_cmdline_user_args():
		var suite=load("res://qa/bubble_focus.gd").new();add_child(suite);suite.start(self);return
	if "--formula-tab" in OS.get_cmdline_user_args():
		var suite=load("res://qa/formula_tab.gd").new();add_child(suite);suite.start(self);return
	if "--ocean-check" in OS.get_cmdline_user_args():
		var suite=load("res://qa/ocean_check.gd").new();add_child(suite);suite.start(self);return
	if "--camera-free" in OS.get_cmdline_user_args():
		var suite=load("res://qa/camera_free_check.gd").new();add_child(suite);suite.start(self);return
	if "--camera-q22" in OS.get_cmdline_user_args():
		var suite=load("res://qa/camera_q22.gd").new();add_child(suite);suite.start(self);return
	if "--stage-track" in OS.get_cmdline_user_args():
		var suite=load("res://qa/stage_track.gd").new();add_child(suite);suite.start(self);return
	if "--font-fix" in OS.get_cmdline_user_args():
		var suite=load("res://qa/font_fix.gd").new();add_child(suite);suite.start(self);return
	if "--focus-ui" in OS.get_cmdline_user_args():
		var suite=load("res://qa/focus_ui.gd").new();add_child(suite);suite.start(self);return
	if "--inspection-all" in OS.get_cmdline_user_args():
		var suite=load("res://modules/review/qa/inspection_all_check.gd").new();add_child(suite);suite.start(self);return
	if "--damage-cutaway" in OS.get_cmdline_user_args():
		var suite=load("res://modules/review/qa/damage_cutaway_check.gd").new();add_child(suite);suite.start(self);return
	if "--home-font" in OS.get_cmdline_user_args():
		var suite=load("res://qa/home_font_check.gd").new();add_child(suite);suite.start(self);return
	if "--freeboard-morph" in OS.get_cmdline_user_args():
		var suite=load("res://modules/review/qa/freeboard_morph_check.gd").new();add_child(suite);suite.start(self);return
	if "--topic-hover" in OS.get_cmdline_user_args():
		var suite=load("res://modules/review/qa/topic_hover_check.gd").new();add_child(suite);suite.start(self);return
	if "--freeboard-side" in OS.get_cmdline_user_args():
		var suite=load("res://modules/review/qa/freeboard_side_check.gd").new();add_child(suite);suite.start(self);return
	if "--topics" in OS.get_cmdline_user_args():
		var suite=load("res://modules/review/qa/topics_check.gd").new();add_child(suite);suite.start(self);return
	if "--q12-check" in OS.get_cmdline_user_args():
		var suite=load("res://qa/q12_check.gd").new();add_child(suite);suite.start(self);return
	if "--q19-check" in OS.get_cmdline_user_args():
		var suite=load("res://qa/q19_check.gd").new();add_child(suite);suite.start(self);return
	if "--source-check" in OS.get_cmdline_user_args():
		var suite=load("res://qa/source_check.gd").new();add_child(suite);suite.start(self);return
	if "--bulkheads" in OS.get_cmdline_user_args():
		var suite=load("res://qa/bulkheads_check.gd").new();add_child(suite);suite.start(self);return
	if "--scientific-review" in OS.get_cmdline_user_args():
		var suite=load("res://qa/scientific_review.gd").new();add_child(suite);suite.start(self);return
	if "--vocabulary-levels" in OS.get_cmdline_user_args():
		var suite=load("res://qa/vocabulary_levels.gd").new();add_child(suite);suite.start(self);return
	if "--notation-check" in OS.get_cmdline_user_args():
		mode="review";review.activate();var suite=load("res://modules/review/qa/notation_check.gd").new();add_child(suite);suite.start(review);return
	if "--merge-check" in OS.get_cmdline_user_args():
		var suite=load("res://qa/merge_check.gd").new();add_child(suite);suite.start(self);return
	if "--stability-check" in OS.get_cmdline_user_args():
		open_review("reading");var suite=load("res://modules/review/qa/stability_check.gd").new();add_child(suite);suite.start(review);return
	var test_path:String="res://qa/continuity_check.gd" if "--continuity" in OS.get_cmdline_user_args() else "res://qa/formal_check.gd"
	if "--progress" in OS.get_cmdline_user_args():test_path="res://qa/progress_check.gd"
	if "--fuel" in OS.get_cmdline_user_args():test_path="res://qa/fuel_check.gd"
	if "--teaching" in OS.get_cmdline_user_args():test_path="res://qa/teaching_check.gd"
	if "--pair" in OS.get_cmdline_user_args():test_path="res://qa/pair_check.gd"
	var tester=load(test_path).new();add_child(tester);tester.start(self)

func open_review(which:String)->void:
	var bank_key:=which if which in ["exam12","exams"] else "legacy"
	if review:review.suspend()
	if not review_banks.has(bank_key):
		var module=preload("res://modules/review/module.gd").new();module.bank_id=bank_key;add_child(module);module.exit_requested.connect(show_home);review_banks[bank_key]=module
	review=review_banks[bank_key]
	animation_waiting=false;player.close(false);held.clear()
	player.process_mode=Node.PROCESS_MODE_DISABLED
	if is_instance_valid(ship):ship.cancel_camera()
	if layout_tween and layout_tween.is_valid():layout_tween.kill()
	Lifecycle.suspend_all()
	mode="review";home_map.hide();review_buttons.hide();title.hide();subtitle.hide()
	if stage:Lifecycle.set_active(stage,false);progress.hide()
	if which in ["reading","exam12","exams"]:review.open_reading()
	else:review.open_vocabulary(which=="scientific")
	layout()

func open_bulkheads(start_id:String="")->void:
	player.close(false);review.suspend()
	player.process_mode=Node.PROCESS_MODE_DISABLED
	if is_instance_valid(ship):ship.cancel_camera()
	if not bulkheads:
		var token:=begin_loading()
		var resources:Array=await preload("res://core/asset_loader.gd").warm(self,["res://assets/bulkhead_t2.glb"])
		if not end_loading(token):return
		bulkheads=preload("res://view/bulkhead_page.gd").new();add_child(bulkheads)
		resources.clear()
		Lifecycle.restore_camera("bulkheads",bulkheads)
		bulkheads.exit_requested.connect(show_home)
		bulkheads.progress_changed.connect(func(id:String,language:String):
			store.data.targets["bulkheads"]=id;lang=language;store.data.language=language;save_progress())
	mode="bulkheads";home_map.hide();review_buttons.hide();title.hide();subtitle.hide()
	if stage:Lifecycle.set_active(stage,false);progress.hide()
	Lifecycle.use("bulkheads",bulkheads,func():var old=bulkheads;bulkheads=null;old.get_parent().remove_child(old);old.queue_free())
	bulkheads.size=size;bulkheads.open(start_id if not start_id.is_empty() else store.data.targets.get("bulkheads",""),lang)

func sync_progress()->void:
	local_indices.clear();var local:Array=[]
	for i in player.beats.size():
		if player.beats[i].group==beat.group:local_indices.append(i);local.append(player.beats[i])
	progress.sync(local,local_indices.find(player.current),lang,course.groups)

func _exit_tree()->void:
	Lifecycle.entries.clear();Lifecycle.order.clear();Lifecycle.cameras.clear()
