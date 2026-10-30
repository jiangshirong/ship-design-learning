extends "res://modules/review/qa/sample_check.gd"
func start(host)->void:
	app=host.review;host.open_review("reading");await frames(10)
	var r=app.reading;var v=app.vocabulary
	v.path="user://review/qa-word-picker-"+str(OS.get_process_id())+".json";v.marks={};v.schedule={}
	r.select_question(0);await frames(8)
	var picker=r.get_meta("word_picker");var spans:Array=app.term_tooltip.glossary.spans(r.question.text)
	var chosen:Dictionary={}
	for span in spans:
		if span.entry.get("study",true) and not span.entry.ru.contains(" "):chosen=span;break
	check(not chosen.is_empty(),"Original question has a real dictionary word")
	var found:=false
	for y in range(2,int(r.question.size.y),3):
		for x in range(2,int(r.question.size.x),3):
			var lc:Vector2i=r.question.get_line_column_at_pos(Vector2i(x,y),false,false)
			if lc.y!=0 or lc.x<chosen.start or lc.x>=chosen.end:continue
			await click(r.question.global_position+Vector2(x,y));await frames(3)
			if picker.panel.visible and picker.selected.id==chosen.entry.id:found=true;break
		if found:break
	check(found,"Actual Russian word click opens meaning popup")
	check(not v.marks.has(chosen.entry.id),"Click alone does not change grade")
	await capture("word-picker")
	check(picker.panel.find_children("*","Button",true,false).is_empty(),"No unknown button in click popup")
	tap(KEY_R);await frames(4)
	picker.dismiss()
	check(v.marks.get(chosen.entry.id)=="完全不会" and not picker.panel.visible,"R records level four")
	var saved:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(v.path))
	check(saved.marks.get(chosen.entry.id)=="完全不会" and saved.schedule.has(chosen.entry.id),"Grade and scientific schedule persist together")
	# A reviewed word must show its exact old grade, and never leak onto an unmarked card.
	app.open_vocabulary(true);v.schedule.clear();v.open_category("单词");await frames(5)
	for level in v.LEVELS:
		var entry:Dictionary=v.entries[0];v.marks[entry.id]=level;v.index=0;v.revealed=true;v.refresh();await frames(3)
		for i in 4:check(v.grade_buttons[i].button_pressed==(v.LEVELS[i]==level),"Only saved grade highlighted "+level+str(i))
		check(v.grade_buttons[v.LEVELS.find(level)].text.ends_with("✓"),"Saved grade has non-color cue "+level)
	await capture("word-picker-grade-highlight")
	v.marks.erase(v.entries[0].id);v.refresh();check(v.grade_buttons.all(func(b):return not b.button_pressed),"Unmarked word has no selected grade")
	var original_id:String=v.entries[0].id;tap(KEY_4);await frames(4)
	check(v.marks.get(original_id)=="完全不会" and (v.entries.is_empty() or v.entries[v.index].id!=original_id),"Numeric grading still saves and advances")
	app.open_reading();await frames(3)
	picker.pick(Vector2(10,20));app.open_vocabulary(true);await frames(3);check(not picker.panel.visible,"Picker cannot leak into another page")
	var failures:Array=results.filter(func(x):return not x.passed)
	var f:=FileAccess.open("res://qa/word-picker-results.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":results.size(),"failures":failures},"  "));f.close()
	print("WORD PICKER ",results.size()," checks; failures ",failures.size());get_tree().quit(0 if failures.is_empty() else 1)
