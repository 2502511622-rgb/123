shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D light_field : filter_linear,repeat_disable;
uniform float night = 0.0;
uniform int quality=2;
uniform float mist = 0.0;
uniform float clock_time = 0.0;
uniform float rain = 0.0;
uniform float wetness = 0.0;
uniform float sunshine = 0.0;
uniform float warmth = 0.0;
uniform vec4 fog_tint : source_color = vec4(0.6,0.7,0.72,1.0);
uniform float focus_strength=0.52;
uniform vec2 world_offset = vec2(0.0);
uniform vec2 hero = vec2(320.0, 180.0);
uniform vec4 lights[24];
uniform int light_count = 0;
void fragment() {
	vec2 pixel=vec2(1.0/640.0,1.0/360.0);
	vec2 p=floor(SCREEN_UV*vec2(640.0,360.0));
	vec2 at=p+world_offset;
	vec3 scene=texture(screen_texture,SCREEN_UV).rgb;
	// A small tilt-shift falloff at the extreme frame; never blur the player or HUD.
	float edge_focus=smoothstep(0.34,0.5,abs(SCREEN_UV.y-0.5))*smoothstep(70.0,150.0,length(p-hero))*focus_strength;
	vec3 soft=scene;
	if(quality>0){soft=(texture(screen_texture,SCREEN_UV+pixel*vec2(1.5,0)).rgb+texture(screen_texture,SCREEN_UV-pixel*vec2(1.5,0)).rgb+texture(screen_texture,SCREEN_UV+pixel*vec2(0,1.5)).rgb+texture(screen_texture,SCREEN_UV-pixel*vec2(0,1.5)).rgb)*0.25;}
	scene=mix(scene,soft,edge_focus);
	vec3 ambient=mix(vec3(1.04,1.02,0.97),vec3(0.46,0.61,0.73),night);
	ambient*=mix(vec3(1.0),vec3(0.82,0.90,0.96),rain);
	ambient+=vec3(0.10,0.09,0.04)*(1.0-smoothstep(15.0,65.0,length(p-hero)))*night;
	ambient+=vec3(0.12,0.035,-0.045)*warmth*(1.0-rain);
	float glow=texture(light_field,SCREEN_UV).r;
	float halo=glow;
	if(quality>1){halo=(texture(light_field,SCREEN_UV+pixel*vec2(3,0)).r+texture(light_field,SCREEN_UV-pixel*vec2(3,0)).r+texture(light_field,SCREEN_UV+pixel*vec2(0,3)).r+texture(light_field,SCREEN_UV-pixel*vec2(0,3)).r)*0.25;}
	scene*=ambient+vec3(1.15,0.64,0.23)*min(glow,1.5)*(0.18+night*0.88);
	scene+=vec3(0.17,0.095,0.026)*max(0.0,halo-0.15)*(0.25+night*0.75);
	float beams=pow(max(0.0,sin(at.x*0.022+at.y*0.009+sin(clock_time*0.09)*0.35)),12.0);
	scene+=vec3(0.09,0.085,0.048)*beams*sunshine*(1.0-rain)*smoothstep(45.0,130.0,length(p-hero));
	float bands=sin(at.y*0.018+sin(at.x*0.004+clock_time*0.045)*2.0+clock_time*0.08);
	float fog=smoothstep(0.15,1.0,bands)*(mist+rain*0.04)*smoothstep(35.0,140.0,length(p-hero));
	scene=mix(scene,fog_tint.rgb,fog);
	float highlight=max(max(scene.r,scene.g),scene.b);
	vec3 bloom=max(soft-vec3(0.64),vec3(0.0));
	scene+=bloom*0.045*(0.3+night);
	float vignette=smoothstep(0.28,0.68,length(SCREEN_UV-vec2(0.5)));
	scene*=1.0-vignette*0.12;
	COLOR=vec4(clamp(scene,vec3(0.0),vec3(1.0)),1.0);
}
