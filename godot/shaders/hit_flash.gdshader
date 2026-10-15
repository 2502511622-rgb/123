shader_type canvas_item;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float environment_blend = 0.0;
uniform float wetness : hint_range(0.0, 1.0) = 0.0;
uniform float motion_clock = 0.0;
uniform float motion_amount = 0.0;
void vertex() {
	// Cloth follow-through at 60 Hz, tapering to zero at the foot anchor.
	float hem = smoothstep(-45.0,-24.0,VERTEX.y)*(1.0-smoothstep(-15.0,-3.0,VERTEX.y));
	VERTEX.x += sin(motion_clock*7.0+VERTEX.y*0.18)*hem*motion_amount*0.9;
}
uniform bool avatar_enabled = false;
uniform vec2 avatar_texture_size = vec2(0.0);
uniform vec4 avatar_region = vec4(0.0);
uniform vec4 avatar_hair : source_color = vec4(0.89,0.90,0.87,1.0);
uniform vec4 avatar_coat : source_color = vec4(0.20,0.31,0.48,1.0);
uniform vec4 avatar_scarf : source_color = vec4(0.72,0.30,0.27,1.0);
uniform vec4 avatar_trousers : source_color = vec4(0.85,0.80,0.69,1.0);
uniform vec4 avatar_boots : source_color = vec4(0.44,0.33,0.27,1.0);
uniform vec4 avatar_skin : source_color = vec4(0.90,0.71,0.55,1.0);
uniform vec4 avatar_trim : source_color = vec4(0.78,0.64,0.37,1.0);
void fragment() {
	if(avatar_enabled && abs(TEXTURE_PIXEL_SIZE.x-1.0/max(avatar_texture_size.x,1.0))<0.0000001 && abs(TEXTURE_PIXEL_SIZE.y-1.0/max(avatar_texture_size.y,1.0))<0.0000001){
		vec3 original=texture(TEXTURE,UV).rgb;
		vec2 at=(UV*avatar_texture_size-avatar_region.xy)/max(avatar_region.zw,vec2(1.0));
		float light=dot(original,vec3(0.299,0.587,0.114));
		float high=max(original.r,max(original.g,original.b));
		float low=min(original.r,min(original.g,original.b));
		float saturation=(high-low)/max(high,0.001);
		vec3 choice=original;
		float reference=1.0;
		bool replace=false;
		if(at.y<0.33 && saturation<0.22 && light>0.25){choice=avatar_hair.rgb;reference=0.73;replace=true;}
		else if(at.y<0.40 && original.r>original.g*1.13 && original.g>original.b*1.12 && original.r<original.g*2.0 && light>0.25){choice=avatar_skin.rgb;reference=0.63;replace=true;}
		else if(original.r>original.g*1.65 && original.r>original.b*1.4 && light>0.10){choice=avatar_scarf.rgb;reference=0.33;replace=true;}
		else if(at.y>0.83 && light<0.55 && original.r>=original.b){choice=avatar_boots.rgb;reference=0.25;replace=true;}
		else if(original.b>original.r*1.12 && original.b>original.g*0.96 && at.y>0.2){choice=avatar_coat.rgb;reference=0.27;replace=true;}
		else if(at.y>0.48 && light>0.35 && saturation<0.34){choice=avatar_trousers.rgb;reference=0.72;replace=true;}
		else if(at.y>0.37 && at.y<0.76 && original.r>original.g*1.03 && original.g>original.b*1.65 && light>0.3){choice=avatar_trim.rgb;reference=0.57;replace=true;}
		if(replace){COLOR.rgb=choice*clamp(light/reference,0.25,1.35)*(COLOR.rgb/max(original,vec3(0.01)));}
	}

	float above=texture(TEXTURE,UV-vec2(0.0,TEXTURE_PIXEL_SIZE.y)).a;
	float left=texture(TEXTURE,UV-vec2(TEXTURE_PIXEL_SIZE.x,0.0)).a;
	float edge=max(0.0,texture(TEXTURE,UV).a-min(above,left));
	vec3 lit=COLOR.rgb*(1.0-wetness*0.06)+vec3(0.12,0.14,0.10)*edge*(0.35+wetness*0.35);
	float luma=dot(lit,vec3(0.299,0.587,0.114));
	lit=mix(lit,mix(lit,vec3(luma)*vec3(0.96,1.0,0.89),0.45),environment_blend);
	COLOR.rgb=mix(lit,vec3(1.0),flash);
}
