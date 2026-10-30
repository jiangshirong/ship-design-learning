extends RefCounted
# Heavy scenes share one bounded pool across homework and review pages.
static var entries:Dictionary={}
static var order:Array=[]
static var cameras:Dictionary={}
static var active_key:=""
static func camera_owner(node:Node)->Node:
	if "ship" in node and is_instance_valid(node.ship):return camera_owner(node.ship)
	return node
static func viewports(node:Node,enabled:bool)->void:
	if node is SubViewport:
		node.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE if enabled else SubViewport.UPDATE_DISABLED
	for child in node.get_children():viewports(child,enabled)
static func set_active(node:Node,enabled:bool)->void:
	if not is_instance_valid(node):return
	if node.has_meta("scene_active") and node.get_meta("scene_active")==enabled and (not node is CanvasItem or node.visible==enabled):return
	node.set_meta("scene_active",enabled)
	node.process_mode=Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
	if node is CanvasItem:node.visible=enabled
	viewports(node,enabled)
static func use(key:String,node:Node,release:Callable)->void:
	for id in entries:
		if id!=key:set_active(entries[id].node,false)
	entries[key]={"node":node,"release":release}
	order.erase(key);order.append(key);active_key=key
	set_active(node,true)
	while order.size()>2:
		var old:String=order.pop_front()
		var item:Dictionary=entries[old];entries.erase(old)
		if is_instance_valid(item.node):
			var camera_node:=camera_owner(item.node)
			if camera_node.has_method("snapshot"):cameras[old]=camera_node.snapshot()
			elif "camera" in camera_node and camera_node.camera:
				var state:Dictionary={}
				for property in ["turn_target","camera_span","yaw","pitch","camera_target","focus","eye","extent","user_camera"]:
					if property in camera_node:state[property]=camera_node.get(property)
				state.transform=camera_node.camera.transform;state.size=camera_node.camera.size;cameras[old]=state
			set_active(item.node,false);item.release.call()
static func suspend_all()->void:
	active_key=""
	for item in entries.values():set_active(item.node,false)
static func restore_camera(key:String,node:Node)->void:
	if not cameras.has(key):return
	node=camera_owner(node)
	var value:Dictionary=cameras[key]
	node.set_meta("camera_restored",true)
	if node.has_method("restore"):node.restore(value);return
	if not "camera" in node or not node.camera:return
	for property in value:
		if property not in ["transform","size"]:node.set(property,value[property])
	node.camera.transform=value.transform;node.camera.size=value.size
