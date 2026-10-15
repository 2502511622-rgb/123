shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float night = 0.0;
uniform float mist = 0.0;
uniform float clock_time = 0.0;
uniform vec2 world_offset = vec2(0.0);
uniform vec2 hero = vec2(320.0, 180.0);
uniform vec4 lights[24];
uniform int light_count = 0;
void fragment() {
	vec2 p = floor(SCREEN_UV * vec2(640.0,360.0));
	vec3 scene = texture(screen_texture, SCREEN_UV).rgb;
	vec3 ambient = mix(vec3(1.0,1.01,0.97),vec3(0.53,0.67,0.76),night);
	float glow = 0.0;
	for(int i=0; i<24; i++) {
		if(i >= light_count) break;
		float distance_to_light = length(p - lights[i].xy);
		float falloff = max(0.0,1.0-distance_to_light/lights[i].z);
		// Deliberately stepped falloff follows the logical pixel grid.
		glow += floor(falloff*falloff*9.0)/9.0*lights[i].w;
	}
	scene *= ambient + vec3(0.78,0.42,0.13)*min(glow,1.3)*(0.22+0.78*night);
	vec2 at = p + world_offset;
	float bands = sin(at.y*0.027 + sin(at.x*0.006+clock_time*0.06)*1.8 + clock_time*0.10);
	float fog = smoothstep(0.1,1.0,bands)*mist*smoothstep(35.0,130.0,length(p-hero));
	scene = mix(scene,vec3(0.53,0.66,0.63),fog);
	vec2 edge = abs(SCREEN_UV-vec2(0.5));
	float vignette = smoothstep(0.25,0.65,length(edge));
	scene *= 1.0-vignette*0.13;
	COLOR = vec4(scene,1.0);
}
