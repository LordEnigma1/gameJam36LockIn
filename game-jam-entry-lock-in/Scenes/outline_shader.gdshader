shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // White
uniform float line_thickness : hint_range(0.0, 10.0) = 0.0;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Default: normal colors

void fragment() {
	vec2 size = TEXTURE_PIXEL_SIZE * line_thickness;
	float alpha = texture(TEXTURE, UV).a;
	
	float outline = texture(TEXTURE, UV + vec2(-size.x, 0.0)).a + 
	                texture(TEXTURE, UV + vec2(size.x, 0.0)).a + 
	                texture(TEXTURE, UV + vec2(0.0, -size.y)).a + 
	                texture(TEXTURE, UV + vec2(0.0, size.y)).a;
	
	if (alpha < 0.0001 && outline > 0.0001) {
    	COLOR = outline_color;
	} else {
    	COLOR = texture(TEXTURE, UV);
	}
}