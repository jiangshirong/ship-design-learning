extends "res://modules/review/qa/topics_check.gd"

func drag_view(view,relative:Vector2)->void:
	var point:Vector2=view.global_position+view.size*Vector2(.2,.2)
	var move:=InputEventMouseMotion.new();move.position=point
	app.get_viewport().push_input(move,true)
	var down:=InputEventMouseButton.new();down.position=point;down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true
	app.get_viewport().push_input(down,true)
	move=InputEventMouseMotion.new();move.position=point;move.relative=relative;move.button_mask=MOUSE_BUTTON_MASK_LEFT
	app.get_viewport().push_input(move,true)
	var up:=InputEventMouseButton.new();up.position=point;up.button_index=MOUSE_BUTTON_LEFT;up.pressed=false
	app.get_viewport().push_input(up,true)
	await frames(3)

func start(target)->void:
	host=target;app=host.review;page=app.stability
	await frames(12)
	host.lang="zh"
	await host.open_course("basics","parts:hull")
	host.ship.cancel_camera();host.ship.restore({"yaw":-.48,"pitch":.4,"zoom":1})
	await frames(10)
	await drag_view(host.ship,Vector2(0,-230))
	check(host.ship.pitch<0,"Original course allows underside orbit")
	await capture("camera-original-underside")
	host.go_home();host.open_review("reading");await frames(5)
	await app.open_topic("damage","N10");await frames(5)
	if page.language!="zh":tap(KEY_F2);await frames(2)
	var marine=page.topic_ship.views.marine
	var identity:int=marine.detailed_ship.get_instance_id()
	check(marine.detailed_ship.parts.size()>30,"Detailed ship components loaded")
	check(marine.liquids.size()==13,"Twelve cargo cells plus forepeak")
	var names:Array=[]
	for part in marine.detailed_ship.parts:names.append(str(part.name))
	check(names.any(func(n):return n.begins_with("Bulkheads")),"Authored cargo bulkheads retained")
	check(names.any(func(n):return n.begins_with("DoubleBottom")),"Double bottom retained")
	check(names.any(func(n):return n.begins_with("PeakBulkhead")),"Forepeak bulkhead present")
	for id in ["TOP:damage:goal","TOP:damage:cutaway","TOP:damage:frames","TOP:damage:wall_height","TOP:damage:foundation_end","TOP:Q22:water","TOP:N10:limit","TOP:Q25:forepeak"]:
		select_beat(id);await settle_topic()
		check(marine.detailed_ship.get_instance_id()==identity,"Same model "+id)
		check(marine.detailed_ship.visible and not marine.shells[0].visible and not marine.fittings[0].visible,"Detailed hull only "+id)
		check(page.bubble.panel.visible,"Explanation visible "+id)
		await capture("damage-"+id.replace(":","-"))
	select_beat("TOP:damage:goal");await settle_topic()
	var distance:float=marine.camera.position.distance_to(marine.turn_target)
	await drag_view(marine,Vector2(0,-230))
	check(marine.camera.position.y<marine.turn_target.y,"Review course allows underside orbit")
	check(absf(marine.camera.position.distance_to(marine.turn_target)-distance)<.01,"Orbit keeps radius")
	check(not marine.dragging,"Mouse release ends orbit")
	await capture("camera-review-underside")
	select_beat("TOP:N10:limit");await settle_topic()
	tap(KEY_F2);await frames(5)
	check(marine.detailed_ship.get_instance_id()==identity,"Language switch keeps model")
	await capture("damage-bulkheads-ru")
	tap(KEY_ESCAPE);await frames(4)
	check(not page.player.active,"Exit stops playback")
	await app.open_topic("cargo","Q11");await frames(4)
	select_beat("Q11:underwater");await settle_topic()
	var hold=page.topic_ship.views.hold
	if hold.camera_tween and hold.camera_tween.is_valid():hold.camera_tween.custom_step(2)
	await frames(3);await drag_view(hold,Vector2(0,-280))
	check(hold.pitch<0,"Cargo view allows underside orbit")
	tap(KEY_ESCAPE);await frames(3);host.show_home()
	await host.open_course("bulkheads","BH:opening");await frames(4)
	var bulk=host.bulkheads.ship
	if bulk.camera_tween and bulk.camera_tween.is_valid():bulk.camera_tween.custom_step(2)
	await frames(4);await drag_view(bulk,Vector2(0,-280))
	check(bulk.eye.y<bulk.focus.y,"Bulkhead course allows underside orbit")
	check(not bulk.orbiting and not bulk.dragging,"Bulkhead orbit release")
	var failed:=results.filter(func(r):return not r.passed).size()
	var file:=FileAccess.open("res://modules/review/qa/damage-cutaway-results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"\t"));file.close()
	print("Damage cutaway: ",results.size()," checks; failures=",failed)
	get_tree().quit(1 if failed else 0)
