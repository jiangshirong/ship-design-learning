extends RefCounted
# Transparent fixed intervals; ratings are self-reported, not inferred mastery.
const INTERVALS={"完全不会":120,"不熟":600,"认识":1800,"已掌握":7200}
static func next_review(level:String,now:float)->Dictionary:
	return {"reviewed_at":now,"due_at":now+INTERVALS[level]}
static func due(id:String,schedule:Dictionary,now:float)->bool:
	return not schedule.has(id) or float(schedule[id].due_at)<=now
static func valid(value:Variant)->bool:
	if not value is Dictionary:return false
	for id in value:
		var row:Variant=value[id]
		if not id is String or not row is Dictionary:return false
		for key in ["reviewed_at","due_at"]:
			if not row.get(key) is float and not row.get(key) is int:return false
			if not is_finite(float(row[key])) or float(row[key])<0:return false
		if row.due_at<row.reviewed_at:return false
	return true
