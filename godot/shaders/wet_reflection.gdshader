shader_type canvas_item;
render_mode unshaded;
uniform sampler2D ground_mask : filter_nearest,repeat_disable;
uniform vec2 map_size=vec2(960.0,640.0);
uniform vec2 origin=vec2(0.0);
uniform vec2 reflection_scale=vec2(1.0,0.34);
uniform float source_height=136.0;
uniform float wetness=0.0;
uniform float clock_time=0.0;
varying vec2 at;
varying float depth;
void vertex(){at=origin+VERTEX*reflection_scale;depth=VERTEX.y/source_height;}
void fragment(){
	vec2 uv=UV;
	uv.x+=sin(at.y*0.20+clock_time*2.0)*0.005;
	vec4 reflected=texture(TEXTURE,uv);
	float mask=texture(ground_mask,at/map_size).r;
	float breakup=0.72+0.28*sin(at.y*1.6+at.x*0.07+clock_time);
	float fade=pow(clamp(1.0-depth,0.0,1.0),0.85);
	float lamp=step(0.5,reflected.r)*step(reflected.g*1.08,reflected.r)*step(reflected.b*1.2,reflected.g);
	COLOR=vec4(reflected.rgb*vec3(0.90,0.94,0.98)*(1.0+lamp*0.12),reflected.a*mask*wetness*fade*(0.62+lamp*0.25)*breakup);
}
