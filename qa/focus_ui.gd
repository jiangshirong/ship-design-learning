extends "res://modules/review/qa/sample_check.gd"
func shot(name_:String)->void:
	await frames(8);await RenderingServer.frame_post_draw
	app.get_viewport().get_texture().get_image().save_png("res://qa/d-"+name_+".png")
func start(host)->void:
	app=host;host.lang="zh";host.show_home()
	await frames(15);await shot("home")
	await click(host.review_buttons.get_child(0).get_global_rect().get_center());await frames(8)
	var reading=host.review.reading
	check(host.review.mode=="reading","Home question button opens reading")
	check(not reading.listing.visible and not reading.answer_panel.visible,"Navigation and answers initially hidden")
	reading.select_question(14);await frames(8);await shot("question")
	tap(KEY_SPACE);await frames(8);check(reading.answer_panel.visible,"Space reveals bottom answer sheet");await shot("answer")
	await click(reading.nav_button.get_global_rect().get_center());await frames(5);check(reading.listing.visible,"Topic navigation opens");await shot("nav")
	await click(reading.nav_button.get_global_rect().get_center())
	host.review.open_question_animation("N13");await frames(20)
	var topic=host.review.stability
	check(topic.visible,"Topic animation opened")
	for i in topic.player.beats.size():
		if topic.player.beats[i].id=="TOP:N13:measure":topic.goto_index(i);break
	await frames(8)
	var marine=topic.topic_ship.views.marine
	if marine.camera_tween and marine.camera_tween.is_valid():marine.camera_tween.custom_step(2)
	await frames(15)
	topic.player.complete_busy();await frames(5)
	await shot("teaching")
	var transform:Transform3D=marine.camera.transform;var span:float=marine.camera.size
	marine.set_camera("topic");await frames(3)
	check(marine.visibility_decision=="hold" and marine.camera.transform.is_equal_approx(transform) and is_equal_approx(span,marine.camera.size),"Observable camera remains unchanged")
	marine.camera.position.z=220;marine.camera.look_at(marine.turn_target)
	marine.set_camera("topic")
	check(marine.visibility_decision=="reframe","Wrong-side camera reframes")
	if marine.camera_tween and marine.camera_tween.is_valid():marine.camera_tween.custom_step(2)
	await frames(8)
	check(not topic.right.visible,"Formula drawer closed initially")
	var old_size:Vector2=topic.ship.size
	await click(topic.formula_toggle.get_global_rect().get_center());await frames(5)
	check(topic.right.visible and topic.ship.size==old_size,"Drawer overlays without resizing viewport")
	await shot("drawer");tap(KEY_ESCAPE);await frames(5)
	check(reading.revealed and reading.index==14,"Esc preserves reading reveal and selection")
	tap(KEY_ESCAPE);await frames(5)
	await click(host.review_buttons.get_child(1).get_global_rect().get_center());await frames(5)
	var v=host.review.vocabulary;v.path="user://review/qa-focus-words.json";v.marks={};v.schedule={}
	await click(v.menu.get_child(0).get_global_rect().get_center());await frames(5);await shot("word")
	check(not v.grades.visible,"Ratings hidden before revealing word")
	var id:String=v.entries[v.index].id
	tap(KEY_SPACE);await frames(3);await shot("word-reveal");tap(KEY_3);await frames(3)
	check(v.marks.get(id,"")=="不熟" and not v.revealed and v.entries[v.index].id!=id,"3 saves grade and advances")
	host.get_window().size=Vector2i(1100,760);await frames(10);await shot("small-word")
	host.show_home();host.open_review("reading");reading.select_question(14);reading.reveal();await frames(10);await shot("small-answer")
	check(reading.panel.size.x>500 and reading.answer_panel.get_rect().end.y<=host.size.y,"Minimum window keeps content bounds")
	host.show_home();await host.open_course("foundation");await frames(15)
	check(host.ship.size.x==host.size.x,"Original lesson uses full viewport")
	host.player.current=3;host.player.prepare();await frames(30);await shot("original")
	await host.open_bulkheads();await frames(10)
	check(host.bulkheads.ship.size.x==host.size.x,"Bulkhead chapter uses full viewport")
	host.bulkheads.player.current=4;host.bulkheads.player.prepare();await frames(10)
	if host.bulkheads.ship.camera_tween and host.bulkheads.ship.camera_tween.is_valid():host.bulkheads.ship.camera_tween.custom_step(2)
	await shot("bulkhead")
	host.show_home();host.get_window().size=Vector2i(1440,900)
	for c in host.review.stability.courses:
		host.open_review("reading");host.review.open_topic(c.id);await frames(4)
		var page=host.review.stability
		page.goto_group(page.course.groups.size()-1,true);await frames(4)
		page.toggle_language();await frames(3)
		check(page.language=="ru" and page.phase_menu.item_count==page.course.groups.size(),"Topic stage navigation and F2: "+c.id)
		tap(KEY_ESCAPE);await frames(2)
		check(host.review.mode=="reading","Topic Esc: "+c.id)
	# A translated term remains backed by the same dictionary in its new layout.
	check(host.review.reading.question is TextEdit,"Russian question retains native selectable term lookup")
	var f:=FileAccess.open("res://qa/d-results.json",FileAccess.WRITE);f.store_string(JSON.stringify(results,"  "));f.close()
	get_tree().quit(0)

