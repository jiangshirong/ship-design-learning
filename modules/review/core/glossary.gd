extends RefCounted
static var shared_entries:Array=[]
static var matches_cache:Dictionary={}
static var study_cache:Dictionary={}
var entries:Array=[]
func _init()->void:
	if shared_entries.is_empty():
		shared_entries=JSON.parse_string(FileAccess.get_file_as_string("res://modules/review/content/glossary.json"))
		shared_entries.append_array(JSON.parse_string(FileAccess.get_file_as_string("res://content/approximation_glossary.json")))
		for extra_path in ["res://modules/review/content/exam12/glossary.json","res://modules/review/content/reasoned_glossary.json","res://modules/review/content/exam12/glossary13.json"]:
			if not FileAccess.file_exists(extra_path):continue
			for extra in JSON.parse_string(FileAccess.get_file_as_string(extra_path)):
				var found:=false
				for existing in shared_entries:
					if existing.id==extra.id:
						for alias in extra.aliases:
							if alias not in existing.aliases:existing.aliases.append(alias)
						found=true;break
				if not found:shared_entries.append(extra)
	entries=shared_entries
func study_entries(path:="res://modules/review/content/reading.json")->Array:
	if study_cache.has(path):return study_cache[path].duplicate(true)
	var used:Dictionary={}
	for question in JSON.parse_string(FileAccess.get_file_as_string(path)):
		if question.get("kind","")=="figure":continue
		for value in [question.question_ru,question.answer.ru]:
			for match_ in spans(value):
				if not used.has(match_.entry.id):used[match_.entry.id]={"id":question.id,"text":value}
	var result:Array=[]
	for entry in entries:
		# The active bank's actual question/answer usage decides membership.
		# A shared word can have been introduced by either bank.
		if used.has(entry.id) and entry.get("study",true):
			var item:Dictionary=entry.duplicate(true);item.context=used[entry.id];result.append(item)
	study_cache[path]=result
	return result.duplicate(true)
func letter(c:String)->bool:
	if c.is_empty():return false
	var n:=c.unicode_at(0)
	return (n>=97 and n<=122) or (n>=0x400 and n<=0x4ff)
func spans(value:String)->Array:
	if matches_cache.has(value):return matches_cache[value]
	var plain:="";var positions:Array[int]=[]
	for i in value.length():
		if value[i] in ["\u0301","\u0300"]:continue
		plain+=value[i].to_lower();positions.append(i)
	var matches:Array=[]
	for entry in entries:
		for alias in entry.aliases:
			var start:int=plain.find(alias)
			while start>=0:
				var end:int=start+alias.length()
				var left_ok:bool=not letter(alias[0]) or start==0 or not letter(plain[start-1])
				var right_ok:bool=not letter(alias[-1]) or end==plain.length() or not letter(plain[end])
				if left_ok and right_ok:
					matches.append({"start":positions[start],"end":positions[end] if end<positions.size() else value.length(),"entry":entry})
				start=plain.find(alias,start+1)
	matches.sort_custom(func(a,b):return a.end-a.start>b.end-b.start)
	matches_cache[value]=matches
	if matches_cache.size()>512:matches_cache.erase(matches_cache.keys()[0])
	return matches
