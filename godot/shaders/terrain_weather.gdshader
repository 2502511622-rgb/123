shader_type canvas_item;
uniform float clock_time=0.0;
uniform float wetness=0.0;
varying vec2 world_at;
void vertex(){world_at=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}
void fragment(){
	float tile=floor(UV.x*32.0);
	if(tile>=11.0 && tile<=13.0){
		vec2 uv=UV;
		uv.x+=sin(world_at.y*0.12+clock_time*1.6)*0.0016;
		uv.x=clamp(uv.x,(tile*32.0+0.5)/1024.0,((tile+1.0)*32.0-0.5)/1024.0);
		float ripple=sin(world_at.x*0.09+clock_time*1.5)*sin(world_at.y*0.24-clock_time*1.8);
		COLOR=texture(TEXTURE,uv);
		COLOR.rgb+=vec3(0.10,0.16,0.16)*smoothstep(0.65,0.97,ripple);
	}else if(tile>=16.0 || tile==10.0){
		float sheen=pow(max(0.0,sin(world_at.y*0.11+world_at.x*0.05)),18.0);
		COLOR.rgb*=1.0-wetness*0.15;
		COLOR.rgb+=vec3(0.05,0.085,0.10)*sheen*wetness;
	}
}
