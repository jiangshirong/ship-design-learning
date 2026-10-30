extends "res://qa/formal_check.gd"
func start(target)->void:
	app=target;await frames(5);app.lang="zh"
	await app.open_course("load","L01:weighted");await settle()
	var start:Array=[app.ship.points[0].position,app.ship.points[1].position]
	for id in ["L01:weighted","L01:moment_area","L01:equivalent"]:
		go_to(id);await settle()
		check(app.ship.visible and not app.concept.visible,id+" uses actual ship scene")
		check(app.ship.fuel_pair.visible and not app.ship.fuel_locations.visible,id+" only pair overlay shown")
		for i in range(2):
			var oil:MeshInstance3D
			for mesh in app.ship.model_meshes:
				if app.ship.load_model.is_ancestor_of(mesh) and mesh.get_meta("zone")=="Fuel%02dOil"%[i+1]:oil=mesh
			check(oil!=null and oil.is_visible_in_tree(),id+" actual oil "+str(i+1)+" visible")
			var bounds:AABB=oil.global_transform*oil.get_aabb()
			check(bounds.get_center().distance_to(app.ship.points[i].position)<.0001,id+" G is at oil centre")
			check(absf(bounds.end.x-app.ship.points[i].position.x)>5,id+" G is not tank endpoint")
			check(app.ship.points[i].position==start[i],id+" source tank not moved")
			var d:Dictionary=app.ship.fuel_pair.dimensions[i]
			check(absf(float(d.x)-[97,67][i])<.0001,id+" dimension reads original centroid x")
			check(Rect2(Vector2.ZERO,app.ship.size).has_point(d.a) and Rect2(Vector2.ZERO,app.ship.size).has_point(d.b),id+" full coordinate span in view")
			check(d.centre.distance_to(app.ship.fuel_pair.project(app.ship.points[i].position))<.01,id+" extension terminates at oil centre")
		for lang in ["zh","ru"]:
			if app.lang!=lang:app.toggle_language()
			await frames(8)
			check(not app.caption.get_v_scroll_bar().visible and not app.caption.get_h_scroll_bar().visible,id+lang+" no dialogue scrollbar")
			check(app.caption.size.y>=app.caption.get_total_visible_line_count()*app.caption.get_line_height(),id+lang+" full dialogue fits")
			check(Rect2(Vector2.ZERO,app.speech.size).encloses(app.speech.panel.get_rect()),id+lang+" dialogue in canvas")
			for tag in app.ship.fuel_pair.tags:
				check(not tag.rect.intersects(app.speech.panel.get_rect()),id+lang+" label not covered by dialogue")
			var tags:Array=app.ship.fuel_pair.tags
			for i in range(tags.size()):
				for j in range(i+1,tags.size()):
					check(not tags[i].rect.intersects(tags[j].rect),id+lang+" spatial labels do not overlap "+str(i)+"/"+str(j))
			for d in app.ship.fuel_pair.dimensions:
				var line_rect:=Rect2(d.a,Vector2.ZERO).expand(d.b).grow(3)
				for tag in tags:
					check(not tag.rect.intersects(line_rect),id+lang+" label does not hide coordinate dimension")
			await capture("pair-"+id.split(":")[1]+"-"+lang)
	# Rendering Vector3 uses single precision; the formula retains double precision.
	check(absf(app.ship.pair_centre().x+75-85.29268292682927)<1e-5,"Rendered pair x matches calculation within 0.01 mm")
	check(app.ship.pair_centre().distance_to(app.ship.points[0].position)<app.ship.pair_centre().distance_to(app.ship.points[1].position),"Combined centre nearer heavier tank")
	go_to("L01:moment_area")
	if app.ship.camera_tween:app.ship.camera_tween.custom_step(1)
	await frames(12);app.player.complete_busy();app.player.play();app.player.animation.custom_step(1.1)
	check(float(app.values.pair_measure)>0 and float(app.values.pair_measure)<1,"Dimension animates continuously")
	var snapshot:Dictionary=app.player.state.duplicate(true);app.toggle_language()
	check(app.player.state==snapshot,"Language switch preserves measurement animation")
	go_to("L01:equivalent");await settle();go_to("L01:weighted");await settle()
	check(float(app.state.pair_merge)==0 and float(app.state.pair_measure)==0,"Backward jump removes future dimensions and result")
	go_to("L01:meaning");await settle();check(not app.ship.fuel_pair.visible,"Pair overlay ends with segment")
	await app.open_course("load","L01:moment_area");await settle()
	check(app.beat.id=="L01:moment_area" and app.ship.fuel_pair.visible,"Old saved ID enters new spatial explanation")
	tap(KEY_ESCAPE);await frames(3);check(app.mode=="home","Escape returns to menu")
	check(app.get_window().get_flag(Window.FLAG_NO_FOCUS),"QA no-focus window")
	app.lang="ru";await app.open_course("dimensions","T16:pass");app.store.data.language="ru";app.save_progress()
	var output:=FileAccess.open("res://qa/pair-"+("minimum" if "--minimum" in OS.get_cmdline_user_args() else "normal")+".json",FileAccess.WRITE)
	output.store_string(JSON.stringify(results,"\t"));output.close()
	print("PAIR ",results.size()," checks")
	get_tree().quit(0 if results.all(func(r):return r.passed) else 1)
