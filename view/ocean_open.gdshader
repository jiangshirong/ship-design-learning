shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D ripple_normal : hint_normal, repeat_enable, filter_linear_mipmap;
uniform vec2 extent = vec2(420.0,240.0);
uniform vec2 hull_extent = vec2(200.0,27.0);
uniform float inspection = 0.0;
uniform float comparison = 0.0;
varying vec3 sea_position;
varying float near_ship;

void vertex() {
	vec3 p = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	float z_distance = mix(abs(p.z), min(abs(p.z-25.0),abs(p.z+25.0)),comparison);
	vec2 outside = max(vec2(abs(p.x),z_distance)-hull_extent*0.5,vec2(0.0));
	near_ship = 1.0-smoothstep(0.0,12.0,length(outside));
	// The authored spectral swell becomes exactly flat at the hull waterline.
	VERTEX.y *= 1.0-near_ship;
 float near_edge=min(extent.x*.5-abs(p.x),extent.y*.5-abs(p.z));
 VERTEX.y *= smoothstep(0.0,12.0,near_edge);
 sea_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
}
void fragment() {
	vec2 uv = sea_position.xz / 48.0;
	vec3 a = texture(ripple_normal,uv+TIME*vec2(.008,.003)).xyz*2.0-1.0;
	vec3 b = texture(ripple_normal,uv*2.13+TIME*vec2(-.004,.006)).xyz*2.0-1.0;
	float swell_a=cos(dot(sea_position.xz,vec2(.18,.27))-TIME*.65);
	float swell_b=cos(dot(sea_position.xz,vec2(-.31,.16))+TIME*.42);
	vec2 slope = (a.xy*.65+b.xy*.22+vec2(.035,.05)*swell_a+vec2(-.025,.014)*swell_b)*(1.0-near_ship*.72);
	vec3 n = normalize(vec3(slope.x,1.0,slope.y));
 if (!FRONT_FACING) n=-n;
	vec3 v = normalize(mat3(INV_VIEW_MATRIX)*VIEW);
	vec3 reflected = reflect(-v,n);
	float fresnel = .035+.965*pow(1.0-abs(dot(n,v)),5.0);
	float cloud = .5+.5*sin(reflected.x*8.0+sin(reflected.z*13.0)*1.8);
	vec3 sky = mix(vec3(.12,.23,.30),vec3(.42,.57,.64),smoothstep(-.1,.8,reflected.y));
	sky += cloud*.065;
	float sparkle = pow(max(dot(reflected,normalize(vec3(-.35,.72,.60))),0.0),95.0);
	float variation = a.z*.04+b.y*.025;
	vec3 deep = vec3(.020,.135,.175)+vec3(.01,.035,.045)*(variation+swell_a*.10);
	ALBEDO = mix(deep,sky,fresnel*.85)+sparkle*vec3(.70,.85,.93)*.40;
 // Physical water is opaque; inspection explicitly removes the teaching cut.
 if (inspection>0.001 && near_ship>0.25) discard;
 if (INV_VIEW_MATRIX[3].y<0.0) {
  float light_window=smoothstep(.58,.96,abs(dot(n,v)));
  float ripple_light=.5+.5*sin(sea_position.x*.32+sin(sea_position.z*.41+TIME*.45)*1.4);
  ALBEDO=mix(vec3(.025,.15,.19),vec3(.17,.39,.42),light_window*.65)+ripple_light*vec3(.012,.026,.025);
 }
}
