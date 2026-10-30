extends Control
const Lifecycle=preload("res://core/scene_lifecycle.gd")
var views:Dictionary={}
var active
var focus:="ship"
var camera_motion:bool:
	get:return is_instance_valid(active) and active.camera_motion
func _ready()->void:resized.connect(arrange)
func arrange()->void:
	for view in views.values():
		if is_instance_valid(view):
			view.position=Vector2.ZERO;view.size=size
			if view.has_method("sync_viewport_size"):view.sync_viewport_size()
func obtain(key:String):
	if views.has(key) and is_instance_valid(views[key]):return views[key]
	var scripts={"doublebottom":"double_bottom_view","hold":"hold_view","interior":"interior_view","design":"design_view","technical":"technical_view","marine":"topic_marine","hullform":"module11_ship"}
	scripts["revision9p"]="revision9p_ship"
	scripts["yacht"]="propulsion_yacht"
	scripts["exam12"]="exam12_ship"
	scripts["exam12_stability"]="exam12_stability"
	var view=load("res://modules/review/view/"+scripts[key]+".gd").new()
	add_child(view);view.hide();views[key]=view
	if key=="technical":view.math_panel.hide()
	Lifecycle.restore_camera("topic:"+key,view)
	return view
func apply(state:Dictionary,language:String)->void:
	var qid:String=state.get("qid","Q01")
	var key:="marine" if state.get("topic","") in ["damage","freeboard"] else ("design" if qid in ["Q01","Q04","Q05"] else ("hold" if qid in ["Q02","Q11","Q14","Q15"] else "technical"))
	if qid=="Q12":key="doublebottom"
	if qid=="Q13":key="interior"
	if state.get("topic","")=="hullform":key="hullform"
	if state.get("topic","") in ["propulsion","arrangement"] or str(state.get("qid","")).begins_with("R9"):key="revision9p"
	if state.get("topic","")=="propulsion":key="yacht"
	if state.get("topic","")=="exam12":key="exam12_stability" if state.get("concept","") in ["roll","stability"] else "exam12"
	var selected=obtain(key)
	if active!=selected or not selected.visible:
		if is_instance_valid(active):active.cancel();Lifecycle.set_active(active,false)
		active=selected
		if key in ["hold","interior","marine","doublebottom","hullform","revision9p","yacht","exam12","exam12_stability"]:
			Lifecycle.use("topic:"+key,active,func():
				var old=views.get(key);views.erase(key)
				if active==old:active=null
				if is_instance_valid(old):remove_child(old);old.queue_free())
		else:Lifecycle.suspend_all();Lifecycle.set_active(active,true)
		arrange()
	else:Lifecycle.set_active(active,true)
	if key in ["marine","hullform","revision9p","yacht","exam12","exam12_stability"]:active.focus=focus;active.apply(state,language)
	else:
		active.lesson_id=qid;active.apply(state,state.get("phase","intro"),language)
		if key=="technical":active.math_panel.hide()
func set_camera(_preset:String)->void:
	if is_instance_valid(active):
		if active.get_meta("camera_restored",false):
			active.set_meta("camera_restored",false);return
		if active in [views.get("marine"),views.get("hullform"),views.get("revision9p"),views.get("yacht"),views.get("exam12"),views.get("exam12_stability")]:active.set_camera("topic")
		elif active.has_method("teach"):active.teach(active.phase)
func anchor()->Vector2:return active.anchor() if is_instance_valid(active) else size*.5
func obstacles()->Array:return active.obstacles() if is_instance_valid(active) else []
func cancel()->void:
	for view in views.values():
		if is_instance_valid(view):view.cancel()
func deactivate()->void:
	cancel()
	for view in views.values():Lifecycle.set_active(view,false)
