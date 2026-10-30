extends "res://modules/review/qa/sample_check.gd"
var page
var marine
func select_beat(id:String)->void:
	for i in page.player.beats.size():
		if page.player.beats[i].id==id:page.goto_index(i);break
	await frames(3)
	if marine.camera_tween and marine.camera_tween.is_valid():marine.camera_tween.custom_step(2)
	await frames(6)
func pose(eye:Vector3,span:float=110)->void:
	marine.cancel();marine.turn_target=Vector3(-4,0,4);marine.camera.position=eye;marine.camera.look_at(marine.turn_target)
	marine.camera.size=span;marine.user_camera=true
func screenshot(name_:String)->void:
	await frames(4);await RenderingServer.frame_post_draw
	app.get_viewport().get_texture().get_image().save_png("res://qa/camera-q22-"+name_+".png")
func start(host)->void:
	app=host;host.open_review("reading");host.review.open_topic("damage");page=host.review.stability;marine=page.topic_ship.views.marine
	await frames(10)
	var policy=preload("res://modules/review/core/beat_observation.gd")
	for eye in [Vector3(-140,70,120),Vector3(110,65,160),Vector3(-50,160,80)]:
		for id in ["TOP:Q22:water","TOP:Q22:sink","TOP:Q22:heel"]:
			await select_beat(id);pose(eye);await frames(5)
			var result:Dictionary=policy.assess(marine.camera,marine.observation_region)
			check(result.mode=="hold","Whole action observable "+id+" "+str(eye))
			var before:Transform3D=marine.camera.transform;var span:float=marine.camera.size;var pivot:Vector3=marine.turn_target
			tap(KEY_E);await frames(5)
			check(marine.camera.transform.is_equal_approx(before),"Finish typing does not reframe "+id)
			if eye.x==-140 and id=="TOP:Q22:water":await screenshot("before")
			tap(KEY_E);await frames(6)
			check(page.player.phase=="playing","D starts action "+id)
			if page.player.animation and page.player.animation.is_valid():page.player.animation.custom_step(1.4)
			await frames(4)
			check(marine.camera.transform.is_equal_approx(before) and is_equal_approx(span,marine.camera.size) and marine.turn_target.is_equal_approx(pivot),"Position orientation zoom pivot remain unchanged "+id)
			if eye.x==-140 and id=="TOP:Q22:water":await screenshot("after")
			page.player.finish();await frames(3)
			tap(KEY_E);await frames(5)
			check(marine.camera.transform.is_equal_approx(before) and not marine.camera_motion,"Next beat preserves observable view after "+id)
	await select_beat("TOP:Q22:water");pose(Vector3(-140,70,120));await frames(3)
	var old=preload("res://view/camera_observability.gd")
	var normal:Vector3=(Vector3(48,75,175)-Vector3(5,2,0)).normalized()
	check(old.inspect(marine.camera,old.envelope(Vector3(5,2,0),normal,185,36,10),normal,.75).mode=="reframe","Reproduced old false rejection for useful custom view")
	pose(Vector3(0,15,-200));marine.set_camera("topic")
	check(marine.last_observation.reason=="closed_side" and marine.camera_motion,"Closed hull side still triggers useful view")
	if marine.camera_tween and marine.camera_tween.is_valid():marine.camera_tween.custom_step(2)
	await frames(5)
	check(policy.assess(marine.camera,marine.observation_region).mode=="hold","Fallback view satisfies declared region")
	pose(Vector3(-140,70,120));marine.camera.position+=marine.camera.basis.x*90
	var direction:Basis=marine.camera.basis
	marine.set_camera("topic")
	check(marine.last_observation.mode in ["nudge","fit"],"Offscreen region uses framing correction")
	if marine.camera_tween and marine.camera_tween.is_valid():marine.camera_tween.custom_step(2)
	await frames(4)
	check(marine.camera.basis.is_equal_approx(direction),"Framing correction preserves viewing direction")
	check(policy.assess(marine.camera,marine.observation_region).mode=="hold","Adjusted region becomes observable")
	await select_beat("TOP:Q22:answer");pose(Vector3(0,15,-200));var answer_pose:Transform3D=marine.camera.transform
	marine.set_camera("topic");check(marine.camera.transform.is_equal_approx(answer_pose),"Text-only answer never resets camera")
	var out:=FileAccess.open("res://qa/camera-q22.json",FileAccess.WRITE);out.store_string(JSON.stringify(results,"  "));out.close();get_tree().quit()

