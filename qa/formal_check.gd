extends Node
var app
var results:Array=[]
func check(ok:bool,name_:String)->void:
	results.append({"passed":ok,"name":name_})
	if not ok:push_warning(name_)
func frames(n:int=4)->void:
	for i in range(n):await get_tree().process_frame
	var main=get_tree().current_scene
	while is_instance_valid(main) and main.get_meta("loading",false):await get_tree().process_frame
func settle()->void:
	app.drawer_open=true;app.layout()
	if app.ship.camera_tween and app.ship.camera_tween.is_valid():app.ship.camera_tween.custom_step(1.0)
	if app.layout_tween:app.layout_tween.custom_step(1.0)
	await frames(7)
	app.player.complete_busy()
	if app.player.phase=="ready":app.player.finish()
	await frames(10)
func start(target)->void:
	if "--minimum" in OS.get_cmdline_user_args():get_window().size=Vector2i(1100,760)
	app=target
	await frames(3)
	if "--tanker" in OS.get_cmdline_user_args():
		await tanker_checks()
		var output:=FileAccess.open("res://qa/tanker-"+("minimum" if "--minimum" in OS.get_cmdline_user_args() else "normal")+".json",FileAccess.WRITE)
		output.store_string(JSON.stringify(results,"\t"));output.close()
		print("TANKER ",results.size()," checks")
		get_tree().quit(0 if results.all(func(r):return r.passed) else 1);return
	if "--trim" in OS.get_cmdline_user_args():
		await trim_checks()
		var output:=FileAccess.open("res://qa/trim-"+("minimum" if "--minimum" in OS.get_cmdline_user_args() else "normal")+".json",FileAccess.WRITE)
		output.store_string(JSON.stringify(results,"\t"));output.close()
		print("TRIM ",results.size()," checks")
		get_tree().quit(0 if results.all(func(r):return r.passed) else 1);return
	if "--baseline" in OS.get_cmdline_user_args():
		await baseline_checks()
		var output:=FileAccess.open("res://qa/baseline-"+("minimum" if "--minimum" in OS.get_cmdline_user_args() else "normal")+".json",FileAccess.WRITE)
		output.store_string(JSON.stringify(results,"\t"));output.close()
		print("BASELINE ",results.size()," checks")
		get_tree().quit(0 if results.all(func(r):return r.passed) else 1);return
	if "--b02" in OS.get_cmdline_user_args():
		await cargo_checks()
		var output:=FileAccess.open("res://qa/b02-"+("minimum" if "--minimum" in OS.get_cmdline_user_args() else "normal")+".json",FileAccess.WRITE)
		output.store_string(JSON.stringify(results,"\t"));output.close()
		print("B02 ",results.size()," checks")
		get_tree().quit(0 if results.all(func(r):return r.passed) else 1);return
	if "--launch-only" in OS.get_cmdline_user_args() or "--reopen" in OS.get_cmdline_user_args():
		check(app.mode=="lesson" and app.beat.id=="T16:pass","Restored new stable step at its start")
		check(app.lang=="ru" and app.store.data.language=="ru","Language restored")
		var path:String="res://qa/checks-launcher.json" if "--launch-only" in OS.get_cmdline_user_args() else "res://qa/formal-reopen.json"
		var report:=FileAccess.open(path,FileAccess.WRITE);report.store_string(JSON.stringify(results));report.close()
		if "--launch-only" in OS.get_cmdline_user_args():
			var proc:=FileAccess.open("res://qa/launcher-process.json",FileAccess.WRITE);proc.store_string(JSON.stringify({"pid":OS.get_process_id()}));proc.close()
		get_tree().quit(0 if results.all(func(r):return r.passed) else 1);return
	app.lang="zh"
	await app.open_course("foundation","B01:meaning");await settle()
	check(app.beat.id=="B01:meaning","B01 stable identity")
	check(app.equations.entries.size()==6,"B01 cumulative six formula records")
	check(app.speech.caption.get_v_scroll_bar().max_value<=app.speech.caption.get_v_scroll_bar().page,"Bubble has no scrolling")
	check(app.values.b01_reveal==5,"B01 unified revealed state")
	var entry=app.equations.entries["B01:ratio"].math
	check(entry.min_render_scale==1,"No formula shrink")
	var id:String=entry.rows[0].full
	check(entry.texture_for(id) is DPITexture,"DPITexture SVG renderer")
	app.right_scroll.scroll_vertical=0;await frames(5)
	app.get_viewport().get_texture().get_image().save_png("res://qa/formal-b01-zh.png")
	app.toggle_language();await frames(7)
	check(app.beat.id=="B01:meaning","F2 preserves stage")
	check(app.right_scroll.scroll_vertical==0,"F2 preserves scroll")
	app.get_viewport().get_texture().get_image().save_png("res://qa/formal-b01-ru.png")
	await record_checks()
	await notation_checks()
	if "--full" in OS.get_cmdline_user_args():await full_checks()
	var report_prefix:String="formal-runtime-" if "--full" in OS.get_cmdline_user_args() else "tooltip-runtime-"
	var file:=FileAccess.open("res://qa/"+report_prefix+("minimum" if "--minimum" in OS.get_cmdline_user_args() else "normal")+".json",FileAccess.WRITE);file.store_string(JSON.stringify(results,"\t"));file.close()
	print("FORMAL SAMPLE ",results.size()," checks")
	get_tree().quit(0 if results.all(func(r):return r.passed) else 1)

func tanker_checks()->void:
	app.lang="zh";await app.open_course("dimensions","T14:adopt");await settle()
	var ship=app.ship
	check(ship.tanker_model.scene_file_path=="res://assets/tanker_learning.glb","New tanker asset actually instantiated")
	check(ship.tanker_model.visible and not ship.cargo_model.visible,"Т2 selects tanker only")
	check(ship.tanker_model.scale.distance_to(Vector3.ONE)<.00001,"Metre scale at adopted dimensions")
	check(absf(ship.water.position.y-10.88)<.0001,"Waterline matches adopted draft")
	check(ship.dims.distance_to(Vector3(189.64,26.60,14.89))<.0001,"T2 dimensions match original adoption")
	var zones:Dictionary={};var bounds:=AABB();var first:=true;var groups:=0
	for node in ship.model_meshes:
		if not ship.tanker_model.is_ancestor_of(node):continue
		groups+=1;zones[node.get_meta("zone")]=true
		if node.get_meta("zone")=="Hull":
			var b:AABB=node.transform*node.get_aabb()
			bounds=b if first else bounds.merge(b);first=false
	check(groups==34,"34 optimized mesh groups include cargo liquid and free surface")
	for zone in ["Hull","Decks","Bulkheads","DoubleBottom","Ballast","Piping","Manifold","Pumps","Vents","Machinery","Propulsion","Survival","Mooring","Railings"]:
		check(zones.has(zone),"Tanker component present: "+zone)
	check(absf(bounds.size.z-26.60)<.1,"Exported hull breadth is 26.60 metres")
	check(absf(bounds.position.y)<.1,"Exported baseline at zero")
	check(not zones.has("Cranes"),"No dry-cargo cranes in tanker")
	await capture("tanker-adopted-zh")
	var before:Vector3=ship.tanker_model.scale;tap(KEY_F2);await frames(10)
	check(app.beat.id=="T14:adopt" and ship.tanker_model.scale==before,"F2 preserves tanker and stage")
	await capture("tanker-adopted-ru")
	app.lang="zh";await app.open_course("mass","T07:check");await settle();await capture("tanker-mass")
	var params:Dictionary=app.state.duplicate(true);params.cutaway_amount=1.0;params.water=false
	ship.set_state(params,app.values,"zh");await frames(6)
	for node in ship.model_meshes:
		if ship.tanker_model.is_ancestor_of(node) and (node.get_meta("near_side") or node.get_meta("cutaway_hide")):
			check(not node.visible,"Cutaway removes "+str(node.name))
	await capture("tanker-cutaway")
	await app.open_course("dimensions","T14:adopt");await settle()
	check(ship.tanker_model.visible,"Reopen restores full tanker")
	for node in ship.model_meshes:
		if ship.tanker_model.is_ancestor_of(node):check(node.visible,"Full state restores "+str(node.name))
	tap(KEY_Q);await settle();tap(KEY_E);await settle()
	check(ship.tanker_model.visible,"Tanker survives forward and reverse")
	tap(KEY_ESCAPE);await frames(3);check(app.mode=="home","Exit returns to chapter tree")
	await app.open_course("foundation","B02:given");await settle()
	check(app.beat.id=="B02:given","Cargo regression checks actual first-port lesson")
	check(ship.cargo_model.visible and not ship.tanker_model.visible,"Other homework retains cargo vessel")
	check(ship.cargo_model.scale.distance_to(Vector3(150.0/78,17.0/7.5,25.0/12.6))<.0001,"Cargo vessel scale remains unchanged")
	check(app.get_window().get_flag(Window.FLAG_NO_FOCUS),"Automated check never takes focus")
	check(app.store.path=="user://qa-progress.json","Automated check uses independent save")
	app.lang="ru";await app.open_course("dimensions","T16:pass");app.store.data.language="ru";app.save_progress()

func tap(code:int)->void:
	for pressed in [true,false]:
		var event:=InputEventKey.new();event.physical_keycode=code;event.pressed=pressed;app.get_viewport().push_input(event,true)
func go_to(id:String)->void:
	for i in range(app.player.beats.size()):
		if app.player.beats[i].id==id:app.player.current=i;app.player.prepare();return
	check(false,"Missing "+id)
func capture(name_:String)->void:
	await frames(3)
	await RenderingServer.frame_post_draw
	app.get_viewport().get_texture().get_image().save_png("res://qa/"+name_+("-minimum" if "--minimum" in OS.get_cmdline_user_args() else "-normal")+".png")
func click_at(point:Vector2)->void:
	var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;app.get_viewport().push_input(motion,true)
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;app.get_viewport().push_input(event,true);await frames(1)
func find_tooltip(node:Node,expected:String)->bool:
	if node is Label and node.text==expected and node.is_visible_in_tree():return true
	for child in node.get_children():
		if find_tooltip(child,expected):return true
	return false
func has_tooltip_popup(node:Node)->bool:
	if node is PopupPanel and node.visible:return true
	for child in node.get_children():
		if has_tooltip_popup(child):return true
	return false
func trim_checks()->void:
	app.go_home();await frames(5)
	for language in ["zh","ru"]:
		app.lang=language;app.build_home();await frames(5)
		for label in app.home_map.captions.values():check(not label.text.contains("·"),language+" tree caption has no suffix")
		await capture("trim-home-"+language)
	app.lang="zh";await app.open_course("foundation","B03:goal");await settle()
	tap(KEY_E);await frames(15)
	check(app.beat.id=="B03:bow","Definition comes before sign convention")
	check(app.caption.full_text.contains("船头比船尾吃水深"),"Bow-down is explained in plain Chinese")
	check(app.state.trim_progress==0,"Definition starts before bow moves")
	tap(KEY_E);tap(KEY_E);await frames(2)
	check(app.player.phase=="playing","D plays bow-down animation")
	app.player.animation.custom_step(1.0);await frames(2)
	check(app.state.trim_progress>0 and app.state.trim_progress<1,"Bow sinks during definition")
	check(not app.equations.entries.has("B03:fore") or not app.equations.entries["B03:fore"].box.visible,"No future fore-draft answer")
	tap(KEY_E);await frames(8)
	for language in ["zh","ru"]:
		if app.lang!=language:tap(KEY_F2);await frames(8)
		check(app.beat.id=="B03:bow" and app.state.trim_progress==1,language+" language switch preserves bow-down state")
		check(app.speech.anchor.distance_to(app.concept.annotation_anchor())<1,language+" explanation points to bow")
		check(not app.speech.panel.get_rect().grow(4).has_point(app.speech.anchor),language+" sentence does not cover bow")
		check(not app.caption.get_v_scroll_bar().visible,language+" sentence fits without scrollbar")
		await capture("trim-definition-"+language)
	tap(KEY_E);await settle();check(app.beat.id=="B03:sign","Sign convention follows definition")
	tap(KEY_Q);await settle();check(app.beat.id=="B03:bow","A returns to definition")
	go_to("B03:mean");await settle()
	check(app.equations.entries.has("B03:fore") and app.equations.entries.has("B03:mean"),"Final calculations remain in record")
func baseline_checks()->void:
	app.lang="zh";await app.open_course("basics","baseline:plane");await settle()
	check(app.beat.anchor=="base_plane","Plane sentence has explicit plane anchor")
	var ship=app.ship
	var point:Vector3=ship.lesson_point(app.beat.anchor)
	check(is_zero_approx(point.y),"Anchor height is zero, not deck height")
	check(absf(point.z)>ship.dims.y*.5,"Anchor lies outside hull width and remains visible")
	var plane_local:Vector3=ship.base_plane.to_local(ship.body.to_global(point))
	check(absf(plane_local.x)<.5 and absf(plane_local.z)<.5 and is_zero_approx(plane_local.y),"Anchor lies in actual base plane mesh")
	check(ship.base_plane.visible and not ship.water.visible,"Only base reference plane shown during its explanation")
	check(not ship.labels[7].visible and not ship.labels[8].visible,"No competing deck or waterline label")
	check(ship.camera_mode=="base_plane","Dedicated view exposes bottom reference plane")
	for language in ["zh","ru"]:
		if app.lang!=language:tap(KEY_F2);await frames(8)
		var target:Vector2=ship.lesson_anchor("base_plane")
		check(app.speech.anchor.distance_to(target)<1,language+" speech leader reaches plane")
		check(target.distance_to(ship.lesson_anchor("deck"))>30,language+" plane endpoint distinct from deck")
		check(Rect2(Vector2(8,8),ship.size-Vector2(16,16)).has_point(target),language+" plane endpoint within viewport")
		check(not app.speech.panel.get_rect().grow(4).has_point(target),language+" bubble does not cover plane endpoint")
		check(app.caption.text==app.beat.words[language] and not app.caption.get_v_scroll_bar().visible,language+" concise sentence fits")
		await capture("baseline-plane-"+language)
	# Real D/A navigation restores the side-view baseline and this plane independently.
	tap(KEY_E);await settle()
	check(app.beat.id=="baseline:reference","D enters side-view baseline explanation")
	check(ship.current.baseline_mode and ship.water.visible,"Side view restores waterline")
	check(not ship.base_plane.visible,"Plane overlay does not leak into next step")
	check(is_zero_approx(ship.lesson_point(app.beat.anchor).y),"Side-view baseline also anchors at zero height")
	await capture("baseline-reference")
	tap(KEY_Q);await settle()
	check(app.beat.id=="baseline:plane" and ship.base_plane.visible,"A restores reference plane")
	check(app.speech.anchor.distance_to(ship.lesson_anchor("base_plane"))<1,"A restores correct leader")
	tap(KEY_ESCAPE);await frames(3)
	check(app.mode=="home" and not ship.is_visible_in_tree(),"Exit hides plane lesson")
func notation_checks()->void:
	check(ProjectSettings.get_setting("gui/timers/tooltip_delay_sec")==0.0,"No tooltip dwell delay")
	check(app.get_theme_stylebox("panel","TooltipPanel") is StyleBoxEmpty,"No native outer tooltip frame")
	for spec in [["foundation","B03:sign","н — нос"],["mass","T06:engine","сэу — судова́я"],["dimensions","T11:water","пр.вод — пре́сная"],["supplement","norman-derive:eta","н — Но́рмана"],["supplement","norman-apply:direct","сэз — судовы́е"]]:
		app.lang="zh";await app.open_course(spec[0],spec[1]);await settle()
		for language in ["zh","ru"]:
			if app.lang!=language:app.toggle_language();await frames(8)
			var math=app.equations.entries[spec[1]].math
			var found:=false
			for hint in math.hint_regions:
				if hint.text.begins_with(spec[2]):
					found=true
					check(math._get_tooltip(hint.rect.get_center())==hint.text,spec[1]+language+" exact subscript hover")
			check(found,spec[1]+language+" accented contextual expansion")
			check(math._get_tooltip(Vector2(-20,-20)).is_empty(),"No hover on blank space "+spec[1])
			check(not math.text.contains("P_e") and not math.latex_text.contains("P_e"),"Copy uses canonical notation "+spec[1])
		await capture("notation-"+str(spec[1]).replace(":","-"))
	# Exercise the real native tooltip with viewport-only input, never the OS cursor.
	app.lang="zh";await app.open_course("mass","T06:engine");await settle()
	var math=app.equations.entries["T06:engine"].math
	var hint:Dictionary=math.hint_regions[0]
	var motion:=InputEventMouseMotion.new();motion.position=math.global_position+hint.rect.get_center();motion.global_position=motion.position
	app.get_viewport().push_input(motion,true)
	await frames(2)
	check(find_tooltip(get_tree().root,hint.text),"Tooltip opens within two frames, without dwell")
	check(hint.text.contains("\n船舶动力装置"),"Tooltip displays Chinese translation below Russian")
	await capture("notation-hover")
	motion=InputEventMouseMotion.new();motion.position=Vector2(5,5);motion.global_position=motion.position;app.get_viewport().push_input(motion,true);await frames(4)
	check(not find_tooltip(get_tree().root,hint.text),"Native tooltip closes outside subscript")
	# Blank formula padding still belongs to the same Control as the subscript.
	var blank:=Vector2(math.size.x-5,5)
	check(math._get_tooltip(blank).is_empty(),"Blank formula padding has no definition")
	motion=InputEventMouseMotion.new();motion.position=math.global_position+blank;motion.global_position=motion.position
	app.get_viewport().push_input(motion,true);await frames(4)
	check(not has_tooltip_popup(get_tree().root),"No empty tooltip frame over formula padding")
	await capture("notation-blank")
	for empty in [""," \n\t"]:
		check(math._make_custom_tooltip(empty)==null,"Empty definition creates no formula panel")
		check(app.concept._make_custom_tooltip(empty)==null,"Empty definition creates no diagram panel")
	for pass_index in range(3):
		motion=InputEventMouseMotion.new();motion.position=math.global_position+hint.rect.get_center();motion.global_position=motion.position
		app.get_viewport().push_input(motion,true);await frames(2)
		check(find_tooltip(get_tree().root,hint.text),"Repeated subscript entry shows translation %d"%pass_index)
		motion=InputEventMouseMotion.new();motion.position=math.global_position+blank;motion.global_position=motion.position
		app.get_viewport().push_input(motion,true);await frames(2)
		check(not has_tooltip_popup(get_tree().root),"Subscript to blank leaves no frame %d"%pass_index)
func record_checks()->void:
	app.lang="zh";await app.open_course("foundation","B01:rectangle");await settle()
	check(app.equations.highlighted_id=="B01:rectangle","Current substitution has active style")
	var previous=app.equations.entries["B01:rectangle"]
	var previous_size:Vector2=previous.math.size
	tap(KEY_E);await frames(8)
	check(app.beat.id=="B01:ratio" and app.equations.highlighted_id=="","Pending formula does not highlight history")
	check(not previous.active and previous.math.modulate==Color.WHITE,"Old calculation returns to normal style")
	check(previous.math.size.is_equal_approx(previous_size),"Highlight removal does not reflow old formula")
	tap(KEY_E);tap(KEY_E);await frames(3)
	check(app.player.phase=="playing" and app.equations.highlighted_id=="","No highlight for unrevealed animated answer")
	tap(KEY_E);await frames(10)
	check(app.equations.highlighted_id=="B01:ratio","Newly revealed formula is highlighted")
	check(app.equations.entries["B01:ratio"].box.get_theme_stylebox("panel")!=previous.box.get_theme_stylebox("panel"),"Active background and border differ from history")
	await capture("formula-current")
	app.right_scroll.scroll_vertical=0;await frames(3);tap(KEY_F2);await frames(8)
	check(app.equations.highlighted_id=="B01:ratio" and app.right_scroll.scroll_vertical==0,"F2 preserves highlight and manual reading position")
	tap(KEY_Q);await settle()
	check(app.equations.highlighted_id=="B01:rectangle","A highlights the restored step")
	check(not app.equations.entries["B01:ratio"].box.visible and not app.equations.entries["B01:ratio"].active,"A hides and clears future highlight")
	await app.open_course("foundation","B03:mean");await settle()
	check(app.equations.highlighted_id=="B03:mean","Direct step navigation highlights only its formula")
func cargo_checks()->void:
	app.lang="zh";await app.open_course("foundation","B02:goal");await settle()
	var scene=app.ship.cargo_lesson
	var node_id:int=scene.first[0].get_instance_id()
	for id in ["goal","given","factor1","mass","volume1","volume2","factor2","bound","answer","check"]:
		go_to("B02:"+id);await settle()
		check(app.ship.visible and not app.concept.visible,"B02:"+id+" uses real ship and cargo")
		check(scene.first[0].is_visible_in_tree(),id+" first-port crates visible")
		check(scene.first[0].get_instance_id()==node_id,id+" reuses cargo nodes")
		check(app.speech.anchor.distance_to(scene.project(scene.active_point))<1,id+" speech points to current object")
		check(abs(scene.first_length/scene.LENGTH-app.values.b02_first_volume_m3/app.values.b02_capacity_volume_m3)<1e-7,id+" envelope uses volume ratio")
		check(abs(app.values.b02_used_m3+app.values.b02_free_m3-app.values.b02_capacity_volume_m3)<1e-6,id+" volume conserved")
		if id not in ["answer","check"]:check(app.values.b02_added_t==0,id+" no second cargo before loading")
		for language in ["zh","ru"]:
			if app.lang!=language:tap(KEY_F2)
			await frames(8)
			check(app.caption.text==app.beat.words[language],id+" "+language+" sentence")
			check(not app.caption.get_v_scroll_bar().visible and not app.caption.get_h_scroll_bar().visible,id+" "+language+" no scroll")
			check(Rect2(Vector2.ZERO,app.speech.size).encloses(app.speech.panel.get_rect()),id+" "+language+" bubble fits")
			check(not app.speech.panel.get_rect().grow(4).has_point(app.speech.anchor),id+" "+language+" target clear")
			check(not Rect2(scene.labels[2].position,scene.labels[2].get_minimum_size()).grow(4).intersects(Rect2(scene.labels[3].position,scene.labels[3].get_minimum_size())),id+" "+language+" cargo labels do not overlap")
			if id in ["given","volume2","check"]:await capture("b02-"+id+"-"+language)
		if app.lang!="zh":tap(KEY_F2)
	check(abs(app.values.b02_total_t-15950)<1e-6,"Final mass reaches 15950 t")
	check(abs(app.values.b02_free_m3-136)<1e-6,"136 m3 stays empty")
	# The real D path starts the loading animation; inspect its middle state.
	go_to("B02:answer");await frames(12);tap(KEY_E);tap(KEY_E)
	if app.ship.camera_tween and app.ship.camera_tween.is_valid():app.ship.camera_tween.custom_step(1)
	check(app.player.phase=="playing","E starts physical loading")
	app.player.animation.custom_step(1.1);await frames(2)
	check(app.values.b02_added_t>2000 and app.values.b02_added_t<3500,"Intermediate added mass")
	check(abs(app.values.b02_used_m3-(14454+app.values.b02_added_t*1.21))<1e-6,"Animated cargo volume equals mass times factor")
	check(abs(scene.second_length/scene.LENGTH-(app.values.b02_used_m3-14454)/20640)<1e-7,"Animated stowage geometry follows values")
	await capture("b02-loading-mid")
	var fraction:float=app.state.cargo_second_fraction;tap(KEY_F2)
	check(app.state.cargo_second_fraction==fraction,"F2 keeps loading state")
	tap(KEY_Q);tap(KEY_Q);await settle()
	check(app.beat.id=="B02:bound" and app.values.b02_added_t==0,"A restores unloaded second cargo")
	tap(KEY_ESCAPE);check(not app.ship.is_visible_in_tree(),"Exit hides cargo lesson")
func full_checks()->void:
	app.go_home();await frames(4)
	check(app.get_window().get_flag(Window.FLAG_NO_FOCUS),"QA window never takes focus")
	check(app.store.path=="user://qa-progress.json","Independent QA save")
	check(app.ship.viewport.msaa_3d==Viewport.MSAA_8X,"Ship viewport 8x MSAA")
	check(app.home_map.cards.size()==app.courses.size(),"All current chapters appear in tree")
	check(not app.home_map.cards.has("ost"),"OST has no entry")
	await capture("formal-home")
	for c in app.courses:
		app.go_home();await frames(3)
		await click_at(app.home_map.cards[c.id].get_global_rect().get_center());await frames(3)
		check((app.mode=="bulkheads" if c.id=="bulkheads" else app.mode=="lesson" and app.course.id==c.id),"Actual tree click "+c.id)
	for c in app.courses:
		if c.id=="bulkheads":continue # Separate bulkheads_check covers its own player and calculations.
		app.lang="zh";await app.open_course(c.id,c.groups[0].beats[0].id)
		for i in range(app.player.beats.size()):
			app.player.current=i;app.player.prepare();await settle()
			var id:String=app.beat.id
			if app.state.get("show_fuel",false):check(not app.ship.labels[11].visible,id+" fuel is not labelled as deck cargo")
			if app.equations.entries.has(id):
				var box:Control=app.equations.entries[id].box
				check(box.get_global_rect().intersects(app.right_scroll.get_global_rect()),id+" current calculation in view")
			for language in ["zh","ru"]:
				if app.lang!=language:app.toggle_language()
				await frames(6)
				check(app.beat.id==id,id+"/"+language+" identity")
				if app.equations.entries.has(id):check(app.equations.entries[id].box.get_global_rect().intersects(app.right_scroll.get_global_rect()),id+"/"+language+" current record after F2")
				check(app.caption.text==app.beat.words[language],id+"/"+language+" full sentence")
				check(not app.caption.get_v_scroll_bar().visible and not app.caption.get_h_scroll_bar().visible,id+"/"+language+" no bubble scroll")
				check(app.caption.size.y>=app.caption.get_total_visible_line_count()*app.caption.get_line_height(),id+"/"+language+" no clipped text")
				check(Rect2(Vector2.ZERO,app.speech.size).encloses(app.speech.panel.get_rect()),id+"/"+language+" enclosed bubble")
				check(not app.speech.panel.get_rect().grow(4).has_point(app.speech.anchor),id+"/"+language+" does not cover teaching target")
				for entry in app.equations.entries.values():
					if entry.box.visible:
						check(entry.math.min_render_scale==1,id+"/"+language+" unshrunk formula")
						var fits:=true
						for drawing in entry.math.drawings:fits=fits and drawing.rect.end.x<=entry.math.size.x+1
						check(fits,id+"/"+language+" formula fits highlighted record width")
				check(app.equations.highlighted_id==(id if app.equations.entries.has(id) else ""),id+"/"+language+" highlight follows step")
			if id in ["L06:x","L01:tank1:x","T07:check","T13:back","T15:report","baseline:plane","B01:meaning"]:await capture("formal-"+id.replace(":","-"))
			if app.lang!="zh":app.toggle_language()
		print("CHAPTER CHECKED ",c.id)
	# Actual input path, busy completion, held-key debounce and reverse reveal.
	await app.open_course("foundation","B01:width");await frames(8)
	tap(KEY_E);check(app.player.phase=="ready","E completes typing only")
	tap(KEY_E);check(app.player.phase=="playing","E starts current animation")
	var event:=InputEventKey.new();event.physical_keycode=KEY_E;event.pressed=true;event.echo=true
	app.get_viewport().push_input(event,true);check(app.player.phase=="playing","Held E echo does not skip")
	tap(KEY_Q);check(app.player.phase in ["settled","complete"],"Q finishes busy action")
	tap(KEY_Q);check(app.beat.id=="B01:area","Second Q returns to previous beat")
	await settle();check(not app.equations.entries["B01:width"].box.visible,"Back hides later record")
	go_to("B03:mean");await settle()
	app.right_scroll.scroll_vertical=0;await frames(3);app.on_state(app.player.state);await frames(3)
	check(app.right_scroll.scroll_vertical==0,"Numeric refresh never steals manual scroll")
	app.toggle_language();await frames(6);check(app.right_scroll.scroll_vertical==0,"Language preserves reading location")
	var old_count:int=app.equations.entries.size();go_to("B01:area");await settle();go_to("B03:mean");await settle()
	check(app.equations.entries.size()==old_count,"Replay creates no duplicate records")
	await app.open_course("supplement","sample:move");await settle();go_to("sample:move");app.player.complete_busy();app.player.play();app.player.animation.custom_step(1.6);await frames(2)
	check(abs(app.values.zG-app.values.MZ/app.values.Dload)<1e-9,"Animated CG and moment agree")
	check(abs(app.ship.cargo.position.y-(17.9+app.state.move_z))<1e-4,"Animated cargo uses domain position")
	var frozen:float=app.state.move_z;var index:int=app.player.current;app.toggle_language()
	check(app.player.current==index and app.state.move_z==frozen,"F2 preserves in-flight state")
	tap(KEY_ESCAPE);await frames(3);check(app.mode=="home" and not app.player.active,"Esc cancels lesson")
	# Old save migration and corruption protection are isolated from real progress.
	var store=load("res://core/safe_store.gd").new();store.path="user://formal-corrupt-test.json"
	var file:=FileAccess.open(store.path,FileAccess.WRITE);file.store_string("{broken");file.close();store.read_file()
	check(store.blocked and not store.write_file(),"Corrupt save blocks overwrite")
	check(FileAccess.get_file_as_string(store.path)=="{broken","Corrupt original preserved")
	store=load("res://core/safe_store.gd").new();store.data.targets={"ost":"ost-item-1:meaning","mass":"t2-root:iteration2","dimensions":"dim-eliminate:root","sample":"sample:move"};store.data.selected="ost";store.migrate()
	check(store.data.selected=="" and not store.data.targets.has("ost"),"OST progress returns to home")
	check(store.data.targets.mass=="T04:transform" and store.data.targets.dimensions=="T13:bridge","Old stages map to new starts")
	check(store.data.targets.supplement=="sample:move","Moving-cargo progress migrates")
	# Canvas/DPI scaling in our own offscreen window; no OS display setting changes.
	if not "--minimum" in OS.get_cmdline_user_args():
		for scale in [1.0,1.25,1.5,2.0]:
			var win:Window=app.get_window();win.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;win.content_scale_size=Vector2i(1440,900);win.size=Vector2i(Vector2(1440,900)*scale)
			await app.open_course("dimensions","T12:float");await settle();app.lang="zh";app.toggle_language();await frames(5)
			await capture("formal-dpi-"+str(int(scale*100)))
			check(app.size.x>=1400,"Logical layout retained at "+str(scale))
			var e=app.equations.entries["T12:float"].math;check(e.min_render_scale==1,"Unshrunk fraction at "+str(scale))
			await app.open_course("supplement","norman-apply:direct");await settle()
			await capture("subscript-dpi-"+str(int(scale*100)))
			var subscript_math=app.equations.entries["norman-apply:direct"].math
			for hint in subscript_math.hint_regions:
				check(subscript_math._get_tooltip(hint.rect.get_center())==hint.text,"Scaled Cyrillic ink hit at "+str(scale))
			var textures:=0
			for item in app.equations.entries.values():textures+=item.math.textures.size()
			check(textures<65,"Only nearby SVG textures at "+str(scale))
	app.lang="ru";await app.open_course("dimensions","T16:pass");app.store.data.language="ru";app.save_progress()
