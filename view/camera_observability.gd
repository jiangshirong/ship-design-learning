extends RefCounted
# Conservative per-shot visibility envelope. The support points include the
# whole moving region, not only its initial centre; view cones reject hidden sides.
static func inspect(camera:Camera3D,points:Array,normal:Vector3,cone:float=0.72)->Dictionary:
	if points.is_empty():return {"mode":"reframe"}
	var view:Vector2=Vector2(camera.get_viewport().size)
	if view.x<10 or view.y<10:return {"mode":"reframe"}
	if camera.global_basis.z.dot(normal.normalized())<cone:return {"mode":"reframe"}
	var bounds:=Rect2(camera.unproject_position(points[0]),Vector2.ZERO)
	for p:Vector3 in points:
		if camera.is_position_behind(p):return {"mode":"reframe"}
		bounds=bounds.expand(camera.unproject_position(p))
	var safe:=Rect2(view*Vector2(.07,.12),view*Vector2(.86,.72))
	if bounds.size.x<20 or bounds.size.y<10:return {"mode":"reframe"}
	if safe.encloses(bounds):return {"mode":"hold"}
	if bounds.size.x>safe.size.x or bounds.size.y>safe.size.y:return {"mode":"reframe"}
	var delta:=Vector2.ZERO
	if bounds.position.x<safe.position.x:delta.x=bounds.position.x-safe.position.x
	elif bounds.end.x>safe.end.x:delta.x=bounds.end.x-safe.end.x
	if bounds.position.y<safe.position.y:delta.y=bounds.position.y-safe.position.y
	elif bounds.end.y>safe.end.y:delta.y=bounds.end.y-safe.end.y
	if delta.length()>view.length()*.13:return {"mode":"reframe"}
	var units:float=camera.size/(view.y if camera.keep_aspect==Camera3D.KEEP_HEIGHT else view.x)
	return {"mode":"nudge","offset":camera.global_basis.x*delta.x*units-camera.global_basis.y*delta.y*units}
static func envelope(target:Vector3,normal:Vector3,width:float,height:float,depth:float=4)->Array:
	var up:=Vector3.UP if absf(normal.normalized().dot(Vector3.UP))<.96 else Vector3(-1,0,0)
	var basis:=Basis.looking_at(-normal,up)
	var points:Array=[]
	for x in [-.5,.5]:
		for y in [-.5,.5]:
			for z in [-.5,.5]:points.append(target+basis*Vector3(x*width,y*height,z*depth))
	return points
