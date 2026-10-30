extends "res://modules/review/qa/topics_check.gd"
func start(target)->void:
	host=target;app=host.review
	host.open_review("reading");await frames(3)
	await app.open_topic("cargo","Q12");page=app.stability
	if page.language!="zh":tap(KEY_F2);await frames(3)
	var group:Dictionary={}
	for g in page.course.groups:
		if g.id=="Q12":group=g
	check(group.beats.size()==7,"Seven drawing/geometry segments")
	var instance_id:int=0
	for b in group.beats:
		select_beat(b.id);await settle_topic()
		var v=page.topic_ship.active
		check(v.get_script().resource_path.ends_with("double_bottom_view.gd"),"Dedicated drawing view "+b.id)
		if instance_id==0:instance_id=v.get_instance_id()
		check(v.get_instance_id()==instance_id,"Persistent scene "+b.id)
		check(page.bubble.panel.visible,"Explanation visible "+b.id)
		check(page.bubble.caption.get_v_scroll_bar().max_value<=page.bubble.caption.get_v_scroll_bar().page,"No text clipping "+b.id)
		if b.id=="Q12:s1":check(v.value("lines")==0 and v.value("inner")==0,"No future drawings")
		if b.id=="Q12:s2":check(v.value("lines")==1 and v.value("inner")==0,"Only lines plan revealed")
		if b.id=="Q12:station":check(is_zero_approx(v.section.position.x),"Same central station")
		if b.id=="Q12:match":check(v.value("match")==1 and v.volume.visible,"Closed section area")
		if b.id=="Q12:s3":
			check(is_equal_approx(v.volume.scale.x,8.),"Full compartment span")
			check(is_equal_approx(v.section.position.x,4.),"Sweep stops at end wall")
			await click(page.formula_toggle.get_global_rect().get_center());await frames(4)
			check(page.right.visible,"Formula drawer available")
			for entry in page.records.entries.values():check(entry.math.render_errors==0 and entry.math.slot_overflows==0,"LaTeX compiles and fits")
			await capture("q12-formula")
			await click(page.formula_toggle.get_global_rect().get_center());await frames(3)
		if b.id in ["Q12:s1","Q12:s2","Q12:inner","Q12:match","Q12:s3"]:await capture("q12-"+b.id.replace(":","-"))
	var v=page.topic_ship.active
	select_beat("Q12:match");await settle_topic()
	var matching:Dictionary=page.current_state.duplicate();matching.db_match=.5;page.state_changed(matching);await frames(3);await capture("q12-align-half")
	var geometry=load("res://modules/review/view/double_bottom_view.gd")
	check(is_equal_approx(geometry.half_width(0),1.5),"Matches authored beam")
	check(is_equal_approx(geometry.hull_section(0)[4].y,-.4),"Matches authored outer bottom")
	check(geometry.half_width(-4)*.9>1.07 and geometry.half_width(4)*.9>1.07,"Selected bottom lies inside flat hull")
	select_beat("Q12:s3");await settle_topic()
	var s:Dictionary=page.current_state.duplicate();s.db_sweep=.5;page.state_changed(s);await frames(4)
	check(is_zero_approx(v.section.position.x) and is_equal_approx(v.volume.scale.x,4.),"Halfway slice and volume agree")
	await capture("q12-sweep-half")
	var pose:Transform3D=v.camera.transform
	tap(KEY_F2);await frames(4);check(v.camera.transform==pose and is_equal_approx(v.value("sweep"),.5),"F2 preserves camera and motion state")
	await capture("q12-russian")
	check(not v.label_lookup.regions.is_empty(),"Russian drawing words have lookup regions")
	if not v.label_lookup.regions.is_empty():
		var region:Dictionary=v.label_lookup.regions[0]
		var e:=InputEventMouseMotion.new();e.position=v.get_global_transform_with_canvas()*region.rect.get_center();app.get_viewport().push_input(e,true);await frames(3)
		check(v.label_lookup.tip.panel.visible,"Immediate drawing word tooltip")
	v.yaw+=.25;v.update_camera();pose=v.camera.transform
	tap(KEY_Q);await frames(3);tap(KEY_Q);await frames(4);check(v.camera.transform==pose,"A preserves camera")
	tap(KEY_E);await frames(3);check(v.camera.transform==pose,"D preserves camera")
	select_beat("Q12:match");await settle_topic()
	DisplayServer.window_set_size(Vector2i(1100,760));await frames(7);await capture("q12-minimum")
	check(page.bubble.caption.get_v_scroll_bar().max_value<=page.bubble.caption.get_v_scroll_bar().page,"Minimum window bubble fits")
	tap(KEY_ESCAPE);await frames(4)
	check(not page.player.active and v.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED,"Exit stops player and 3D")
	await app.open_topic("cargo","Q13");page=app.stability;select_beat("Q13:s1");await settle_topic()
	check(page.topic_ship.active.get_script().resource_path.ends_with("interior_view.gd"),"Q13 keeps existing view")
	var out:=FileAccess.open("res://qa/q12-drawings.json",FileAccess.WRITE);out.store_string(JSON.stringify(results,"\t"));out.close()
	print("Q12 ",results.size()," checks; failures ",results.filter(func(r):return not r.passed).size());get_tree().quit()
