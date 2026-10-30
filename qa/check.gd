extends Node
var app:Control
var checks:Array=[]
var suffix:="normal"
var minimum_math_scale:=1.0
func check(name:String,ok:bool)->void:checks.append({"name":name,"passed":ok})
func key(code:int,pressed:=true)->void:
	var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=pressed;get_viewport().push_input(e,true)
func tap(code:int)->void:key(code);key(code,false)
func click_at(point:Vector2)->void:
	var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;get_viewport().push_input(motion,true);await get_tree().process_frame
	for pressed in [true,false]:
		var e:=InputEventMouseButton.new();e.position=point;e.global_position=point;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;get_viewport().push_input(e,true);await get_tree().process_frame
func click_chapter(id:String)->void:
	var card:Control=app.home_map.cards[id]
	await click_at(card.get_global_rect().get_center())
func mouse_button(point:Vector2,button:int,pressed:bool)->void:
	var e:=InputEventMouseButton.new();e.position=point;e.global_position=point;e.button_index=button;e.pressed=pressed;get_viewport().push_input(e,true)
func mouse_motion(point:Vector2)->void:
	var e:=InputEventMouseMotion.new();e.position=point;e.global_position=point;get_viewport().push_input(e,true)
func go_to(id:String)->void:
	for i in range(app.player.beats.size()):
		if app.player.beats[i].id==id:app.player.current=i;app.player.prepare();return
	check("missing:"+id,false)
func screenshot(name:String)->void:
	print("CAPTURE ",name);await get_tree().process_frame;await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://qa/"+name+"-"+suffix+".png")
func settle()->void:await get_tree().create_timer(1.0).timeout
func spatial_preview()->void:
	var placements:Array=[]
	for spec in [["basics","parts:direction"],["basics","parts:deck"],["basics","baseline:reference"],["basics","baseline:draft"],["sample","sample:move"],["dimensions","dim-eliminate:root"],["foundation","cargo:limits"],["mass","t2-root:iteration2"]]:
		await app.open_course(spec[0],spec[1]);await settle()
		app.player.set_display_text(app.caption.full_text,true);await get_tree().process_frame
		check("lesson header removed:"+spec[1],not app.title.visible and not app.subtitle.visible)
		check("spatial paragraph visible:"+spec[1],app.speech.panel.visible and not app.speech.pending)
		var rect:Rect2=app.speech.panel.get_rect()
		check("spatial paragraph enclosed:"+spec[1],Rect2(Vector2.ZERO,app.speech.size).encloses(rect))
		check("paragraph clear of anchor:"+spec[1],not rect.grow(8).has_point(app.speech.anchor))
		var overlaps:=0
		for obstacle in app.speech.protected_rects:
			if rect.intersection(obstacle).get_area()>1:overlaps+=1
		check("paragraph avoids geometry:"+spec[1],overlaps==0)
		var frozen:Vector2=app.speech.panel.position
		app.toggle_language();await get_tree().process_frame
		var rows:int=app.caption.get_total_visible_line_count()
		check("Russian paragraph height:"+spec[1],app.caption.size.y>=rows*app.caption.get_line_height())
		check("no narration scrollbar:"+spec[1],not app.caption.get_v_scroll_bar().visible and not app.caption.get_h_scroll_bar().visible)
		check("single narration control:"+spec[1],app.speech.panel.get_child_count()==1 and app.speech.panel.get_child(0)==app.caption)
		check("F2 keeps paragraph position:"+spec[1],app.speech.panel.position==frozen)
		if spec[1] in ["sample:move","baseline:draft"]:await screenshot("spatial-ru-"+spec[1].replace(":","-"))
		app.toggle_language()
		if app.ship.visible:
			app.ship.yaw+=.1;app.ship.update_camera();await get_tree().process_frame
			check("orbit keeps paragraph fixed:"+spec[1],app.speech.panel.position==frozen)
			app.ship.yaw-=.1;app.ship.update_camera()
		placements.append({"step":spec[1],"position":[frozen.x,frozen.y],"anchor":[app.speech.anchor.x,app.speech.anchor.y],"overlaps":overlaps})
		await screenshot("spatial-"+spec[1].replace(":","-"))
		if spec[1]=="sample:move":
			app.advance();await get_tree().create_timer(.7).timeout
			check("motion keeps paragraph fixed",app.speech.panel.position==frozen)
			check("leader tracks moving cargo",app.speech.anchor.distance_to(app.ship.lesson_anchor("load"))<.01)
			await screenshot("spatial-cargo-moving")
	var file:=FileAccess.open("res://qa/spatial-"+suffix+".json",FileAccess.WRITE);file.store_string(JSON.stringify(placements,"\t"));file.close()
	check("different subjects have different placements",placements[1].position!=placements[2].position)
	app.go_home()

func start(root:Control)->void:
	app=root
	if "--minimum" in OS.get_cmdline_user_args():suffix="minimum";get_window().size=Vector2i(1100,760)
	await get_tree().process_frame;await get_tree().process_frame
	if "--copy-only" in OS.get_cmdline_user_args():
		suffix="copy";await app.open_course("sample","sample:move");app.player.set_display_text(app.caption.full_text,true);await settle()
		var old_clip:=DisplayServer.clipboard_get()
		for pressed in [true,false]:
			var e:=InputEventMouseButton.new();e.position=app.equations.global_position+Vector2(24,28);e.global_position=e.position;e.button_index=MOUSE_BUTTON_RIGHT;e.pressed=pressed;get_viewport().push_input(e,true)
		await get_tree().create_timer(.4).timeout;await screenshot("v5-copy-menu")
		print("MENU ",app.equations.popup.position," SIZE ",app.equations.popup.size," EMBED ",app.equations.popup.is_embedded()," EQUATIONS ",app.equations.global_position)
		await click_at(Vector2(app.equations.popup.position)+Vector2(70,18));await get_tree().create_timer(.2).timeout
		print("AFTER VISIBLE ",app.equations.popup.visible," SIGNAL ",app.equations.has_meta("copied")," CLIP MATCH ",DisplayServer.clipboard_get().replace("\r\n","\n")==app.equations.latex_text)
		await screenshot("v5-copy-after");check("copy linear formula",DisplayServer.clipboard_get().replace("\r\n","\n")==app.equations.latex_text);DisplayServer.clipboard_set(old_clip);finish();return
	if "--reopen" in OS.get_cmdline_user_args():
		suffix="reopen";check("persistent language",app.lang=="ru");check("opens knowledge map",app.mode=="home" and app.home_map.visible)
		await app.open_course("dimensions");check("persistent stable step",app.beat.id=="dim-eliminate:root");check("restores beginning",app.player.phase=="typing");finish();return
	app.store.data.targets={};app.lang="zh";app.build_home();app.refresh_chrome()
	if "--launch-only" in OS.get_cmdline_user_args():
		suffix="launcher";await click_chapter("basics");check("launcher direct chapter",app.mode=="lesson" and app.beat.id=="parts:direction")
		tap(KEY_F2);check("launcher F2",app.lang=="ru" and "́" in app.caption.full_text)
		var p:=FileAccess.open("res://qa/launcher-process.json",FileAccess.WRITE);p.store_string(JSON.stringify({"pid":OS.get_process_id(),"engine":Engine.get_version_info().string}));p.close();await screenshot("launcher");finish();return
	if "--spatial-only" in OS.get_cmdline_user_args():
		await spatial_preview();finish();return
	await spatial_preview()
	check("home graph and no introductory text",app.home_map.visible and not app.subtitle.visible)
	check("eight chapters without internal nodes",app.home_map.cards.size()==8 and app.home_map.graph.groups.is_empty())
	var buttons:=0
	for child in app.get_children():
		if child is Button:buttons+=1
	check("removed footer and auxiliary buttons",buttons==1)
	for card in app.home_map.cards.values():
		check("initial chapter fully visible:"+str(card.position),app.home_map.view.get_global_rect().encloses(card.get_global_rect()))
	await screenshot("v6-knowledge-map")
	var map=app.home_map;var view=map.view;var initial:Dictionary=view.get_view_state()
	var point:Vector2=map.cards["basics"].get_global_rect().get_center()
	mouse_motion(point);await get_tree().process_frame
	check("map node hover",map.cards["basics"].get_meta("visual_state")=="hover")
	mouse_button(point,MOUSE_BUTTON_LEFT,true);await get_tree().process_frame
	check("map node pressed",map.cards["basics"].get_meta("visual_state")=="pressed")
	mouse_motion(point+Vector2(45,25));await get_tree().process_frame
	check("node drag pans",view.dragged and view.get_view_state().center!=initial.center)
	mouse_motion(point);mouse_button(point,MOUSE_BUTTON_LEFT,false);await get_tree().process_frame
	check("drag return never opens chapter",app.mode=="home")
	view.restore_view_state(initial)
	var local_point:Vector2=point-view.global_position
	var world_point:Vector2=(local_point-view.pan)/view.zoom
	mouse_button(point,MOUSE_BUTTON_WHEEL_UP,true);mouse_button(point,MOUSE_BUTTON_WHEEL_UP,false);await get_tree().process_frame
	check("wheel zoom anchors pointer",view.zoom>initial.zoom and ((local_point-view.pan)/view.zoom).distance_to(world_point)<.001)
	var zoomed:Dictionary=view.get_view_state();tap(KEY_F2)
	check("map F2 keeps view",view.get_view_state()==zoomed and map.captions["basics"].text.contains("́"))
	tap(KEY_F2)
	await click_chapter("basics");tap(KEY_ESCAPE);await get_tree().process_frame
	check("return preserves map view",app.mode=="home" and view.get_view_state()==zoomed)
	check("return marks current knowledge",map.current_id=="basics")
	view.restore_view_state(initial)
	for node in map.graph.nodes:
		await click_chapter(node.id)
		check("map opens:"+node.id,app.mode=="lesson" and app.course.id==node.course and app.beat.id==node.step)
		tap(KEY_ESCAPE)
	for language in ["zh","ru"]:
		if app.lang!=language:tap(KEY_F2)
		await get_tree().process_frame
		if language=="ru":await screenshot("v6-knowledge-map-ru")
		for node_id in map.captions:
			var label:Label=map.captions[node_id]
			check("map label fits:"+node_id+language,label.get_minimum_size().y<=map.cards[node_id].size.y-8)
	if app.lang!="zh":tap(KEY_F2)
	await click_chapter("basics");check("chapter click opens lecture directly",app.mode=="lesson" and app.beat.id=="parts:direction");go_to("baseline:reference")
	tap(KEY_E);await settle();check("baseline camera is side view",absf(app.ship.yaw)<.001 and app.ship.pitch<.04)
	tap(KEY_E);await get_tree().create_timer(.7).timeout
	check("baseline grows",app.state.baseline_reveal>0 and app.state.baseline_reveal<1)
	await screenshot("v5-baseline-growing");tap(KEY_E)
	check("baseline lies at zero",app.ship.label_points[12].y==0 and app.ship.labels[12].visible)
	tap(KEY_E);tap(KEY_E);await settle();tap(KEY_E);await get_tree().create_timer(1).timeout
	check("draft grows vertically",app.beat.id=="baseline:draft" and app.state.draft_measure>0 and app.state.draft_measure<1)
	await screenshot("v5-draft-growing");tap(KEY_E)
	tap(KEY_E);tap(KEY_E);await settle();tap(KEY_E);await get_tree().create_timer(2.6).timeout
	check("depth shown separately",app.beat.id=="baseline:depth" and app.ship.labels[4].visible and not app.ship.labels[5].visible)
	await screenshot("v5-depth")
	go_to("parts:deck");tap(KEY_E);await settle()
	check("deck camera above ship",app.ship.pitch>1)
	check("strong focus material",app.ship.highlight_material.albedo_color.a==1 and app.ship.dim_material.albedo_color.a==1)
	await screenshot("v5-deck")
	go_to("parts:compartments");tap(KEY_E);await settle()
	app.ship.yaw=-1.2;app.ship.pitch=1.1;app.ship.update_camera();tap(KEY_E)
	await get_tree().create_timer(.2).timeout
	check("camera frames before action",app.animation_waiting and app.state.cutaway_amount==0)
	await get_tree().create_timer(1.2).timeout
	check("action starts after framing",not app.animation_waiting and app.state.cutaway_amount>0 and app.ship.camera_mode=="cutaway")
	await screenshot("v5-cutaway");tap(KEY_ESCAPE);await settle()
	check("exit cancels camera and action",app.mode=="home" and not app.ship.camera_motion and not app.player.active)
	await click_chapter("sample");check("sample leaf opens",app.beat.id=="sample:known")
	go_to("sample:move");tap(KEY_E);await settle();tap(KEY_E);await get_tree().create_timer(1).timeout
	check("real cargo motion",app.ship.cargo.visible and not app.ship.points[5].visible and app.state.move_z<0 and app.state.move_z> -6)
	check("cargo shares computed coordinates",absf(app.ship.cargo.position.y-app.values.rows[5][2])<.00001)
	check("LaTeX mass product and subscript",app.equations.latex_text.contains("\\sum") and app.equations.latex_text.contains("_{i}"))
	check("MathJax SVG renders",app.equations.render_errors==0 and not app.equations.drawings.is_empty())
	await screenshot("v5-cargo-math")
	var id:String=app.beat.id;tap(KEY_F2)
	check("F2 preserves running animation",app.beat.id==id and app.player.phase=="playing" and "́" in app.caption.text)
	await screenshot("v5-cargo-math-ru");tap(KEY_E)
	check("correct final centroid",absf(app.values.zG-(140879.07-600)/20616)<1e-9)
	var old_clip:=DisplayServer.clipboard_get()
	for pressed in [true,false]:
		var e:=InputEventMouseButton.new();e.position=app.equations.global_position+Vector2(24,28);e.global_position=e.position;e.button_index=MOUSE_BUTTON_RIGHT;e.pressed=pressed;get_viewport().push_input(e,true)
	await get_tree().create_timer(.3).timeout
	check("formula context menu opens",app.equations.popup.visible)
	await click_at(Vector2(app.equations.popup.position)+Vector2(70,18));await get_tree().process_frame
	check("formula copies actual LaTeX",DisplayServer.clipboard_get().replace("\r\n","\n")==app.equations.latex_text)
	DisplayServer.clipboard_set(old_clip);app.equations.popup.hide()
	tap(KEY_Q);check("back restores pre-move state",app.beat.id=="sample:before" and app.state.move_z==0)
	check("MathJax fraction source",app.equations.bundle.lessons["sample:weighted"].zh[0].tex.contains("\\frac"))
	check("MathJax radical source",app.equations.bundle.lessons["dim-eliminate:root"].zh[0].tex.contains("\\sqrt"))
	# Every course still renders in both languages, with formulas and no footer.
	for c in app.courses:
		await app.open_course(c.id)
		for i in range(app.player.beats.size()):
			app.player.current=i;app.player.prepare()
			check("short sentence:"+app.beat.id,app.beat.words.zh.length()<=32)
			for language in ["zh","ru"]:
				if app.lang!=language:app.toggle_language()
				app.player.set_display_text(app.caption.full_text,true);await get_tree().process_frame
				check("resolved:"+app.beat.id+language,not "@" in app.equations.text and not app.caption.full_text.is_empty())
				check("shared state:"+app.beat.id+language,app.ship.current==app.state)
				check("bubble fits:"+app.beat.id+language,app.speech.pending or Rect2(Vector2.ZERO,app.speech.size).encloses(app.speech.panel.get_rect()))
				check("right fits:"+app.beat.id+language,not app.right.visible or app.right.get_rect().end.x<=app.stage.size.x+1)
				check("LaTeX SVG:"+app.beat.id+language,app.equations.render_errors==0 and app.concept.latex_renderer.render_errors==0)
				minimum_math_scale=minf(minimum_math_scale,app.equations.min_render_scale)
				for drawing in app.equations.drawings:check("formula fits:"+app.beat.id+language,drawing.rect.end.x<=app.equations.size.x+1)
				if language=="zh" and app.beat.id=="dim-eliminate:root":await settle();await screenshot("latex-zh-dim-root")
			if app.beat.id in ["load-fuel:5","t2-root:iteration2","dim-eliminate:root","cargo:limits","t2-coefficients:admiralty","dim-equations:stability","norman-apply:direct"]:await settle();await screenshot("latex-"+app.beat.id.replace(":","-"))
	check("formula body at least 21 px",minimum_math_scale>=.75)
	print("MIN MATH SCALE ",minimum_math_scale)
	check("numeric slots fit throughout animation",app.equations.slot_overflows==0)
	# Physics remains independent of UI and display rounding.
	var v:Dictionary=app.domain.values({})
	check("load reference",absf(v.Dload-20616)<1e-9 and absf(v.MZ-140879.07)<1e-6 and absf(v.MX-1547648.03)<1e-6)
	var exact:Dictionary=app.domain.tanker(15.9,false)
	check("root residual",absf(exact.mass_error)<1e-7)
	check("three size constraints",absf(exact.residual_float)<1e-7 and absf(exact.residual_volume)<1e-7 and absf(exact.residual_stability)<1e-8)
	await app.open_course("sample","sample:move");key(KEY_E);key(KEY_E);key(KEY_E,false);check("held D one action",app.player.phase=="ready")
	await settle();app.ship.yaw=1.2;app.ship.update_camera();tap(KEY_E);await get_tree().create_timer(.1).timeout
	check("manual orbit triggers framing",app.animation_waiting and app.ship.camera_motion)
	tap(KEY_ESCAPE);await settle();check("cancel framing stays at map",app.mode=="home" and not app.player.active and not app.ship.camera_motion)
	await app.open_course("basics","parts:direction");app.player.set_display_text("Ма́сса");check("accent stays together",not 2 in app.player.glyph_ends and 3 in app.player.glyph_ends)
	# Native narration selection with internal pointer events only.
	app.caption.set_content("Ма́сса");app.caption.visible_characters=-1;await settle()
	var saved_clipboard:=DisplayServer.clipboard_get();app.caption.select_all();app.caption.grab_focus()
	for pressed in [true,false]:
		var e:=InputEventKey.new();e.keycode=KEY_C;e.ctrl_pressed=true;e.pressed=pressed;get_viewport().push_input(e,true)
	await get_tree().process_frame;check("native narration copy",DisplayServer.clipboard_get()=="Ма́сса");DisplayServer.clipboard_set(saved_clipboard)
	var bad=load("res://core/safe_store.gd").new();bad.path="user://qa-damaged.json"
	var file:=FileAccess.open(bad.path,FileAccess.WRITE);file.store_string("broken original");file.close();bad.read_file()
	check("damaged store preserved",bad.blocked and not bad.write_file() and FileAccess.get_file_as_string(bad.path)=="broken original")
	app.lang="ru";app.store.data.language="ru";app.store.data.targets.dimensions="dim-eliminate:root";app.store.data.selected="dimensions";app.save_progress();finish()
func finish()->void:
	var f:=FileAccess.open("res://qa/checks-"+suffix+".json",FileAccess.WRITE);f.store_string(JSON.stringify(checks,"\t"));f.close()
	var failures:=0
	for c in checks:
		if not c.passed:failures+=1;print("FAIL ",c.name)
	print("QA ",checks.size()," checks, failures ",failures);get_tree().quit(0 if failures==0 else 1)

