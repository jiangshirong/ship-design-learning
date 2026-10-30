extends "res://modules/review/qa/sample_check.gd"
const Hydro=preload("res://modules/review/core/stability_math.gd")
var page
func settled()->void:
	page.drawer_open=true;page.arrange()
	if page.ship.camera_tween and page.ship.camera_tween.is_valid():page.ship.camera_tween.custom_step(2)
	await frames(12);page.player.complete_busy()
	if page.player.phase=="ready":page.player.play();page.player.finish()
	await frames(12)
func select_id(id:String)->void:
	for i in page.player.beats.size():
		if page.player.beats[i].id==id:page.goto_index(i);return
func start(target)->void:
	app=target;page=app.stability;app.language="zh"
	page.store.data={"version":1,"beat":"ST:goal","foundation_done":false,"pending":"","language":"zh"}
	await app.open_lesson("","Q18");await settled()
	check(app.mode=="stability" and page.beat.id=="ST:goal","Q18 first visit starts foundation")
	check(page.store.data.pending=="Q18","Requested question retained")
	await capture("stability-overview")
	for id in ["ST:Cmove","ST:arm","ST:Mconstruct","ST:waterplane","ST:width","ST:shape"]:
		select_id(id);await settled()
		check(page.bubble.panel.visible,"Caption placed "+id)
		check(page.bubble.caption.get_v_scroll_bar().max_value<=page.bubble.caption.get_v_scroll_bar().page,"No caption scroll "+id)
		check(page.ship.shells[0].mesh!=null,"Computed hull visible "+id)
		check(absf(page.ship.metrics.residual)<.00001,"Hydro volume residual "+id)
		check(is_equal_approx(page.ship.bodies[0].rotation.x,-deg_to_rad(page.ship.metrics.angle)),"Pose and calculation share angle "+id)
		check(absf(page.ship.overlay_points.G.distance_to(page.ship.overlay_points.M)-page.ship.metrics.h)<.0001,"True spatial GM distance "+id)
		if id=="ST:waterplane":check(page.ship.waterplane_boundary.size()>50 and page.ship.waterplane_fill.visible,"Actual hull waterplane polygon")
		await capture("stability-"+id.replace("ST:",""))
	# Manual stage jumps above intentionally cancel the pending destination.
	# Restore the first-entry scenario before checking automatic handoff.
	select_id("ST:foundation_end");await settled()
	page.store.data.pending="Q18";page.store.data.foundation_done=false
	page.advance();await settled()
	check(page.store.data.foundation_done and page.beat.id=="ST:Q18:goal","Foundation resumes requested Q18")
	if "--stability-sample" not in OS.get_cmdline_user_args():
		for i in page.player.beats.size():
			page.goto_index(i);await settled()
			check(page.bubble.panel.visible,"All beats caption "+page.beat.id)
			check(page.bubble.caption.get_v_scroll_bar().max_value<=page.bubble.caption.get_v_scroll_bar().page,"All beats unclipped "+page.beat.id)
			check(page.ship.metrics.h>0,"Selected states positive initial h "+page.beat.id)
			for entry in page.records.entries.values():check(entry.math.render_errors==0 and entry.math.slot_overflows==0,"Formula clear "+page.beat.id)
			if page.beat.id in ["ST:zero","ST:lower_G","ST:lower_H","ST:roll_compare","ST:acceleration"]:await capture("stability-"+page.beat.id.replace("ST:",""))
		select_id("ST:zero_shift");await settled();page.experiment_value("heel",80);page.experiment_value("zg",7.5);await frames(12)
		check(is_equal_approx(page.current_state.zg,7.5),"Restricted slider updates G")
		var before:Dictionary=page.current_state.duplicate(true);tap(KEY_F2);await frames(12)
		check(page.current_state==before and page.language=="ru","F2 preserves experiment and pose")
		await capture("stability-russian")
		page.reset_segment();await frames(8);check(page.current_state==page.player.after[page.player.current],"Reset restores segment")
		# Actual viewport input, no system cursor changes.
		var slider:HSlider=page.sliders.heel
		await click(slider.global_position+Vector2(slider.size.x*.55,slider.size.y*.5));await frames(6)
		check(page.current_state.heel>70 and page.current_state.heel<95,"Real slider click changes heel")
		await click(page.reset_button.global_position+page.reset_button.size*.5);await frames(6)
		check(page.current_state==page.player.after[page.player.current],"Real reset click")
		page.phase_menu.scroll_horizontal=int(page.phase_menu.cell_width*5)
		await frames(2)
		await click(page.phase_menu.track.global_position+Vector2(page.phase_menu.cell_width*5.5,15));await frames(4)
		check(page.beat.id=="ST:Q20:goal","Actual stage button jumps to Q20")
		tap(KEY_E);await frames(3);check(page.player.phase!="typing","D finishes typing once")
		var stable_id:String=page.beat.id
		var repeat:=InputEventKey.new();repeat.physical_keycode=KEY_E;repeat.pressed=true;repeat.echo=true;app.get_viewport().push_input(repeat,true);await frames(2)
		check(page.beat.id==stable_id,"Held key never skips stages")
		await click(page.progress.global_position+page.progress.point(1));await frames(3)
		check(page.beat.id=="ST:cycle","Actual segment node jump")
		page.player.complete_busy();page.player.play();page.player.animation.pause();page.player.animation.custom_step(page.player.beats[page.player.current].action.duration*.25);await frames(3)
		check(absf(page.current_state.clock/page.player.after[page.player.current].clock-.25)<.025,"Roll clock progresses linearly")
		tap(KEY_Q);await frames(3);check(page.beat.id=="ST:cycle" and page.player.phase=="settled","A while moving finishes current animation")
		tap(KEY_Q);await frames(3);check(page.beat.id=="ST:Q20:goal","Second A moves back")
		# Restore a persisted stable ID with a separate Store instance.
		var persisted=preload("res://modules/review/core/topic_store.gd").new();persisted.path=page.topic_store.path;persisted.read_file()
		var record:Dictionary=persisted.data.topics.stability
		check(record.beat==page.beat.id and record.foundation_done,"Topic state persists independently")
		var corrupt=preload("res://modules/review/core/stability_store.gd").new();corrupt.path="user://review/qa-stability-corrupt.json"
		var bad:=FileAccess.open(corrupt.path,FileAccess.WRITE);bad.store_string("{broken");bad.close();corrupt.read_file()
		check(corrupt.blocked and not corrupt.save() and FileAccess.get_file_as_string(corrupt.path)=="{broken","Damaged topic save retained without overwrite")
		app.get_window().size=Vector2i(1100,760);await frames(12)
		for id in ["ST:arm","ST:zero_shift","ST:acceleration"]:
			select_id(id);await settled();await capture("stability-small-"+id.replace("ST:",""))
			check(page.bubble.caption.get_v_scroll_bar().max_value<=page.bubble.caption.get_v_scroll_bar().page,"Small Russian caption "+id)
		for i in page.player.beats.size():
			page.goto_index(i);await settled()
			check(page.bubble.caption.get_v_scroll_bar().max_value<=page.bubble.caption.get_v_scroll_bar().page,"All Russian minimum-window sentences "+page.beat.id)
			check(Rect2(Vector2.ZERO,page.ship.size).encloses(page.bubble.panel.get_rect()),"Russian caption in bounds "+page.beat.id)
		for factor in [1.0,1.25,1.5,2.0]:
			app.get_window().content_scale_factor=factor;app.get_window().size=Vector2i(roundi(1100*factor),roundi(760*factor));await frames(12)
			select_id("ST:peak_lower");await settled()
			check(page.phase_menu.get_rect().end.x<=page.size.x+.1,"Navigation fits DPI "+str(factor))
			check(page.stage_buttons[-1].get_global_rect().end.x<=app.size.x+1,"All stage buttons visible DPI "+str(factor))
			check(page.bubble.caption.get_v_scroll_bar().max_value<=page.bubble.caption.get_v_scroll_bar().page,"DPI caption readable "+str(factor))
			await capture("stability-scale-"+str(factor))
		app.get_window().content_scale_factor=1;app.get_window().size=Vector2i(1440,900);await frames(8)
		tap(KEY_ESCAPE);await frames(8);check(app.mode=="reading" and not page.player.active,"Escape cancels course")
		await app.open_lesson("","Q19");await settled();check(page.beat.id=="ST:Q19:goal","Completed foundation allows direct entry")
	var report_path:="res://modules/review/qa/stability-sample-checks.json" if "--stability-sample" in OS.get_cmdline_user_args() else "res://modules/review/qa/stability-checks.json"
	var file:=FileAccess.open(report_path,FileAccess.WRITE);file.store_string(JSON.stringify(results,"\t"));file.close()
	print("STABILITY ",results.size()," checks; failures ",results.filter(func(r):return not r.passed).size());get_tree().quit()
