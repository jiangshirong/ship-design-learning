extends RefCounted
# Preserve authored surface colours; remove only the inspection window.
var materials:Array=[]
var nodes:Array=[]
var last_parameters:Dictionary={}
var parameter_writes:=0
var highlighted_zones:Array=[]
static var common_shader:Shader
func attach(root:Node3D)->void:
	collect(root,root)
func collect(node:Node,root:Node3D)->void:
	if node is MeshInstance3D:
		nodes.append(node)
		var name_:String=str(node.name)
		var zone:String=name_.get_slice("_",0)
		var role:=0
		if zone in ["Hull","InnerSide","Ballast"]:role=1
		elif zone in ["Decks","Rails","Equipment","Cranes","Hatches","Hatch","Piping","Walkway","FireSystem","Manifold","TankAccess","Stairs","Forecastle"]:role=2
		elif zone in ["Bulkheads","Frames","DoubleBottom","InnerBottom","Girders","Longitudinal"]:role=3
		if zone=="SectionLongitudinal":role=8
		if zone.begins_with("Fuel") and "Shell" in zone and ("_near_" in name_ or "_cover" in name_):role=4
		if zone in ["Accommodation","AftDeck"] and "_cover" in name_:role=2
		if zone=="CargoLiquidOil":role=5
		if zone=="CargoLiquidSurface":role=6
		if zone=="Frames" or (zone=="Bulkheads" and "_near_" in name_):role=7
		for i in node.mesh.get_surface_count():
			var src=node.material_override if node.material_override is StandardMaterial3D else node.mesh.surface_get_material(i)
			var color:Color=src.albedo_color if src is StandardMaterial3D else Color("a2aaa6")
			if common_shader==null:
				common_shader=Shader.new()
				common_shader.code="""shader_type spatial;
render_mode cull_disabled;
uniform vec4 coating:source_color;
uniform mat4 to_ship;
uniform float cut=0.0;
uniform float centre=0.0;
uniform float span=20.0;
uniform float floor_y=0.0;
uniform float roof_y=10.0;
uniform float near_z=0.0;
uniform int role=0;
uniform bool section_view=false;
uniform float section_depth=1000.0;
uniform float deck_rise=0.0;
uniform float oil_height=100.0;
uniform bool lesson_highlight=false;
varying vec3 p;
void vertex(){
 p=(to_ship*vec4(VERTEX,1.0)).xyz;
 float rise=deck_rise*clamp(p.y-1.0,0.0,1.0);
 VERTEX+=(inverse(mat3(to_ship))*vec3(0.0,rise,0.0));
 if(role==6 && oil_height<99.0){VERTEX+=inverse(mat3(to_ship))*vec3(0.0,oil_height-p.y,0.0);p.y=oil_height;}
}
void fragment(){
 bool window=cut>0.001 && abs(p.x-centre)<span*cut;
 if(role==5 && p.y>oil_height)discard;
 if(role==6 && oil_height<2.26)discard;
 if(section_view && (p.x>centre+0.10 || p.x<centre-section_depth))discard;
 if(window){
  if(role==4)discard;
  if(role==8 && p.z>near_z && p.y>floor_y+4.0)discard;
  if(role==7 && p.z>near_z && p.y>floor_y+0.3)discard;
  if(role==1 && p.z>near_z && p.y>floor_y)discard;
  if(role==2 && p.y>roof_y)discard;
 }
 ALBEDO=coating.rgb;ROUGHNESS=0.6;METALLIC=0.15;
 if(lesson_highlight){ALBEDO=mix(ALBEDO,vec3(1.0,0.72,0.25),0.35);EMISSION=vec3(0.32,0.16,0.025)*(0.65+0.35*sin(TIME*2.0));}
}"""
			var mat:=ShaderMaterial.new();mat.shader=common_shader
			mat.set_shader_parameter("coating",color)
			mat.set_shader_parameter("to_ship",root.global_transform.affine_inverse()*node.global_transform)
			mat.set_shader_parameter("role",role)
			mat.set_meta("zone",zone)
			node.set_surface_override_material(i,mat);materials.append(mat)
	for child in node.get_children():collect(child,root)
func parameters(changes:Dictionary)->void:
	for key in changes:
		if last_parameters.has(key) and last_parameters[key]==changes[key]:continue
		last_parameters[key]=changes[key]
		for mat in materials:mat.set_shader_parameter(key,changes[key]);parameter_writes+=1
func window(amount:float,centre:float,span:float,floor_y:float,roof_y:float,near_z:=0.0,section_view:=false)->void:
	parameters({"cut":amount,"centre":centre,"span":span,"floor_y":floor_y,"roof_y":roof_y,"near_z":near_z,"section_view":section_view})
func raise_deck(amount:float)->void:parameters({"deck_rise":amount})
func fill_liquid(height:float)->void:parameters({"oil_height":height})
func highlight_zones(zones:Array)->void:
	if zones==highlighted_zones:return
	highlighted_zones=zones.duplicate()
	for mat in materials:mat.set_shader_parameter("lesson_highlight",mat.get_meta("zone","") in zones)
