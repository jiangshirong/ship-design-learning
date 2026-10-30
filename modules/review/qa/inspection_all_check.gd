extends "res://modules/review/qa/topics_check.gd"
func start(target)->void:
	host=target;app=host.review;page=app.stability
	if "--minimum" in OS.get_cmdline_user_args():host.get_window().size=Vector2i(1100,760)
	await frames(12);host.open_review("reading")
	for item in [["cargo","Q11","Q11:underwater"],["cargo","Q12","Q12:s1"],["cargo","Q13","Q13:s1"],["cargo","Q13","Q13:s2"],["cargo","Q15","Q15:shortage"],["damage","N10","TOP:N10:limit"],["freeboard","N15","TOP:N15:volume"]]:
		await app.open_topic(item[0],item[1]);await frames(3)
		if page.language!="zh":tap(KEY_F2)
		select_beat(item[2]);await settle_topic()
		check(page.ship==page.topic_ship,"Topic renderer "+item[2])
		check(page.bubble.panel.visible,"Bubble "+item[2])
		if item[1] in ["Q12","Q13"]:
			check(page.topic_ship.active==page.topic_ship.views["doublebottom" if item[1]=="Q12" else "interior"],"Interior route "+item[1])
		await capture("inspection-"+item[2].replace(":","-"))
		tap(KEY_ESCAPE);await frames(2)
	await app.open_topic("cargo","Q11");select_beat("Q11:raise");await settle_topic()
	var hold=page.topic_ship.views.hold
	check(hold.detailed.scale==Vector3.ONE,"Raising depth never scales underwater hull")
	check(is_equal_approx(float(hold.inspection.materials[0].get_shader_parameter("deck_rise")),1),"One metre deck increase")
	await capture("inspection-Q11-raised")
	await app.open_topic("cargo","Q13");select_beat("Q13:s2");await settle_topic()
	var inside=page.topic_ship.views.interior
	check(is_equal_approx(float(inside.tank_cut.materials[0].get_shader_parameter("oil_height")),10.74),"Oil level uses fill state")
	check(inside.tanker.scale.x==inside.tanker.scale.y and inside.tanker.scale.y==inside.tanker.scale.z,"Tanker proportions preserved")
	await app.open_topic("stability","Q17");await frames(3)
	var ids:Array=[]
	for b in page.player.beats:
		if b.id in ["ST:Cmove","ST:Mconstruct","ST:arm","ST:lower_H","ST:roll_compare"]:ids.append(b.id)
	check(ids.size()>=3,"Stability representative steps")
	for id in ids:
		select_beat(id);await settle_topic()
		check(page.original_ship.fittings[0].visible,"Keep fittings "+id)
		check("ALPHA=" not in page.original_ship.shell_material.shader.code,"Opaque steel "+id)
		await capture("inspection-"+id.replace(":","-"))
	tap(KEY_ESCAPE);await frames(2);host.show_home()
	for course in ["foundation","load"]:
		await host.open_course(course);await frames(3)
		var found:=false
		for i in host.player.beats.size():
			var b:Dictionary=host.player.beats[i]
			var s:Dictionary=host.player.after[i].duplicate(true);s.merge(b.get("scene_params",{}),true)
			if (course=="foundation" and s.get("cargo_lesson",false)) or (course=="load" and s.get("fuel_detail",false)):
				host.jump_to_step(i);host.player.complete_busy();host.player.finish()
				if host.ship.camera_tween and host.ship.camera_tween.is_valid():host.ship.camera_tween.custom_step(2)
				await frames(10)
				check(host.ship.model_meshes.all(func(m):return m.visible),"No group deletion "+course)
				await capture("inspection-original-"+course);found=true;break
		check(found,"Original chapter sample "+course)
		host.go_home()
	await host.open_course("bulkheads","BH:longitudinal");await frames(4)
	host.bulkheads.player.complete_busy();host.bulkheads.player.finish()
	if host.bulkheads.ship.camera_tween and host.bulkheads.ship.camera_tween.is_valid():host.bulkheads.ship.camera_tween.custom_step(2)
	await frames(8)
	check(host.bulkheads.ship.detailed.visible and not host.bulkheads.ship.hull.visible,"6a authored hull")
	await capture("inspection-bulkheads")
	var failed:=results.filter(func(r):return not r.passed).size()
	var file:=FileAccess.open("res://modules/review/qa/inspection-all-results.json",FileAccess.WRITE);file.store_string(JSON.stringify(results,"\t"));file.close()
	print("INSPECTION ",results.size()," checks; failures ",failed)
	get_tree().quit(1 if failed else 0)
