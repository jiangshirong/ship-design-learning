extends RefCounted
var path:="user://progress.json"
var blocked:=false
var issue:=""
var data:Dictionary={"schema_version":1,"targets":{},"selected":"","language":"zh"}
func read_file()->void:
	if not FileAccess.file_exists(path):return
	var parser:=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK:
		blocked=true;issue="invalid_json";return
	var value:Variant=parser.data
	if not value is Dictionary or value.get("schema_version",0)!=1 or not value.get("targets") is Dictionary or value.get("language","") not in ["zh","ru"] or not value.get("selected","") is String:
		blocked=true;issue="invalid_schema";return
	for key in value.targets:
		if not key is String or not value.targets[key] is String:blocked=true;issue="invalid_target";return
	data=value
func write_file()->bool:
	if blocked:return false
	var file:=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null:issue="write_failed";return false
	file.store_string(JSON.stringify(data,"\t"));file.close()
	var backup:=path+".bak"
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(backup):DirAccess.remove_absolute(backup)
		if DirAccess.rename_absolute(path,backup)!=OK:issue="backup_failed";return false
	var code:=DirAccess.rename_absolute(path+".tmp",path)
	if code!=OK:
		if FileAccess.file_exists(backup):DirAccess.rename_absolute(backup,path)
		issue="replace_failed";return false
	issue="";return true

func migrate()->void:
	if blocked:return
	var courses:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://content/courses.json"))
	data.targets.erase("ost")
	if data.selected=="ost":data.selected=""
	for old in ["sample","norman"]:
		if data.targets.has(old):
			data.targets["supplement"]=data.targets[old];data.targets.erase(old)
		if data.selected==old:data.selected="supplement"
	for course in courses:
		var id:String=course.id
		if not data.targets.has(id):continue
		var saved:String=data.targets[id]
		var target:String=course.get("resume_aliases",{}).get(saved,saved)
		var exists:=false
		for group in course.groups:
			for b in group.beats:
				if b.id==target:exists=true
		data.targets[id]=target if exists else course.groups[0].beats[0].id
