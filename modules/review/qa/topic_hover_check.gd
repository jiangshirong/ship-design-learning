extends "res://modules/review/qa/topics_check.gd"

func start(target)->void:
	host=target;app=host.review;page=app.stability
	await frames(12)
	await click(host.review_buttons.get_child(0).get_global_rect().get_center())
	await frames(5)
	for course in page.courses:
		await app.open_topic(course.id)
		if page.language!="ru":page.toggle_language()
		var tested:=false
		for i in page.player.beats.size():
			var matches:Array=app.term_tooltip.glossary.spans(page.player.beats[i].words.ru)
			if matches.is_empty():continue
			page.goto_index(i);await settle_topic()
			var field=page.bubble.caption
			var span=matches[0]
			# Scan native glyph hit positions, then deliver viewport-only mouse input.
			for y in range(2,int(field.size.y),3):
				for x in range(2,int(field.size.x),3):
					var lc:Vector2i=field.get_line_column_at_pos(Vector2i(x,y),false,false)
					if lc.y!=0 or lc.x<span.start or lc.x>=span.end:continue
					var motion:=InputEventMouseMotion.new()
					motion.position=field.global_position+Vector2(x,y)
					app.get_viewport().push_input(motion,true)
					await frames(2)
					if app.term_tooltip.panel.visible and app.term_tooltip.owner_field==field:
						check(app.term_tooltip.words.text.contains("[b][color=#146b70]"+span.entry.ru),"Styled accented lemma "+course.id)
						check(app.term_tooltip.words.text.contains(span.entry.zh),"Chinese meaning "+course.id)
						tested=true
						break
				if tested:break
			if tested:
				await capture("topic-hover-"+course.id)
				page.toggle_language();await frames(3)
				check(not app.term_tooltip.panel.visible,"Language change clears tip "+course.id)
				break
		check(tested,"Actual bubble hover "+course.id)
	await app.open_topic("design","Q03")
	if page.language!="ru":page.toggle_language()
	select_beat("Q03:s2");await settle_topic()
	var diagram=page.topic_ship.views.technical
	var lookup=diagram.label_lookup
	for lemma in ["эски́зный","техни́ческий","прове́рка"]:
		var found:=false
		for region in lookup.regions:
			if region.entry.ru!=lemma:continue
			var motion:=InputEventMouseMotion.new()
			motion.position=diagram.get_global_transform_with_canvas()*region.rect.get_center()
			app.get_viewport().push_input(motion,true)
			await frames(1)
			check(lookup.tip.panel.visible,"Immediate diagram hover "+lemma)
			check(lookup.tip.words.text.contains(region.entry.zh),"Diagram Chinese "+lemma)
			check(not lookup.tip.words.text.contains("原型："),"No redundant lemma prefix "+lemma)
			found=true
			break
		check(found,"Diagram label hit region "+lemma)
	await capture("topic-hover-diagram")
	page.toggle_language();await frames(3)
	check(not lookup.tip.panel.visible,"Diagram language change clears tooltip")
	var failed:=results.filter(func(r):return not r.passed).size()
	var file:=FileAccess.open("res://modules/review/qa/topic-hover-results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"\t"));file.close()
	print("Topic hover: ",results.size()," checks; failures=",failed)
	get_tree().quit(1 if failed else 0)
