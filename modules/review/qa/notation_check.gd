extends "res://modules/review/qa/sample_check.gd"
func start(target)->void:
	app=target;app.open_reading();var page=app.reading
	page.store.data.filter="all";page.rebuild_filter()
	for dimensions in [Vector2i(1440,900),Vector2i(1100,760)]:
		app.get_window().size=dimensions;await frames(10)
		for number in [6,7,8,9,14]:
			var index:int=page.entries.find(page.entries.filter(func(q):return q.id=="Q%02d"%number)[0])
			page.select_question(index);await frames(12)
			var field=page.question
			check(not field.symbol_regions.is_empty(),"Question has typeset notation "+str(number))
			check(field.text==page.entries[index].question_ru,"Exact source text preserved "+str(number))
			field.select_all();check(field.get_selected_text()==field.full_text,"Native copy preserves full original "+str(number));field.deselect()
			for region in field.symbol_regions:
				check(region.font_size<field.get_theme_font_size("font_size") and region.sub_rect.get_center().y>region.base_rect.get_center().y,"Subscript smaller and lower "+str(number))
				for part in ["base","sub"]:
					var point:Vector2=region[part+"_rect"].get_center()
					var motion:=InputEventMouseMotion.new();motion.position=field.global_position+point;app.get_viewport().push_input(motion,true);await frames(2)
					check(app.term_tooltip.panel.visible and app.term_tooltip.words.text==region.span[part+"_hint"],"Real hover "+str(number)+part)
					if number==8:await capture("notation-Q08-"+part+"-"+str(dimensions.x))
			page.reveal();await frames(10)
			page.scroll.scroll_vertical=10000;await frames(5)
			for panel in page.formula_panels:
				check(panel.hint_regions.any(func(h):return h.text.contains("约定符号")),"Formula main symbol explanation "+str(number))
				for hint in panel.hint_regions:
					check(panel._get_tooltip(hint.rect.get_center())==hint.text,"Formula distinct symbol hit region "+str(number))
				check(panel.render_errors==0,"Formula renders "+str(number))
			if number==8:await capture("notation-Q08-formula-"+str(dimensions.x))
	var f:=FileAccess.open("res://modules/review/qa/notation-checks.json",FileAccess.WRITE);f.store_string(JSON.stringify(results,"\t"));f.close()
	print("NOTATION ",results.size()," failures ",results.filter(func(r):return not r.passed).size());get_tree().quit()
