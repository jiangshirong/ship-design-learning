extends RefCounted
var path:="user://review/stability-progress.json"
var blocked:=false
var data:Dictionary={"version":1,"beat":"ST:goal","foundation_done":false,"pending":"","language":"zh"}
func read_file()->void:
	if not FileAccess.file_exists(path):return
	var j:=JSON.new()
	if j.parse(FileAccess.get_file_as_string(path))!=OK:blocked=true;return
	var v:Variant=j.data
	if not v is Dictionary:blocked=true;return
	if v.get("version",0)!=1 or not v.get("beat") is String or not v.get("foundation_done") is bool or not v.get("pending") is String or v.get("language","") not in ["zh","ru"]:blocked=true;return
	data=v
func save()->bool:
	if blocked:return false
	var f:=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if not f:return false
	f.store_string(JSON.stringify(data));f.close()
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path+".bak"):DirAccess.remove_absolute(path+".bak")
		if DirAccess.rename_absolute(path,path+".bak")!=OK:return false
	if DirAccess.rename_absolute(path+".tmp",path)!=OK:
		if FileAccess.file_exists(path+".bak"):DirAccess.rename_absolute(path+".bak",path)
		return false
	return true
