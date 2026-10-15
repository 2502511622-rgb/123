shader_type canvas_item;
render_mode unshaded, blend_add;
uniform float radius = 115.0;
uniform float clock_time = 0.0;
uniform float phase = 0.0;
varying vec2 local_position;
void vertex(){local_position=VERTEX;}
void fragment(){
	float f=max(0.0,1.0-length(local_position)/radius);
	float strength=f*f*(0.92+0.04*sin(clock_time*2.3+phase));
	COLOR=vec4(vec3(strength),1.0);
}
