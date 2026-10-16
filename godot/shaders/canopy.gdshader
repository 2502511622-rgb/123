shader_type canvas_item;
uniform float clock_time=0.0;
uniform float wind=0.5;
uniform float phase=0.0;
uniform float wetness=0.0;
uniform bool world_phase=false;
void vertex(){
	float phase_value=phase+(world_phase?(MODEL_MATRIX[3].x*0.03+MODEL_MATRIX[3].y*0.02):0.0);
	float canopy=clamp((124.0-VERTEX.y)/100.0,0.0,1.0);
	VERTEX.x+=(sin(clock_time*1.1+phase_value)*1.8+sin(clock_time*2.5+phase_value+VERTEX.y*0.08)*0.65)*canopy*canopy*wind;
	VERTEX.y+=sin(clock_time*1.5+phase_value)*canopy*0.5*wind;
}
void fragment(){
	float edge=abs(texture(TEXTURE,UV+vec2(-0.016,-0.011)).a-COLOR.a);
	COLOR.rgb*=1.0-wetness*0.11;
	COLOR.rgb+=vec3(0.12,0.16,0.09)*edge*0.3;
}
