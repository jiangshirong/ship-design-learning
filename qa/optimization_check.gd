extends "res://modules/review/qa/topics_check.gd"
const Hydro=preload("res://modules/review/core/stability_math.gd")
const Lifecycle=preload("res://core/scene_lifecycle.gd")
func count_draws()->int:
	var count:=0
	for entry in page.records.entries.values():count+=entry.math.draw_count
	return count
func enabled_viewports(node:Node)->int:
	var count:=1 if node is SubViewport and node.render_target_update_mode!=SubViewport.UPDATE_DISABLED else 0
	for child in node.get_children():count+=enabled_viewports(child)
	return count
func start(target)->void:
	host=target;app=host.review
	await frames(5)
	check(not is_instance_valid(host.ship),"Home has no homework model")
	check(app._stability==null and app._reading==null and app._vocabulary==null,"Home does not instantiate review pages")
	tap(KEY_ESCAPE);await frames(2)
	check(host.mode=="home" and not is_instance_valid(host.ship),"Home Escape does not create a model")
	host.open_review("reading");await frames(5)
	check(app._stability==null and enabled_viewports(host)==0,"Reading creates no 3D scenes")
	host.open_review("scientific");await frames(5)
	check(app._stability==null and enabled_viewports(host)==0,"Scientific review creates no 3D scenes")
	host.open_review("reading");await app.open_topic("stability")
	page=app.stability;select_beat("ST:arm");await settle_topic()
	check(page.original_ship.bodies.size()==1,"Comparison ship is lazy")
	page.drawer_open=true;page.arrange();await frames(12)
	var history:int=page.history_computations
	var curves:int=Hydro.curve_computations
	for i in 30:
		var s:Dictionary=page.current_state.duplicate(true);s.heel=float(i)*.3
		page.state_changed(s)
		await frames(1)
	check(page.history_computations==history,"Numeric ticks never recompute history")
	check(Hydro.curve_computations==curves,"Angle-only animation reuses complete arm curve")
	await frames(12)
	var drawings:=count_draws()
	await frames(45)
	check(count_draws()==drawings,"Unchanged formulas request no redraw")
	var physics:int=Hydro.value_computations;curves=Hydro.curve_computations
	page.original_ship.camera.position+=Vector3(2,3,4);await frames(8)
	check(Hydro.value_computations==physics and Hydro.curve_computations==curves,"Camera movement performs no hydro calculation")
	var cutter=page.original_ship.interior_cuts[0]
	var writes:int=cutter.parameter_writes
	page.state_changed(page.current_state)
	check(cutter.parameter_writes==writes,"Unchanged cut parameters are not uploaded again")
	select_beat("ST:roll_compare");await settle_topic()
	check(page.original_ship.bodies.size()==2,"Comparison ship appears when needed")
	curves=Hydro.curve_computations
	for i in 20:
		var s:Dictionary=page.current_state.duplicate(true);s.clock=float(i)*.1;page.state_changed(s);await frames(1)
	check(Hydro.curve_computations==curves,"Roll clock does not rebuild arm curve")
	var record_debug:Array=[]
	for id in page.records.entries:
		var m=page.records.entries[id].math
		record_debug.append({"id":id,"visible":m.is_visible_in_tree(),"size":str(m.size),"position":str(m.global_position),"clip":str(m.visible_region()),"drawings":m.drawings.size(),"textures":m.textures.size(),"draw_count":m.draw_count})
		if m.is_visible_in_tree() and m.drawings.any(func(d):return d.rect.intersects(m.visible_region())):
			check(not m.textures.is_empty(),"Visible formula is rendered after layout and scroll "+id)
	var debug_file:=FileAccess.open("res://qa/optimization-record-debug.json",FileAccess.WRITE);debug_file.store_string(JSON.stringify(record_debug,"\t"))
	await capture("optimization-stability")
	var observed_camera:Transform3D=page.original_ship.camera.transform
	for id in ["damage","freeboard","cargo","loads"]:
		await app.open_topic(id);await settle_topic()
		check(Lifecycle.entries.size()<=2,"Heavy scene cache bounded "+id)
		if id=="damage":
			var view=page.topic_ship.active
			check(view.shells.is_empty() and view.fittings.is_empty() and view.interior_models.is_empty(),"Damage view does not create unused intact solver models")
	check(not is_instance_valid(page.original_ship),"Least recently used stability model was released")
	var computed_history:int=page.history_computations
	await app.open_topic("stability");await frames(8)
	check(page.original_ship.camera.transform.is_equal_approx(observed_camera),"Rebuilt scene restores its observation camera")
	check(page.history_computations==computed_history,"Returning to a topic reuses its completed calculation history")
	app.go_home();await frames(8)
	check(enabled_viewports(host)==0,"Reading disables all cached 3D viewports")
	var stored:Dictionary=app.reading.store.data.duplicate(true)
	await host.open_course("load");await frames(8)
	check(host.ship.loaded_model==2,"Homework loads only its fuel vessel")
	check(host.ship.cargo_model.get_child_count()==0 and host.ship.tanker_model.get_child_count()==0,"Unrelated homework hulls absent")
	check(host.ship.cargo_lesson.first.is_empty(),"Unrelated cargo crates absent")
	host.show_home();await frames(8)
	check(enabled_viewports(host)==0,"Home disables all cached 3D viewports")
	check(not host.player.active and host.player.process_mode==Node.PROCESS_MODE_DISABLED,"Hidden homework player is stopped")
	check(app.reading.store.data==stored,"Animation and cache changes preserve reading progress")
	host.open_course("foundation");tap(KEY_ESCAPE);await frames(45)
	check(host.mode=="home" and not host.loading and enabled_viewports(host)==0,"Escape cancels an unfinished opening")
	var failed:=results.filter(func(r):return not r.passed).size()
	var f:=FileAccess.open("res://qa/optimization-results.json",FileAccess.WRITE);f.store_string(JSON.stringify(results,"\t"))
	if "--perf-launcher" in OS.get_cmdline_user_args():
		var launch:=FileAccess.open("res://qa/performance-launcher.json",FileAccess.WRITE)
		launch.store_string(JSON.stringify({"pid":OS.get_process_id(),"checks":results.size(),"failures":failed,"project":ProjectSettings.globalize_path("res://"),"no_focus":host.get_window().get_flag(Window.FLAG_NO_FOCUS),"window":str(host.size)},"\t"))
	print("OPTIMIZATION ",results.size()," checks; failures=",failed)
	get_tree().quit(1 if failed else 0)
