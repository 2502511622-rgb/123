shader_type canvas_item;
uniform float clock_time=0.0;
uniform float wind=.5;
uniform float wetness=0.0;
uniform vec2 player_at;
void vertex(){
 vec2 root=(MODEL_MATRIX*vec4(vec2(.5,1.0)/TEXTURE_PIXEL_SIZE,0.0,1.0)).xy;
 float tip=1.0-UV.y;
 float push=(1.0-smoothstep(5.0,27.0,distance(root,player_at)))*sign(root.x-player_at.x);
 VERTEX.x+=tip*tip*(sin(clock_time*1.8+root.x*.05)*wind*1.2+push*3.0);
}
void fragment(){
 vec4 tex=texture(TEXTURE,UV);if(tex.a<.42){discard;}
 COLOR.rgb*=1.0-wetness*.10;
}
