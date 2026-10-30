extends MeshInstance3D
# Shared external sea only. Internal flood liquids and hydrostatic planes are separate.
static func create(width:float=420.0,depth:float=240.0)->MeshInstance3D:
	var sea=load("res://view/ocean.gd").new()
	var authored:Node=load("res://assets/ocean/calm_ocean.glb").instantiate()
	var meshes=authored.find_children("*","MeshInstance3D",true,false)
	assert(not meshes.is_empty(),"Ocean asset has no surface")
	sea.mesh=meshes[0].mesh
	authored.free()
	var shader:=ShaderMaterial.new()
	shader.shader=preload("res://view/ocean.gdshader")
	shader.set_shader_parameter("ripple_normal",load("res://assets/ocean/ripple_normal.png"))
	sea.material_override=shader
	sea.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sea.set_extent(width,depth)
	return sea

func set_extent(width:float,depth:float)->void:
	var bounds:=mesh.get_aabb()
	scale=Vector3(width/bounds.size.x,1.0,depth/bounds.size.z)
	material_override.set_shader_parameter("extent",Vector2(width,depth))

func teaching(hull_length:float,hull_beam:float,cut:float=0.0,compare:bool=false)->void:
	material_override.set_shader_parameter("hull_extent",Vector2(hull_length,hull_beam))
	material_override.set_shader_parameter("inspection",clampf(cut,0.0,1.0))
	material_override.set_shader_parameter("comparison",1.0 if compare else 0.0)
