shader_type canvas_item;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float wetness : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	float above=texture(TEXTURE,UV-vec2(0.0,TEXTURE_PIXEL_SIZE.y)).a;
	float left=texture(TEXTURE,UV-vec2(TEXTURE_PIXEL_SIZE.x,0.0)).a;
	float edge=max(0.0,texture(TEXTURE,UV).a-min(above,left));
	vec3 lit=COLOR.rgb*(1.0-wetness*0.06)+vec3(0.12,0.14,0.10)*edge*(0.35+wetness*0.35);
	COLOR.rgb=mix(lit,vec3(1.0),flash);
}
