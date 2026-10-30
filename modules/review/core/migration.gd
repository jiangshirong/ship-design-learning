extends RefCounted
static func run(qa:=false,source:="",destination:="")->Dictionary:
	if qa:return {}
	if source.is_empty():source=OS.get_user_data_dir().get_base_dir().path_join("第一周口试25题")
	if destination.is_empty():destination="user://review"
	var report:={"copied":[],"existing":[],"errors":[]}
	if DirAccess.make_dir_recursive_absolute(destination)!=OK:report.errors.append("destination");return report
	for name in ["progress.json","reading-review.json","stability-progress.json"]:
		for suffix in ["",".bak"]:
			var from:=source.path_join(name+suffix);var to:=destination.path_join(name+suffix)
			if not FileAccess.file_exists(from):continue
			if FileAccess.file_exists(to):report.existing.append(name+suffix);continue
			var bytes:=FileAccess.get_file_as_bytes(from)
			var file:=FileAccess.open(to+".tmp",FileAccess.WRITE)
			if not file:report.errors.append(name+suffix);continue
			file.store_buffer(bytes);file.close()
			if FileAccess.get_file_as_bytes(to+".tmp")!=bytes or DirAccess.rename_absolute(to+".tmp",to)!=OK:report.errors.append(name+suffix)
			else:report.copied.append(name+suffix)
	return report
