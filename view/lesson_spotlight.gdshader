shader_type canvas_item;
uniform vec2 logical_size;
uniform vec2 centre;
uniform vec2 radii;
uniform float strength=0.46;
void fragment(){
 vec2 q=(UV*logical_size-centre)/max(radii,vec2(1.0));
 float outside=smoothstep(0.86,1.12,length(q));
 COLOR=vec4(0.018,0.035,0.050,strength*outside);
}
