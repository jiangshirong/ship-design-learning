extends RefCounted
var path:="user://review/progress.json"
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

