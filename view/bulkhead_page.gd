extends Control
signal exit_requested
signal progress_changed(id:String,language:String)
const M=preload("res://core/bulkhead_math.gd")
var player=preload("res://core/lesson_player.gd").new()
var course:Dictionary
var ship
var speech
var record
var scroll:ScrollContainer
var table:RichTextLabel
var phase_menu:ScrollContainer
var progress
var reset:Button
var lang:="zh"
var beat:Dictionary={}
var current_state:Dictionary={}
var phase_indices:Array=[]
var show_records:=false
var drawer_open:=false
var animation_waiting:=false
var formula_toggle:Button
func _ready()->void:
	course=JSON.parse_string(FileAccess.get_file_as_string("res://content/bulkheads.json"))
	add_child(player)
	ship=preload("res://view/bulkhead_ship.gd").new();add_child(ship)
	speech=preload("res://view/source_speech.gd").new();add_child(speech)
	speech.focus_requested.connect(func():
		if not is_visible_in_tree() or beat.is_empty():return
		ship.set_camera(beat.get("camera","overview"));speech.invalidate())
	scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;add_child(scroll)
	var column:=VBoxContainer.new();column.size_flags_horizontal=SIZE_EXPAND_FILL;scroll.add_child(column)
	table=RichTextLabel.new();table.fit_content=true;table.selection_enabled=true;table.add_theme_font_size_override("normal_font_size",19);column.add_child(table)
	record=preload("res://modules/review/view/calculation_record.gd").new();column.add_child(record);record.scroll=scroll
	phase_menu=preload("res://view/stage_progress.gd").new();add_child(phase_menu);phase_menu.item_selected.connect(func(i:int):player.jump(i))
	progress=preload("res://modules/review/view/lesson_progress.gd").new();add_child(progress)
	progress.step_requested.connect(func(i:int):jump_index(phase_indices[i]))
	reset=Button.new();add_child(reset);reset.pressed.connect(func():current_state=player.after[player.current].duplicate(true);refresh())
	player.prepared.connect(prepared);player.characters.connect(func(n:int):speech.caption.visible_characters=n)
	player.state_changed.connect(func(s:Dictionary):current_state=s.duplicate(true);if not beat.is_empty():refresh())
	player.phase_changed.connect(func(_p:String):if not beat.is_empty():refresh())
	ship.wall_moved.connect(func(n:float):current_state.bh_frame=n;refresh())
	formula_toggle=Button.new();formula_toggle.text="公式与计算";add_child(formula_toggle);formula_toggle.pressed.connect(func():drawer_open=not drawer_open;layout())
	resized.connect(layout);hide()
var initial_camera_pending:=false
func open(id:String,language:String)->void:
	initial_camera_pending=not ship.get_meta("camera_restored",false);ship.set_meta("camera_restored",false)
	lang=language;drawer_open=false;show();menus();layout();record.clear_records();beat={};player.open(course,id)
func suspend()->void:
	animation_waiting=false;player.close(false);ship.dragging=false
	if ship.camera_tween and ship.camera_tween.is_valid():ship.camera_tween.kill()
	hide()
func menus()->void:
	phase_menu.clear()
	for group in course.groups:phase_menu.add_item(group.title[lang])
	reset.text="恢复本段" if lang=="zh" else "Восстанови́ть"
func layout()->void:
	if not ship:return
	var spatial_width:float=size.x-clampf(size.x*.30,410,510)-40 if show_records and drawer_open else size.x
	ship.position=Vector2.ZERO;ship.size=Vector2(spatial_width,size.y-70)
	speech.position=ship.position;speech.size=ship.size;speech.arrange()
	var pane:float=clampf(size.x*.30,410,510)
	scroll.visible=show_records and drawer_open;scroll.position=Vector2(size.x-pane-24,90);scroll.size=Vector2(pane,size.y-170)
	phase_menu.position=Vector2(24,14);phase_menu.size=Vector2(size.x-250,94)
	reset.position=Vector2(size.x*.5-80,size.y-120);reset.size=Vector2(160,44)
	progress.position=Vector2(size.x*.12,size.y-60);progress.size=Vector2(size.x*.76,42)
	if formula_toggle:
		formula_toggle.visible=show_records;formula_toggle.position=Vector2(size.x-210,24);formula_toggle.size=Vector2(180,48)
		formula_toggle.text=("收起计算" if drawer_open else "公式与计算") if lang=="zh" else ("Скрыть" if drawer_open else "Расчёт")
func prepared(b:Dictionary,index:int)->void:
	animation_waiting=false;beat=b;current_state=player.before[index].duplicate(true);ship.dragging=false
	var has_records:=false
	for i in range(index+1):
		if not player.beats[i].get("lines",[]).is_empty():has_records=true;break
	show_records=has_records;layout()
	phase_menu.select(int(b.group));phase_indices.clear();var local:Array=[]
	for i in player.beats.size():
		if not player.beats[i].has("record_values"):player.beats[i]["record_values"]=M.values(player.after[i])
		if player.beats[i].group==b.group:phase_indices.append(i);local.append(player.beats[i])
	progress.sync(local,phase_indices.find(index),lang,course.groups)
	speech.set_source(b,lang);speech.begin_beat(b.words);speech.caption.set_content(b.words[lang]);player.set_display_text(b.words[lang]);speech.arrange()
	if initial_camera_pending:
		initial_camera_pending=false;ship.set_camera(b.get("camera","overview"))
	refresh();progress_changed.emit(b.id,lang)
func refresh()->void:
	if not player.active or beat.is_empty():return
	ship.apply(current_state,beat,lang)
	ship.interactive=beat.get("experiment",false) and player.phase in ["settled","complete"]
	reset.visible=ship.interactive
	record.set_prefix(player.beats,player.current,M.values(current_state),lang,beat.id)
	var count:int=beat.get("table_rows",0);table.visible=count>0
	if count>0:
		var text:="肋位 · 间隔数 × 肋距 · 舱长\n" if lang=="zh" else "Шпанго́уты · шпа́ции · длина́\n"
		var rows:=M.rows(float(current_state.get("bh_frame",60)))
		for i in count:
			var r:Dictionary=rows[i]
			text+="%s  %d–%d\n%s = %.2f m\ns=%.2f m; x=%.2f m\n"%[r.name[lang],r.start,r.end,r.expression,r.length,r.s,r.x]
		table.text=text
func _process(_dt:float)->void:
	if not visible or beat.is_empty():return
	player.presentation_ready=not (ship.camera_tween and ship.camera_tween.is_valid() and ship.camera_tween.is_running())
	if animation_waiting and player.presentation_ready:animation_waiting=false;player.advance()
	speech.set_target_point(ship.anchor());speech.arrange()
	if player.presentation_ready and speech.pending and speech.ready_to_place():
		var obstacles:Array=ship.obstacles()
		if scroll.visible:obstacles.append(scroll.get_rect())
		speech.place_near_target(obstacles)
func jump_index(i:int)->void:
	ship.dragging=false;player.current=i;player.prepare()
func handle_input(event:InputEvent)->void:
	if not visible:return
	if event is InputEventKey:
		var key:int=event.physical_keycode if event.physical_keycode else event.keycode
		if event.pressed and not event.echo:
			if key==KEY_ESCAPE:suspend();exit_requested.emit();get_viewport().set_input_as_handled();return
			if key==KEY_F2:
				lang="ru" if lang=="zh" else "zh";menus();phase_menu.select(beat.group)
				progress.sync(progress.steps,progress.current,lang,course.groups)
				speech.set_source(beat,lang);speech.caption.set_content(beat.words[lang]);player.set_display_text(beat.words[lang],true);speech.arrange();refresh();progress_changed.emit(beat.id,lang)
				get_viewport().set_input_as_handled();return
		if key in [KEY_Q,KEY_E]:
			ship.dragging=false
			if key==KEY_Q and event.pressed and animation_waiting:
				animation_waiting=false
				if ship.camera_tween and ship.camera_tween.is_valid():ship.camera_tween.kill()
			if not animation_waiting:player.handle_key(event)
			get_viewport().set_input_as_handled()
