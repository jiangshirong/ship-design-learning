extends "res://modules/review/qa/sample_check.gd"
var host
var page
func settle_topic()->void:
	if page.ship.camera_motion:
		if page.ship==page.original_ship:
			if page.ship.camera_tween and page.ship.camera_tween.is_valid():page.ship.camera_tween.custom_step(2)
		elif page.topic_ship.active and page.topic_ship.active.camera_tween and page.topic_ship.active.camera_tween.is_valid():page.topic_ship.active.camera_tween.custom_step(2)
	await frames(4)
	page.player.complete_busy()
	if page.player.phase=="ready":page.player.finish()
	await frames(7)
func select_beat(id:String)->void:
	for i in page.player.beats.size():
		if page.player.beats[i].id==id:page.goto_index(i);return
	check(false,"Unknown beat "+id)
func start(target)->void:
	if "--minimum" in OS.get_cmdline_user_args():get_window().size=Vector2i(1100,760)
	host=target;app=host.review;page=app.stability
	await frames(12)
	check(host.mode=="home","Launcher starts home")
	await click(host.review_buttons.get_child(0).get_global_rect().get_center());await frames(8)
	var r=app.reading
	check(r.entries.size()==62,"62 unique cards")
	check(r.topics.size()==9,"9 topic tree groups")
	var aliases:Array=[]
	for q in r.entries:aliases.append_array(q.sources)
	check(aliases.size()==90,"90 source references")
	check(r.listing is Tree,"Reading uses native expandable tree")
	r.rebuild_filter()
	await capture("topics-tree")
	for i in r.entries.size():
		r.select_question(i);await frames(2)
		check(not r.revealed and not r.details.visible,"Answer hidden "+r.entries[i].id)
		tap(KEY_F);await frames(2)
		check(r.revealed,"Reveal "+r.entries[i].id)
		await click(r.animation_button.get_global_rect().get_center());await frames(3)
		check(app.mode=="stability" and page.course.id==r.entries[i].topic,"Topic route "+r.entries[i].id)
		check(page.store.data.pending==r.entries[i].id,"Pending first question "+r.entries[i].id)
		tap(KEY_ESCAPE);await frames(2)
		check(app.mode=="reading" and r.index==i and r.revealed,"Return original "+r.entries[i].id)
		check(not page.player.active,"Hidden player stopped")
	for course in r.topics:
		await app.open_topic(course.id);await frames(3)
		page.goto_group(1,true);await frames(2)
		check(not page.store.data.foundation_done and page.store.data.pending=="","Manual skip does not complete foundation "+course.id)
		await app.open_topic(course.id);await frames(2)
		var shape:int=page.ship.get_instance_id()
		var pcount:int=page.player.beats.size()
		for i in pcount:
			page.goto_index(i);await settle_topic()
			check(page.ship.get_instance_id()==shape,"Persistent view "+page.beat.id)
			check(page.bubble.panel.visible,"Bubble visible "+page.beat.id)
			check(page.bubble.caption.get_v_scroll_bar().max_value<=page.bubble.caption.get_v_scroll_bar().page,"Bubble unclipped "+page.beat.id)
			check(page.player.phase in ["settled","complete"],"Stable step "+page.beat.id)
			for entry in page.records.entries.values():
				check(entry.math.render_errors==0 and entry.math.slot_overflows==0,"Formula "+page.beat.id)
			if page.beat.id in ["TOP:N01:width","TOP:N02:goal","TOP:Q22:water","TOP:Q22:heel","TOP:N13:measure","TOP:N16:sheer","TOP:N16:forecastle"]:
				await capture("topics-"+page.beat.id.replace(":","-"))
		check(page.player.current==pcount-1,"Topic has end "+course.id)
		page.advance();check(page.player.current==pcount-1,"No cross-topic autoplay "+course.id)
		# First-entry prerequisite completes and returns the precise requested stage.
		page.store.data.foundation_done=false;page.store.data.beat=course.groups[0].beats[0].id;page.persist()
		var last_q:String=course.questions[-1]
		await app.open_topic(course.id,last_q);await settle_topic()
		# Walk to the last foundation beat without clearing pending.
		for i in page.player.beats.size():
			if page.player.beats[i].id==course.foundation_end:page.player.current=i;page.player.prepare();break
		await settle_topic();page.advance();await frames(3)
		check(page.store.data.foundation_done and page.beat.id==course.question_targets[last_q],"Foundation handoff "+course.id)
		app.go_home();await app.open_topic(course.id,last_q);await frames(3)
		check(page.beat.id==course.question_targets[last_q],"Direct revisit "+course.id)
		page.advance();await frames(2)
		var no_repeat:String=page.beat.id
		var repeat:=InputEventKey.new();repeat.physical_keycode=KEY_E;repeat.pressed=true;repeat.echo=true;app.get_viewport().push_input(repeat,true);await frames(2)
		check(page.beat.id==no_repeat,"Held E does not skip "+course.id)
		var before:Dictionary=page.player.state.duplicate(true)
		tap(KEY_F2);await frames(3);check(page.player.state==before,"F2 keeps state "+course.id)
		await capture("topics-"+course.id+"-ru")
		tap(KEY_ESCAPE);await frames(2)
	# Data and persistence checks independent of animation.
	var Store=load("res://modules/review/core/topic_store.gd")
	var saved=Store.new();saved.path=page.topic_store.path;saved.read_file()
	check(saved.data==page.topic_store.data,"All topic progress reopens")

	var existing:Dictionary=saved.data.duplicate(true)
	for c in r.topics:saved.select_topic(c,{"Q01":"old"},true)
	check(saved.data==existing,"New progress wins on repeat migration")
	var corrupt=Store.new();corrupt.path="user://review/qa-topics-corrupt.json"
	var f:=FileAccess.open(corrupt.path,FileAccess.WRITE);f.store_string("{broken");f.close()
	corrupt.read_file();corrupt.select_topic(r.topics[0],{},true);corrupt.put({"beat":"x","foundation_done":false,"pending":"","language":"zh"})
	check(corrupt.blocked and FileAccess.get_file_as_string(corrupt.path)=="{broken","Corrupt progress retained")
	var legacy_path:="user://review/qa-topics-legacy.json"
	var legacy_data:={"version":1,"beat":"ST:Cmove","foundation_done":true,"pending":"","language":"ru"}
	var legacy_file:=FileAccess.open(legacy_path,FileAccess.WRITE);legacy_file.store_string(JSON.stringify(legacy_data));legacy_file.close()
	var migrated=Store.new();migrated.path="user://review/qa-topics-migration.json"
	var st_course:Dictionary=r.topics.filter(func(c):return c.id=="stability")[0]
	var migrated_record:Dictionary=migrated.select_topic(st_course,{},false,legacy_path)
	check(migrated_record.beat=="ST:Cmove" and migrated_record.foundation_done and migrated_record.language=="ru","Legacy stability progress imported")
	check(FileAccess.get_file_as_string(legacy_path)==JSON.stringify(legacy_data),"Legacy source untouched")
	migrated_record.beat="TOP:N01:goal";migrated.put(migrated_record)
	check(migrated.select_topic(st_course,{},false,legacy_path).beat=="TOP:N01:goal","Existing new position wins over legacy")
	var bad_legacy=Store.new();bad_legacy.path="user://review/qa-topics-bad-migration.json"
	bad_legacy.select_topic(st_course,{},false,corrupt.path)
	check(bad_legacy.blocked and FileAccess.get_file_as_string(corrupt.path)=="{broken","Corrupt legacy blocks overwrite")
	var load_course:Dictionary=r.topics.filter(func(c):return c.id=="loads")[0]
	var mapped=Store.new()
	var mapped_record:Dictionary=mapped.select_topic(load_course,{"Q02":"Q02:capacity","Q09":"Q09:s2"},false,"","Q09")
	check(mapped_record.beat==load_course.question_targets.Q09,"Legacy selected question maps to its stage")
	var math=load("res://modules/review/core/stability_math.gd")
	var a:Dictionary=math.values({});var b:Dictionary=math.values({"display_scale":2})
	check(is_equal_approx(a.h/a.B,b.h/b.B),"Similarity preserves relative h")
	check(is_equal_approx(b.volume/a.volume,8),"Similarity scales volume cubically")
	check(is_equal_approx(b.period/a.period,sqrt(2)),"Similarity scales effective radius too")
	# Actual animation midpoint, not only settled endpoint.
	await app.open_topic("stability","N01");select_beat("TOP:N01:width");await frames(5)
	page.player.complete_busy();page.player.play();page.player.animation.pause();page.player.animation.custom_step(1.5);await frames(3)
	check(page.current_state.route=="narrow" and absf(page.current_state.morph-.5)<.01,"Narrow hull interpolates midway")
	check(is_equal_approx(page.ship.metrics.B,math.values(page.current_state).B),"Midpoint geometry and formula share B")
	page.retreat();await frames(3);check(page.player.phase in ["settled","complete"],"Busy A completes current action first")
	page.retreat();await frames(3);check(page.beat.id=="TOP:N01:goal","Second Q retreats")
	app.go_home()
	for test in [
		["stability","N02","TOP:N02:goal","display_scale",1.5],
		["damage","Q22","TOP:Q22:water","flood",.5],
		["damage","N12","TOP:N12:opening","heel_demo",14.0],
		["freeboard","N13","TOP:N13:reserve","draft",9.5],
		["freeboard","N16","TOP:N16:sheer","sheer",.5]]:
		await app.open_topic(test[0],test[1]);select_beat(test[2]);await frames(3)
		page.player.complete_busy();page.player.play();page.player.animation.pause();page.player.animation.custom_step(1.5);await frames(2)
		check(absf(float(page.current_state[test[3]])-float(test[4]))<.01,"Continuous midpoint "+test[2])
		var current:Dictionary=page.current_state.duplicate(true)
		page.toggle_language();await frames(2);check(page.current_state==current,"F2 keeps live midpoint "+test[2])
		app.go_home();check(not page.player.active,"Exit cancels new animation "+test[2])
	for q in r.entries:
		if q.id in ["Q07","Q08","Q09","Q10"]:
			check(q.has("calculation"),"Calculation retained "+q.id)
			r.select_question(r.entries.find(q))
			for kind in ["example","variant"]:
				r.open_exercise(kind);r.reveal();await frames(3)
				check(r.formula_panels.size()>0,"Calculation formula "+q.id+kind)
	# Normal and minimum window, including actual word/card controls.
	for dimensions in [Vector2i(1440,900),Vector2i(1100,760)]:
		host.get_window().size=dimensions;app.open_reading();await frames(6)
		for i in r.entries.size():
			r.select_question(i);r.reveal();await frames(2)
			check(r.panel.get_global_rect().end.x<=host.size.x+1,"Reading fits "+str(dimensions)+r.entries[i].id)
		await capture("topics-reading-"+str(dimensions.x))
		await app.open_topic("damage","N12");await settle_topic();await capture("topics-damage-"+str(dimensions.x))
		check(page.bubble.panel.visible,"Damage fits "+str(dimensions))
		app.go_home()
	for factor in [1.0,1.25,1.5,2.0]:
		host.get_window().content_scale_factor=factor;host.get_window().size=Vector2i(roundi(1100*factor),roundi(760*factor));await frames(6)
		app.open_reading()
		for i in r.entries.size():
			if r.entries[i].id=="N01":r.select_question(i);r.reveal();break
		await frames(5)
		check(r.question.inline_textures.size()==3,"Inline LaTeX fractions "+str(factor))
		await capture("topics-inline-scale-"+str(factor))
		await app.open_topic("stability","N01");select_beat("TOP:N01:width");await settle_topic()
		check(page.bubble.caption.get_v_scroll_bar().max_value<=page.bubble.caption.get_v_scroll_bar().page,"DPI bubble "+str(factor))
		await capture("topics-formula-scale-"+str(factor));app.go_home()
	host.get_window().content_scale_factor=1;host.get_window().size=Vector2i(1440,900)
	app.open_vocabulary();app.vocabulary.open_category("单词");await frames(5)
	var glossary=load("res://modules/review/core/glossary.gd").new()
	var terms:Array=glossary.study_entries()
	check(terms.any(func(e):return e.ru=="надво́дный борт"),"New question vocabulary included")
	for e in terms:
		check(e.ru not in ["мочь","ну́жно","мо́жно","бо́льше","ещё","како́й","быть","наприме́р","снача́ла","ме́ньше"],"Excluded basic "+e.id)
	var old_index:int=app.vocabulary.index
	tap(KEY_SPACE);await frames(2);tap(KEY_3);await frames(2)
	check(app.vocabulary.index==old_index+1,"Numeric grade advances actual card")
	check(not app.vocabulary.revealed,"Grade advances and hides Chinese")
	# Original coursework remains reachable, review stays inactive.
	for c in host.courses:
		await host.open_course(c.id);await frames(3)
		check(not app.visible and not page.player.active,"Original chapter isolated "+c.id)
		host.show_home()
	var report:={"checks":results.size(),"failures":results.filter(func(x):return not x.passed),"results":results}
	var out:=FileAccess.open("res://modules/review/qa/topics-checks.json",FileAccess.WRITE);out.store_string(JSON.stringify(report,"\t"));out.close()
	print("TOPICS ",results.size()," checks; failures ",report.failures.size())
	get_tree().quit(0 if report.failures.is_empty() else 1)
