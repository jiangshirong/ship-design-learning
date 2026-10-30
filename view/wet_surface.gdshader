shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float water_height=10.88;
uniform float reveal=1.0;
varying vec3 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 if(world_position.y>water_height)discard;
 ALBEDO=vec3(0.18,0.83,0.76);
 ALPHA=(0.28+0.14*sin(TIME*2.0))*reveal;
}
