extends "res://modules/review/core/safe_store.gd"
var catalog_path:="res://modules/review/content/question_bank.json"
var migration_bank:=""
var migration_source_path:=""
func _init()->void:
	path="user://review/reading-review.json"
	data={"schema_version":1,"selected":"Q01","filter":"all","marks":{},"expanded":{},"unknown_words":{},"word_levels":{}}
func valid_id(id:Variant)->bool:
	if not id is String:return false
	id=canonical_id(id)
	for q in JSON.parse_string(FileAccess.get_file_as_string(catalog_path)):
		if q.id==id:return true
	return false
func canonical_id(id:Variant)->Variant:
	for q in JSON.parse_string(FileAccess.get_file_as_string(catalog_path)):
		if id in q.get("legacy_ids",[]):return q.id
	return id
func merge_duplicate_progress(value:Dictionary)->void:
	value.selected=canonical_id(value.selected)
	var marks:Dictionary=value.marks
	for old_id in marks.keys():
		var target:Variant=canonical_id(old_id)
		if target==old_id:continue
		if not value.has("merged_duplicate_marks"):value.merged_duplicate_marks={}
		value.merged_duplicate_marks[old_id]=marks[old_id]
		if marks.get(target,"")=="review" or marks[old_id]=="review":marks[target]="review"
		else:marks[target]=marks[old_id]
		marks.erase(old_id)
func read_file()->void:
	var source_path:=path
	var importing:=false
	if not FileAccess.file_exists(source_path):
		if migration_source_path.is_empty() or not FileAccess.file_exists(migration_source_path):return
		source_path=migration_source_path;importing=true
	var parser:=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(source_path))!=OK:blocked=true;return
	var value:Variant=parser.data
	if value is Dictionary and value.get("schema_version")==1 and value.get("selected") is String and value.get("marks") is Dictionary:
		for id in value.marks:
			if not id is String or value.marks[id] not in ["known","review"]:blocked=true;return
		if migration_bank=="exam12":
			if not value.get("moved_exam_marks",{}) is Dictionary:blocked=true;return
			for id in value.marks.keys():
				if str(id).begins_with("THU"):
					if not value.has("moved_exam_marks"):value.moved_exam_marks={}
					value.moved_exam_marks[id]=value.marks[id];value.marks.erase(id)
			if value.selected.begins_with("THU"):
				value.moved_exam_selected=value.selected;value.selected="P12_T03"
		elif migration_bank=="exams" and importing:
			var imported_marks:Dictionary={}
			if not value.get("moved_exam_marks",{}) is Dictionary:blocked=true;return
			for id in value.get("moved_exam_marks",{}):imported_marks[id]=value.moved_exam_marks[id]
			for id in value.marks:
				if str(id).begins_with("THU"):imported_marks[id]=value.marks[id]
			value.marks=imported_marks
			if not value.selected.begins_with("THU"):value.selected=value.get("moved_exam_selected","THU01")
	if not value is Dictionary or value.get("schema_version")!=1 or not valid_id(value.get("selected")) or value.get("filter") not in ["all","pending"] or not value.get("marks") is Dictionary:blocked=true;return
	for id in value.marks:
		if not valid_id(id) or value.marks[id] not in ["known","review"]:blocked=true;return
	if not value.get("expanded",{}) is Dictionary:blocked=true;return
	if value.has("grouping") and value.grouping not in ["topic","alphabet"]:blocked=true;return
	if not value.get("unknown_words",{}) is Dictionary:blocked=true;return
	for k in value.get("unknown_words",{}):
		if not k is String or value.unknown_words[k]!=true:blocked=true;return
	if not value.get("word_levels",{}) is Dictionary:blocked=true;return
	for k in value.get("word_levels",{}):
		var level:Variant=value.word_levels[k]
		if not k is String or (not level is int and not level is float) or float(level) not in [1.0,2.0,3.0,4.0]:blocked=true;return
		value.word_levels[k]=int(level)
	merge_duplicate_progress(value)
	data=value
	if not data.has("word_levels"):data.word_levels={}
	if not data.has("unknown_words"):data.unknown_words={}
	if not data.has("expanded"):data.expanded={}
