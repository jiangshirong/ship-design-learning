extends RefCounted
# Regions are declared by stable beat ID. Samples come from the player's real
# before/after/keyframe path; this module never changes the rendered scene.
const Motion=preload("res://modules/review/core/state_math.gd")
const Hull=preload("res://modules/review/view/damage_cutaway.gd")
static func prepare(spec:Dictionary,before:Dictionary,after:Dictionary,route:Array)->Dictionary:
	var result:Dictionary={"spec":spec,"points":[],"samples":[]}
	if spec.is_empty() or spec.get("mode","")=="keep":return result
	# <= 1 degree between samples for the supported rigid heel path.
	var steps:int=maxi(16,ceili(absf(float(after.get("heel_demo",0))-float(before.get("heel_demo",0)))))
	for frame in route:steps=maxi(steps,ceili(absf(float(frame.state.get("heel_demo",0))-float(before.get("heel_demo",0)))))
	for i in range(steps+1):
		var state:Dictionary=Motion.sample(before,after,route,float(i)/steps)
		var transform:=Transform3D(Basis(Vector3.RIGHT,-deg_to_rad(float(state.get("heel_demo",0)))),Vector3(0,-float(state.get("draft",8))-float(state.get("sink",0)),0))
		var low:=Vector3(-34,0,-13.3);var high:=Vector3(26,16,13.3)
		if spec.region=="flooded_cell":
			var bay:int=clampi(int(state.get("bay",2)),0,5)
			low=Vector3(Hull.CARGO_EDGES[bay]+.09,Hull.FLOOR,.09)
			high=Vector3(Hull.CARGO_EDGES[bay+1]-.09,Hull.FLOOR+8,Hull.HALF_WIDTH)
		result.samples.append({"transform":transform,"centre":(low+high)*.5})
		for x in [low.x,high.x]:
			for y in [low.y,high.y]:
				for z in [low.z,high.z]:result.points.append(transform*Vector3(x,y,z))
		if spec.get("include_waterline",false):
			for x in [low.x,high.x]:
				for z in [-16,16]:result.points.append(Vector3(x,0,z))
	return result
static func assess(camera:Camera3D,observation:Dictionary)->Dictionary:
	var spec:Dictionary=observation.spec
	if spec.get("mode","")=="keep":return {"mode":"hold","reason":"text_only"}
	var points:Array=observation.points
	if points.is_empty():return {"mode":"reframe","reason":"missing_region"}
	# Accept all useful azimuths of the actual open side, not proximity to the
	# recommended camera's direction. Above the open deck is also admissible.
	if spec.get("visible_from","")=="cut_side_or_above":
		for sample in observation.samples:
			var local:Vector3=sample.transform.affine_inverse()*camera.global_position
			var delta:Vector3=local-sample.centre
			var from_side:bool=delta.z>0 and delta.z/maxf(delta.length(),.001)>.06 and local.y>Hull.FLOOR
			var from_above:bool=local.y>Hull.ROOF and delta.y/maxf(delta.length(),.001)>.65
			if not from_side and not from_above:return {"mode":"reframe","reason":"closed_side"}
	var view:=Vector2(camera.get_viewport().size)
	var margins:Array=spec.safe_margin
	var safe:=Rect2(view*Vector2(margins[0],margins[1]),view*Vector2(1.0-margins[0]-margins[2],1.0-margins[1]-margins[3]))
	var bounds:=Rect2(camera.unproject_position(points[0]),Vector2.ZERO)
	var centre:=Vector3.ZERO
	for point:Vector3 in points:
		if camera.is_position_behind(point):return {"mode":"reframe","reason":"behind_camera"}
		bounds=bounds.expand(camera.unproject_position(point));centre+=point
	centre/=points.size()
	var minimum:=Vector2(spec.minimum_pixels[0],spec.minimum_pixels[1])
	if safe.grow(2).encloses(bounds) and bounds.size.x>=minimum.x and bounds.size.y>=minimum.y:
		return {"mode":"hold","reason":"whole_action_visible","bounds":bounds}
	var factor:float=maxf(bounds.size.x/safe.size.x,bounds.size.y/safe.size.y)
	var span:float=camera.size
	if factor>1:span*=factor*1.04
	elif bounds.size.x<minimum.x or bounds.size.y<minimum.y:span*=minf(bounds.size.x/minimum.x,bounds.size.y/minimum.y)
	var same_scale:bool=is_equal_approx(span,camera.size)
	var delta:=Vector2.ZERO
	if same_scale:
		if bounds.position.x<safe.position.x:delta.x=bounds.position.x-safe.position.x-2
		elif bounds.end.x>safe.end.x:delta.x=bounds.end.x-safe.end.x+2
		if bounds.position.y<safe.position.y:delta.y=bounds.position.y-safe.position.y-2
		elif bounds.end.y>safe.end.y:delta.y=bounds.end.y-safe.end.y+2
	else:delta=bounds.get_center()-view*.5
	var units:float=camera.size/(view.y if camera.keep_aspect==Camera3D.KEEP_HEIGHT else view.x)
	var offset:Vector3=camera.global_basis.x*delta.x*units-camera.global_basis.y*delta.y*units
	return {"mode":"nudge" if same_scale else "fit","reason":"region_framing","offset":offset,"span":span,"bounds":bounds}
