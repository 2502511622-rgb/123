shader_type canvas_item;
uniform float clock_time=0.0;
uniform float wetness=0.0;
uniform float snow=0.0;
uniform float dust=0.0;
uniform sampler2D material_atlas : filter_nearest, repeat_disable;
uniform sampler2D terrain_types : filter_nearest, repeat_disable;
uniform vec2 map_size;
uniform bool indoor = false;
uniform bool continent = false;
uniform int quality=2;
uniform vec4 turf_tint : source_color = vec4(0.35,0.44,0.29,1.0);
uniform vec4 stone_tint : source_color = vec4(0.65,0.61,0.51,1.0);
uniform vec4 water_tint : source_color = vec4(0.25,0.44,0.48,1.0);
varying vec2 world_at;
void vertex(){world_at=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}
void fragment(){
	// TileMap batches may remap UVs: the actual map type comes from world coordinates.
	vec2 tile_uv=(floor(world_at/32.0)+0.5)/(map_size/32.0);
	float tile=floor(texture(terrain_types,tile_uv).r*255.0+0.5);
	vec2 local_uv=clamp(fract(floor(world_at)/96.0),vec2(0.002),vec2(0.998))*0.5;
	vec3 region_turf=turf_tint.rgb;
	if(continent){
		region_turf=world_at.y<2400.0?(world_at.x<3200.0?vec3(0.39,0.39,0.27):vec3(0.41,0.38,0.25)):(world_at.x<3200.0?vec3(0.34,0.43,0.27):vec3(0.28,0.35,0.32));
	}
	vec3 turf=mix(region_turf,texture(material_atlas,local_uv).rgb,0.55);
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
		surface=mix(surface,mix(stone_tint.rgb,stone,0.55)*1.04,paving);
		float sheen=pow(max(0.0,sin(world_at.y*0.11+world_at.x*0.05)),18.0);
		surface*=1.0-wetness*0.15;
		surface+=vec3(0.05,0.085,0.10)*sheen*wetness;
	}else if(tile==8.0 || tile==9.0){
		vec3 soil=texture(material_atlas,local_uv+vec2(0.0,0.5)).rgb;
		surface=soil*(tile==9.0?0.78:1.12);
	}else if(tile>=11.0 && tile<=13.0){
		// Two travelling wave fields create broken highlights rather than tiled stripes.
		vec2 flow=world_at+vec2(clock_time*3.0,-clock_time*1.6);
		float wave=sin(flow.x*0.065+sin(flow.y*0.081))*0.55+sin(flow.y*0.12-flow.x*0.035)*0.3;
		float fine=sin(flow.x*0.23+sin(flow.y*0.19))*sin(flow.y*0.31+clock_time*0.7);
		vec2 cell=mod(world_at,32.0);
		float shore=32.0;
		for(int i=0;i<4;i++){
			vec2 offset=vec2(i==0?-1.0:(i==1?1.0:0.0),i==2?-1.0:(i==3?1.0:0.0));
			float neighbor=floor(texture(terrain_types,tile_uv+offset/(map_size/32.0)).r*255.0+0.5);
			if(neighbor<11.0 || neighbor>13.0){
				float distance_value=i==0?cell.x:(i==1?32.0-cell.x:(i==2?cell.y:32.0-cell.y));
				shore=min(shore,distance_value);
			}
		}
		float depth=smoothstep(0.0,27.0,shore);
		surface=mix(water_tint.rgb*0.9,water_tint.rgb*0.35,depth);
		surface+=vec3(0.035,0.06,0.055)*wave;
		float sky=smoothstep(0.48,0.92,wave+fine*0.17);
		surface+=vec3(0.16,0.20,0.19)*sky;
		float glint=step(0.91,sin(flow.x*0.42+sin(flow.y*0.18)))*step(0.86,sin(flow.y*0.55+sin(flow.x*0.04)));
		surface+=vec3(0.09,0.12,0.11)*glint;
		float foam=(1.0-smoothstep(0.6,2.5,abs(shore-2.8-sin(clock_time*1.3+world_at.x*0.08)*1.0)))*(0.45+0.25*sin(world_at.y*0.27));
		surface=mix(surface,vec3(0.47,0.52,0.42),foam*0.4);
		// Small rain rings appear only during wet weather.
		vec2 rain_cell=floor(world_at/18.0);
		float seed=fract(sin(dot(rain_cell,vec2(12.9898,78.233)))*43758.5453);
		float age=fract(clock_time*0.7+seed);
		float ring=1.0-smoothstep(0.3,0.85,abs(length(mod(world_at,18.0)-9.0)-age*8.0));
		if(quality>0){surface+=vec3(0.07,0.1,0.1)*ring*(1.0-age)*wetness;}

	}
 if(continent && !(tile>=11.0 && tile<=13.0)){
  bool desert=world_at.x<3200.0 && world_at.y<2400.0;
  bool edo=world_at.x>=3200.0 && world_at.y<2400.0;
  bool mountain=world_at.x>=3200.0 && world_at.y>=2400.0;
  float grain=fract(sin(dot(floor(world_at/2.0),vec2(12.9898,78.233)))*43758.5453);
  bool paved=tile==10.0 || tile>=16.0;
  if(desert){
   float dunes=sin(world_at.y*0.028+sin(world_at.x*0.009)*2.3);
   vec3 sand=vec3(0.57,0.45,0.30)*(0.94+dunes*0.075+grain*0.055);
   float ridge=smoothstep(0.75,0.94,dunes);
   sand+=vec3(0.025,0.022,0.015)*ridge;
   float trail_distance=min(min(abs(world_at.x-1504.0),abs(world_at.x-4896.0)),min(abs(world_at.y-1056.0),abs(world_at.y-3552.0)));
   float trail=1.0-smoothstep(14.0,44.0,trail_distance+sin(world_at.y*.045)*6.0);
   bool courtyard=world_at.x>1088.0 && world_at.x<1920.0 && world_at.y>608.0 && world_at.y<1476.0;
   surface=courtyard && paved?mix(mix(vec3(0.46,0.40,0.31),surface,0.38),sand,0.35+grain*0.25):sand*(1.0-trail*.055);
   surface=mix(surface,sand,dust*0.12);
  }else if(edo){
   vec3 soil=vec3(0.31,0.33,0.30)*(0.9+grain*0.13);
   float patches=smoothstep(0.2,0.8,sin(world_at.x*0.019+cos(world_at.y*.021)));
   surface=paved?mix(vec3(0.32,0.31,0.28),surface,0.40):mix(soil,vec3(0.30,0.37,0.30),patches*.5);
   float joints=step(30.5,mod(world_at.y,32.0))+step(46.5,mod(world_at.x+floor(world_at.y/32.0)*16.0,48.0));
   if(paved){surface*=1.0-min(1.0,joints)*0.25;}
   float drift=smoothstep(0.1,0.85,sin(world_at.x*.023+cos(world_at.y*.017))*.5+.5);
   surface=mix(surface,vec3(0.63,0.68,0.69),snow*(0.35+drift*.5));
  }else if(mountain){
   float slope=sin(world_at.x*.011+sin(world_at.y*.006)*2.0);
   float strata=smoothstep(0.75,0.96,sin(world_at.y*.043+slope*2.0));
   vec3 earth=mix(vec3(0.25,0.28,0.27),vec3(0.32,0.32,0.29),slope*.5+.5);
   earth*=0.94+grain*.1-strata*.08;
   float trail_distance=min(min(abs(world_at.x-1504.0),abs(world_at.x-4896.0)),min(abs(world_at.y-1056.0),abs(world_at.y-3552.0)));
   float trail=1.0-smoothstep(10.0,46.0,trail_distance+sin(world_at.y*.024)*8.0+sin(world_at.x*.033)*4.0);
   surface=earth*(1.0-trail*0.13);
   if(grain>.93 && trail>.25){surface+=vec3(0.025,0.023,0.020);}
  }
  surface*=1.0-wetness*0.10;
 }
	if(indoor){surface=texture(material_atlas,local_uv+vec2(0.5,0.5)).rgb*1.32;}
	COLOR=vec4(surface,COLOR.a);
}
