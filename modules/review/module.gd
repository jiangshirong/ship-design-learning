extends Control
signal exit_requested
const Lifecycle=preload("res://core/scene_lifecycle.gd")
var store=preload("res://modules/review/core/safe_store.gd").new()
var language:="zh"
var mode:="inactive"
var qa:=false
var bank_id:="legacy"
func content_path(file:String)->String:
	return "res://modules/review/content/"+(bank_id+"/" if bank_id in ["exam12","exams"] else "")+file
var held:Dictionary={}
var term_tooltip
var status_label:Label
var shell_background:ColorRect
var bottom_bar
var shell_motion:Tween
var font_scale:=1.0
var _reading
var _vocabulary
var _stability
var reading:
	get:
		if not _reading:
			ensure_tooltip()
			_reading=preload("res://modules/review/view/reading_review.gd").new();_reading.bank_id=bank_id;_reading.content_root=content_path("")
			if qa:_reading.store.path="user://review/qa-"+bank_id+"-reading-review.json"
			if qa and "--reading-launch-check" in OS.get_cmdline_user_args():_reading.store.path="user://review/qa-reading-fresh-"+str(OS.get_process_id())+".json"
			_reading.field_created.connect(term_tooltip.bind);add_child(_reading);_reading.hide()
			var picker=preload("res://modules/review/view/word_picker.gd").new();picker.field=_reading.question;picker.tip=term_tooltip;picker.controller=_reading.words
			_reading.add_child(picker);_reading.set_meta("word_picker",picker)
			_reading.changed.connect(picker.dismiss);_reading.navigated.connect(picker.dismiss)
			_reading.changed.connect(func():term_tooltip.hide_tip())
			_reading.animation_requested.connect(open_question_animation);_reading.topic_requested.connect(open_topic)
			layout()
		return _reading
var vocabulary:
	get:
		if not _vocabulary:
			_vocabulary=preload("res://modules/review/view/vocabulary.gd").new();_vocabulary.reading_path=content_path("reading.json");add_child(_vocabulary);_vocabulary.hide()
			_vocabulary.grade_changed.connect(func(_id,_level):
				if _reading:_reading.words.refresh_ink()
				if _vocabulary and not _vocabulary.scientific and _vocabulary.is_visible_in_tree():_vocabulary.rebuild();_vocabulary.refresh())
			_vocabulary.changed.connect(func():call_deferred("layout"));layout()
		return _vocabulary
var stability:
	get:
		if not _stability:
			ensure_tooltip();_stability=preload("res://modules/review/view/stability_course.gd").new();_stability.bank_id=bank_id;_stability.courses=JSON.parse_string(FileAccess.get_file_as_string(content_path("topics.json")))
			_stability.field_created.connect(term_tooltip.bind);add_child(_stability);_stability.hide()
			_stability.language_changed.connect(func(value:String):language=value;store.data.language=value;save())
			layout()
		return _stability
func style(color:String)->StyleBoxFlat:
	var box:=StyleBoxFlat.new();box.bg_color=Color(color);box.set_corner_radius_all(8)
	box.content_margin_left=16;box.content_margin_right=16;box.content_margin_top=10;box.content_margin_bottom=10;return box
func _ready()->void:
	qa="--qa" in OS.get_cmdline_user_args()
	if bank_id in ["exam12","exams"]:store.path="user://review/"+bank_id+"-progress.json"
	if qa:store.path="user://review/qa-"+bank_id+"-progress.json"
	DirAccess.make_dir_recursive_absolute("user://review");store.read_file();language=store.data.language
	theme=preload("res://view/focus_theme.gd").make()
	shell_background=ColorRect.new();shell_background.color=Color("f6f4ee");shell_background.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(shell_background)
	bottom_bar=preload("res://modules/review/mobile_ui/bottom_bar.gd").new();add_child(bottom_bar);bottom_bar.z_index=10
	bottom_bar.selected.connect(switch_tab)
	status_label=Label.new();status_label.add_theme_font_size_override("font_size",16);status_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(status_label)
	resized.connect(layout);suspend();layout()
func ensure_tooltip()->void:
	if term_tooltip:return
	term_tooltip=preload("res://modules/review/view/term_tooltip.gd").shared(self)
func labels()->void:
	if term_tooltip:term_tooltip.hide_tip()
	if mode in ["reading","vocabulary"]:status_label.add_theme_color_override("font_color",Color("a45c55"))
	status_label.text="存档损坏：保留原文件，本次不覆盖。" if store.blocked else ""
	layout()
func layout()->void:
	if status_label:status_label.position=Vector2(24,4);status_label.size=Vector2(size.x-48,25)
	if shell_background:shell_background.position=Vector2.ZERO;shell_background.size=size
	if bottom_bar:bottom_bar.position=Vector2(0,size.y-76);bottom_bar.size=Vector2(size.x,76)
	for page in [_reading,_vocabulary,_stability]:
		if page:page.position=Vector2.ZERO;page.size=Vector2(size.x,size.y-(76 if page!=_stability else 0))
	var reading_mode:bool=mode in ["reading","vocabulary"]
	if shell_background:shell_background.visible=reading_mode
	if bottom_bar:
		bottom_bar.visible=reading_mode
		if reading_mode:bottom_bar.select("题目" if mode=="reading" else ("科学复习" if vocabulary.scientific else "词汇"))
func save()->void:
	if not store.write_file() and not store.blocked:status_label.text="进度未能保存。"
func hide_pages()->void:
	if _reading and _reading.has_meta("word_picker"):_reading.get_meta("word_picker").dismiss()
	if _stability:_stability.close()
	for page in [_reading,_vocabulary]:
		if page:Lifecycle.set_active(page,false)
	if term_tooltip:term_tooltip.hide_tip()
func suspend()->void:
	hide_pages();held.clear();mode="inactive";hide();process_mode=Node.PROCESS_MODE_DISABLED
func activate()->void:
	process_mode=Node.PROCESS_MODE_INHERIT;show();held.clear()
	if _vocabulary:_vocabulary.load_marks()
func open_reading(restore:=false)->void:
	activate();hide_pages();Lifecycle.suspend_all();mode="reading"
	var page=reading
	if not restore:page.revealed=false;page.exercise="";page.refresh()
	Lifecycle.set_active(page,true);labels()
func open_vocabulary(scientific:=false)->void:
	activate();hide_pages();Lifecycle.suspend_all();mode="vocabulary"
	var page=vocabulary;page.scientific=scientific;page.open_menu();Lifecycle.set_active(page,true);labels()
func open_topic(id:String,question:="")->void:
	if not reading.topic_has_animation(id):return
	activate();hide_pages();mode="stability"
	var page=stability
	await page.open_topic(id,question,language,store.data.targets,store.data.selected)
	layout()
func open_question_animation(id:String)->void:
	for q in reading.entries:
		if q.id==id:
			if q.get("animation_available",true):await open_topic(q.topic,id)
			return
func open_lesson(_id:String="",lesson_id:String="Q14")->void:await open_question_animation(lesson_id)
func open_stability(question:="")->void:await open_topic("stability",question)
func switch_tab(tab:String)->void:
	if term_tooltip:term_tooltip.hide_tip()
	if _reading and _reading.has_meta("word_picker"):_reading.get_meta("word_picker").dismiss()
	if tab=="题目":open_reading(true)
	else:open_vocabulary(tab=="科学复习")
	var page=reading if tab=="题目" else vocabulary
	if shell_motion and shell_motion.is_valid():shell_motion.kill()
	page.modulate.a=.55;page.position.x=12
	shell_motion=create_tween().set_parallel(true);shell_motion.tween_property(page,"modulate:a",1.0,.18);shell_motion.tween_property(page,"position:x",0.0,.18)
func adjust_font(direction:int)->void:
	font_scale=clampf(font_scale+direction*.1,.8,1.6)
	reading.store.data["desktop_ui"]={"font_scale":font_scale};reading.save()
	if _reading:_reading.arrange();_reading.words.schedule()
	if _vocabulary:_vocabulary.arrange();_vocabulary.refresh()
func open_dictionary_entry(entry:Dictionary)->void:
	var picker=reading.get_meta("word_picker");picker.open_entries(entry.ru,[entry.id])
func toggle_language()->void:
	if mode=="stability":stability.toggle_language()
func go_home()->void:
	if _reading and _reading.has_meta("word_picker") and _reading.get_meta("word_picker").is_open():_reading.get_meta("word_picker").dismiss();return
	if term_tooltip:term_tooltip.hide_tip()
	if mode=="stability":open_reading(true)
	else:suspend();exit_requested.emit()
func handle_input(event:InputEvent)->void:
	if not is_visible_in_tree() or not event is InputEventKey:return
	var code:int=event.physical_keycode if event.physical_keycode else event.keycode
	if not event.pressed:held.erase(code);return
	if event.echo or event.ctrl_pressed or event.alt_pressed or event.shift_pressed or event.meta_pressed or held.has(code):return
	if mode=="reading" and code in [KEY_W,KEY_S,KEY_A,KEY_D,KEY_R,KEY_T]:
		held[code]=true
		if code==KEY_R:reading.words.mark_unknown()
		elif code==KEY_T:reading.words.mark_known()
		else:reading.words.navigate(code)
		get_viewport().set_input_as_handled();return
	var grade_keys:Array=[KEY_1,KEY_2,KEY_3,KEY_4,KEY_KP_1,KEY_KP_2,KEY_KP_3,KEY_KP_4]
	if code in grade_keys:
		if mode!="vocabulary" or vocabulary.category.is_empty() or not vocabulary.card.is_visible_in_tree():return
		held[code]=true
		vocabulary.mark(vocabulary.LEVELS[grade_keys.find(code)%4])
		get_viewport().set_input_as_handled();return
	if mode=="stability" and code in [KEY_A,KEY_D]:
		held[code]=true
		if code==KEY_D:stability.advance()
		else:stability.retreat()
		get_viewport().set_input_as_handled();return
	if code not in [KEY_Q,KEY_E,KEY_ESCAPE,KEY_F2,KEY_SPACE,KEY_V,KEY_F]:return
	held[code]=true
	match code:
		KEY_V:
			if mode=="reading" and reading.index>=0 and not reading.animation_button.disabled:reading.animation_button.pressed.emit()
		KEY_ESCAPE:go_home()
		KEY_F2:toggle_language()
		KEY_F:
			if mode=="reading":reading.reveal()
		KEY_SPACE:
			if mode=="reading":reading.words.show_meaning()
			elif mode=="vocabulary":vocabulary.reveal()
		KEY_E:
			if mode=="reading":reading.move(1)
			elif mode=="vocabulary":vocabulary.move(1)
			elif mode=="stability":stability.advance()
			
		KEY_Q:
			if mode=="reading":reading.move(-1)
			elif mode=="vocabulary":vocabulary.move(-1)
			elif mode=="stability":stability.retreat()
			
	get_viewport().set_input_as_handled()
func _notification(what:int)->void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:held.clear()
