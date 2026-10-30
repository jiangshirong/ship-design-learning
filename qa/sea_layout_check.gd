extends "res://modules/review/qa/topics_check.gd"
func start(target)->void:
	host=target;app=host.review;page=app.stability
	await frames(12)
	host.open_review("reading");await frames(4)
	await app.open_topic("freeboard")
	select_beat("M11:M11Q07:impact");await settle_topic()
	var v=page.topic_ship.active
	select_beat("M11:M11Q06:before");await settle_topic()
	host.get_window().size=Vector2i(1920,1170);await frames(8)
	v.cancel();v.camera.position=Vector3(-5,60,-100);v.turn_target=Vector3(55,9,0);v.camera.look_at(v.turn_target);v.camera.size=200
	var runtime_near:float=v.camera.near
	v.camera.near=.05
	await frames(8);await capture("sea-clip-reproduced")
	v.camera.near=runtime_near
	check(runtime_near<0,"Runtime signed orthographic range; no QA fixup")
	await frames(8);await capture("sea-clip-fixed-same-camera")
	for dimensions in [Vector2i(1440,900),Vector2i(1920,1170),Vector2i(1100,760)]:
		host.get_window().size=dimensions;await frames(10)
		for expanded in [false,true]:
			page.drawer_open=expanded;page.arrange();await frames(6)
			check(page.ship.size.y==page.size.y,"Scene fills page "+str(dimensions)+str(expanded))
			check(v.size==page.ship.size and v.container.size==v.size,"Container follows scene size")
			check(v.viewport.size==Vector2i(v.size),"Render target follows scene size")
		var picture:Image=v.viewport.get_texture().get_image()
		var reference:Color=picture.get_pixel(30,dimensions.y-30);var variation:=0
		for y in range(dimensions.y-150,dimensions.y-15,5):
			for x in range(20,250,5):
				var c:Color=picture.get_pixel(x,y)
				if absf(c.r-reference.r)+absf(c.g-reference.g)+absf(c.b-reference.b)>.002:variation+=1
		check(variation>50,"Sea texture continues under bottom controls "+str(dimensions))
		page.drawer_open=false;page.arrange();await frames(5)
		await capture("sea-layout-fixed-"+str(dimensions.x))
	# Reproduce both sides of the user's orbit, including a stern behind the eye.
	for pose in [[Vector3(5,45,70),Vector3(55,9,0)], [Vector3(-5,60,-100),Vector3(55,9,0)], [Vector3(35,28,-80),Vector3(55,9,0)], [Vector3(100,140,25),Vector3(55,9,0)]]:
		v.camera.position=pose[0];v.turn_target=pose[1];v.camera.look_at(v.turn_target);v.camera.size=240
		await frames(6)
		var misses:=0
		for x in [-98.,101.]:
			for y in [-11.,30.]:
				for z in [-20.,20.]:
					var depth:float=-(v.camera.to_local(Vector3(x,y,z))).z
					if depth<v.camera.near or depth>v.camera.far:misses+=1
		check(misses==0,"Whole ship survives free orbit "+str(pose[0]))
		var sea_misses:=0
		for x in range(10,int(v.size.x),50):
			for y in range(int(v.size.y*.70),int(v.size.y)-1,15):
				var origin:Vector3=v.camera.project_ray_origin(Vector2(x,y))
				var direction:Vector3=v.camera.project_ray_normal(Vector2(x,y))
				var t:float=-origin.y/direction.y
				var depth:float=-(v.camera.to_local(origin+direction*t)).z
				if depth<v.camera.near or depth>v.camera.far:sea_misses+=1
		check(sea_misses==0,"Bottom sea survives free orbit "+str(pose[0]))
		await capture("sea-clip-orbit-"+str(int(pose[0].y)))
	var before:Transform3D=v.camera.transform
	page.advance();await settle_topic()
	check(v.camera.transform.is_equal_approx(before),"D preserves observation camera")
	check(not page.bubble.panel.get_global_rect().intersects(page.progress.get_global_rect()),"Sentence avoids progress nodes")
	page.toggle_language();await frames(5);check(v.camera.transform.is_equal_approx(before),"F2 preserves camera")
	app.go_home();check(v.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED,"Hidden sea stops rendering")
	var failures:Array=results.filter(func(r):return not r.passed)
	var out=FileAccess.open("res://qa/sea-layout-results.json",FileAccess.WRITE);out.store_string(JSON.stringify({"checks":results.size(),"failures":failures,"results":results},"  "));out.close()
	print("SEA LAYOUT ",results.size()," checks; failures ",failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)
