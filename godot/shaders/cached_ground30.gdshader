shader_type canvas_item;
uniform sampler2D terrain_types: filter_nearest,repeat_disable;
uniform sampler2D landscape_field: filter_linear,repeat_disable;
uniform vec2 map_size;
uniform vec2 hero_at;
uniform float clock_time=0.0;
uniform float wetness=0.0;
uniform float snow=0.0;
uniform float dust=0.0;
uniform float blood=0.0;
varying vec2 at;
void vertex(){at=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}
void fragment(){
 vec4 cached=texture(TEXTURE,UV);vec3 base=cached.rgb;
 bool water=cached.a>.25;
 if(water){
  float wave=sin(at.x*.065+at.y*.035+clock_time*1.2)*sin(at.y*.081-clock_time*.7);
  base+=vec3(.025,.04,.04)*wave;
  vec2 cell=mod(at,18.0)-9.0;
  float age=fract(clock_time*.7+fract(dot(floor(at/18.0),vec2(.71,.39))));
  float ring=1.0-smoothstep(.3,.85,abs(length(cell)-age*8.0));
  base+=vec3(.07,.10,.10)*ring*(1.0-age)*wetness;
 }else{
  // Quiet midtones keep enemies, silhouettes and impact colors readable.
  float luma=dot(base,vec3(.299,.587,.114));
  base=mix(base,vec3(luma),.12);
  base=mix(base,vec3(.20,.22,.20),.13);
  base*=1.0-wetness*.13;
  if(at.x>3296.0 && at.y<2304.0){base=mix(base,vec3(.62,.67,.69),snow*.55);}
  if(at.x<3104.0 && at.y<2304.0){base=mix(base,vec3(.43,.34,.25),dust*.20);}
  if(at.x>3296.0 && at.y>2496.0){base*=mix(vec3(1),vec3(1.04,.92,.94),blood*.40);}

 }
 COLOR=vec4(base,1.0);
}
