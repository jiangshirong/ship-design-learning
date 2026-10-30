extends "res://modules/review/qa/topics_check.gd"

func normalized(value:String)->String:
	return value.to_lower().replace("\u0301","").replace("\u0300","")

func start(target)->void:
	host=target;host.open_review("reading");app=host.review;page=app.stability
	await frames(8)
	var glossary=app.term_tooltip.glossary
	var audit=JSON.parse_string(FileAccess.get_file_as_string("res://modules/review/qa/lookup-audit/editorial-decisions.json"))
	for row in audit.lexical:
		var matches:Array=glossary.spans(row.form)
		check(not matches.is_empty(),"Reviewed form resolves: "+row.form)
	var before=JSON.parse_string(FileAccess.get_file_as_string("res://modules/review/qa/lookup-audit/glossary-before-review.json"))
	var ids:Dictionary={}
	for entry in glossary.entries:ids[entry.id]=entry
	for old in before:
		check(ids.has(old.id),"Stable vocabulary ID: "+old.id)
		if old.has("study") and not old.study:check(not ids[old.id].get("study",true),"Excluded card remains excluded: "+old.id)
	for form in ["меняется","спасению","закрытию","отвечающие","направлена","вдвое","в качестве"]:
		var matches:Array=glossary.spans(form)
		var expected:Dictionary={"меняется":"меня́ться","спасению":"спасе́ние","закрытию":"закры́тие","отвечающие":"отвеча́ть","направлена":"напра́вить","вдвое":"вдво́е","в качестве":"в ка́честве"}
		check(not matches.is_empty() and matches[0].entry.ru==expected[form],"Correct contextual lemma: "+form)
	var excluded:=["ещё","какой","быть","например","сначала","меньше","можно","больше","мочь","нужно","для"]
	for entry in glossary.study_entries():
		check(normalized(entry.ru) not in excluded,"Study filter: "+entry.id)
		check(entry.context.text!="","Study card has question/answer source: "+entry.id)
	await app.open_topic("stability")
	if page.language!="ru":page.toggle_language()
	select_beat("TOP:N04:type");await settle_topic()
	var field=page.bubble.caption
	check(field.text.contains("учи́тывают"),"Correct stress in actual animation sentence")
	for word in ["для","учи́тывают","тип","нагру́зку"]:
		var start:int=field.text.find(word)
		var found:=false
		for y in range(2,int(field.size.y),3):
			for x in range(2,int(field.size.x),3):
				var lc:Vector2i=field.get_line_column_at_pos(Vector2i(x,y),false,false)
				if lc.x<0 or lc.y<0:continue
				var offset:int=lc.x
				for line in lc.y:offset+=field.get_line(line).length()+1
				if offset<start or offset>=start+word.length():continue
				var motion:=InputEventMouseMotion.new()
				motion.position=field.global_position+Vector2(x,y)
				host.get_viewport().push_input(motion,true)
				await frames(2)
				if app.term_tooltip.panel.visible and not app.term_tooltip.current.is_empty():
					check(not app.term_tooltip.current.zh.is_empty(),"Actual hover has Chinese: "+word)
					check(app.term_tooltip.words.text.contains(app.term_tooltip.current.ru),"Actual hover has lemma: "+word)
					found=true
					if word=="учи́тывают":await capture("lookup-reviewed-verb")
					break
			if found:break
		check(found,"Actual viewport hover: "+word)
	var failed:int=results.filter(func(r):return not r.passed).size()
	var file:=FileAccess.open("res://qa/lookup-review.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"\t"));file.close()
	print("Lookup review: ",results.size()," checks; failures=",failed)
	get_tree().quit(1 if failed else 0)
