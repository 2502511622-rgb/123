shader_type canvas_item;
uniform float clock_time = 0.0;
uniform float wind = 0.5;
uniform float wetness = 0.0;
uniform vec2 player_at;
uniform vec2 world_size;
uniform int actor_count = 0;
uniform vec2 actor_at[6];
uniform int trail_count = 0;
uniform vec4 trails[12];
uniform bool foreground = false;
varying vec2 root_at;
varying float seed;
varying float bend_amount;
void vertex(){
	root_at = INSTANCE_CUSTOM.yz * world_size;
	seed = INSTANCE_CUSTOM.x;
	float tip = UV.y;
	float push = 0.0;
	for(int i=0;i<6;i++){
		if(i>=actor_count){break;}
		vec2 away = root_at-actor_at[i];
		float influence = 1.0-smoothstep(9.0,361.0,dot(away,away));
		push += influence*(away.x<0.0?-1.0:1.0);
	}
	for(int i=0;i<12;i++){
		if(i>=trail_count){break;}
		vec2 away = root_at-trails[i].xy;
		float influence = 1.0-smoothstep(4.0,324.0,dot(away,away));
		push += influence*trails[i].z*(away.x<0.0?-0.65:0.65);
	}
	push=clamp(push,-1.6,1.6);
	bend_amount=abs(push);
	float gust=sin(clock_time*1.7+root_at.x*0.025+root_at.y*0.013)*0.7+sin(clock_time*3.2+seed*25.0)*0.3;
	// Explicit UV-to-world geometry: UV 0 is always the planted root.
	VERTEX.x=(UV.x-0.5)*2.2;
	VERTEX.y=-tip*9.0;
	VERTEX.x+=tip*tip*(gust*wind+push*3.2);
	VERTEX.y+=tip*tip*abs(push)*2.0;
}
void fragment(){
	float tip=UV.y;
	float center=0.5+sin(tip*2.0+seed*5.0)*tip*0.13;
	float width=mix(0.47,0.015,tip*tip);
	if(abs(UV.x-center)>width){discard;}
	if(foreground && (root_at.y<player_at.y || distance(root_at,player_at)>17.0)){discard;}
	vec3 low=vec3(0.20,0.25,0.14);
	vec3 high=mix(vec3(0.28,0.33,0.19),vec3(0.34,0.36,0.23),seed*0.65);
	vec3 color=mix(low,high,tip);
	color*=0.88+seed*0.24;
	color*=1.0-wetness*0.12;
	color+=vec3(0.025,0.028,0.01)*bend_amount;
	COLOR=vec4(color,1.0);
}
