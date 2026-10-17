shader_type canvas_item;
uniform float clock_time=0.0;
uniform float wetness=0.0;
uniform float snow=0.0;
uniform float dust=0.0;
uniform sampler2D material_atlas : filter_nearest, repeat_disable;
uniform sampler2D regional_material : filter_nearest, repeat_disable;
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
vec2 terrain_hash(vec2 cell){
 return fract(sin(vec2(dot(cell,vec2(127.1,311.7)),dot(cell,vec2(269.5,183.3))))*43758.5453);
}
vec3 terrain_patch(vec2 corner,vec2 p,vec2 quadrant){
 vec2 anchor=vec2(.30)+terrain_hash(corner)*.40;
 // Each sample stays inside its material quadrant; no wrapping or mirror seam.
 vec2 uv=anchor+(p-corner)*.18;
 return texture(regional_material,(quadrant+uv)*.5).rgb;
}
vec3 continuous_ground(vec2 at,vec2 quadrant){
 vec2 p=floor(at)/160.0;vec2 base=floor(p);vec2 f=fract(p);
 vec2 weight=f*f*(3.0-2.0*f);
 vec3 a=terrain_patch(base,p,quadrant);
 vec3 b=terrain_patch(base+vec2(1,0),p,quadrant);
 vec3 c=terrain_patch(base+vec2(0,1),p,quadrant);
 vec3 d=terrain_patch(base+vec2(1,1),p,quadrant);
 return mix(mix(a,b,weight.x),mix(c,d,weight.x),weight.y);
}
uniform bool landscape_enabled=false;
uniform bool forest_zone=false;
uniform bool grave_zone=false;
uniform float blood_moon29=0.0;
uniform sampler2D landscape_field : filter_linear, repeat_disable;
uniform sampler2D landscape_materials : filter_nearest, repeat_disable;
uniform sampler2D coast_materials : filter_nearest, repeat_disable;
// Polynomial hash keeps world-space variation without dozens of sine calls per pixel.
vec2 hash29(vec2 p){
 vec3 q=fract(vec3(p.x,p.y,p.x)*vec3(.1031,.1030,.0973));
 q+=dot(q,q.yxz+33.33);
 return fract((q.xx+q.yz)*q.zy);
}
float noise29(vec2 p){
 vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash29(i).x,hash29(i+vec2(1,0)).x,f.x),mix(hash29(i+vec2(0,1)).x,hash29(i+vec2(1,1)).x,f.x),f.y);
}
vec3 patch29(vec2 corner,vec2 p,float row){
 vec2 h=hash29(corner+vec2(row*37.0,19.0));
 float variant=row==1.0?(h.x<.52?0.0:(h.x<.80?3.0:(h.x<.95?1.0:2.0))):floor(h.x*4.0);
 vec2 uv=vec2(.30)+hash29(corner+31.0)*.40+(p-corner)*.28;
 if(h.y>.5){uv.x=1.0-uv.x;}
 return texture(landscape_materials,(vec2(variant,row)+uv)/vec2(4,3)).rgb;
}
vec3 material29(vec2 at,float row){
 vec2 p=floor(at)/48.0,base=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(patch29(base,p,row),patch29(base+vec2(1,0),p,row),f.x),mix(patch29(base+vec2(0,1),p,row),patch29(base+vec2(1,1),p,row),f.x),f.y);
}
vec3 coast_patch29(vec2 corner,vec2 p){
 vec2 h=hash29(corner+73.0);
 float v=h.x<.40?0.0:(h.x<.75?2.0:(h.x<.94?1.0:3.0));
 vec2 uv=vec2(.30)+hash29(corner+91.0)*.40+(p-corner)*.28;
 return texture(coast_materials,(vec2(mod(v,2.0),floor(v/2.0))+uv)*.5).rgb;
}
vec3 coast_ground29(vec2 at){
 vec2 p=floor(at)/64.0,b=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(coast_patch29(b,p),coast_patch29(b+vec2(1,0),p),f.x),mix(coast_patch29(b+vec2(0,1),p),coast_patch29(b+vec2(1,1),p),f.x),f.y);
}
float coast29(vec2 at){
 if(!continent){return 0.0;}
 vec2 q=abs(at-vec2(5656,2072))-vec2(424,232);
 return 1.0-smoothstep(-24.0,72.0,max(q.x,q.y));
}
vec3 landscape29(vec2 at){
 vec3 field=texture(landscape_field,at/map_size).rgb;
 float n=noise29(at/23.0),fine=noise29(floor(at)/3.0);
 float d=field.r+(fine-.5)*3.0+(n-.5)*2.0;
 float road=1.0-smoothstep(-1.5,1.8,d);
 float shoulder=1.0-smoothstep(1.0,19.0,d);
 bool mountain=grave_zone || (continent && at.x>3296.0 && at.y>2496.0);
 float forest=grave_zone?0.0:forest_zone?1.0:(continent?(at.x<3104.0?1.0:max(smoothstep(3824.0,3904.0,at.y),smoothstep(5180.0,5256.0,at.x)*smoothstep(3300.0,3372.0,at.y))):1.0);
 vec3 ground=material29(at,mountain && forest<.999?2.0:1.0);
 if(mountain && forest>.0 && forest<.999){ground=mix(ground,material29(at,1.0),forest);}
 ground=mix(ground,vec3(.19,.235,.205),forest*.14);
 ground=mix(ground,mix(vec3(.24,.245,.235),vec3(.14,.205,.15),forest),.28);
 ground*=.96+(noise29(at/160.0)-.5)*.12;
 float coastal=coast29(at);
 if(coastal>.0){
  vec3 shore=coast_ground29(at);
  shore*=1.0-smoothstep(.0,.7,-field.g)*.25;
  ground=mix(ground,shore,coastal);
 }
 vec3 earth=mix(ground,vec3(.25,.225,.18),.50);
 if(mountain){earth=mix(earth,vec3(.255,.225,.22),.25);}
 vec3 stone=shoulder>.001?material29(at,0.0)*.88:ground;
 if(mountain){stone=mix(stone,earth,.73*(1.0-forest));}
 if(coastal>.0){stone=mix(stone,earth,coastal*.90);}
 vec3 surface=mix(ground,earth,shoulder*.65);
 surface=mix(surface,stone,road);
 float fragments=step(.70,fine)*(1.0-smoothstep(0.0,10.0,abs(d-3.0)));
 surface=mix(surface,stone,fragments*.23);
 float pit=clamp(-field.g,0.0,1.0);
 surface=mix(surface,vec3(.12,.105,.105),pit*.48);
 float relief=clamp((dFdx(field.g)+dFdy(field.g))*3.5,-.12,.12);
 surface*=1.0+max(field.g,0.0)*.13-relief-clamp(field.b,0.0,.30)*.55;
 float pooled=smoothstep(.34,.78,pit+(n-.5)*.23)*max(coastal,wetness*.65);
 vec3 water=mix(vec3(.20,.245,.25),vec3(.28,.315,.31),.5+.5*sin(at.y*.13+sin(at.x*.04)+clock_time*.25));
 surface=mix(surface,mix(earth*.65,water,.72),pooled*.72);
 surface+=vec3(.025,.032,.030)*pooled*pow(max(0.0,sin(at.x*.10+at.y*.17+clock_time*.4)),14.0);
 if(mountain){
  float shadow=(1.0-clamp(dot(surface,vec3(.299,.587,.114))*2.5,0.0,1.0));
  surface=mix(surface,surface*vec3(1.13,.85,.87),shadow*(.12+blood_moon29*.30)*(1.0-forest*.65));
  surface+=vec3(.028,.004,.006)*blood_moon29*max(0.0,noise29(at/240.0)-.58);
 }
 surface*=1.0-wetness*.11;
 if(continent && at.x>3296.0 && at.y<2304.0){surface=mix(surface,vec3(.62,.67,.69),snow*.55);}
 return surface;
}
void fragment(){
	// TileMap batches may remap UVs: the actual map type comes from world coordinates.
	vec2 tile_uv=(floor(world_at/32.0)+0.5)/(map_size/32.0);
	float tile=floor(texture(terrain_types,tile_uv).r*255.0+0.5);
 bool use_landscape=landscape_enabled && !indoor && !(tile>=11.0 && tile<=13.0) && ((!continent && (forest_zone || grave_zone)) || (continent && (world_at.y>2496.0 || coast29(world_at)>.0)));
 if(use_landscape){COLOR=vec4(landscape29(world_at),COLOR.a);}else{
	vec2 local_uv=clamp(fract(floor(world_at)/96.0),vec2(0.002),vec2(0.998))*0.5;
	vec3 region_turf=turf_tint.rgb;
	if(continent){
		region_turf=world_at.y<2400.0?(world_at.x<3200.0?vec3(0.39,0.39,0.27):vec3(0.41,0.38,0.25)):(world_at.x<3200.0?vec3(0.34,0.43,0.27):vec3(0.28,0.35,0.32));
	}
	vec3 turf=mix(region_turf,texture(material_atlas,local_uv).rgb,0.55);
	float macro=0.96+0.035*sin(world_at.x*0.017+cos(world_at.y*0.012));
	vec3 surface=turf*macro;
 vec2 quadrant=vec2(world_at.x>=3200.0?1.0:0.0,world_at.y>=2400.0?1.0:0.0);
 vec3 regional_ground=continent?continuous_ground(world_at,quadrant):turf;
 float pavement=0.0;
 if(continent){surface=regional_ground*macro*0.88;}
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
		pavement=paving;
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
   vec3 sand=mix(vec3(0.57,0.45,0.30),regional_ground,0.80)*(0.94+dunes*0.035+grain*0.035);
   float ridge=smoothstep(0.75,0.94,dunes);
   sand+=vec3(0.025,0.022,0.015)*ridge;
   float trail=pavement*.75;
   bool courtyard=world_at.x>1088.0 && world_at.x<1920.0 && world_at.y>608.0 && world_at.y<1476.0;
   surface=courtyard && paved?mix(mix(vec3(0.46,0.40,0.31),surface,0.38),sand,0.35+grain*0.25):sand*(1.0-trail*.055);
   surface=mix(surface,sand,dust*0.12);
  }else if(edo){
   vec3 soil=mix(vec3(0.31,0.33,0.30),regional_ground,0.80)*(0.9+grain*0.08);
   float patches=smoothstep(0.2,0.8,sin(world_at.x*0.019+cos(world_at.y*.021)));
   surface=mix(mix(soil,vec3(0.30,0.37,0.30),patches*.20),mix(vec3(0.32,0.31,0.28),surface,0.65),pavement);
   float joints=step(30.5,mod(world_at.y,32.0))+step(46.5,mod(world_at.x+floor(world_at.y/32.0)*16.0,48.0));
   if(paved){surface*=1.0-min(1.0,joints)*0.25;}
   float drift=smoothstep(0.1,0.85,sin(world_at.x*.023+cos(world_at.y*.017))*.5+.5);
   surface=mix(surface,vec3(0.63,0.68,0.69),snow*(0.35+drift*.5));
  }else if(mountain){
   float slope=sin(world_at.x*.011+sin(world_at.y*.006)*2.0);
   float strata=smoothstep(0.75,0.96,sin(world_at.y*.043+slope*2.0));
   vec3 earth=mix(vec3(0.25,0.28,0.27),vec3(0.32,0.32,0.29),slope*.5+.5);
   earth=mix(earth,regional_ground,0.82);
   earth*=0.94+grain*.06-strata*.04;
   float trail=pavement*(0.75+0.12*sin(world_at.y*.024));
   surface=earth*(1.0-trail*0.13);
   if(grain>.93 && trail>.25){surface+=vec3(0.025,0.023,0.020);}
  }
  surface*=1.0-wetness*0.10;
 }
	if(indoor){surface=texture(material_atlas,local_uv+vec2(0.5,0.5)).rgb*1.32;}
	COLOR=vec4(surface,COLOR.a);
 }
}
