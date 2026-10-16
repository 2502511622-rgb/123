shader_type canvas_item;
uniform float snow=0.0;
uniform float dust=0.0;
uniform float wetness=0.0;
varying vec2 world_at;
void vertex(){world_at=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}
void fragment(){
 vec4 texel=texture(TEXTURE,UV);
 if(texel.a<0.4){discard;}
 vec3 surface=COLOR.rgb;
 float inside=min(min(texture(TEXTURE,UV+vec2(TEXTURE_PIXEL_SIZE.x,0)).a,texture(TEXTURE,UV-vec2(TEXTURE_PIXEL_SIZE.x,0)).a),min(texture(TEXTURE,UV+vec2(0,TEXTURE_PIXEL_SIZE.y)).a,texture(TEXTURE,UV-vec2(0,TEXTURE_PIXEL_SIZE.y)).a));
 surface*=1.0-wetness*0.13;
 float grain=fract(sin(dot(floor(UV/TEXTURE_PIXEL_SIZE),vec2(12.9898,78.233)))*43758.5453);
 float roof=1.0-smoothstep(0.3,0.58,UV.y);
 if(world_at.x>=3200.0 && world_at.y<2400.0){surface=mix(surface,vec3(0.66,0.71,0.74),snow*roof*inside*(0.38+grain*0.4));}
 if(world_at.x<3200.0 && world_at.y<2400.0){surface=mix(surface,surface*vec3(1.08,1.02,0.89),dust*0.25);}
 COLOR.rgb=surface;
 COLOR.a*=smoothstep(0.4,0.8,texel.a);
}
