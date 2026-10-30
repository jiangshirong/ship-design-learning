extends Node3D
# Reuse the authored tanker, including its real teaching compartment arrangement.
# Clip only a local inspection window; do not replace steelwork with transparent hulls.
var parts:Array=[]
var materials:Array=[]
var last_parameters:Dictionary={}
var cutaway:=0.0
var divider_visibility:=1.0
const CARGO_EDGES=[-54.0,-34.0,-14.0,6.0,26.0,46.0,66.0]
const FLOOR=2.24
const ROOF=14.75
const HALF_WIDTH=10.82
func _ready()->void:
	var model=load("res://assets/damage_tanker.glb").instantiate()
	add_child(model);collect(model)
func collect(node:Node)->void:
	if node is MeshInstance3D:
		parts.append(node)
		var zone:String=str(node.name).get_slice("_",0)
		if zone.begins_with("CargoLiquid"):node.hide();return
		var role:=0
		if zone=="Hull" and "_near_" in str(node.name):role=1
		elif zone=="Ballast" and "_near_" in str(node.name):role=2
		elif zone=="DoubleBottom":role=4
		elif zone in ["Bulkheads","PeakBulkhead"]:role=5
		elif zone in ["Frames","PeakFrame"]:role=6
		elif zone not in ["Hull","Ballast","Machinery","Propulsion"]:role=3
		for i in node.mesh.get_surface_count():
			var original=node.mesh.surface_get_material(i)
			var color:Color=original.albedo_color if original is StandardMaterial3D else Color("a4b4b8")
			var shader:=Shader.new()
			shader.code="""shader_type spatial;
render_mode cull_disabled;
uniform vec4 steel_color : source_color;
uniform float cut=0.0;
uniform float dividers=1.0;
uniform float focus_wall=0.0;
uniform int role=0;
uniform bool forepeak=false;
varying vec3 p;
void vertex(){p=VERTEX;}
void fragment(){
	float centre=forepeak?84.0:6.0;
	float span=forepeak?22.0:44.0;
	bool window=cut>0.001 && abs(p.x-centre)<span*cut;
	if(window){
		if(role==1 && p.y>0.35) discard;
		if(role==2 && p.y>2.24) discard;
		if(role==3 && p.y>14.7) discard;
		// Reveal the floors and bottom girders through a narrow near-side strip.
		if(role==4 && p.y>2.05 && p.z>6.8) discard;
	}
	bool internal=p.x>-53.7 && p.x<65.7;
	if(role==5 && internal && dividers<0.5)discard;
	ALBEDO=steel_color.rgb;ROUGHNESS=0.65;METALLIC=0.12;
	EMISSION=role==5?vec3(0.25,0.13,0.035)*focus_wall:vec3(0.0);
}"""
			var mat:=ShaderMaterial.new();mat.shader=shader
			mat.set_shader_parameter("steel_color",color);mat.set_shader_parameter("role",role)
			node.set_surface_override_material(i,mat);materials.append(mat)
	for child in node.get_children():collect(child)
func apply(value:Dictionary)->void:
	cutaway=float(value.get("cutaway",1));divider_visibility=float(value.get("partitions",1))
	var params:Dictionary={"cut":cutaway,"dividers":divider_visibility,"focus_wall":1.0 if value.get("phase","")=="bulkheads" or value.get("qid","")=="N10" else 0.0,"forepeak":value.get("phase","")=="forepeak"}
	for key in params:
		if last_parameters.has(key) and last_parameters[key]==params[key]:continue
		for mat in materials:mat.set_shader_parameter(key,params[key])
	last_parameters=params
