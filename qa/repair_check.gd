extends "res://qa/formal_check.gd"
func screenshot(name_:String)->void:
	await frames(8)
	app.get_viewport().get_texture().get_image().save_png("res://qa/repair-20261023/"+name_+("-minimum" if "--minimum" in OS.get_cmdline_user_args() else "")+".png")
func hover_word(field:TextEdit,word:String,tip)->void:
	for line in field.get_line_count():
		var at:int=field.get_line(line).find(word)
		if at<0:continue
		var rect:Rect2i=field.get_rect_at_line_column(line,at+1)
		var event:=InputEventMouseMotion.new();event.position=field.global_position+Vector2(rect.get_center());app.get_viewport().push_input(event,true)
		await frames(2);return
	check(false,"Hover word found: "+word)
func start(target)->void:
	app=target
	if "--minimum" in OS.get_cmdline_user_args():get_window().size=Vector2i(1100,760)
	app.lang="ru";await app.open_course("basics","basics:opening");await settle()
	var tip=preload("res://modules/review/view/term_tooltip.gd").shared(app)
	await hover_word(app.caption,"су́дна",tip)
	check(tip.panel.visible and "船舶" in tip.words.text,"Homework native hover displays Chinese")
	await screenshot("homework-tooltip")
	app.go_home();await frames(2);check(not tip.panel.visible,"Tooltip hides on leaving chapter")
	await app.open_course("bulkheads","BH:webfore");await frames(12)
	if app.bulkheads.ship.camera_tween and app.bulkheads.ship.camera_tween.is_valid():app.bulkheads.ship.camera_tween.custom_step(1.0)
	app.bulkheads.player.complete_busy();app.bulkheads.player.finish();await frames(8)
	check(app.bulkheads.speech.panel.visible,"Bulkhead speech is placed after camera transition")
	await hover_word(app.bulkheads.speech.caption,"шпа́ция",tip)
	check(tip.panel.visible and "肋距" in tip.words.text,"Bulkhead native hover displays Chinese")
	check(not str(app.bulkheads.speech.caption.get_meta("source_phrase","")).is_empty(),"Teacher rule appears in purple speech")
	await screenshot("bulkhead-tooltip")
	app.go_home();app.lang="zh";await app.open_course("mass","T07:check");await settle()
	check(app.ship.get_global_rect().end.x<app.right.get_global_rect().position.x,"Model viewport ends before equation pane")
	var observation:=Vector3(app.ship.yaw,app.ship.pitch,app.ship.zoom)
	app.drawer_open=false;app.layout();await frames(5);app.drawer_open=true;app.layout();await frames(5)
	check(observation==Vector3(app.ship.yaw,app.ship.pitch,app.ship.zoom),"Drawer does not reset observer camera")
	await screenshot("mass-with-record")
	var glossary=preload("res://modules/review/core/glossary.gd").new()
	for word in ["ме́ньшей","недоста́точная","определи́ть","грузоподъёмность","прототи́па"]:check(not glossary.spans(word).is_empty(),"Inflection lookup "+word)
	for e in glossary.study_entries():check(e.ru not in ["мочь","ну́жно","бо́льше","ме́ньше","ме́ньший"],"Excluded basic word "+e.id)
	app.go_home();app.open_review("reading");await frames(3)
	var page=app.review.stability
	await app.review.open_topic("arrangement","R9Q39");await frames(5)
	for scene in ["bridge","width","forecastle","free_ok"]:
		var id:String={"bridge":"R9:R9Q39:1","width":"R9:R9Q40:1","forecastle":"R9:R9Q41:1","free_ok":"R9:R9Q17:1"}[scene]
		if scene=="free_ok":await app.review.open_topic("freeboard","R9Q17")
		for i in page.player.beats.size():
			if page.player.beats[i].id==id:page.goto_index(i);break
		page.player.complete_busy();page.player.finish();await frames(8)
		var view=page.topic_ship.active
		view.set_camera("topic",true)
		var s:Dictionary=page.current_state.duplicate(true)
		var low_y:=0.0
		for value in [0.0,.5,1.0]:
			s.p=value;view.apply(s,"zh");await frames(4)
			if scene=="bridge":
				var cabin=view.parts.filter(func(p):return str(p.name).begins_with("BridgeCabin"))[0]
				if value==0:low_y=cabin.global_position.y
				else:check(cabin.global_position.y>low_y,"Actual bridge rises at "+str(value))
				check(cabin.visible,"Actual bridge visible")
			if scene=="width":
				var walls=view.parts.filter(func(p):return str(p.name).begins_with("Enclosed"))[0]
				check(walls.visible and is_equal_approx(walls.scale.z,lerpf(1.,.62,value)),"Actual walls narrow at "+str(value))
			if scene=="forecastle" and value>0:check(view.parts.any(func(p):return str(p.name).begins_with("Forecastle") and p.visible),"Real forecastle visible")
			await screenshot(scene+"-"+str(value))
		if scene=="free_ok":
			s.p=3.;view.apply(s,"zh");await screenshot("free-short")
	var failed:int=results.filter(func(r):return not r.passed).size()
	var report=FileAccess.open("res://qa/repair-20261023/interaction"+("-minimum" if "--minimum" in OS.get_cmdline_user_args() else "")+".json",FileAccess.WRITE);report.store_string(JSON.stringify(results,"\t"));report.close()
	print("REPAIR ",results.size()," checks; failures ",failed);get_tree().quit(1 if failed else 0)
