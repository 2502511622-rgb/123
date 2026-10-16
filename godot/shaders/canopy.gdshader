shader_type canvas_item;
uniform float clock_time=0.0;
uniform float wind=0.5;
uniform float phase=0.0;
uniform float wetness=0.0;
uniform float snow=0.0;
varying vec2 canopy_at;
uniform bool world_phase=false;
void vertex(){
 canopy_at=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;
	float phase_value=phase+(world_phase?(MODEL_MATRIX[3].x*0.03+MODEL_MATRIX[3].y*0.02):0.0);
	float canopy=clamp((124.0-VERTEX.y)/100.0,0.0,1.0);
	VERTEX.x+=(sin(clock_time*1.1+phase_value)*1.8+sin(clock_time*2.5+phase_value+VERTEX.y*0.08)*0.65)*canopy*canopy*wind;
	VERTEX.y+=sin(clock_time*1.5+phase_value)*canopy*0.5*wind;
}
void fragment(){
	float edge=abs(texture(TEXTURE,UV+vec2(-0.016,-0.011)).a-COLOR.a);
	COLOR.rgb*=1.0-wetness*0.11;
	COLOR.rgb*=1.0-edge*0.08;
 if(texture(TEXTURE,UV).a<0.35){discard;}
 COLOR.a*=smoothstep(0.35,0.8,texture(TEXTURE,UV).a);
 if(canopy_at.x>=3200.0 && canopy_at.y<2400.0){COLOR.rgb=mix(COLOR.rgb,vec3(0.61,0.68,0.71),snow*(1.0-smoothstep(0.2,0.65,UV.y))*0.45);}
}
