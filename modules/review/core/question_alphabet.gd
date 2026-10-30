extends RefCounted
# Ignore only the leading Почему. Keep prepositions such as в, при and после:
# these are exactly the words the reader sees next on the exam paper.
const ALPHABET:="АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"
static var word_regex:RegEx
static func plain(value:String)->String:
	return value.replace("\u0301","").replace("\u0300","").to_lower()
static func rank(letter:String)->int:
	var position:=ALPHABET.find(letter)
	return position if position>=0 else 100
static func sort_key(value:String)->String:
	var result:=""
	for letter in plain(value):
		var position:=ALPHABET.find(letter.to_upper())
		result+=String.chr(0x400+position) if position>=0 else letter
	return result
static func info(entry:Dictionary)->Dictionary:
	if entry.get("kind","")=="figure":return {"letter":"识图","tail":"","sort":""}
	var text:String=entry.get("question_ru",entry.get("question_original","")).strip_edges()
	if word_regex==null:
		word_regex=RegEx.new();word_regex.compile("[А-Яа-яЁё][А-Яа-яЁё\u0301\u0300]*")
	var words:=word_regex.search_all(text)
	if words.is_empty():return {"letter":"其他","tail":text,"sort":sort_key(text)}
	var first:=1 if plain(words[0].get_string())=="почему" and words.size()>1 else 0
	var tail:=text.substr(words[first].get_start()).replace("\n"," ")
	return {"letter":plain(words[first].get_string()).left(1).to_upper(),"tail":tail,"sort":sort_key(tail)}
