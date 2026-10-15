shader_type canvas_item;
uniform sampler2D material_atlas : filter_linear;
uniform sampler2D plots : filter_nearest;
varying vec2 world_at;
void vertex(){world_at=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}
void fragment(){
	vec2 cell=(floor((world_at-vec2(320.0,256.0))/32.0)+0.5)/vec2(8.0,6.0);
	vec2 flags=texture(plots,cell).rg;
	vec2 local_uv=clamp(fract(world_at/256.0),vec2(0.002),vec2(0.998))*0.5+vec2(0.0,0.5);
	vec3 earth=texture(material_atlas,local_uv).rgb;
	float furrow=0.88+0.12*sin(world_at.y*0.72);
	earth*=furrow*mix(1.10,0.68,flags.g);
	COLOR=vec4(earth,flags.r);
}
