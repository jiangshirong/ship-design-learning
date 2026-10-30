extends "res://qa/formal_check.gd"
func start(host)->void:
	app=host;app.lang="zh";await frames(5)
	var minimum:bool="--minimum" in OS.get_cmdline_user_args()
	get_window().size=Vector2i(1100,700) if minimum else Vector2i(1440,900)
	check(app.home_map.nodes_by_id.has("approximation2"),"Second approximation tree entry")
	check(app.home_map.nodes_by_id.has("approximation3"),"Third approximation tree entry")
	for course_id in ["approximation2","approximation3"]:
		await app.open_course(course_id);await settle()
		var original_yaw:float=app.ship.yaw
		for i in app.player.beats.size():
			app.jump_to_step(i);await settle()
			var b:Dictionary=app.beat
			check(app.ship.yaw==original_yaw,"Camera preserved "+str(b.id))
			check(not app.speech.caption.full_text.is_empty(),"Sentence "+str(b.id))
			if app.equations.entries.has(b.id):
				var math=app.equations.entries[b.id].math
				check(math.render_errors==0,"Formula renders "+str(b.id))
				for drawing in math.drawings:check(drawing.rect.end.x<=math.size.x+2,"Formula fits "+str(b.id)+" row "+str(drawing.row))
				if b.has("source_rule"):check(not math.source_blocks.is_empty(),"Source style "+str(b.id))
			check(app.speech.panel.get_global_rect().end.x<=get_window().size.x+1,"Bubble inside window "+str(b.id))
			check(not app.right.visible or not app.speech.panel.get_global_rect().intersects(app.right.get_global_rect()),"Bubble outside record "+str(b.id))
			if str(b.id) in ["AP2:steel_object","AP2:criterion","AP3:wet","AP3:friction_chart","AP3:residual_chart","AP3:psi_chart","AP3:catalog","AP3:handoff"]:
				await frames(3)
				app.get_viewport().get_texture().get_image().save_png("res://qa/approx-"+str(b.id).replace(":","-")+("-minimum" if minimum else "")+".png")
			if str(b.id) in ["AP2:criterion","AP3:psi_chart","AP3:handoff"]:
				var index:int=app.player.current;app.toggle_language();await frames(10)
				check(app.player.current==index,"Language preserves step")
				check(app.caption.full_text==app.beat.words.ru,"Russian display")
				app.toggle_language();await frames(5)
		app.go_home();await frames(4)
		check(app.mode=="home","Return home")
		await app.open_course(course_id);await settle()
		check(app.player.current==app.player.beats.size()-1,"Resume final stable identity")
		app.go_home()
	await app.open_course("approximation3","AP3:scaleL");await settle()
	check(absf(app.values.L-189.13)<.0001,"Model final length")
	await app.open_course("approximation3","AP3:handoff");await settle()
	var final=preload("res://core/approximation_final.gd")
	var bulk=preload("res://core/bulkhead_math.gd")
	check(app.values.H==bulk.H and app.values.L==bulk.L and app.values.D==final.D,"Shared final dimensions")
	var words=preload("res://modules/review/core/glossary.gd").new()
	check(not words.spans("смо́ченная пове́рхность").is_empty(),"New terminology hover")
	check(words.study_entries().all(func(e):return not str(e.id).begins_with("approximation_lookup_")),"No new study cards")
	await app.open_course("approximation3","AP3:lambda");await settle()
	app.ship.yaw+=.18;app.ship.update_camera();var yaw:float=app.ship.yaw
	tap(KEY_E);await frames(5);check(app.beat.id=="AP3:scaleL","D enters next segment")
	tap(KEY_E);await frames(2);check(app.player.phase=="ready","D completes text only")
	tap(KEY_E);await frames(3);check(app.player.phase=="playing","D starts action")
	var epoch:int=app.player.epoch;tap(KEY_F2);await frames(3)
	check(app.player.epoch==epoch and app.player.phase=="playing","F2 preserves live action")
	check(app.ship.yaw==yaw,"D and F2 retain observer camera")
	check(app.values.L>=189.13 and app.values.L<=189.64,"Intermediate model dimension")
	check(absf(app.ship.dims.x-app.values.L)<.0001,"Intermediate model shares result")
	go_to("AP3:catalog");await settle();await frames(10)
	check(app.beat.id=="AP3:catalog" and app.values.L==189.64,"Jump cancels old animation")
	tap(KEY_Q);await frames(5);check(app.beat.id=="AP3:margin","A returns previous segment")
	await settle();tap(KEY_ESCAPE);await frames(5)
	check(app.mode=="home" and not app.player.active,"Esc stops lesson")
	check(app.ship.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED,"Hidden 3D viewport stopped")
	await app.open_course("approximation3");await settle();check(app.beat.id=="AP3:margin","Resume after keyboard exit")
	app.phase_menu.scroll_horizontal=0;await frames(3)
	await click_at(app.phase_menu.track.global_position+Vector2(app.phase_menu.cell_width*.5,20));await settle()
	check(app.beat.id=="AP3:goal","Actual stage click")
	await click_at(app.progress.global_position+app.progress.point(1));await settle()
	check(app.beat.id=="AP3:input","Actual progress node click")
	go_to("AP3:psi_chart");await settle()
	var wheel:=InputEventMouseButton.new();wheel.position=app.concept.global_position+app.concept.approximation_diagrams.area.get_center();wheel.global_position=wheel.position;wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.pressed=true
	app.get_viewport().push_input(wheel,true);await frames(4)
	check(app.concept.approximation_diagrams.chart_zoom>1,"Teacher graph wheel zoom")
	app.lang="zh"
	go_to("AP3:required");await settle()
	var formula=app.equations.entries["AP3:required"].math
	check(formula.hint_regions.any(func(r):return r.text.contains("所需主机功率")),"Russian power subscript meaning")
	go_to("AP2:gst") if app.course.id=="approximation2" else go_to("AP3:norman")
	await settle()
	for dpi in [1.25,1.5,2.0]:
		get_window().size=Vector2i(Vector2(1440,900)*dpi);get_window().content_scale_factor=dpi;await frames(8)
		check(app.speech.panel.get_rect().end.y<=app.ship.size.y+1,"DPI bubble "+str(dpi))
		var math=app.equations.entries["AP3:norman"].math
		check(math.render_errors==0 and math.min_render_scale==1,"DPI formula full scale "+str(dpi))
		if dpi==2.0:await capture("approx-dpi-2")
	get_window().content_scale_factor=1;get_window().size=Vector2i(1100,700) if minimum else Vector2i(1440,900);await frames(8)
	app.go_home();await app.open_course("dimensions","T14:adopt");await settle()
	check(app.values.D==44388,"First approximation unchanged")
	var report:={"checks":results,"failures":results.filter(func(r):return not r.passed)}
	var f:=FileAccess.open("res://qa/approximations-"+("minimum" if minimum else "normal")+".json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close()
	print("APPROXIMATIONS ",results.size()," checks; ",report.failures.size()," failures")
	get_tree().quit(0 if report.failures.is_empty() else 1)
