extends "res://qa/formal_check.gd"
var page
func screenshot(name_:String)->void:
	await frames(8)
	app.get_viewport().get_texture().get_image().save_png("res://qa/repair-"+name_+".png")
func topic_step(id:String)->void:
	for i in page.player.beats.size():
		if page.player.beats[i].id==id:page.goto_index(i);break
	await frames(8)
	page.player.complete_busy()
	if page.player.phase=="ready":page.player.finish()
	await frames(12)
func start(host)->void:
	app=host;app.lang="zh";await frames(5)
	for spec in [["dimensions","T12:stability"],["dimensions","T11:total"],["mass","T02:fuel"],["supplement","reserve:volume"]]:
		await app.open_course(spec[0],spec[1]);await settle()
		var math=app.equations.entries[spec[1]].math
		check(not math.latex_text.contains("B_1M"),"No beam/metacentre substitution "+spec[1])
		check(math.render_errors==0,"Formula rendered "+spec[1])
		if spec[1] in ["T12:stability","T11:total"]:
			check(not math.source_blocks.is_empty(),"Teacher formula marking "+spec[1])
			for block in math.source_blocks:
				check(math._get_tooltip(block.rect.position+Vector2(3,3)).is_empty(),"No provenance popup")
		if spec[1]=="T11:total":
			check(math.hint_regions.any(func(h):return h.text.contains("干舱室")),"Coefficient meaning on hover")
		await screenshot(spec[1].replace(":","-")+"-zh")
		app.toggle_language();await frames(12)
		check(not app.speech.caption.full_text.is_empty(),"Russian sentence present")
		check(not app.speech.panel.get_global_rect().intersects(app.right.get_global_rect()),"Russian bubble outside history "+spec[1])
		check(app.speech.panel.get_global_rect().position.y>=112,"Bubble below stage navigation "+spec[1])
		for child in app.phase_menu.track.get_children():
			check(child.position.x+child.size.x<=app.phase_menu.track.size.x,"Stage title within track")
		app.lang="zh"
	await app.open_course("dimensions","T13:iteration2");await settle()
	check(app.beat.id=="T13:trace","Old solver progress maps to complete record")
	check(app.equations.entries["T13:trace"].math.latex_text.contains("n=1"),"Merged trace retains first iteration")
	check(app.equations.entries["T13:trace"].math.latex_text.contains("n=31"),"Merged trace retains last iteration")
	app.go_home();app.open_review("reading");await frames(10)
	await app.review.open_topic("stability");page=app.review.stability;await frames(15)
	await topic_step("ST:peak")
	check(not page.drawer_open and not page.right.visible,"History remains optional")
	check(page.chart.is_visible_in_tree(),"Curve visible with history closed")
	check(page.condition.is_visible_in_tree(),"Comparison conditions visible with history closed")
	check(not page.evidence.get_rect().intersects(page.parameters.get_rect()),"Evidence above parameter controls")
	await screenshot("stability-curve-1440")
	get_window().size=Vector2i(1100,700);await frames(20)
	page.toggle_language();await frames(15)
	check(page.evidence.get_rect().end.y<page.parameters.position.y,"Minimum Russian evidence fits")
	check(page.condition.get_v_scroll_bar().max_value<=page.condition.get_v_scroll_bar().page,"Condition has no hidden scroll")
	await screenshot("stability-curve-1100-ru")
	for q in ["Q16","Q17","Q18","Q20","Q21"]:
		check(page.player.beats.filter(func(b):return b.id in ["ST:"+q+":answer","TOP:"+q+":answer"]).size()==1,"Single conclusion "+q)
	page.store.data.foundation_done=true;page.store.data.beat="TOP:Q20:answer";page.persist()
	await app.review.open_topic("stability");await frames(12)
	check(page.beat.id=="ST:Q20:answer","Old duplicate answer progress restored")
	get_window().size=Vector2i(1440,900);await frames(10)
	await app.review.open_topic("damage");page=app.review.stability;await frames(12)
	await topic_step("TOP:Q25:symmetry")
	var marine=page.topic_ship.active
	check(marine.bodies[0].rotation.z<0,"Forepeak flooding bows down")
	var normal:Vector3=marine.bodies[0].basis.transposed()*Vector3.UP
	check((marine.bodies[0].basis*normal).is_equal_approx(Vector3.UP),"Liquid normal remains world vertical")
	await screenshot("forepeak-trim")
	await topic_step("TOP:N10:limit")
	check(is_zero_approx(marine.bodies[0].rotation.z),"Next scenario resets trim")
	await app.review.open_topic("freeboard");page=app.review.stability;await frames(12)
	await topic_step("TOP:N16:sheer");marine=page.topic_ship.active
	var sheer_top:Vector3=marine.bow_deck_point()
	check(sheer_top.y>15,"Bow dimension follows raised deck")
	await screenshot("bow-sheer")
	await topic_step("TOP:N16:forecastle")
	check(page.current_state.sheer==0 and page.current_state.forecastle==1,"Bow comparisons restore common base")
	var base_height:float=marine.ring_at(marine.bow_deck_point().x).map(func(v):return v.y).max()
	check(absf(marine.bow_deck_point().y-base_height-5)<.01,"Forecastle dimension reaches its deck")
	await screenshot("bow-forecastle")
	var f=FileAccess.open("res://qa/curriculum-repairs-runtime.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(results,"  "));f.close()
	print("CURRICULUM REPAIRS ",results.size()," checks; ",results.filter(func(r):return not r.passed).size()," failures")
	get_tree().quit(0 if results.all(func(r):return r.passed) else 1)
