extends "res://modules/review/qa/sample_check.gd"
var page
func select_beat(id:String)->void:
	for i in page.player.beats.size():
		if page.player.beats[i].id==id:page.goto_index(i);break
	page.player.complete_busy()
	if page.player.phase=="ready":page.player.finish()
	await frames(5)
	var marine=page.topic_ship.views.marine
	if marine.camera_tween and marine.camera_tween.is_valid():marine.camera_tween.custom_step(2)
	await frames(12)
func start(host)->void:
	app=host;host.open_review("reading");host.review.open_topic("damage")
	page=host.review.stability;await frames(8)
	await select_beat("TOP:N12:answer")
	check(not page.condition.visible,"Answer recap absent from calculation panel")
	await select_beat("TOP:Q22:water")
	var marine=page.topic_ship.views.marine
	marine.cancel();marine.camera.position=Vector3(0,-60,-200);marine.camera.look_at(Vector3.ZERO)
	var original:Transform3D=marine.camera.transform
	var state:Dictionary=page.player.state.duplicate(true)
	await click(page.bubble.caption.get_global_rect().get_center())
	check(marine.camera_motion,"Click actual caption starts camera motion")
	if marine.camera_tween and marine.camera_tween.is_valid():marine.camera_tween.custom_step(2)
	await frames(12)
	check(not marine.camera.transform.is_equal_approx(original) and marine.camera.position.z>0,"Damage caption returns to visible cut side")
	check(page.player.state==state,"Caption click preserves animation state")
	var point:Vector2=page.bubble.caption.get_global_rect().position+Vector2(12,12)
	var down:=InputEventMouseButton.new();down.position=point;down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;host.get_viewport().push_input(down,true)
	var move:=InputEventMouseMotion.new();move.position=point+Vector2(50,0);move.relative=Vector2(50,0);move.button_mask=MOUSE_BUTTON_MASK_LEFT;host.get_viewport().push_input(move,true)
	var up:=InputEventMouseButton.new();up.position=move.position;up.button_index=MOUSE_BUTTON_LEFT;up.pressed=false;host.get_viewport().push_input(up,true)
	await frames(2);check(not marine.camera_motion,"Text selection does not refocus")
	host.show_home();await host.open_course("basics");await frames(8)
	for i in host.player.beats.size():
		if host.player.beats[i].get("anchor","")=="ship" and not host.player.beats[i].get("opening",false):
			host.jump_to_step(i);break
	if host.ship.camera_tween and host.ship.camera_tween.is_valid():host.ship.camera_tween.custom_step(2)
	if host.layout_tween and host.layout_tween.is_valid():host.layout_tween.custom_step(2)
	host.player.complete_busy();await frames(15)
	check(host.speech.panel.is_visible_in_tree() and not host.concept.visible,"Original 3D caption is visible")
	host.ship.yaw=2.5;host.ship.update_camera()
	await click(host.caption.get_global_rect().get_center())
	check(host.ship.camera_motion,"Original lesson caption focuses camera")
	host.show_home();await host.open_bulkheads();await frames(8)
	if host.bulkheads.ship.camera_tween and host.bulkheads.ship.camera_tween.is_valid():host.bulkheads.ship.camera_tween.custom_step(2)
	host.bulkheads.player.complete_busy();await frames(15)
	await click(host.bulkheads.speech.caption.get_global_rect().get_center())
	check(host.bulkheads.ship.camera_tween and host.bulkheads.ship.camera_tween.is_running(),"Bulkhead caption focuses camera")
	var f:=FileAccess.open("res://qa/bubble-focus.json",FileAccess.WRITE);f.store_string(JSON.stringify(results,"  "));f.close()
	get_tree().quit()
