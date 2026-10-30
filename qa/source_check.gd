extends "res://qa/bulkheads_check.gd"
func start(host)->void:
	app=host;await frames(5)
	await app.open_course("bulkheads","BH:opening");page=app.bulkheads;await frames(10)
	for language in ["zh","ru"]:
		page.lang=language;page.menus()
		for id in ["BH:webvalues_ordinary","BH:webtransition_ordinary","BH:fore_range","BH:fore_place","BH:dbformula","BH:dbadopt","BH:sideadopt","BH:six","BH:tanklimits"]:
			await show_step(id)
			var e:Dictionary=page.record.entries[id]
			var marked:bool=page.beat.has("source_phrase")
			if page.beat.has("source_rule"):
				check(page.beat.source_rule.has("teacher_reference") and not page.beat.source_rule.teacher_reference.contains("6a-Женя"),"Teacher provenance "+id)
				for block in e.math.source_blocks:check(e.math._get_tooltip(block.rect.position+Vector2(6,4)).is_empty(),"No purple block popup "+id)
			check(not page.speech.badge.visible,"Speech marking "+language+id)
			check(page.speech.panel.size.y>=page.speech.caption.size.y,"Bubble height "+language+id)
			if marked:
				check(page.speech.badge.tooltip_text.is_empty(),"No source tooltip "+id)
				check(page.speech.caption.full_text.contains(page.beat.source_phrase[language]),"Exact phrase "+language+id)
				var start:int=page.speech.caption.text.find(page.beat.source_phrase[language])
				var point:Vector2=Vector2(page.speech.caption.get_pos_at_line_column(0,start+1))-Vector2(0,8)
				check(page.speech.caption.get_tooltip(point).is_empty(),"No phrase popup "+language+id)
			if id=="BH:fore_place":check(not page.beat.has("source_rule"),"Adopted value is ordinary")
			if id=="BH:tanklimits":
				check(e.math.source_blocks.size()==1,"Condition and formula grouped")
				check(not e.math.source_condition.is_empty(),"Condition remains visible")
				check(e.math.source_blocks[0].rect.end.y<e.math.drawings[-1].rect.position.y,"Substitution outside source block")
			if id in ["BH:dbadopt","BH:tanklimits","BH:six","BH:webtransition_ordinary"]:await capture("source-"+language+"-"+id.replace(":","-"))
	page.lang="zh"
	for id in ["BH:webvalues_ordinary","BH:webtransition_ordinary","BH:webvalues","BH:engine_integer"]:
		await show_step(id)
		var math=page.record.entries[id].math
		var matches:=0
		for hint in math.hint_regions:
			if "肋距" in hint.text or "间隔数" in hint.text:
				check(math._get_tooltip(hint.rect.get_center())==hint.text,"English variable actual glyph hover "+id)
				matches+=1
		check(matches>=2,"Both base and suffix carry Chinese meaning "+id)
		if id=="BH:webvalues":
			check(page.beat.record_text.zh.contains("船中部"),"T2 cargo wording")
			for hint in math.hint_regions:
				if hint.text.begins_with("机舱框架肋距"):
					var hover:=InputEventMouseMotion.new();hover.position=math.global_position+hint.rect.get_center();app.get_viewport().push_input(hover,true);break
			await frames(8);await capture("english-subscript-web")
	for id in ["BH:webvalues","BH:webengine","BH:webtransition","BH:webfore","BH:webaft"]:
		await show_step(id+"_ordinary")
		check(page.beat.spacing_stage=="ordinary","Ordinary spacing taught separately "+id)
		check(page.beat.record_text.zh.ends_with("普通肋距"),"Ordinary calculation record "+id)
		check(not page.record.entries.has(id) or not page.record.entries[id].box.visible,"Future frame calculation hidden "+id)
		await capture("spacing-"+id.replace(":","-")+"-ordinary")
		await show_step(id)
		check(page.beat.spacing_stage=="web","Frame spacing taught separately "+id)
		check(page.beat.words.zh.contains("等于普通肋距") if id in ["BH:webfore","BH:webaft"] else page.beat.words.zh.contains("乘"),"Frame relation explained "+id)
		check(page.ship.region_preview,"Spatial region preview "+id)
		check(page.ship.walls.all(func(w):return w.visible and is_equal_approx(w.scale.y,1)),"Nine partition walls visible "+id)
		check(page.ship.longitudinal.visible and page.ship.bottom.visible,"Actual inner structure visible "+id)
		var pair:Vector2i=page.ship.region_frames
		var expected:float={"BH:webvalues":3.4,"BH:webengine":1.7,"BH:webtransition":1.38,"BH:webfore":.6,"BH:webaft":.6}[id]
		check(is_equal_approx(absf(M.x(pair.x)-M.x(pair.y)),expected),"Frame geometry equals displayed spacing "+id)
		await capture("spacing-"+id.replace(":","-"))
	await show_step("BH:fore_range")
	check(not page.ship.region_preview and not page.ship.longitudinal.visible,"Later staged construction restored")
	page.lang="ru"
	await show_step("BH:dbadopt")
	var move:=InputEventMouseMotion.new();move.position=page.speech.badge.global_position+Vector2(8,8);app.get_viewport().push_input(move,true)
	await frames(8);await capture("source-hover")
	tap(KEY_F2);await frames(6);check(page.lang=="zh","F2 preserves step and changes source badge")
	app.get_window().size=Vector2i(1100,720);await frames(8)
	await show_step("BH:tanklimits");await capture("source-minimum")
	check(page.speech.panel.get_rect().end.y<=page.ship.size.y+1,"Minimum window bubble fits")
	for scale in [1.25,1.5,2.0]:
		app.get_window().size=Vector2i(Vector2(1440,900)*scale);app.get_window().content_scale_factor=scale;await frames(8)
		await show_step("BH:dbadopt");await capture("source-scale-"+str(scale))
		check(page.speech.panel.get_rect().end.y<=page.ship.size.y+1,"Scale bubble "+str(scale))
	tap(KEY_ESCAPE);await frames(4);check(app.mode=="home","Exit returns home")
	var out:=FileAccess.open("res://qa/source-check.json",FileAccess.WRITE);out.store_string(JSON.stringify(results,"\t"));out.close()
	var failed:int=results.filter(func(r):return not r.passed).size()
	print("SOURCE ",results.size()," checks; failures ",failed);get_tree().quit(1 if failed else 0)
