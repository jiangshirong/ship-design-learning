extends "res://modules/review/qa/topics_check.gd"
func finish_player(p)->void:
	p.complete_busy()
	if p.phase=="ready":p.finish()
func start(target)->void:
	host=target;app=host.review;page=app.stability
	await frames(10)
	for id in ["stability","damage","freeboard","cargo"]:
		host.open_review("reading");await app.open_topic(id)
		await settle_topic()
		var view=page.ship
		if view==page.topic_ship:view=page.topic_ship.active
		view.cancel()
		# User-chosen transform, deliberately different from every preset.
		view.camera.position+=Vector3(3,4,5);view.camera.size*=.91
		var pose:Transform3D=view.camera.transform;var span:float=view.camera.size
		for key in [KEY_E,KEY_E,KEY_E,KEY_Q]:
			tap(key);await frames(4)
			check(view.camera.transform.is_equal_approx(pose) and is_equal_approx(view.camera.size,span),id+" camera retained "+str(key))
			finish_player(page.player);await frames(2)
		app.suspend()
	await host.open_course("basics")
	await frames(55)
	host.ship.cancel_camera();host.ship.yaw=.73;host.ship.pitch=-.3;host.ship.zoom=.86;host.ship.update_camera()
	var original:Transform3D=host.ship.camera.transform
	finish_player(host.player)
	for key in [KEY_E,KEY_E,KEY_Q]:
		tap(key);await frames(4)
		check(host.ship.camera.transform.is_equal_approx(original),"Original course retains view "+str(key))
		finish_player(host.player)
	await host.open_bulkheads()
	await frames(55)
	var bulk=host.bulkheads
	if bulk.ship.camera_tween and bulk.ship.camera_tween.is_valid():bulk.ship.camera_tween.kill()
	bulk.ship.eye+=Vector3(8,-5,10)
	await frames(3)
	var pose:Transform3D=bulk.ship.camera.transform
	finish_player(bulk.player)
	for key in [KEY_E,KEY_E,KEY_Q]:
		tap(key);await frames(4)
		check(bulk.ship.camera.transform.is_equal_approx(pose),"Bulkheads retains view "+str(key))
		finish_player(bulk.player)
	var failed:=results.filter(func(r):return not r.passed).size()
	var file:=FileAccess.open("res://qa/camera-free-results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"\t"))
	print("Free camera: ",results.size()," checks; failures=",failed)
	get_tree().quit(1 if failed else 0)

