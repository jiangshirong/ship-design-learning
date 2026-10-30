extends "res://modules/review/qa/topics_check.gd"
func start(target)->void:
	host=target;app=host.review;page=app.stability
	await frames(10);host.open_review("reading");await frames(4)
	var r=app.reading
	for i in r.entries.size():
		if r.entries[i].id=="Q03":r.select_question(i);break
	check(r.entries[r.index].answer.ru=="Эски́зный прое́кт.","Single sketch-design answer")
	await app.open_topic("design","Q03");await frames(4)
	select_beat("Q03:s2");await settle_topic()
	check(not page.bubble.caption.full_text.contains("和技术设计"),"Narration no longer says both stages")
	await capture("q03-corrected-zh")
	page.toggle_language();await frames(5)
	check(page.bubble.caption.full_text=="Эски́зный прое́кт: прове́рка осто́йчивости.","Russian narration corrected")
	await capture("q03-corrected-ru")
	select_beat("TOP:Q03:answer");await settle_topic()
	check(page.bubble.caption.full_text=="Эски́зный прое́кт.","Animation recap agrees with card")
	print("Q03 ",results.size()," checks; failures ",results.filter(func(x):return not x.passed).size())
	get_tree().quit()
