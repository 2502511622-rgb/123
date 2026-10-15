shader_type canvas_item;
uniform float clock_time=0.0;
uniform float wetness=0.0;
uniform sampler2D material_atlas : filter_linear, repeat_disable;
uniform sampler2D terrain_types : filter_nearest, repeat_disable;
uniform vec2 map_size;
uniform bool indoor = false;
varying vec2 world_at;
void vertex(){world_at=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}
void fragment(){
	// TileMap batches may remap UVs: the actual map type comes from world coordinates.
	vec2 tile_uv=(floor(world_at/32.0)+0.5)/(map_size/32.0);
	float tile=floor(texture(terrain_types,tile_uv).r*255.0+0.5);
	vec2 local_uv=clamp(fract(world_at/256.0),vec2(0.002),vec2(0.998))*0.5;
	vec3 turf=mix(vec3(0.20,0.235,0.15),texture(material_atlas,local_uv).rgb,0.43);
	float macro=0.96+0.035*sin(world_at.x*0.017+cos(world_at.y*0.012));
	vec3 surface=turf*macro;
	if(tile>=16.0 || tile==10.0){
		vec3 stone=texture(material_atlas,local_uv+vec2(0.5,0.0)).rgb;
		float paving=1.0;
		if(tile>=16.0){
			int mask=int(tile)-16;
			vec2 p=mod(world_at,32.0);
			float left=(mask&8)!=0?0.0:4.0;
			float right=(mask&2)!=0?32.0:28.0;
			float top=(mask&1)!=0?0.0:4.0;
			float bottom=(mask&4)!=0?32.0:28.0;
			float edge=max(max(left-p.x,p.x-right),max(top-p.y,p.y-bottom));
			paving=1.0-smoothstep(-0.7,1.0,edge);
		}
		surface=mix(surface,mix(vec3(0.33,0.32,0.25),stone,0.74)*1.18,paving);
		float sheen=pow(max(0.0,sin(world_at.y*0.11+world_at.x*0.05)),18.0);
		surface*=1.0-wetness*0.15;
		surface+=vec3(0.05,0.085,0.10)*sheen*wetness;
	}else if(tile==8.0 || tile==9.0){
		vec3 soil=texture(material_atlas,local_uv+vec2(0.0,0.5)).rgb;
		surface=soil*(tile==9.0?0.78:1.12);
	}else if(tile>=11.0 && tile<=13.0){
		float ripple=sin(world_at.x*0.09+clock_time*1.5)*sin(world_at.y*0.24-clock_time*1.8);
		surface=vec3(0.13,0.235,0.24)+vec3(0.045,0.07,0.065)*sin(world_at.y*0.035+sin(world_at.x*0.022));
		surface+=vec3(0.09,0.13,0.13)*smoothstep(0.75,0.99,ripple);
	}
	if(indoor){surface=texture(material_atlas,local_uv+vec2(0.5,0.5)).rgb*1.32;}
	COLOR=vec4(surface,COLOR.a);
}
