extends "res://modules/review/core/safe_store.gd"
# One record per topic. No writes to legacy, reading, or vocabulary files.
var topic_id:=""
func _init()->void:
	path="user://review/topic-progress.json"
	data={"version":1,"topics":{}}
func read_file()->void:
	if not FileAccess.file_exists(path):return
	var p:=JSON.new()
	if p.parse(FileAccess.get_file_as_string(path))!=OK:blocked=true;return
	var v:Variant=p.data
	if not v is Dictionary or v.get("version")!=1 or not v.get("topics") is Dictionary:blocked=true;return
	for item in v.topics.values():
		if not item is Dictionary or not item.get("beat") is String or not item.get("foundation_done") is bool or not item.get("pending") is String or item.get("language") not in ["zh","ru"]:
			blocked=true;return
	data=v;data.version=int(data.version)
	if data.topics.has("stability") and data.topics.stability.beat=="TOP:Q19:answer":data.topics.stability.beat="ST:Q19:answer"
func select_topic(course:Dictionary,legacy_targets:Dictionary,qa:bool,legacy_path:="",legacy_selected:="")->Dictionary:
	topic_id=course.id
	if data.topics.has(topic_id):return data.topics[topic_id].duplicate(true)
	var record:Dictionary={"beat":course.groups[0].beats[0].id,"foundation_done":false,"pending":"","language":"zh"}
	if topic_id=="stability" and not qa:
		var old=preload("res://modules/review/core/stability_store.gd").new()
		if not legacy_path.is_empty():old.path=legacy_path
		old.read_file()
		if old.blocked:
			blocked=true
		elif FileAccess.file_exists(old.path):
			record=old.data.duplicate(true)
	elif not qa:
		var candidates:Array=course.questions.duplicate()
		if legacy_selected in candidates:candidates.erase(legacy_selected);candidates.push_front(legacy_selected)
		for qid in candidates:
			if legacy_targets.has(qid):
				record.beat=course.question_targets[qid]
				break
	data.topics[topic_id]=record
	return record.duplicate(true)
func put(record:Dictionary)->void:
	data.topics[topic_id]=record.duplicate(true)
	if not blocked:write_file()
